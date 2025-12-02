# Coolify + Tailscale Deployment Guide

**Created:** 2025-12-02
**Your Stack:** Coolify + Tailscale + Own Domain
**Status:** Planning Phase

---

## Why Coolify + Tailscale is the Perfect Combination

**Coolify** = Self-hosted PaaS (like Heroku/Render) running on your server
**Tailscale** = Secure mesh VPN for private access
**Your Domain** = Professional custom domain

### What Coolify Provides:

✅ **Beautiful Web UI**
- Deploy with clicks, not commands
- Manage all services from browser
- Real-time logs and monitoring
- Database management UI

✅ **Automatic Deployments**
- Git integration (GitHub, GitLab, Gitea)
- Automatic rebuilds on push
- Zero-downtime deployments
- Rollback to previous versions

✅ **Built-in Services**
- PostgreSQL, MySQL, Redis, MongoDB
- One-click database creation
- Automatic backups
- Health checks and monitoring

✅ **SSL/HTTPS Management**
- Automatic Let's Encrypt certificates
- Or use Tailscale HTTPS (even better!)
- Certificate auto-renewal
- Multiple domains per app

✅ **Environment Management**
- Web UI for environment variables
- Secret management
- Multiple environments (dev, staging, prod)

✅ **Resource Monitoring**
- CPU, memory, disk usage
- Application logs
- Database metrics
- Email/webhook alerts

### Why This Combo is Perfect:

| Feature | With Coolify + Tailscale | Manual Docker Setup |
|---------|--------------------------|---------------------|
| Deployment | Web UI | Command line |
| SSL Certificates | Automatic | Manual configuration |
| Database Management | Web UI | Docker commands |
| Monitoring | Built-in dashboard | Manual setup |
| Backups | Automatic | Manual scripts |
| Rollbacks | One-click | Manual git/docker |
| Logs | Real-time web UI | `docker logs` |
| Security | Tailscale + Coolify | Manual hardening |
| Updates | Web UI | Manual rebuild |

**Verdict:** Coolify eliminates 90% of deployment complexity!

---

## Architecture with Coolify + Tailscale

```
Your Devices (Phone, Laptop, etc.)
    ↓ (Tailscale - encrypted)
    ↓ https://homesite.yourdomain.com
    ↓
Coolify Web UI (port 8000)
    ↓ (manages)
Phoenix App Container (Coolify-managed)
    ↓
PostgreSQL Container (Coolify-managed)
```

**Access Points:**
- **Blog:** `https://homesite.yourdomain.com` (Phoenix app)
- **Coolify UI:** `https://coolify.yourdomain.com:8000` (management)
- **Both only accessible via Tailscale** (secure!)

---

## Installation Plan

### Phase 1: Install Tailscale (Same as Before)

```bash
# On your home server
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --hostname homeserver

# Enable MagicDNS and HTTPS in Tailscale admin console
# https://login.tailscale.com/admin/dns
```

**Time:** 10 minutes

---

### Phase 2: Install Coolify

**Requirements:**
- Linux server (Ubuntu 20.04+ recommended)
- Docker installed (Coolify installs this for you)
- 2GB RAM minimum (4GB+ recommended)
- 20GB disk space minimum

**1. Install Coolify:**

```bash
# One-line installation
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

This script:
- Installs Docker (if not present)
- Installs Coolify
- Starts Coolify services
- Creates initial admin user

**2. Access Coolify UI:**

```bash
# Coolify runs on port 8000
# Access via Tailscale IP:
http://100.x.x.x:8000

# Or via Tailscale hostname:
http://homeserver.your-tailnet.ts.net:8000
```

**3. Complete Initial Setup:**

- Open Coolify UI in browser
- Set admin email and password
- Configure server settings
- Add your Git repository (optional)

**Time:** 15 minutes

---

### Phase 3: Configure Custom Domain for Coolify

**Option A: Tailscale MagicDNS (Recommended)**

**1. In Coolify UI:**
- Settings → Configuration → General
- Set "FQDN": `coolify.yourdomain.com`

**2. In Tailscale Admin Console:**
- DNS → HTTPS
- Add custom domain: `coolify.yourdomain.com`
- Add provided TXT records to your DNS

**3. In Your DNS Provider:**

```
Type: CNAME
Name: coolify
Value: homeserver.your-tailnet.ts.net
TTL: 3600

