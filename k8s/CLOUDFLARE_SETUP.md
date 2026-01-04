# Cloudflare Tunnel Setup for job509.polym.at

The Cloudflare tunnel is already configured in the pistats project. To add job509.polym.at,
update the cloudflared ConfigMap in `/Users/luc/code/personal/pistats/k8s/cloudfared-deployment.yaml`.

## Update the ConfigMap

Add the job509 route to the ingress section of the cloudflared-config ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cloudflared-config
  namespace: cloudflare
data:
  config.yaml: |
    tunnel: aaa2e315-4ded-4ff5-a0e6-8d0965f02d42
    credentials-file: /etc/cloudflared/creds/credentials.json
    metrics: 0.0.0.0:2000

    ingress:
    # Pi Stats
    - hostname: stats.polym.at
      service: http://pistats-service.default.svc.cluster.local:80
      originRequest:
        noTLSVerify: true
        httpHostHeader: stats.polym.at

    # Job509 (NEW - add this block)
    - hostname: job509.polym.at
      service: http://job509-service.default.svc.cluster.local:80
      originRequest:
        noTLSVerify: true
        httpHostHeader: job509.polym.at

    # Catch-all rule - must be last
    - service: http_status:404
```

## Apply the Changes

```bash
# Apply the updated cloudflared config
kubectl apply -f /Users/luc/code/personal/pistats/k8s/cloudfared-deployment.yaml

# Restart cloudflared to pick up the new config
kubectl rollout restart deployment/cloudflared -n cloudflare

# Verify the rollout
kubectl rollout status deployment/cloudflared -n cloudflare
```

## Add DNS Record in Cloudflare Dashboard

1. Go to Cloudflare Dashboard > polym.at > DNS
2. Add a new CNAME record:
   - Name: `job509`
   - Target: `aaa2e315-4ded-4ff5-a0e6-8d0965f02d42.cfargotunnel.com`
   - Proxy status: Proxied (orange cloud)

Or use the Cloudflare CLI:
```bash
cloudflared tunnel route dns aaa2e315-4ded-4ff5-a0e6-8d0965f02d42 job509.polym.at
```

## Verify

After deployment, verify the route is working:
```bash
curl -I https://job509.polym.at/up
```
