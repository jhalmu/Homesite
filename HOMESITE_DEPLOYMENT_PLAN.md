# Homesite Deployment Plan - Hetzner + CI/CD

**Tavoite:** Saada Homesite julki nopeasti, turvallisesti ja yksinkertaisesti. Ei megalomaaniaa.

**Deadline:** Sivusto julki 3 päivässä.

**Päivitetty:** Joulukuu 2025 (versiot tarkistettu 15.12.2025)

**Käytetyt versiot:**
- Elixir 1.19.4 + OTP 27.3 (latest stable)
- Phoenix 1.8.3 (December 2025)
- PostgreSQL 18-alpine (18.1 latest)
- Debian Bookworm (Phoenix default) TAI Alpine 3.20.3
- Domain: juhahalmu.fi

---

## Tekniset valinnat

### Infrastruktuuri
- **Hetzner Cloud CAX11** (ARM, 3.79€/kk) tai CPX11 (4.51€/kk)
- **Ubuntu 24.04 LTS**
- **Docker + Docker Compose** (rootless mode, ei Kubernetes)
- **Caddy 2** - automaattinen HTTPS
- **PostgreSQL 18-alpine** kontti
- **Ei-root käyttäjä** (deploy) - turvallisuus!

### CI/CD & Versiot
- **GitHub Actions** - testit + deployment
- **Docker image** → GitHub Container Registry
- **SSH deployment** - deploy-käyttäjänä (ei root!)
- **Elixir 1.19.4** + **OTP 27.3** (vakaa tuotantoon)
- **Phoenix 1.8.3** (joulukuu 2025)
- **PostgreSQL 18** (syyskuu 2025):
  - Parannettu VACUUM-suorituskyky
  - Parempi write throughput
  - JSON/SQL parannukset
  - Vakaa tuotantoon ✅

### Turvallisuus
- **Ei-root käyttäjä** (deploy) - kaikki ajossa deploy-käyttäjänä
- SSH vain key-autentikaatiolla, root login disabled
- UFW firewall (22, 80, 443)
- GitHub Secrets environment-muuttujille
- Fail2ban (valinnainen mutta suositeltu)

---

## Vaiheistettu toteutus

### Vaihe 1: Hetzner Setup (30 min)

**1.1 Luo serveri**
- Hetzner Cloud Console → Create Server
- Location: Helsinki (lähin)
- Image: Ubuntu 24.04
- Type: CAX11 (ARM) tai CPX11 (x86)
- SSH key: lisää julkinen avaimesi

**1.2 Perusturvallisuus + Deploy-käyttäjä**
```bash
# Serverillä (root)
apt update && apt upgrade -y
apt install -y docker.io docker-compose-v2 ufw fail2ban

# Luo deploy-käyttäjä (EI rootia normaaliin käyttöön!)
adduser --disabled-password --gecos "Deploy User" deploy
usermod -aG docker deploy
usermod -aG sudo deploy

# Rajoita sudo vain docker-komentoihin
echo "deploy ALL=(ALL) NOPASSWD: /usr/bin/docker, /usr/bin/docker-compose" > /etc/sudoers.d/deploy
chmod 440 /etc/sudoers.d/deploy

# SSH-avain deploy-käyttäjälle
mkdir -p /home/deploy/.ssh
cp /root/.ssh/authorized_keys /home/deploy/.ssh/
chown -R deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys

# Disable root SSH login
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

# Firewall
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Projektin kansio
mkdir -p /opt/homesite
chown -R deploy:deploy /opt/homesite
```

**1.3 DNS**
- Cloudflare: `juhahalmu.fi` → Hetzner IP (A record)
- `www.juhahalmu.fi` → juhahalmu.fi (CNAME)

---

### Vaihe 2: Projektin valmistelu (1-2h)

**2.1 Phoenix release --docker (SUOSITELTU)**

Phoenix luo optimoidun Dockerfilen automaattisesti:

```bash
# Projektikansiossa
mix phx.gen.release --docker
```

Tämä luo:
- `Dockerfile` - Tuotantovalmis multi-stage build
- `.dockerignore` - Oikeat excludet
- `rel/overlays/bin/server` - Start script
- `rel/overlays/bin/migrate` - Migration script  
- `lib/homesite/release.ex` - Release helper

**HUOM:** Generated Dockerfile tarvitsee pieniä päivityksiä:

**TÄRKEÄ VALINTA: Debian vs Alpine**

Phoenix suosittelee **Debian** base imagea DNS-ongelmien välttämiseksi:
```dockerfile
# Phoenix default (Debian-based)
ARG BUILDER_IMAGE="hexpm/elixir:1.19.4-erlang-27.3-debian-bookworm-20251215-slim"
ARG RUNNER_IMAGE="debian:bookworm-slim"
```