Type: TXT
Name: _acme-challenge.coolify
Value: (provided by Tailscale)
TTL: 300
```

**4. Enable HTTPS in Coolify:**

Coolify will detect Tailscale HTTPS and use it automatically.

**Time:** 20 minutes (including DNS propagation)

---

**Option B: Let Coolify Manage HTTPS (Alternative)**

If not using Tailscale HTTPS:

```bash
# Coolify will request Let's Encrypt certificate
# Requires ports 80/443 accessible (not recommended with Tailscale)
```

**Recommendation:** Use Tailscale HTTPS for simplicity and security.

---

### Phase 4: Deploy PostgreSQL Database via Coolify

**1. In Coolify UI:**
- Resources → Databases → New Database
- Select: PostgreSQL
- Choose version: 16 (latest stable)
- Set database name: `homesite_prod`
- Set username: `homesite`
- Generate strong password (Coolify can auto-generate)

**2. Coolify Creates:**
- PostgreSQL container
- Persistent volume for data
- Automatic backups (configurable)
- Health checks
- Connection details

**3. Note Database Connection Info:**

Coolify provides:
- Internal hostname: `homesite_prod` (accessible from app)
- Port: `5432`
- Username: `homesite`
- Password: (auto-generated or your choice)
- Database: `homesite_prod`

**Connection string format:**
```
postgres://homesite:PASSWORD@homesite_prod:5432/homesite_prod
```

**Time:** 5 minutes

---

### Phase 5: Deploy Phoenix App via Coolify

**Method A: Deploy from Dockerfile (Recommended)**

**1. Prepare Your Repository:**

```bash
# In your project root
cd /Users/juha/Library/CloudStorage/Dropbox/Projektit/Elixir/homesite

# Generate release files (if not done yet)
mix phx.gen.release --docker

# Commit Dockerfile to Git
git add Dockerfile .dockerignore
git commit -m "Add Docker deployment files"
git push
```

**2. In Coolify UI:**

- Resources → Applications → New Application
- Source: Git Repository
- Repository URL: `https://github.com/yourusername/homesite.git` (or your Git URL)
- Branch: `main`
- Build Pack: Dockerfile
- Dockerfile location: `./Dockerfile`

**3. Configure Environment Variables:**

In Coolify UI → Your App → Environment Variables:

```bash
# Database (use Coolify internal hostname)
DATABASE_URL=postgres://homesite:PASSWORD@homesite_prod:5432/homesite_prod

# Phoenix
SECRET_KEY_BASE=generate_with_mix_phx_gen_secret
PHX_HOST=homesite.yourdomain.com
PORT=4000
PHX_SERVER=true
POOL_SIZE=10

# Email (if using)
SENDGRID_API_KEY=your_sendgrid_api_key
```

**Generate secrets:**
```bash
# On your local machine
mix phx.gen.secret
# Copy output to SECRET_KEY_BASE in Coolify
```

**4. Configure Custom Domain:**

In Coolify UI → Your App → Domains:

- Add domain: `homesite.yourdomain.com`
- Enable HTTPS (use Tailscale certificate)
- Save

**5. Deploy:**

- Click "Deploy" button
- Coolify will:
  1. Clone your repository
  2. Build Docker image
  3. Run migrations (if configured)
  4. Start application
  5. Monitor health

**6. Watch Real-time Logs:**

Coolify UI shows live deployment logs and application logs.

**Time:** 20 minutes (first deployment)

---

**Method B: Deploy from Local Docker Image (Alternative)**

If you don't want to use Git:

**1. Build locally and push to registry:**

```bash
# Build image
docker build -t homesite:latest .

# Tag for Coolify's registry
docker tag homesite:latest coolify-registry:5000/homesite:latest

# Push to Coolify
docker push coolify-registry:5000/homesite:latest
```

**2. In Coolify UI:**
- Resources → Applications → New Application
- Source: Docker Image
- Image: `coolify-registry:5000/homesite:latest`
- Configure environment variables (same as Method A)
- Deploy

---

### Phase 6: Configure Automatic Deployments

**Enable Git Webhooks:**

**1. In Coolify UI:**
- Your App → Source → Webhooks
- Copy webhook URL

**2. In GitHub/GitLab:**
- Repository Settings → Webhooks
- Add webhook URL from Coolify
- Select events: Push to branch
- Save

**Now:** Every `git push` automatically deploys to Coolify!

**Time:** 5 minutes

---

### Phase 7: Database Migrations

**Option A: Run Manually via Coolify UI:**

