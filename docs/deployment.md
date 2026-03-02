# Deployment Guide

This document covers the full deployment of job509.com to a k3s Kubernetes cluster running on a Raspberry Pi 5, accessible via Cloudflare Tunnel at `job509.polym.at`.

## Architecture

```
Internet
  │
  ▼
Cloudflare CDN (DNS + TLS)
  │
  ▼
Cloudflare Tunnel (cloudflared pods in k3s)
  │
  ▼
Traefik Ingress Controller (k3s built-in)
  │
  ▼
job509-service (ClusterIP :80)
  │
  ▼
Rails App (Puma + Thruster)  ──►  PostgreSQL (job509-postgres :5432)
```

## Prerequisites

- **k3s** running on Raspberry Pi 5 (ARM64)
- **Cloudflare Tunnel** already configured with `cloudflared` pods in the `cloudflare` namespace
- **Docker** with `buildx` for cross-compilation (if building from a non-ARM machine)
- **SSH access** to the Pi (`ssh pi5luc`)

## Kubernetes Resources

| Resource | File | Description |
|----------|------|-------------|
| Deployment + Service + PVC | `k8s/deployment.yaml` | Rails app, ClusterIP service, 1Gi storage |
| PostgreSQL | `k8s/postgres.yaml` | PostgreSQL 16, 5Gi PVC |
| Ingress | `k8s/ingress.yaml` | Traefik ingress for `job509.polym.at` |
| Secrets | `k8s/secrets.yaml.example` | Template for required secrets |

## Step-by-Step Deployment

### 1. Build the Docker Image (ARM64)

The app runs on a Raspberry Pi (ARM64). If building from an x86 Mac/Linux machine, use `docker buildx` for cross-compilation:

```bash
docker buildx build --platform linux/arm64 \
  -t ghcr.io/luccastera/job509:latest \
  --output type=docker,dest=/tmp/job509-arm64.tar .
```

**Key Dockerfile details:**
- Multi-stage build with Ruby 3.4.8 slim base
- Uses jemalloc for memory efficiency
- Non-root user (uid 1000)
- Runs Puma behind Thruster on port 80
- `BUNDLE_WITHOUT=development` excludes dev/test gems (including `mysql2`)

### 2. Transfer Image to the Pi

Since the Pi's k3s uses containerd (not Docker), transfer the image tarball and import it directly:

```bash
# Transfer
scp /tmp/job509-arm64.tar pi5luc:/tmp/job509-arm64.tar

# Import into k3s containerd
ssh pi5luc "sudo k3s ctr images import /tmp/job509-arm64.tar"

# Verify
ssh pi5luc "sudo k3s crictl images | grep job509"
```

> **Note:** The deployment uses `imagePullPolicy: IfNotPresent` so k3s won't try to pull from GHCR. If you push to GHCR instead, change this to `Always`.

### 3. Create Secrets

```bash
# Generate a secure postgres password
PG_PASS=$(openssl rand -hex 16)

# Generate SECRET_KEY_BASE
SECRET_KEY=$(openssl rand -hex 64)

# Get RAILS_MASTER_KEY from config/master.key
MASTER_KEY=$(cat config/master.key)

ssh pi5luc "sudo kubectl create secret generic job509-secrets \
  --from-literal=RAILS_MASTER_KEY=${MASTER_KEY} \
  --from-literal=POSTGRES_USER=job509 \
  --from-literal=POSTGRES_PASSWORD=${PG_PASS} \
  --from-literal=DATABASE_URL=postgres://job509:${PG_PASS}@job509-postgres:5432/job509_production \
  --from-literal=SECRET_KEY_BASE=${SECRET_KEY} \
  --dry-run=client -o yaml | sudo kubectl apply -f -"
```

### 4. Deploy PostgreSQL

```bash
cat k8s/postgres.yaml | ssh pi5luc "sudo kubectl apply -f -"

# Wait for it to be ready
ssh pi5luc "sudo kubectl rollout status deployment/job509-postgres --timeout=120s"
```

### 5. Deploy the Rails App

```bash
# Apply deployment, service, and PVC
cat k8s/deployment.yaml | ssh pi5luc "sudo kubectl apply -f -"

# Apply ingress
cat k8s/ingress.yaml | ssh pi5luc "sudo kubectl apply -f -"

# Watch the rollout
ssh pi5luc "sudo kubectl rollout status deployment/job509 --timeout=300s"
```

**What happens on first deploy:**
1. The init container runs `db:prepare` (creates database + runs migrations)
2. It then checks if Solid Queue tables exist
3. If missing, it loads the queue/cache/cable schemas
4. The main container starts Puma + Thruster

### 6. Configure Cloudflare Tunnel

The tunnel on this cluster is **remotely managed** via the Cloudflare Zero Trust dashboard. The local ConfigMap is overridden by remote configuration.

**Add the public hostname in Cloudflare Zero Trust:**

