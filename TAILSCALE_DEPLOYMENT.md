# Tailscale Deployment Guide for Home Server

**Created:** 2025-12-02
**Your Choice:** Tailscale + Own Domain + Caddy
**Status:** Planning Phase

---

## Why Tailscale is Excellent for Home Server

**Tailscale provides a secure mesh VPN network** - perfect for home server deployment!

### Key Advantages:

✅ **No Port Forwarding Required**
- No need to open ports 80/443 on your router
- No exposure to public internet
- Significantly better security posture

✅ **Automatic HTTPS with Your Domain**
- Tailscale provides free HTTPS certificates
- Can use your own domain (e.g., `homesite.yourdomain.com`)
- Automatic certificate renewal

✅ **Zero-Trust Security**
- Only authorized Tailscale users can access your server
- WireGuard encryption for all traffic
- No public attack surface

✅ **Simple Setup**
- One command to install on server
- Mobile apps for access from anywhere
- Works behind CGNAT and strict firewalls

✅ **Free for Personal Use**
- Up to 100 devices
- Unlimited bandwidth
- All security features included

### Comparison with Other Approaches:

| Feature | Tailscale | Cloudflare Tunnel | Port Forwarding |
|---------|-----------|-------------------|-----------------|
| Port forwarding needed | ❌ No | ❌ No | ✅ Yes |
| Public attack surface | ❌ None | ⚠️ Via Cloudflare | ✅ Full exposure |
| Setup complexity | 🟢 Low | 🟡 Medium | 🟢 Low |
| Access control | ✅ Built-in | ⚠️ Via Cloudflare rules | ❌ None |
| Custom domain | ✅ Yes | ✅ Yes | ✅ Yes |
| Cost | 🟢 Free | 🟢 Free | 🟢 Free |
| Works behind CGNAT | ✅ Yes | ✅ Yes | ❌ No |
| Mobile access | ✅ Native apps | ✅ Browser | ✅ Browser |

**Verdict:** Tailscale is the best choice for secure home server deployment.

---

## Architecture Overview

```
Your Devices (Phone, Laptop, etc.)
    ↓ (Tailscale mesh network - WireGuard encrypted)
Home Server (Tailscale installed)
    ↓ (localhost:4000)
Phoenix App (Docker container)
    ↓
PostgreSQL Database (Docker or external)
```

**Key Points:**
- Users access server via `https://homesite.yourdomain.com` (Tailscale domain)
- Traffic encrypted end-to-end via WireGuard
- No public DNS record pointing to your home IP
- Caddy handles local HTTPS and proxying to Phoenix app

---

## Implementation Plan

### Phase 1: Install Tailscale on Server

**1. Install Tailscale:**

```bash
# On your home server (Linux)
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscale and authenticate
sudo tailscale up
```

This opens a browser to authenticate with your Tailscale account (create one if needed).

**2. Check Tailscale IP:**

```bash
# Get your server's Tailscale IP (100.x.x.x)
tailscale ip -4
```

**3. Enable Tailscale on Boot:**

```bash
sudo systemctl enable tailscaled
sudo systemctl start tailscaled
```

**Time:** 10 minutes

---

### Phase 2: Configure Custom Domain with Tailscale

Tailscale allows you to use your own domain for HTTPS certificates!

**Option A: MagicDNS with Custom Domain (Recommended)**

**1. Enable MagicDNS in Tailscale Admin:**

- Go to https://login.tailscale.com/admin/dns
- Enable "MagicDNS"
- Enable "HTTPS"

**2. Set Machine Name:**

```bash
# Set a memorable hostname for your server
sudo tailscale set --hostname homesite
```

Your server is now accessible at:
- `homesite.your-tailnet.ts.net` (automatic Tailscale domain)
- Uses automatic HTTPS certificate from Tailscale

**3. Add Custom Domain (Optional but Recommended):**

You can use your own domain (e.g., `homesite.yourdomain.com`) with Tailscale HTTPS:

- In Tailscale Admin Console: DNS → HTTPS
- Click "Add a custom domain"
- Enter: `homesite.yourdomain.com`
- Tailscale provides TXT records to add to your DNS

**In your DNS provider (Namecheap, Cloudflare, etc.):**

```
Type: CNAME
Name: homesite
Value: homesite.your-tailnet.ts.net
TTL: 3600
```

**Add TXT records for certificate validation:**
```
Type: TXT
Name: _acme-challenge.homesite
Value: (provided by Tailscale)
TTL: 300
```