**Alpine-vaihtoehto** (pienempi image, ~200MB vs ~600MB):
```dockerfile
# Alpine (jos ei tarvitse clustering/DNS)
FROM hexpm/elixir:1.19.4-erlang-27.3-alpine-3.20.3 AS builder
FROM alpine:3.20.3
```

**Suositus:** Aloita Debian (Phoenix default), vaihda Alpine jos:
- Haluat pienemmän imagen (~400MB säästö)
- Et tarvitse Erlang distribution/clustering heti
- Haluat kokeilla DNS toimiiko

**Jos käytät npm packageja, lisää node-builder:**

```dockerfile
FROM node:lts-slim as node-builder
WORKDIR /app
COPY assets/package*.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit

# Phoenix gen luo loput, lisää vain ennen assets deployta:
COPY --from=node-builder /app/assets/node_modules ./assets/node_modules
```

Phoenix `mix phx.gen.release --docker` hoitaa loput automaattisesti!

**2.2 docker-compose.yml (HUOM: Ei version-numeroa!)**
```yaml
# HUOM: version kenttä on deprecated, älä käytä!

services:
  db:
    image: postgres:18-alpine  # Latest: 18.1
    restart: unless-stopped
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: homesite_prod
      POSTGRES_USER: homesite
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U homesite"]
      interval: 10s
      timeout: 5s
      retries: 5

  app:
    image: ghcr.io/${GITHUB_REPOSITORY_OWNER}/homesite:latest
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      DATABASE_URL: ecto://homesite:${DB_PASSWORD}@db/homesite_prod
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
      PHX_HOST: ${PHX_HOST}
      PORT: 4000
    expose:
      - "4000"

  caddy:
    image: caddy:2-alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"  # HTTP/3
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      - app

volumes:
  pgdata:
  caddy_data:
  caddy_config:
```

**2.3 Caddyfile**
```
{$PHX_HOST} {
    reverse_proxy app:4000
    
    encode gzip
    
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        Referrer-Policy "strict-origin-when-cross-origin"
    }
}
```

**2.4 .env.example**
```bash
# Copy to .env and fill in real values
DB_PASSWORD=changeme
SECRET_KEY_BASE=changeme  # mix phx.gen.secret
PHX_HOST=juhahalmu.fi
GITHUB_REPOSITORY_OWNER=your-username
```

**2.5 config/runtime.exs tarkistus**
Varmista että production-config lukee ympäristömuuttujat:
```elixir
if config_env() == :prod do
  database_url = System.get_env("DATABASE_URL") ||
    raise "DATABASE_URL not available"

  config :homesite, Homesite.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  secret_key_base = System.get_env("SECRET_KEY_BASE") ||
    raise "SECRET_KEY_BASE not available"

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :homesite, HomesiteWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base,
    server: true
end
```

---

### Vaihe 3: GitHub Actions CI/CD (1-2h)

**3.1 .github/workflows/test.yml**
```yaml
name: Test

on:
  pull_request:
  push:
    branches: [develop]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4
      
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.19.4'
          otp-version: '27.3'
      
      - name: Cache deps
        uses: actions/cache@v3
        with:
          path: deps
          key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}
      
      - run: mix deps.get
      - run: mix compile --warnings-as-errors
      - run: mix test
      - run: mix credo --strict
      - run: mix format --check-formatted
```

**3.2 .github/workflows/deploy.yml**
```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.19.4'
          otp-version: '27.3'
      - run: mix deps.get
      - run: mix test
      - run: mix credo --strict

  build:
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ghcr.io/${{ github.repository_owner }}/homesite:latest
            ghcr.io/${{ github.repository_owner }}/homesite:${{ github.sha }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    
    steps:
      - name: Deploy to Hetzner
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.HETZNER_HOST }}
          username: deploy  # EI root!
          key: ${{ secrets.HETZNER_SSH_KEY }}
          script: |
            cd /opt/homesite
            sudo docker compose pull
            sudo docker compose up -d
            sudo docker compose exec -T app bin/homesite eval "Homesite.Release.migrate"
            sudo docker system prune -f
```

**3.3 GitHub Secrets setup**
Repository Settings → Secrets and variables → Actions:

```
HETZNER_HOST: <server-ip>
HETZNER_USER: deploy  # EI root!
HETZNER_SSH_KEY: <deploy-user-private-key>
```

Serverillä `/opt/homesite/.env` (deploy-käyttäjänä):
```
DB_PASSWORD=<generated>
SECRET_KEY_BASE=<mix phx.gen.secret>
PHX_HOST=homesite.fi
GITHUB_REPOSITORY_OWNER=<your-github-username>
```

---

### Vaihe 4: Migration helper (15 min)

**lib/homesite/release.ex**
```elixir
defmodule Homesite.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :homesite

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
```

