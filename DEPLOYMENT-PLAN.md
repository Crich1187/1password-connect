# 1Password Connect Deployment Plan

## What You Have
- ✅ 1Password Connect Token (in 1Password: "1Password Connect Token")
- ✅ Setup Credentials File (in 1Password: "Setup Credentials File")
- ✅ Credentials downloaded to `/tmp/1password-credentials.json`
- ✅ Base64 encoded at `/tmp/1password-credentials.b64`

## Next Steps
1. Create GitHub repo: `github.com/Crich1187/1password-connect`
2. Add files from `~/3_Development/infrastructure/1password-connect/`
3. Push to GitHub
4. Create Render service connected to that repo
5. **IMPORTANT**: Add environment variables manually in Render Dashboard:
   - `OP_SESSION` = contents of `/tmp/1password-credentials.b64`
   - `TAILSCALE_AUTHKEY` = (generate new ephemeral key or reuse Kong's key)
6. Deploy and verify on Tailscale network

## Security Note
- OP_SESSION contains encrypted credentials - NEVER commit to Git
- render.yaml has `sync: false` for both secrets
- Must be added manually in Render Dashboard

## Kong Integration
Once deployed, Kong can fetch secrets via:
- URL: `http://1password-connect.tailscale-network:8080`
- Token: (from "1Password Connect Token" item)

## Alternative: Skip for Now
Use Render environment variables for Kong/MCP secrets instead
- Simpler, no extra infrastructure
- Can add 1Password Connect later
