# Homesite Deployment Guide

**Created:** 2025-12-02 | **Updated:** 2025-12-15
**Stack:** Phoenix + PostgreSQL + Docker + Coolify + Tailscale
**Status:** Ready for Implementation

---

## Quick Summary

| Component | Choice | Why |
|-----------|--------|-----|
| **PaaS** | Coolify | Web UI, auto-deploy, backups, monitoring |
| **VPN** | Tailscale | Zero-config security, custom domains, HTTPS |
| **Database** | PostgreSQL (Coolify-managed) | One-click setup, auto backups |
| **Email** | SendGrid Free | 100 emails/day, $0 |
| **Cost** | ~$60-115/year | Domain + electricity only |

---

## Architecture

```
Your Devices (Phone, Laptop)
    ↓ Tailscale (WireGuard encrypted)
    ↓ https://homesite.yourdomain.com
    ↓
Home Server
    ├── Coolify (port 8000) - Management UI
    ├── Phoenix App (Docker) - Your blog
    └── PostgreSQL (Docker) - Database
```

**Access Points:**
- Blog: `https://homesite.yourdomain.com`
- Admin: `https://coolify.yourdomain.com:8000` (Tailscale only)

---

## Phase 1: Tailscale Setup (15 min)

### 1.1 Install on Server

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --hostname homeserver

# Verify
tailscale ip -4  # Shows 100.x.x.x

# Enable on boot
sudo systemctl enable tailscaled
```

### 1.2 Configure DNS & HTTPS

**In Tailscale Admin Console** (https://login.tailscale.com/admin/dns):
1. Enable **MagicDNS**
2. Enable **HTTPS**
3. Add custom domain: `homesite.yourdomain.com`
4. Copy the TXT record values provided

**In Your DNS Provider:**
```
Type: CNAME
Name: homesite
Value: homeserver.your-tailnet.ts.net
TTL: 3600

Type: TXT
Name: _acme-challenge.homesite
Value: (from Tailscale)
TTL: 300
```

Wait 5-60 minutes for DNS propagation.

---

## Phase 2: Coolify Setup (20 min)

### 2.1 Install Coolify

```bash
# One-line installation (installs Docker too)
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

### 2.2 Access Coolify

```bash
# Get Tailscale IP
tailscale ip -4

# Open in browser (via Tailscale)
http://100.x.x.x:8000
```

Complete initial setup:
- Set admin email and password
- Configure server settings

### 2.3 Configure Coolify Domain (Optional)

In Coolify UI: Settings → Configuration → General
- Set FQDN: `coolify.yourdomain.com`

Add DNS records (same pattern as above).

---

## Phase 3: Database Setup (5 min)

**In Coolify UI:**

1. Resources → Databases → New Database
2. Select: **PostgreSQL 18**
3. Configure:
   - Database name: `homesite_prod`
   - Username: `homesite`
   - Password: (auto-generate)
4. Click Create

**Note the connection string:**
```
postgres://homesite:PASSWORD@homesite_prod:5432/homesite_prod
```

Enable automatic backups in database settings.

---

## Phase 4: Prepare Phoenix App (10 min)

### 4.1 Generate Release Files

```bash
cd /path/to/homesite

# Generate Dockerfile and release files
mix phx.gen.release --docker

# Generate secret key
mix phx.gen.secret
# Save this output!

# Commit to Git
git add Dockerfile .dockerignore rel/
git commit -m "feat: Add Docker deployment files"
git push
```

### 4.2 Add Health Check (if not exists)

**File:** `lib/homesite_web/controllers/health_controller.ex`
```elixir
defmodule HomesiteWeb.HealthController do
  use HomesiteWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok", timestamp: DateTime.utc_now()})
  end
end
```

**In `router.ex`:**
```elixir
scope "/", HomesiteWeb do
  pipe_through :api
  get "/health", HealthController, :index
end
```

---

## Phase 5: Deploy Application (20 min)

### 5.1 Create Application in Coolify

**In Coolify UI:**

1. Resources → Applications → New Application
2. Source: **Git Repository**
3. Repository URL: `https://github.com/yourusername/homesite.git`
4. Branch: `main`
5. Build Pack: **Dockerfile**

### 5.2 Configure Environment Variables

In Coolify: Your App → Environment Variables