---

### Vaihe 5: Deployment (30 min)

**5.1 Serverillä**
```bash
# Luo projektin kansio
mkdir -p /opt/homesite
cd /opt/homesite

# Kopioi tiedostot (tee tämä manuaalisesti tai scp:llä)
# - docker-compose.yml
# - Caddyfile
# - .env (täytetty oikeilla arvoilla)

# Luo salasanat
mix phx.gen.secret  # -> SECRET_KEY_BASE
openssl rand -base64 32  # -> DB_PASSWORD

# Testaa että compose toimii
docker compose up -d
docker compose logs -f

# Jos kaikki ok, lisää GitHub Actions hoitamaan loput
```

**5.2 Ensimmäinen deployment GitHub Actionsilla**
```bash
# Lokaalisti
git add .
git commit -m "Add Docker and CI/CD setup"
git push origin main

# Seuraa GitHub Actions → Deploy workflow
# Tarkista että kaikki menee läpi
```

**5.3 Tarkista että toimii**
```bash
curl -I https://juhahalmu.fi
# HTTP/2 200
# strict-transport-security: max-age=31536000

# Serverillä
docker compose ps
# Pitäisi näyttää db, app, caddy RUNNING
```

---

## Ylläpito ja seuranta

### Lokit
```bash
# Kaikki palvelut
docker compose logs -f

# Vain app
docker compose logs -f app

# Viimeinen 100 riviä
docker compose logs --tail=100 app
```

### Backupit (setup heti kun toimii!)
```bash
# Manuaalinen backup
docker compose exec db pg_dump -U homesite homesite_prod | gzip > backup_$(date +%Y%m%d).sql.gz

# Hetzner Backup (automaattinen)
# Enable Hetzner Console → Server → Backups (20% lisämaksu)
```

### Päivitykset
```bash
# Serverin päivitykset (kerran kuussa)
apt update && apt upgrade -y
reboot

# App päivitys
git push origin main  # GitHub Actions hoitaa
```

---

## Mitä EI tehdä (anti-megalomania)

❌ **Kubernetes** - Docker Compose riittää  
❌ **Multiple servers** - Yksi riittää alkuun  
❌ **Blue-green deployment** - Simple restart riittää  
❌ **Staging environment** - Testaa lokaalisti  
❌ **Monitoring stack** - Caddy lokit + docker logs riittää  
❌ **CDN for assets** - Phoenix digest + Caddy gzip riittää  
❌ **Redis** - Lisää vain jos tarvitset  
❌ **Load balancer** - Ei tarvita yhdellä serverillä
❌ **Oma Dockerfile tyhjästä** - Käytä `mix phx.gen.release --docker`

✅ **Yksinkertainen**  
✅ **Toimiva**  
✅ **Nopea deployata**  
✅ **Helppo debugata**
✅ **Phoenix release --docker** - Luo optimoidun setupin automaattisesti

---

## Troubleshooting

### Ongelma: App ei käynnisty
```bash
docker compose logs app
# Tarkista SECRET_KEY_BASE ja DATABASE_URL
```

### Ongelma: 502 Bad Gateway
```bash
docker compose ps
# Varmista että app on RUNNING
docker compose logs caddy
```

### Ongelma: SSL ei toimi
```bash
# Tarkista että DNS on propagoitunut
dig homesite.fi +short
# Pitäisi näyttää Hetzner IP

docker compose logs caddy
# Caddy yrittää automaattisesti uudestaan
```

### Ongelma: Migrations eivät aja
```bash
# Aja manuaalisesti
docker compose exec app bin/homesite eval "Homesite.Release.migrate"
```

---

## Timeline

**Päivä 1 (tänään):**
- [ ] Hetzner tili + serveri
- [ ] DNS → Hetzner IP
- [ ] Perusturvallisuus (UFW, SSH key)

**Päivä 2 (huomenna):**
- [ ] Dockerfile + docker-compose.yml
- [ ] GitHub Actions workflow
- [ ] Testaa deployment paikallisesti

**Päivä 3 (ylihuomenna):**
- [ ] Ensimmäinen production deployment
- [ ] Testaa että sivusto toimii
- [ ] Setup backupit

**Valmis! Nyt voit keskittyä sisältöön ja käyttäjiin.**

---

## Seuraavat askeleet (myöhemmin)

1. **Monitoring:** Lisää yksinkertainen uptime-check (UptimeRobot ilmainen)
2. **Analytics:** Plausible tai Fathom (privacy-friendly)
3. **Email:** Setup SMTP kun tarvitset (Postmark/Mailgun)
4. **Backups:** Automatisoitu pg_dump cron jobilla
5. **Staging:** Jos todella tarvitset, mutta aluksi test-branch riittää

**Pidä tämä dokkarit tallessa - tarvitset sitä!**
