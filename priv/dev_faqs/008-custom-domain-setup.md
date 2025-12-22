---
title: "Custom Domain Setup for User Profiles"
order: 8
category: "deployment"
---

# Custom Domain Setup for User Profiles

## Overview

You can point your own domain (e.g., `yourdomain.com`) to your user profile page on the homesite. This guide explains the setup process.

## Prerequisites

1. A registered domain name you control
2. Access to your domain's DNS settings
3. Server admin access (for Caddy configuration)

## How It Works

The setup involves two parts:

1. **DNS Configuration** - Point your domain to the server
2. **Caddy Configuration** - Reverse proxy and URL rewriting

## Step 1: Configure DNS

Point your domain's **A record** to the server IP address.

**Example:**
```
yourdomain.com    A    [SERVER_IP]
```

If you're using Cloudflare or similar DNS proxy:
- Enable DNS proxy (orange cloud) for HTTPS
- Or disable proxy if you want Caddy to handle TLS directly

## Step 2: Caddy Configuration

Add a new server block to the Caddyfile:

### Option A: Redirect to User Profile

```caddyfile
yourdomain.com {
    redir https://juhahalmu.fi/users/@yourusername{uri} permanent
}
```

This redirects all requests to the main site's user profile.

### Option B: Reverse Proxy with Rewrite

```caddyfile
yourdomain.com {
    reverse_proxy localhost:4000
    rewrite * /users/@yourusername{uri}
}
```

This proxies requests and rewrites URLs, keeping the custom domain in the browser.

**Note:** Option B requires adding the domain to `PHX_CHECK_ORIGIN_HOSTS` environment variable:

```bash
PHX_CHECK_ORIGIN_HOSTS=yourdomain.com,otherdomain.net
```

## Step 3: TLS Certificate

Caddy automatically obtains Let's Encrypt certificates. After adding the Caddyfile config:

1. Reload Caddy: `caddy reload`
2. Wait 1-2 minutes for certificate provisioning
3. Visit your domain via HTTPS

## Example: juhahalmu.net

To point `juhahalmu.net` to the user profile at `/users/@jhalmu`:

**DNS (at domain registrar):**
```
juhahalmu.net    A    [HETZNER_SERVER_IP]
```

**Caddyfile:**
```caddyfile
juhahalmu.net {
    redir https://juhahalmu.fi/users/@jhalmu{uri} permanent
}
```

**Or for proxy mode:**
```caddyfile
juhahalmu.net {
    reverse_proxy localhost:4000
    rewrite * /users/@jhalmu{uri}
}
```

Plus add to `.env`:
```
PHX_CHECK_ORIGIN_HOSTS=orangedinos.de,juhahalmu.net
```

## Troubleshooting

### WebSocket/LiveView Not Working

If LiveView connections fail with "origin mismatch":
- Add domain to `PHX_CHECK_ORIGIN_HOSTS`
- Restart the application

### 404 Errors

If you see 404s:
- Check the rewrite rule matches your actual username
- Verify the user profile exists at the main site

### TLS Certificate Issues

If certificate provisioning fails:
- Ensure DNS is pointing correctly (check with `dig yourdomain.com`)
- Check Caddy logs: `journalctl -u caddy -f`
- Verify port 80/443 are accessible

## Current Domains

| Domain | Points To | Type |
|--------|-----------|------|
| juhahalmu.fi | Main site | Primary |
| orangedinos.de | Main site | Alias |
| juhahalmu.net | /users/@jhalmu | User profile (planned) |