```bash
# Database (use Coolify internal hostname)
DATABASE_URL=postgres://homesite:PASSWORD@homesite_prod:5432/homesite_prod

# Phoenix
SECRET_KEY_BASE=your_generated_secret_key_base
PHX_HOST=homesite.yourdomain.com
PORT=4000
PHX_SERVER=true
POOL_SIZE=10

# Email (optional)
SENDGRID_API_KEY=your_sendgrid_api_key
```

### 5.3 Configure Domain

In Coolify: Your App → Domains
- Add domain: `homesite.yourdomain.com`
- Enable HTTPS

### 5.4 Deploy

Click **Deploy** button. Coolify will:
1. Clone repository
2. Build Docker image
3. Start application
4. Monitor health

Watch real-time logs in Coolify UI.

### 5.5 Run Migrations

In Coolify: Your App → Execute Command
```bash
/app/bin/migrate
```

---

## Phase 6: Auto-Deploy Setup (5 min)

### GitHub Webhook

1. In Coolify: Your App → Source → Webhooks → Copy URL
2. In GitHub: Repository → Settings → Webhooks → Add webhook
3. Paste Coolify URL, select "Push" events

Now `git push` automatically deploys!

---

## Phase 7: Client Access (5 min per device)

### Install Tailscale on Your Devices

- **Desktop:** https://tailscale.com/download
- **iOS:** App Store → "Tailscale"
- **Android:** Google Play → "Tailscale"

Sign in with same account. Access blog from anywhere!

---

## Public vs Private Access

### Private Only (Default)

Blog accessible only via Tailscale. Most secure.

### Public Blog + Private Admin

Enable Tailscale Funnel for public access:

```bash
# On server
sudo tailscale funnel 443 on
```

Result:
- Blog: Public (anyone can read)
- Coolify UI: Private (Tailscale only)
- Admin routes: Protected by Phoenix auth

---

## Maintenance

### Backups

Coolify handles database backups automatically.
- Configure in: Database → Backups
- Schedule: Daily at 2 AM
- Retention: 30 days

### Rollback

If deployment breaks:
1. Coolify UI → Deployments
2. Select previous version
3. Click "Redeploy"

### Monitoring

Coolify provides:
- Real-time logs
- CPU/memory graphs
- Health checks
- Email/webhook alerts

---

## Cost Breakdown

| Component | Cost/Year |
|-----------|-----------|
| Coolify | $0 (open source) |
| Tailscale | $0 (free tier) |
| Home Server | $0 (owned) |
| Electricity | ~$50-100 |
| Domain | $10-15 |
| SendGrid | $0 (free tier) |
| **Total** | **$60-115** |

---

## Troubleshooting

### App Won't Start

```bash
# Check logs in Coolify UI
# Verify environment variables
# Test database connection
```

### Can't Access via Tailscale

```bash
sudo tailscale status
ping homeserver.your-tailnet.ts.net
```

### HTTPS Not Working

- Check DNS propagation: `dig homesite.yourdomain.com`
- Verify TXT records in Tailscale admin
- Wait up to 1 hour for propagation

---

## Checklist

### Server Setup
- [ ] Install Tailscale, set hostname
- [ ] Enable MagicDNS and HTTPS
- [ ] Add custom domain DNS records
- [ ] Install Coolify
- [ ] Set Coolify admin password

### Database
- [ ] Create PostgreSQL in Coolify
- [ ] Enable automatic backups
- [ ] Note connection string

### Application
- [ ] Generate release files (`mix phx.gen.release --docker`)
- [ ] Add health check endpoint
- [ ] Commit and push to Git
- [ ] Create application in Coolify
- [ ] Configure environment variables
- [ ] Add custom domain
- [ ] Deploy and run migrations

### Automation
- [ ] Configure GitHub webhook
- [ ] Test auto-deploy

### Access
- [ ] Install Tailscale on devices
- [ ] Test access from each device
- [ ] (Optional) Enable Funnel for public access

---

## Resources

- **Coolify Docs:** https://coolify.io/docs/
- **Tailscale Docs:** https://tailscale.com/kb/
- **Tailscale + Coolify:** https://coolify.io/docs/knowledge-base/tailscale
- **Phoenix Deployment:** https://hexdocs.pm/phoenix/deployment.html