**Wait for DNS propagation** (5-60 minutes), then Tailscale will issue HTTPS certificate.

**4. Verify:**

```bash
# Test connection from any Tailscale-connected device
curl https://homesite.yourdomain.com
```

**Time:** 30 minutes (including DNS propagation)

---

**Option B: Tailscale Funnel (Public Access - If Needed)**

**If you want to make your site publicly accessible** (not just to Tailscale users):

```bash
# Enable Tailscale Funnel
sudo tailscale serve https / http://127.0.0.1:4000
sudo tailscale funnel 443 on
```

This makes your site accessible to:
- ✅ Anyone with the `homesite.yourdomain.com` URL
- ✅ Still encrypted via Tailscale's HTTPS
- ✅ No port forwarding needed
- ⚠️ Public internet access (choose if you want this)

**For private blog (Tailscale users only):**
```bash
# Use Tailscale Serve (private)
sudo tailscale serve https / http://127.0.0.1:4000
```

**Time:** 5 minutes

---

### Phase 3: Deploy Phoenix App (Same as Before)

Use the deployment plan from the previous document, but with these changes:

**1. Generate Release Files:**

```bash
cd /Users/juha/Library/CloudStorage/Dropbox/Projektit/Elixir/homesite
mix phx.gen.release --docker
```

**2. Create `docker-compose.yml`:**

(Use the same configuration as in the main deployment plan)

**3. Create `.env.production`:**

```bash
# Database
DB_PASSWORD=generate_strong_password_here

# Phoenix
SECRET_KEY_BASE=generate_with_mix_phx_gen_secret
PHX_HOST=homesite.yourdomain.com  # Your Tailscale domain
PORT=4000

# Email (if using)
SENDGRID_API_KEY=your_sendgrid_api_key
```

**4. Add Health Check Endpoint:**

(Same as in main deployment plan)

**5. Build and Start:**

```bash
# Build Docker image
docker compose build

# Run migrations
docker compose run --rm app /app/bin/migrate

# Start application
docker compose up -d

# Check health
curl http://localhost:4000/health
```

**Time:** 30 minutes

---

### Phase 4: Configure Caddy (Optional but Recommended)

**Why use Caddy with Tailscale?**
- Additional security headers
- Rate limiting
- Caching for static assets
- Better logging
- Can serve multiple apps on same server

**Minimal Caddyfile for Tailscale:**

```caddyfile
{
    # Let Tailscale handle HTTPS certificates
    auto_https off
}

:80 {
    # Reverse proxy to Phoenix app
    reverse_proxy localhost:4000

    # Security headers
    header {
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
    }

    # Enable compression
    encode gzip

    # Logging
    log {
        output file /var/log/caddy/homesite.log
        format json
    }
}
```

**Or let Tailscale handle everything directly:**

If using `tailscale serve`, you don't need Caddy at all! Tailscale handles:
- ✅ HTTPS certificates
- ✅ Automatic renewal
- ✅ Reverse proxy to localhost:4000

**Time:** 10 minutes (if using Caddy)

---

### Phase 5: Install Tailscale on Client Devices

**To access your blog from other devices:**

**1. Install Tailscale Client:**

- **Laptop/Desktop:** https://tailscale.com/download
- **iOS:** App Store → "Tailscale"
- **Android:** Google Play → "Tailscale"

**2. Connect to Tailnet:**

- Open Tailscale app
- Sign in with same account
- Your server appears in device list

**3. Access Your Site:**

```bash
# From browser on connected device
https://homesite.yourdomain.com
```

**Time:** 5 minutes per device

---

## Security Considerations with Tailscale

### What Tailscale Provides:

✅ **Network-Level Security:**
- WireGuard encryption (state-of-the-art)
- Zero-trust architecture
- No public ports exposed
- Automatic key rotation

✅ **Access Control:**
- ACLs (Access Control Lists) for fine-grained permissions
- Can restrict which users access which services
- Audit logs of all connections

✅ **No Attack Surface:**
- Server not reachable from public internet
- Port scanners can't find it
- No DDoS risk
- No brute force attempts

### What You Still Need:

⚠️ **Application-Level Security:**
- Authentication (your app already has this)
- Rate limiting (Hammer is configured)
- Input validation (Ecto handles this)
- Security headers (add via Caddy)

⚠️ **Server Hardening:**
- Keep OS updated
- Use SSH keys (not passwords)
- Configure firewall (can be simpler with Tailscale)
- Regular backups

