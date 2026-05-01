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

<<<<<<< HEAD

// var builder = WebApplication.CreateBuilder(args);

=======
>>>>>>> e2692fa3eeaf4a146766959f7f01fb546b9a48b6
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

// builder.Services.AddScoped<UserService>();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

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
