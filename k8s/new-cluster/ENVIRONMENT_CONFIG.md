# TaxonWorks Kubernetes Environment Configuration

This document lists all environment-specific configurations required before deploying TaxonWorks to Kubernetes.

## Required Configuration Files

### 1. Create Secret File

First, create your secrets file from the template:

```bash
cp base/secret-template.yml base/secret.yml
```

Then configure the following values in `base/secret.yml`:

| Variable | Description | How to Generate |
|----------|-------------|-----------------|
| `db.password` | PostgreSQL database password | Choose a strong password |
| `secret_key_base` | Rails secret key base | Run `rails secret` or `openssl rand -hex 64` |
| `nginx.secret` | Nginx secret key | Run `openssl rand -hex 32` |

⚠️ **IMPORTANT**: Never commit `base/secret.yml` to version control!

## Configuration Values to Update

### 2. Domain Configuration

Update the following domain-related settings:

**File: `base/configmap.yml`**

| Variable | Description | Example |
|----------|-------------|---------|
| `server.name` | Primary domain name | `taxonworks.yourorg.com` |
| `tw.action_mailer_url_host` | URL host for emails (same as server.name) | `taxonworks.yourorg.com` |
| `tw.mail_domain` | Email domain | `yourorg.com` |

**File: `base/ingress.yml`**

| Variable | Location | Example |
|----------|----------|---------|
| `spec.rules[0].host` | Ingress host | `taxonworks.yourorg.com` |
| `spec.tls[0].hosts` | TLS hosts (if using HTTPS) | `taxonworks.yourorg.com` |

### 3. Email/SMTP Configuration

**File: `base/configmap.yml`**

| Variable | Description | Example |
|----------|-------------|---------|
| `tw.exception_notification.sender_address` | From address for error emails | `noreply@yourorg.com` |
| `tw.exception_recipients` | Email(s) to receive error notifications | `admin@yourorg.com` |
| `tw.action_mailer_smtp_settings.address` | SMTP server address | `smtp.gmail.com` |
| `tw.action_mailer_smtp_settings.port` | SMTP server port | `587` |
| `tw.action_mailer_smtp_settings.domain` | SMTP domain | `yourorg.com` |

### 4. Storage Configuration

**File: `base/pv-claims.yml`**

1. **Storage Class**: Uncomment and set the `storageClassName` for all three PVCs:
   ```yaml
   storageClassName: your-storage-class  # e.g., "standard", "gp2", "rook-ceph-block"
   ```

2. **Storage Sizes**: Adjust based on your needs:

   | PVC | Current Size | Usage |
   |-----|--------------|-------|
   | `taxonworks-media-pv-claim` | 100Gi | Images and media files |
   | `taxonworks-backup-pv-claim` | 100Gi | Database backups |
   | `taxonworks-staging-pv-claim` | 50Gi | Staging/temp files |

   To find available storage classes:
   ```bash
   kubectl get storageclass
   ```

### 5. Ingress Configuration

**File: `base/ingress.yml`**

| Setting | Description | Example |
|---------|-------------|---------|
| `ingressClassName` | Your ingress controller class | `nginx`, `traefik`, `haproxy` |
| TLS section | Uncomment if using HTTPS | See file for structure |
| `cert-manager.io/cluster-issuer` | Uncomment if using cert-manager | `letsencrypt-prod` |

## Pre-Deployment Checklist

- [ ] Created `base/secret.yml` with all secrets configured
- [ ] Updated all domain references in `configmap.yml` and `ingress.yml`
- [ ] Configured email/SMTP settings in `configmap.yml`
- [ ] Set appropriate storage class in all PVCs
- [ ] Adjusted storage sizes based on requirements
- [ ] Configured ingress class and TLS settings
- [ ] Verified storage class supports `ReadWriteMany` access mode

## Security Considerations

1. **Secrets Management**:
   - Consider using Kubernetes secrets management tools (Sealed Secrets, Vault, etc.)
   - Ensure `base/secret.yml` is in `.gitignore`
   - Use strong, unique passwords

2. **Network Security**:
   - Configure network policies if required
   - Use TLS/HTTPS in production
   - Restrict database access to the app namespace

3. **Resource Limits**:
   - Consider adding resource requests/limits in `base/app.yml`
   - Monitor resource usage and adjust accordingly

## Environment-Specific Overlays (Recommended Approach)

Instead of modifying the base files directly, use Kustomize overlays to manage environment-specific configurations. This keeps your base files generic and your custom settings separate.

### What are Overlays?

Overlays allow you to customize Kubernetes resources for different environments without modifying the original files. Think of it as applying patches on top of base configurations.

### Directory Structure

```bash
k8s/new-cluster/
├── base/                    # Generic base configuration (don't modify these)
│   ├── configmap.yml       # Keep example.com values
│   ├── ingress.yml         # Keep example.com values
│   └── ...other files...
└── overlays/
    ├── aks/       # AKS test environment
    │   ├── kustomization.yml
    │   ├── configmap.yml   # Only your specific overrides
    │   └── ingress.yml     # Only your specific overrides
    ├── staging/           # Staging environment
    │   └── ...
    └── production/        # Production environment
        └── ...
```

### Creating an Overlay

1. **Create overlay directory**:
   ```bash
   mkdir -p k8s/new-cluster/overlays/myenv
   ```

2. **Create kustomization.yml**:
   ```yaml
   # k8s/new-cluster/overlays/myenv/kustomization.yml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   resources:
     - ../../base
   
   patchesStrategicMerge:
     - configmap.yml
     - ingress.yml
   ```

3. **Create override files** (only include what you're changing):
   ```yaml
   # k8s/new-cluster/overlays/myenv/configmap.yml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: taxonworks
   data:
     server.name: "taxonworks.mydomain.com"
     tw.action_mailer_url_host: "taxonworks.mydomain.com"
   ```

### Deploying with Overlays

Instead of:
```bash
kubectl apply -k k8s/new-cluster/base/
```

Use:
```bash
kubectl apply -k k8s/new-cluster/overlays/aks/
```

### Benefits

1. **Base files stay generic** - Can be safely committed
2. **Environment configs are isolated** - Easy to manage
3. **No accidental commits** - Your specific settings are separate
4. **Easy switching** - Deploy different environments easily
5. **Team-friendly** - Multiple teams can have their own overlays

### Update the Deploy Script

When using overlays, update your deploy command:
```bash
./deploy.sh /path/to/kubeconfig k8s/new-cluster/overlays/aks/
```