1. Go to [Cloudflare Zero Trust](https://one.dash.cloudflare.com/)
2. Navigate to **Networks** > **Tunnels**
3. Click on tunnel `aaa2e315-4ded-4ff5-a0e6-8d0965f02d42`
4. Go to **Public Hostname** tab > **Add a public hostname**
5. Configure:
   - **Subdomain**: `job509`
   - **Domain**: `polym.at`
   - **Type**: `HTTP`
   - **URL**: `job509-service.default.svc.cluster.local:80`

**Add DNS record** (if not already created):

```bash
ssh pi5luc "cloudflared tunnel --origincert ~/.cloudflared/cert.pem \
  route dns aaa2e315-4ded-4ff5-a0e6-8d0965f02d42 job509.polym.at"
```

This creates a CNAME record: `job509.polym.at` -> `aaa2e315-4ded-4ff5-a0e6-8d0965f02d42.cfargotunnel.com`

### 7. Verify

```bash
# Check pods
ssh pi5luc "sudo kubectl get pods -l app=job509"
ssh pi5luc "sudo kubectl get pods -l app=job509-postgres"

# Health check
curl https://job509.polym.at/up

# View logs
ssh pi5luc "sudo kubectl logs deployment/job509 --tail=20"
```

## Updating the Application

### Rebuild and Redeploy

```bash
# 1. Build new image
docker buildx build --platform linux/arm64 \
  -t ghcr.io/luccastera/job509:latest \
  --output type=docker,dest=/tmp/job509-arm64.tar .

# 2. Transfer and import
scp /tmp/job509-arm64.tar pi5luc:/tmp/job509-arm64.tar
ssh pi5luc "sudo k3s ctr images import /tmp/job509-arm64.tar"

# 3. Restart deployment (picks up new image)
ssh pi5luc "sudo kubectl rollout restart deployment/job509"

# 4. Watch rollout
ssh pi5luc "sudo kubectl rollout status deployment/job509 --timeout=300s"
```

### Applying Manifest Changes

```bash
# If you changed deployment.yaml, postgres.yaml, or ingress.yaml:
cat k8s/deployment.yaml | ssh pi5luc "sudo kubectl apply -f -"
```

## Database Management

### Rails Console

```bash
ssh pi5luc "sudo kubectl exec -it deployment/job509 -- bin/rails console"
```

### PostgreSQL Console

```bash
ssh pi5luc "sudo kubectl exec -it deployment/job509-postgres -- psql -U job509 job509_production"
```

### Run Migrations

Migrations run automatically via the init container on every deployment. To run manually:

```bash
ssh pi5luc "sudo kubectl exec -it deployment/job509 -- bin/rails db:migrate"
```

## Troubleshooting

### Pod Not Starting

```bash
# Check pod status
ssh pi5luc "sudo kubectl describe pod -l app=job509"

# Check init container logs (database migrations)
ssh pi5luc "sudo kubectl logs deployment/job509 -c migrate"

# Check main container logs
ssh pi5luc "sudo kubectl logs deployment/job509 -c job509"
```

### Common Issues

**`solid_queue_recurring_tasks` does not exist**

The Solid Queue/Cache/Cable schemas haven't been loaded. The init container handles this automatically on first deploy. If it fails, run manually:

```bash
ssh pi5luc "sudo kubectl exec -it deployment/job509 -- \
  env DISABLE_DATABASE_ENVIRONMENT_CHECK=1 \
  bin/rails db:schema:load:queue db:schema:load:cache db:schema:load:cable"
```

**Connection refused to PostgreSQL**

The `DATABASE_URL` secret must point to the k8s service name `job509-postgres`:

```
postgres://job509:<password>@job509-postgres:5432/job509_production
```

**Image pull errors**

The deployment uses `imagePullPolicy: IfNotPresent`. Make sure the image is imported into k3s containerd:

```bash
ssh pi5luc "sudo k3s crictl images | grep job509"
```

If missing, re-import: `sudo k3s ctr images import /tmp/job509-arm64.tar`

**Cloudflare tunnel returns 404**

The tunnel is remotely managed. Verify the public hostname is configured in the Cloudflare Zero Trust dashboard, not just in the local ConfigMap.

### Viewing Events

```bash
ssh pi5luc "sudo kubectl get events --sort-by='.lastTimestamp' | grep job509"
```

## Resource Limits

Optimized for Raspberry Pi 5 (8GB RAM):

| Component | Memory (req/limit) | CPU (req/limit) | Storage |
|-----------|--------------------|-----------------|---------|
| Rails App | 256Mi / 512Mi | 100m / 500m | 1Gi (storage) |
| PostgreSQL | 128Mi / 256Mi | 50m / 250m | 5Gi (data) |

## Security

- Rails app runs as non-root user (uid 1000)
- No privilege escalation allowed
- Secrets stored in Kubernetes secrets (not in manifests)
- TLS terminated at Cloudflare edge
- Cloudflare Tunnel provides secure connection without exposing ports

## Code Changes for Production

Several files were modified to support the k3s deployment:

| File | Change | Reason |
|------|--------|--------|
| `Gemfile` | Moved `mysql2` to `group: :development` | Not needed in production, avoids build failures |
| `Dockerfile` | Added `zlib1g-dev` to build dependencies | Required by `faraday-gzip` (PayPal SDK dependency) |
| `lib/tasks/migrate_from_mysql.rake` | Lazy-load `mysql2` inside task method | Prevents `LoadError` during asset precompilation |
| `config/database.yml` | Production uses `DATABASE_URL` for all databases | Single PostgreSQL instance serves primary + queue + cache + cable |
| `k8s/deployment.yaml` | `imagePullPolicy: IfNotPresent`, smart init container | Supports local image import, safe schema loading on restart |
| `k8s/postgres.yaml` | Fixed probe commands to use `/bin/sh -c` | K8s exec probes don't expand `$(VAR)` syntax |
