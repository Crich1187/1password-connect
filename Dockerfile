FROM 1password/connect-api:latest AS connect

FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache ca-certificates iptables curl

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Copy 1Password Connect from official image
COPY --from=connect /usr/local/bin/op-connect /usr/local/bin/op-connect

# Copy startup script
COPY start-connect.sh /start-connect.sh
RUN chmod +x /start-connect.sh

# Expose 1Password Connect API port
EXPOSE 8080

# Start Tailscale and 1Password Connect
CMD ["/start-connect.sh"]
