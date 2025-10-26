#!/bin/sh
set -e

# Ensure Tailscale state directory exists
mkdir -p /var/lib/tailscale
chmod 700 /var/lib/tailscale

# Ensure 1Password Connect data directory exists
mkdir -p /home/opuser/.op/data
chmod 700 /home/opuser/.op/data

# Decode and write credentials file
if [ -n "$OP_SESSION" ]; then
    echo "Writing 1Password Connect credentials..."
    echo "$OP_SESSION" | base64 -d > /home/opuser/.op/1password-credentials.json
    chmod 600 /home/opuser/.op/1password-credentials.json
else
    echo "ERROR: OP_SESSION environment variable not set"
    exit 1
fi

# Start Tailscale daemon with persistent state
echo "Starting Tailscale daemon..."
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 --state=/var/lib/tailscale/tailscaled.state &

# Wait for tailscaled to start
sleep 5

# Authenticate with Tailscale
if [ -n "$TAILSCALE_AUTHKEY" ]; then
    echo "Checking Tailscale connection status..."

    # Check if already connected (state persisted from previous deploy)
    if tailscale status 2>/dev/null | grep -q "100\."; then
        echo "Tailscale already connected! Reusing existing machine."
        tailscale status
    else
        echo "Authenticating with Tailscale for the first time..."
        tailscale up --authkey="$TAILSCALE_AUTHKEY" --hostname=1password-connect
        echo "Tailscale connected!"
        tailscale status
    fi
else
    echo "WARNING: TAILSCALE_AUTHKEY not set, skipping Tailscale authentication"
fi

# Start 1Password Connect API server
echo "Starting 1Password Connect API server..."
exec op-connect api \
    --credentials=/home/opuser/.op/1password-credentials.json \
    --http-addr=0.0.0.0:8080