**Simplified Firewall with Tailscale:**

```bash
# Allow SSH (adjust port if non-standard)
sudo ufw allow 22/tcp

# Allow Tailscale
sudo ufw allow in on tailscale0

# Deny everything else
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Enable firewall
sudo ufw enable
```

Notice: **No need to allow ports 80/443!** Tailscale handles access.

---

## Database Strategy with Tailscale

### Option A: Docker PostgreSQL (Simplest)

Use the docker-compose.yml from main deployment plan. Database only accessible from Phoenix app container.

**No changes needed.**

---

### Option B: External PostgreSQL on Same Tailscale Network

**If your PostgreSQL server is also on Tailscale:**

**1. Install Tailscale on Database Server:**

```bash
# On database server
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --hostname homesite-db
```

**2. Update `docker-compose.yml`:**

```yaml
services:
  app:
    environment:
      # Use Tailscale hostname for database
      DATABASE_URL: postgres://homesite:${DB_PASSWORD}@homesite-db.your-tailnet.ts.net/homesite_prod
      # ... other env vars
```

**3. Configure PostgreSQL to Accept Tailscale Connections:**

**Edit `pg_hba.conf`:**
```conf
# Allow connections from Tailscale network
host    homesite_prod    homesite    100.64.0.0/10    scram-sha-256
```

**Edit `postgresql.conf`:**
```conf
listen_addresses = '*'
```

**Restart PostgreSQL:**
```bash
sudo systemctl restart postgresql
```

**Benefits:**
- ✅ Database and app on separate servers
- ✅ Secure communication via Tailscale
- ✅ No public database exposure
- ✅ Can scale independently

**Time:** 20 minutes

---

### Option C: External PostgreSQL NOT on Tailscale

Use the external PostgreSQL setup from main deployment plan with localhost/private network IP.

**No Tailscale-specific changes needed.**

---

## Email Strategy (Same as Main Plan)

Tailscale doesn't affect email configuration. Choose:

1. **SendGrid Free Tier** (recommended) - 100 emails/day, $0
2. **Password-only** - No email needed
3. **Gmail SMTP** - If you have Gmail account

Configure in `config/runtime.exs` as documented in main deployment plan.

---

## Cost Analysis with Tailscale

| Component | Cost | Notes |
|-----------|------|-------|
| **Tailscale** | $0 | Free for personal use (up to 100 devices) |
| **Home Server** | $0 | Already owned |
| **Electricity** | ~$50-100/year | Server power consumption |
| **Domain Name** | $10-15/year | Your existing domain |
| **Email (SendGrid)** | $0 | Free tier: 100 emails/day |
| **SSL Certificate** | $0 | Provided by Tailscale |
| **TOTAL** | **$60-115/year** | Domain + electricity only! |

**Comparison:**
- **Cloudflare Tunnel:** Same cost, but traffic routes through Cloudflare
- **Port Forwarding:** Same cost, but full public exposure
- **VPS (DigitalOcean):** $72-144/year + domain + you don't own hardware

**Verdict:** Tailscale + home server = Most cost-effective AND most secure option!

---

## Advantages of Tailscale Over Port Forwarding

