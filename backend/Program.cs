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

var builder = WebApplication.CreateBuilder(args);

// ── Firebase ───────────────────────────────────────────────
var firebaseConfig = builder.Configuration.GetSection("Firebase");
var projectId = firebaseConfig["ProjectId"];
var credentialPath = firebaseConfig["CredentialsFilePath"];

var credential = CredentialFactory
    .FromFile<ServiceAccountCredential>(credentialPath)
    .ToGoogleCredential();

FirebaseApp.Create(new AppOptions()
{
    Credential = credential,
    ProjectId = projectId
});

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

// ── Controllers, Swagger ───────────────────────────────────
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

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
app.UseAuthorization();

// 8. Endpoints
app.MapControllers();
app.MapHub<FriendHub>("/hubs/friend");

app.Run();