```bash
# In Coolify UI → Your App → Execute Command
/app/bin/migrate
```

**Option B: Automatic on Deploy:**

Create a deployment script that Coolify runs:

**File:** `.coolify/deploy.sh` (in your repository)

```bash
#!/bin/bash
set -e

# Run migrations
/app/bin/migrate

# Start server
/app/bin/server
```

Make executable:
```bash
chmod +x .coolify/deploy.sh
```

In Coolify UI → Your App → Build Settings:
- Start Command: `.coolify/deploy.sh`

**Time:** 5 minutes

---

### Phase 8: Configure Backups

**Database Backups:**

**In Coolify UI → Your Database → Backups:**

- Enable automatic backups
- Schedule: Daily at 2 AM
- Retention: 30 days
- Backup location: Local or S3-compatible storage

**Coolify handles everything automatically!**

**Application Data Backups:**

For uploaded files (if any):

**In Coolify UI → Your App → Persistent Storage:**

- Add volume: `/app/priv/static/uploads`
- Enable backup
- Same schedule as database

**Time:** 5 minutes

---

## Coolify Web UI Guide

### Main Dashboard:

**Resources:**
- Applications (your Phoenix app)
- Databases (PostgreSQL)
- Services (Redis, etc. if needed)

**For Each Resource:**
- **Overview:** Status, metrics, health
- **Logs:** Real-time application logs
- **Environment:** Manage variables
- **Deployments:** History and rollback
- **Settings:** Domain, storage, backups

**Server Settings:**
- Resource usage (CPU, RAM, disk)
- Cleanup old images
- Docker management

---

## Complete Deployment Workflow

### Initial Deployment:

1. ✅ Install Tailscale on server
2. ✅ Install Coolify
3. ✅ Access Coolify UI via Tailscale
4. ✅ Create PostgreSQL database
5. ✅ Create Phoenix application
6. ✅ Configure environment variables
7. ✅ Add custom domain
8. ✅ Deploy application
9. ✅ Run migrations
10. ✅ Test application

### Subsequent Deployments:

1. Make code changes locally
2. Commit and push to Git
3. Webhook triggers automatic deployment
4. Watch logs in Coolify UI
5. Coolify runs migrations (if configured)
6. Zero-downtime deployment complete!

**Or:** Click "Deploy" in Coolify UI manually.

---

## Access Configuration

### For Private Blog (Tailscale Only):

**1. Don't enable Tailscale Funnel**

Your app is accessible only via Tailscale:
- Admin: `https://coolify.yourdomain.com:8000`
- Blog: `https://homesite.yourdomain.com`

**2. Install Tailscale on Client Devices:**

- Download Tailscale for your devices
- Connect to your Tailnet
- Access blog from anywhere securely

### For Public + Private Access:

**1. Enable Tailscale Funnel for Blog:**

```bash
# On server
sudo tailscale funnel 443 on
```

**2. Keep Coolify UI Private:**

Don't enable Funnel for Coolify - keep it Tailscale-only.

**Result:**
- Blog: Public (anyone can read)
- Coolify UI: Private (only you via Tailscale)
- Admin routes: Protected by Phoenix authentication

---

## Cost Analysis: Coolify + Tailscale

| Component | Cost | Notes |
|-----------|------|-------|
| **Coolify** | $0 | Open source, self-hosted |
| **Tailscale** | $0 | Free for personal use |
| **Home Server** | $0 | Already owned |
| **Electricity** | ~$50-100/year | Server power |
| **Domain Name** | $10-15/year | Your existing domain |
| **Email (SendGrid)** | $0 | Free tier: 100 emails/day |
| **SSL Certificates** | $0 | Tailscale or Let's Encrypt |
| **TOTAL** | **$60-115/year** | Domain + electricity only! |

**Comparison with Cloud Services:**

- **Heroku:** $7-16/month = $84-192/year + domain
- **Render:** $7-25/month = $84-300/year + domain
- **Fly.io:** $5-10/month = $60-120/year + domain
- **Coolify (self-hosted):** $60-115/year all-in!

**Plus you own the infrastructure and data!**

---

## Advantages Over Manual Docker Setup

### Before (Manual Docker):
```bash
# Build image
docker build -t homesite .

# Run migrations
docker exec -it homesite /app/bin/migrate

# View logs
docker logs -f homesite

# Update environment
vi .env.production
docker restart homesite

# Backup database
docker exec postgres pg_dump ...

# Monitor resources
docker stats
```

