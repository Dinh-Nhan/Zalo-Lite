using System.Reflection;
using backend.Attributes;
using backend.Hubs;
using backend.Middleware;
using backend.Services;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using FluentValidation;
using FluentValidation.AspNetCore;
using Mapster;
using MapsterMapper;
using Serilog;
using StackExchange.Redis;
using Microsoft.OpenApi.Models;
using backend.swagger;
using backend.settings;

var builder = WebApplication.CreateBuilder(args);

// var firebaseConfig = builder.Configuration.GetSection("Firebase");
// var projectId = firebaseConfig["ProjectId"];
// var credentialPath = firebaseConfig["CredentialsFilePath"];

// var credential = CredentialFactory
//     .FromFile<ServiceAccountCredential>(credentialPath)
//     .ToGoogleCredential();

// FirebaseApp.Create(new AppOptions()
// {
//     Credential = credential,
//     ProjectId = projectId
// });

// background service 
builder.Services.AddHostedService<StoryExpirationService>();


//var builder = WebApplication.CreateBuilder(args);

// ── Serilog ────────────────────────────────────────────────
builder.Host.UseSerilog((ctx, config) => config
    .ReadFrom.Configuration(ctx.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console(outputTemplate:
        "[{Timestamp:HH:mm:ss} {Level:u3}] {SourceContext} | {Message}{NewLine}{Exception}"));

// ── Redis ──────────────────────────────────────────────────
builder.Services.AddSingleton<IConnectionMultiplexer>(sp =>
{
    var config = builder.Configuration["Redis:ConnectString"]!;
    return ConnectionMultiplexer.Connect(config);
});
builder.Services.AddScoped<IDatabase>(sp =>
{
    var redis = sp.GetRequiredService<IConnectionMultiplexer>();
    return redis.GetDatabase();
});
// ── Cloudinary ────────────────────────────────────────────────
builder.Services.Configure<CloudinarySettings>(
    builder.Configuration.GetSection("Cloudinary"));
// ── Mapster ────────────────────────────────────────────────
var mapsterConfig = TypeAdapterConfig.GlobalSettings;
mapsterConfig.Scan(Assembly.GetExecutingAssembly());
builder.Services.AddSingleton(mapsterConfig);
builder.Services.AddScoped<IMapper, ServiceMapper>();

// ── FluentValidation ───────────────────────────────────────
builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddValidatorsFromAssemblyContaining<Program>();

// ── Auto scan Services ─────────────────────────────────────
builder.Services.Scan(scan => scan
    .FromAssemblyOf<Program>()
    .AddClasses(c => c.WithAttribute<ScopedServiceAttribute>())
    .AsSelf()
    .WithScopedLifetime());

// ── Middleware ─────────────────────────────────────────────
builder.Services.AddTransient<GlobalExceptionHandler>();

// ── Firebase & Firestore ───────────────────────────────────
builder.Services.AddSingleton<FirebaseService>();
builder.Services.AddSingleton(sp =>
    sp.GetRequiredService<FirebaseService>().FirestoreDb);

builder.Services.AddScoped<UserService>();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
// add options using bearer token to verify access token when request api
builder.Services.AddSwaggerGen(
    options =>
{
    // config xml for comment in controller to explain api 
    var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    options.IncludeXmlComments(xmlPath);


    //require bearer token for per request in backend
    options.OperationFilter<AuthorizeCheckOperationFilter>();

    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Nhập token theo định dạng: Bearer {token}"
    });
}
);

// ── SignalR ────────────────────────────────────────────────
builder.Services.AddSignalR();

// ── CORS ───────────────────────────────────────────────────
builder.Services.AddCors(opt =>
{
    opt.AddDefaultPolicy(policy =>
        policy
            .AllowAnyHeader()
            .AllowAnyMethod()
            .SetIsOriginAllowed(_ => true) // dev only — thu hẹp lại khi lên production
            .AllowCredentials());
});

// ══════════════════════════════════════════════════════════
//  PIPELINE — đúng thứ tự ASP.NET Core
// ══════════════════════════════════════════════════════════
var app = builder.Build();

// ── Warm-up Firebase ───────────────────────────────────────
// Initialize FirebaseService immediately to ensure FirebaseApp.DefaultInstance is ready
app.Services.GetRequiredService<FirebaseService>();

// 1. Bắt exception toàn cục — phải đứng đầu tiên
app.UseMiddleware<GlobalExceptionHandler>();

// 2. HTTPS redirect
app.UseHttpsRedirection();

// 3. Swagger (chỉ dev)
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// 4. Routing — phải trước CORS & Auth
app.UseRouting();

// 5. CORS — sau Routing, trước Auth
app.UseCors();

// 6. Firebase Auth Middleware — parse & validate token,
//    gắn claims vào HttpContext trước khi UseAuthorization chạy
app.UseMiddleware<FirebaseAuthMiddleware>();

// 7. Authorization
app.UseAuthentication();
app.UseAuthorization();

// 8. Endpoints
app.MapControllers();
app.MapHub<FriendHub>("/hubs/friend");

app.Run();