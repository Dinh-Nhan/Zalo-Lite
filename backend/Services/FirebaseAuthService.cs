using FirebaseAdmin.Auth;

public class FirebaseAuthService
{
    public async Task<FirebaseToken?> VerifyTokenAsync(string idToken)
    {
        try
        {
            return await FirebaseAuth.DefaultInstance
                .VerifyIdTokenAsync(idToken, true);
        }
        catch
        {
            return null;
        }
    }

    public async Task<UserRecord?> GetUserAsync(string uid)
    {
        try
        {
            return await FirebaseAuth.DefaultInstance.GetUserAsync(uid);
        }
        catch
        {
            return null;
        }
    }

    public async Task<bool> RevokeRefreshTokensAsync(string uid)
    {
        try
        {
            await FirebaseAuth.DefaultInstance.RevokeRefreshTokensAsync(uid);
            return true;
        }
        catch
        {
            return false;
        }
    }
}