### After (Coolify):
- Click "Deploy" button ✅
- Migrations run automatically ✅
- Real-time logs in browser ✅
- Edit variables in web UI ✅
- Automatic backups ✅
- Resource graphs in dashboard ✅

**Result:** 90% less manual work!

---

## Coolify Features You'll Love

### 1. One-Click Rollback

**If deployment breaks:**
- Coolify UI → Deployments → Previous version
- Click "Redeploy"
- Back to working state in 30 seconds

### 2. Multiple Environments

**Run staging + production:**
- Create two applications in Coolify
- `staging.yourdomain.com` - Test changes
- `homesite.yourdomain.com` - Production
- Deploy to staging first, then production

### 3. Service Management

**Need Redis for caching?**
- Coolify UI → Services → Redis
- One click to create
- Automatic connection string
- Linked to your app

### 4. Health Checks

**Coolify monitors:**
- HTTP health endpoint (`/health`)
- Restarts app if unhealthy
- Sends alerts (email/webhook)
- Shows status history

### 5. Resource Limits

**Set constraints:**
- Max memory: 512MB
- Max CPU: 50%
- Prevents app from consuming all resources
- Configurable per application

---

## Security with Coolify + Tailscale

### What You Get:

✅ **Network Security (Tailscale):**
- Zero public exposure
- WireGuard encryption
- No port forwarding
- No attack surface

✅ **Application Security (Phoenix):**
- Authentication system
- Rate limiting (Hammer)
- CSRF protection
- SQL injection prevention (Ecto)

✅ **Infrastructure Security (Coolify):**
- Isolated Docker containers
- Secret management
- Automatic updates available
- Resource limits

### Simplified Firewall:

```bash
# With Tailscale, firewall is simple
sudo ufw allow 22/tcp          # SSH
sudo ufw allow in on tailscale0 # Tailscale
sudo ufw default deny incoming
sudo ufw enable
```

**That's it!** No need to expose ports 80/443/8000.

---

## Monitoring and Logs

### In Coolify Dashboard:

**Application Metrics:**
- CPU usage over time
- Memory usage graph
- Network I/O
- Disk usage

**Application Logs:**
- Real-time streaming
- Filter by level (info, error)
- Search logs
- Download logs

**Database Metrics:**
- Connection count
- Query performance
- Storage usage
- Backup status

**Alerts:**
- Email notifications
- Webhook for Slack/Discord
- Triggered by:
  - Deployment failed
  - Application unhealthy
  - High resource usage
  - Backup failed

---

## Troubleshooting Guide

### Application Won't Start:

**1. Check Logs:**
- Coolify UI → Your App → Logs
- Look for error messages

**2. Verify Environment Variables:**
- Check `DATABASE_URL` format
- Verify `SECRET_KEY_BASE` is set
- Confirm `PHX_HOST` matches domain

**3. Test Database Connection:**
- Coolify UI → Database → Logs
- Ensure database is running
- Check connection from app container

### Deployment Fails:

**1. Check Build Logs:**
- Coolify UI → Deployments → Failed deployment
- View build output
- Look for dependency errors

**2. Verify Dockerfile:**
- Ensure `mix phx.gen.release --docker` was run
- Check `Dockerfile` is in repository
- Verify `.dockerignore` is correct

**3. Check Resource Limits:**
- Build might need more memory
- Increase in Settings → Resource Limits

### Can't Access via Tailscale:

**1. Verify Tailscale Status:**
```bash
sudo tailscale status
ping homeserver.your-tailnet.ts.net
```

**2. Check Domain Configuration:**
- Verify CNAME points to Tailscale hostname
- Check TXT records for HTTPS
- Wait for DNS propagation (up to 1 hour)

**3. Test Direct IP:**
```bash
# Try accessing via Tailscale IP
curl http://100.x.x.x:4000/health
```

---

## Implementation Checklist

### Server Setup:
- [ ] Install Tailscale on server
- [ ] Set hostname: `homeserver`
- [ ] Enable MagicDNS in Tailscale
- [ ] Enable HTTPS in Tailscale
- [ ] Install Coolify
- [ ] Access Coolify UI via Tailscale
- [ ] Set Coolify admin password
- [ ] Configure Coolify custom domain

### Database:
- [ ] Create PostgreSQL database in Coolify
- [ ] Note connection details
- [ ] Enable automatic backups

