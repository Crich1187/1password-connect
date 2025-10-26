# 1Password Connect Server on Render

Secure secret management server for Kong Gateway and MCP servers, deployed on Render with Tailscale networking.

## Architecture

- **1Password Connect API**: Self-hosted secrets API server
- **Tailscale**: Private network overlay for secure access
- **Render**: Cloud hosting with persistent storage
- **Kong Integration**: Gateway fetches secrets via Tailscale network

## Deployment Steps

### 1. Create Render Service

1. Go to https://dashboard.render.com
2. Click "New +" → "Web Service"
3. Connect to GitHub repository: `Crich1187/1password-connect`
4. Configure service:
   - **Name**: `1password-connect`
   - **Region**: Virginia (or match Kong's region)
   - **Branch**: `main` or `master`
   - **Runtime**: Docker
   - **Plan**: Starter ($7/month) - required for persistent disks

### 2. Add Environment Variables

**CRITICAL**: Add these manually in Render Dashboard (never commit to Git):

| Variable | Value | Source |
|----------|-------|--------|
| `OP_SESSION` | [base64 credentials] | `/tmp/1password-credentials.b64` |
| `TAILSCALE_AUTHKEY` | [auth key] | Generate ephemeral key at https://login.tailscale.com/admin/settings/keys |

To get `OP_SESSION` value:
```bash
cat /tmp/1password-credentials.b64
```

To generate Tailscale auth key:
1. Go to https://login.tailscale.com/admin/settings/keys
2. Click "Generate auth key"
3. Check "Ephemeral" (auto-cleanup when offline)
4. Set description: "1Password Connect on Render"
5. Copy the key (starts with `tskey-auth-`)

### 3. Deploy

1. Click "Create Web Service"
2. Render will build and deploy automatically
3. Check logs for successful startup:
   - "Tailscale connected!"
   - "Starting 1Password Connect API server..."

### 4. Verify on Tailscale

1. Go to https://login.tailscale.com/admin/machines
2. Look for `1password-connect` machine
3. Note the IP address (e.g., `100.x.x.x`)

### 5. Test the API

From any Tailscale-connected machine:

```bash
# Get 1Password Connect Token from 1Password
OP_TOKEN="<token from 1Password item>"

# Test health endpoint
curl http://1password-connect:8080/health

# Test vaults endpoint
curl -H "Authorization: Bearer $OP_TOKEN" \
     http://1password-connect:8080/v1/vaults
```

## Kong Integration

Configure Kong to fetch secrets from this server:

```bash
# Kong can now access secrets at:
# URL: http://1password-connect:8080
# Token: (from "1Password Connect Token" item in 1Password)
```

## Files

- `Dockerfile`: Multi-stage build with 1Password Connect + Tailscale
- `start-connect.sh`: Startup script with persistent state management
- `render.yaml`: Service configuration with persistent disks
- `DEPLOYMENT-PLAN.md`: Detailed deployment notes

## Persistent Storage

Two persistent disks configured:

1. **op-data** (`/home/opuser/.op/data`): 1Password Connect data
2. **tailscale-state** (`/var/lib/tailscale`): Maintains single Tailscale identity

## Security

- ✅ Credentials stored in Render environment (not Git)
- ✅ Ephemeral Tailscale keys auto-cleanup old instances
- ✅ Tailscale-only access (not exposed to public internet)
- ✅ Encrypted credentials file (even in environment)

## Troubleshooting

**Multiple Tailscale instances appearing**:
- First deployment creates new instance due to infrastructure changes
- Subsequent deploys reuse persistent state
- Old instances auto-cleanup with ephemeral keys

**Cannot connect to API**:
- Verify Tailscale machine is online: `tailscale status`
- Check Render logs for startup errors
- Confirm `OP_SESSION` is set correctly

**1Password Connect errors**:
- Verify credentials file is valid
- Check that it matches the Connect Token in 1Password
