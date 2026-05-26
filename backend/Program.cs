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

builder.Host.UseSerilog((ctx, config) => config
    .ReadFrom.Configuration(ctx.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console(outputTemplate:
        "[{Timestamp:HH:mm:ss} {Level:u3}] {SourceContext} | {Message}{NewLine}{Exception}"));

// ── Redis ────────────────────────────────────────────────
builder.Services.AddSingleton<IConnectionMultiplexer>(sp =>
{
    var config = builder.Configuration["Redis:ConnectString"]!;
    return ConnectionMultiplexer.Connect(config);
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

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
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

// ── SignalR ──────────────────────────────────────
builder.Services.AddSignalR();

// ── CORS (cần thiết cho Flutter Web / dev) ────────────────
builder.Services.AddCors(opt =>
{
    opt.AddDefaultPolicy(policy =>
        policy
            .AllowAnyHeader()
            .AllowAnyMethod()
            .SetIsOriginAllowed(_ => true) // dev only
            .AllowCredentials());
});

var app = builder.Build();
app.UseCors("AllowAll");
app.UseAuthorization();
app.UseMiddleware<GlobalExceptionHandler>();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();
app.UseHttpsRedirection();
app.UseRouting();

app.UseMiddleware<FirebaseAuthMiddleware>();

app.MapControllers();
app.MapHub<FriendHub>("/hubs/friend");

app.Run();