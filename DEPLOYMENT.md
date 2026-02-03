# Deployment Guide

## Environment Variables

The application requires the following environment variables to be configured on the production server.

### Required Variables

Create a `.env` file in `/opt/homesite/` on your Hetzner server with these variables:

```bash
# Database
DB_PASSWORD=your_secure_database_password

# Phoenix
SECRET_KEY_BASE=your_secret_key_base_64_chars_minimum
PHX_HOST=orangedinos.de
PHX_CHECK_ORIGIN_HOSTS=orangedinos.de,www.orangedinos.de
PHX_ALTERNATE_HOST=www.orangedinos.de

# Email (SMTP)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your_smtp_username
SMTP_PASSWORD=your_smtp_password

# Cloudflare Turnstile (CAPTCHA)
TURNSTILE_SITE_KEY=your_turnstile_site_key
TURNSTILE_SECRET_KEY=your_turnstile_secret_key

# MaxMind GeoIP (Optional - for geolocation)
MAXMIND_LICENSE_KEY=your_maxmind_license_key
```

## Cloudflare Turnstile Setup

### 1. Get Turnstile Credentials

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Select your account
3. Go to **Turnstile** (in the left sidebar)
4. Click **Add Site**
5. Configure:
   - **Site name**: Homesite Registration
   - **Domain**: `orangedinos.de`
   - **Widget Mode**: Managed (Recommended)
6. Click **Create**
7. Copy the **Site Key** and **Secret Key**

### 2. Add Credentials to Production Server

SSH into your Hetzner server:

```bash
ssh deploy@your-server-ip
```

Edit the `.env` file:

```bash
cd /opt/homesite
nano .env
```

Add or update these lines:

```bash
TURNSTILE_SITE_KEY=1x00000000000000000000AA
TURNSTILE_SECRET_KEY=1x0000000000000000000000000000000AA
```

Save and exit (Ctrl+X, then Y, then Enter).

### 3. Restart the Application

```bash
cd /opt/homesite
docker compose restart app
```

### 4. Enable CAPTCHA in Admin Settings

1. Log in to your admin account
2. Go to **Admin** → **Settings**
3. Under **Registration Settings**, toggle **CAPTCHA Protection** to **ON**
4. Click **Save**

## Verifying Configuration

### Check Environment Variables

```bash
docker compose exec app env | grep TURNSTILE
```

You should see:
```
TURNSTILE_SITE_KEY=1x00000000000000000000AA
TURNSTILE_SECRET_KEY=1x0000000000000000000000000000000AA
```

### Check Application Logs

```bash
docker compose logs app | tail -50
```

Look for any errors related to Turnstile.

## Troubleshooting

### CAPTCHA Not Showing

**Symptoms**: The CAPTCHA widget doesn't appear on the registration page.

**Causes**:
1. Turnstile credentials not configured
2. CAPTCHA not enabled in admin settings
3. JavaScript blocked by browser
4. Wrong domain in Turnstile dashboard

**Solutions**:
1. Verify environment variables are set (see above)
2. Enable CAPTCHA in Admin → Settings
3. Check browser console for JavaScript errors (F12)
4. Verify domain in Cloudflare Turnstile dashboard matches your site

### Registration Fails with "Something went wrong"

**Symptoms**: Form submits but shows generic error.

**Causes**:
1. CAPTCHA verification failing
2. Missing credentials
3. Network issues between server and Cloudflare

**Solutions**:
1. Check application logs: `docker compose logs app | grep -i turnstile`
2. Verify credentials are correct
3. Test CAPTCHA manually at https://challenges.cloudflare.com/

### CAPTCHA Verification Failed

**Symptoms**: Error message "CAPTCHA verification failed. Please try again."

**Causes**:
1. User didn't complete CAPTCHA
2. CAPTCHA token expired (2 minutes)
3. Secret key mismatch

**Solutions**:
1. Ask user to complete the CAPTCHA
2. Refresh page if staying too long before submitting
3. Verify `TURNSTILE_SECRET_KEY` matches the one in Cloudflare dashboard

## Alternative: Disable CAPTCHA Temporarily

If you need to allow registrations while troubleshooting:

1. Go to **Admin** → **Settings**
2. Toggle **CAPTCHA Protection** to **OFF**
3. Change **Registration Mode** to **Invite Only** for security

**Warning**: This allows anyone to register without CAPTCHA protection. Only use temporarily.

## Security Notes

- Keep your `TURNSTILE_SECRET_KEY` secret - never commit to Git
- Rotate credentials if compromised
- Monitor Turnstile dashboard for abuse patterns
- Consider using "Invisible" mode for better UX (requires manual verification)
- Test on staging environment first before production changes
