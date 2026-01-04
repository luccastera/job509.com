# Kubernetes Deployment for Job509

This directory contains Kubernetes manifests for deploying Job509 to a k3s cluster.

## Prerequisites

1. k3s cluster running on Raspberry Pi (ARM64)
2. Cloudflare Tunnel configured (see pistats project)
3. GitHub Container Registry access configured
4. `kubectl` configured to access your cluster

## Files

| File | Description |
|------|-------------|
| `deployment.yaml` | Rails app deployment, service, and storage |
| `postgres.yaml` | PostgreSQL database deployment and service |
| `ingress.yaml` | Traefik ingress for job509.polym.at |
| `secrets.yaml.example` | Template for secrets (copy to secrets.yaml) |
| `github-actions-sa.yaml` | Service account for CI/CD |
| `CLOUDFLARE_SETUP.md` | Instructions for Cloudflare Tunnel |

## Initial Setup

### 1. Create Secrets

```bash
# Copy the example and fill in real values
cp k8s/secrets.yaml.example k8s/secrets.yaml

# Edit secrets.yaml with your values:
# - RAILS_MASTER_KEY: from config/master.key
# - POSTGRES_PASSWORD: generate a secure password
# - DATABASE_URL: update with your password
# - SECRET_KEY_BASE: run `bin/rails secret` to generate

# Apply secrets
kubectl apply -f k8s/secrets.yaml
```

### 2. Create GHCR Pull Secret

```bash
# Create secret for pulling images from GitHub Container Registry
kubectl create secret docker-registry ghcr-login-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_GITHUB_PAT \
  --docker-email=YOUR_EMAIL
```

### 3. Deploy PostgreSQL

```bash
kubectl apply -f k8s/postgres.yaml

# Wait for PostgreSQL to be ready
kubectl rollout status deployment/job509-postgres
```

### 4. Deploy the Application

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/ingress.yaml

# Wait for deployment
kubectl rollout status deployment/job509
```

### 5. Update Cloudflare Tunnel

Update the cloudflared config in the pistats project to add job509.polym.at routing.
See `CLOUDFLARE_SETUP.md` for details.

```bash
# In the pistats project directory
kubectl apply -f k8s/cloudfared-deployment.yaml
kubectl rollout restart deployment/cloudflared -n cloudflare
```

### 6. Add DNS Record

In Cloudflare Dashboard:
- Add CNAME: `job509` -> `<tunnel-id>.cfargotunnel.com`
- Or run: `cloudflared tunnel route dns <tunnel-id> job509.polym.at`

## GitHub Actions CI/CD

### Setup Service Account

```bash
# Apply the service account (if not using pistats' existing one)
kubectl apply -f k8s/github-actions-sa.yaml

# Get the token
kubectl get secret github-actions-token -o jsonpath='{.data.token}' | base64 -d
```

### Configure GitHub Secrets

Add these secrets to your GitHub repository:

1. `KUBECONFIG_DATA` - Base64 encoded kubeconfig with the service account token

```bash
# Generate kubeconfig
cat > /tmp/kubeconfig << EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://YOUR_CLUSTER_IP:6443
    certificate-authority-data: <base64-encoded-ca-cert>
  name: k3s
contexts:
- context:
    cluster: k3s
    user: github-actions
  name: github-actions
current-context: github-actions
users:
- name: github-actions
  user:
    token: <token-from-above>
EOF

# Encode and add to GitHub secrets
cat /tmp/kubeconfig | base64
```

## Useful Commands

```bash
# View logs
kubectl logs -f deployment/job509

# Rails console
kubectl exec -it deployment/job509 -- bin/rails console

# Database console
kubectl exec -it deployment/job509-postgres -- psql -U job509 job509_production

# Check status
kubectl get pods -l app=job509
kubectl get pods -l app=job509-postgres

# Restart deployment
kubectl rollout restart deployment/job509

# View events
kubectl get events --sort-by='.lastTimestamp'
```

## Resource Usage

Designed for Raspberry Pi 5 with limited resources:

| Component | Memory Request | Memory Limit | CPU Request | CPU Limit |
|-----------|---------------|--------------|-------------|-----------|
| Rails App | 256Mi | 512Mi | 100m | 500m |
| PostgreSQL | 128Mi | 256Mi | 50m | 250m |

## Troubleshooting

### Pod stuck in pending
```bash
kubectl describe pod -l app=job509
# Check for resource constraints or node selector issues
```

### Database connection errors
```bash
# Verify PostgreSQL is running
kubectl get pods -l app=job509-postgres

# Check PostgreSQL logs
kubectl logs -l app=job509-postgres

# Test connection from Rails pod
kubectl exec -it deployment/job509 -- bin/rails dbconsole
```

### Image pull errors
```bash
# Verify ghcr-login-secret exists
kubectl get secret ghcr-login-secret

# Check image pull status
kubectl describe pod -l app=job509
```