| Aspect | Tailscale | Port Forwarding |
|--------|-----------|-----------------|
| **Security** | Zero public exposure | Full public exposure |
| **Setup** | Install + run 1 command | Configure router, firewall, DNS |
| **CGNAT** | Works perfectly | Doesn't work |
| **Dynamic IP** | Doesn't matter | Need dynamic DNS |
| **Mobile access** | Native apps | Browser only |
| **Multiple services** | Easy to add | Need more port forwards |
| **Attack surface** | Zero | Large (entire internet) |
| **Certificate management** | Automatic | Manual (Let's Encrypt) |
| **Rate limiting** | Natural (private network) | Must configure aggressively |
| **Fail2Ban needed** | No (no brute force possible) | Yes (critical) |

**Tailscale eliminates most security concerns automatically!**

---

## Implementation Checklist

### Server Setup:
- [ ] Install Tailscale on home server
- [ ] Set machine hostname: `homesite`
- [ ] Enable MagicDNS in Tailscale admin
- [ ] Enable HTTPS in Tailscale admin
- [ ] Add custom domain (optional): `homesite.yourdomain.com`
- [ ] Add CNAME and TXT records to DNS
- [ ] Generate Phoenix release files (`mix phx.gen.release --docker`)
- [ ] Create `docker-compose.yml`
- [ ] Create `.env.production` with secrets
- [ ] Add health check controller
- [ ] Build Docker image
- [ ] Run migrations
- [ ] Start application
- [ ] Test health endpoint

### Optional (Caddy):
- [ ] Install Caddy
- [ ] Create Caddyfile for local reverse proxy
- [ ] Configure security headers
- [ ] Enable logging

### Client Devices:
- [ ] Install Tailscale on laptop/desktop
- [ ] Install Tailscale on phone/tablet
- [ ] Test access from each device

### Email (If Using):
- [ ] Sign up for SendGrid (or choose alternative)
- [ ] Add API key to `.env.production`
- [ ] Configure mailer in `config/runtime.exs`
- [ ] Test email delivery

### Database (If External):
- [ ] Install Tailscale on database server (optional)
- [ ] Configure PostgreSQL for remote connections
- [ ] Update `DATABASE_URL` in `.env.production`
- [ ] Test connection

### Monitoring:
- [ ] Create backup script
- [ ] Schedule backups via cron
- [ ] Create health monitoring script (optional - less critical with Tailscale)

---

## Quick Start Command Summary

```bash
# On home server
# 1. Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --hostname homesite

# 2. Enable MagicDNS and HTTPS
# (Do this in Tailscale admin console)

# 3. Generate Phoenix deployment files
cd /Users/juha/Library/CloudStorage/Dropbox/Projektit/Elixir/homesite
mix phx.gen.release --docker

# 4. Create docker-compose.yml and .env.production
# (Copy from main deployment plan)

# 5. Build and deploy
docker compose build
docker compose run --rm app /app/bin/migrate
docker compose up -d

# 6. Test
curl http://localhost:4000/health

# 7. Access from Tailscale-connected device
# https://homesite.yourdomain.com
```

---

## Tailscale + Public Access (Optional)

**If you want both:**
1. **Private access** for admin/writing (via Tailscale)
2. **Public access** for readers (via Funnel)

**Use Tailscale Funnel:**

```bash
# Enable Funnel for public access
sudo tailscale funnel 443 on
```

This makes your site:
- ✅ Accessible to anyone with the URL
- ✅ Still encrypted via Tailscale HTTPS
- ✅ No port forwarding needed
- ✅ Can be disabled anytime

**Or use Access Control Lists (ACLs):**

Configure different paths for public vs private:
- `/posts/*` - Public (via Funnel)
- `/admin/*` - Private (Tailscale only)

---

## Troubleshooting

### Can't connect to server via Tailscale:

```bash
# Check Tailscale status
sudo tailscale status

# Check if server is reachable
ping homesite.your-tailnet.ts.net

# Check Tailscale logs
sudo journalctl -u tailscaled -n 50
```

### HTTPS certificate not issued:

```bash
# Check DNS propagation
dig homesite.yourdomain.com

# Verify TXT records
dig _acme-challenge.homesite.yourdomain.com TXT

# Check Tailscale HTTPS status
# (Visit Tailscale admin console → DNS → HTTPS)
```

### Application won't start:

```bash
# Check Docker logs
docker compose logs -f app

# Check health endpoint
curl http://localhost:4000/health

# Check Phoenix logs inside container
docker compose exec app cat /app/log/production.log
```

---

## Next Steps

**Decision Points:**

1. **Email Strategy:**
   - [ ] Password-only (simplest)
   - [ ] SendGrid free tier (100 emails/day)
   - [ ] Keep hybrid with SendGrid

2. **Database:**
   - [ ] Docker PostgreSQL (included in docker-compose.yml)
   - [ ] External PostgreSQL on Tailscale
   - [ ] External PostgreSQL on local network

3. **Access Control:**
   - [ ] Private (Tailscale only)
   - [ ] Public (Tailscale Funnel)

4. **Caddy:**
   - [ ] Use Caddy for additional features
   - [ ] Skip Caddy (Tailscale handles everything)

**Ready to implement?**

When you're ready, start with Phase 1 (Install Tailscale) and work through the checklist.

---

## Additional Resources

- **Tailscale Documentation:** https://tailscale.com/kb/
- **Tailscale Custom Domains:** https://tailscale.com/kb/1153/enabling-https/
- **Tailscale Funnel:** https://tailscale.com/kb/1223/funnel/
- **Tailscale ACLs:** https://tailscale.com/kb/1018/acls/
- **Main Deployment Plan:** See `declarative-juggling-quail.md` in `.claude/plans/`

---

**Document Status:** Ready for implementation when you decide on email/database/access strategy.
