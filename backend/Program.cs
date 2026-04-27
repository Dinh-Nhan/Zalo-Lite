using backend.Services;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;

var builder = WebApplication.CreateBuilder(args);

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
// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddSingleton<FirebaseService>();
builder.Services.AddScoped<UserService>();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseMiddleware<FirebaseAuthMiddleware>();

app.MapControllers();

app.Run();