### Application:
- [ ] Generate Phoenix release files (`mix phx.gen.release --docker`)
- [ ] Commit Dockerfile to Git
- [ ] Push to repository
- [ ] Create application in Coolify
- [ ] Link to Git repository
- [ ] Configure environment variables
- [ ] Add custom domain
- [ ] Deploy application
- [ ] Run migrations
- [ ] Test health endpoint

### Automation:
- [ ] Configure Git webhook for auto-deploy
- [ ] Test automatic deployment
- [ ] Configure deployment script (optional)

### Email (If Using):
- [ ] Sign up for SendGrid
- [ ] Add API key to Coolify environment
- [ ] Test email delivery

### Client Access:
- [ ] Install Tailscale on laptop
- [ ] Install Tailscale on phone
- [ ] Test access from each device

### Monitoring:
- [ ] Configure health checks
- [ ] Set up alerts (email/webhook)
- [ ] Verify backup schedule
- [ ] Test rollback feature

---

## Quick Start Commands

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --hostname homeserver

# Install Coolify
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# Access Coolify (via Tailscale)
# http://100.x.x.x:8000
# (Use Tailscale IP shown by: tailscale ip -4)

# Generate Phoenix release files
cd /Users/juha/Library/CloudStorage/Dropbox/Projektit/Elixir/homesite
mix phx.gen.release --docker

# Commit and push
git add Dockerfile .dockerignore
git commit -m "feat: Add Docker deployment files for Coolify

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
git push

# Create database in Coolify UI
# Create application in Coolify UI
# Configure environment variables
# Deploy!
```

---

## Recommended Configuration

### Email Strategy:
✅ **SendGrid Free Tier** (100 emails/day, $0)
- Best balance of simplicity and features
- Keep magic link + password hybrid

### Database:
✅ **Coolify-managed PostgreSQL**
- Built-in backups
- Web UI management
- No external server needed

### Access Control:
✅ **Private via Tailscale**
- Coolify UI: Private (Tailscale only)
- Blog: Private initially, can enable Funnel later
- Maximum security

### Deployment:
✅ **Git + Automatic Webhooks**
- Push to deploy
- Full version history
- Easy rollbacks

---

## Migration from Manual Setup (If Needed)

**If you already have manual Docker setup:**

### 1. Backup Current Data:

```bash
# Backup database
docker exec postgres pg_dump -U homesite homesite_prod > backup.sql

# Backup uploads
tar -czf uploads_backup.tar.gz /var/lib/docker/volumes/homesite_app_uploads
```

### 2. Import to Coolify:

**Database:**
- Create PostgreSQL in Coolify
- Coolify UI → Database → Import
- Upload `backup.sql`

**Application:**
- Create app in Coolify
- Deploy from Git
- Uploads will be in new volume

### 3. Switch DNS:

Update CNAME to point to Coolify-managed domain.

### 4. Cleanup Old Containers:

```bash
docker compose down
docker system prune -a
```

**Time:** 30 minutes

---

## Next Steps

**Decision Points:**

1. **When to implement:**
   - [ ] Now
   - [ ] After reviewing guide
   - [ ] When you have 2 hours free

2. **Email strategy:**
   - [ ] SendGrid free tier (recommended)
   - [ ] Password-only
   - [ ] Decide later (can add anytime)

3. **Access level:**
   - [ ] Private (Tailscale only)
   - [ ] Public blog, private admin
   - [ ] Decide later

**Ready to start?**

The combination of Coolify + Tailscale gives you:
- ✅ Enterprise-grade security (Tailscale)
- ✅ Professional deployment experience (Coolify)
- ✅ Minimal ongoing costs ($60-115/year)
- ✅ Full control of your infrastructure

---

## Additional Resources

- **Coolify Documentation:** https://coolify.io/docs/
- **Coolify GitHub:** https://github.com/coollabsio/coolify
- **Tailscale + Coolify Guide:** https://coolify.io/docs/knowledge-base/tailscale
- **Coolify Discord:** https://coolify.io/discord
- **Tailscale Documentation:** https://tailscale.com/kb/
- **Main Deployment Plan:** See `.claude/plans/declarative-juggling-quail.md`
- **Tailscale Guide:** See `TAILSCALE_DEPLOYMENT.md`

---

**Document Status:** Ready for implementation - this is the recommended approach!

**Why This is Best:**
- Combines security (Tailscale) with ease-of-use (Coolify)
- One-time setup, then just push to deploy
- Perfect for personal projects that may grow
- Can easily add more services (Redis, additional apps, etc.)
