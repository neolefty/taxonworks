# TaxonWorks Kubernetes Deployment

This directory contains updated Kubernetes manifests for deploying TaxonWorks to a modern K8s cluster.

## Prerequisites

1. Kubernetes cluster (1.19+)
2. kubectl installed and configured
3. kustomize installed
4. Storage class that supports ReadWriteMany (for shared volumes)
5. Ingress controller installed (e.g., nginx-ingress)

## Environment Configuration

Before deploying, you must configure environment-specific settings. See [ENVIRONMENT_CONFIG.md](./ENVIRONMENT_CONFIG.md) for detailed instructions on all required configuration values.

### AKS Deployment

For Azure Kubernetes Service deployment with specific constraints, see the [AKS Quick Start](./overlays/aks/README.md) guide.

## Quick Start

1. **Create secrets file**:
   ```bash
   cp base/secret-template.yml base/secret.yml
   # Edit base/secret.yml with your actual values
   ```

2. **Update configuration**:
   - Edit `base/configmap.yml` with your email/SMTP settings
   - Edit `base/ingress.yml` with your domain name
   - Update PVC storage sizes in `base/pv-claims.yml` if needed
   - Update storage class names in PVC files

3. **Deploy**:
   ```bash
   ./deploy.sh /path/to/your/kubeconfig
   ```

## Manual Deployment

If you prefer to deploy manually:

```bash
# Set kubeconfig
export KUBECONFIG=/path/to/your/kubeconfig

# Create namespace
kubectl create namespace taxonworks

# Deploy all resources
kubectl apply -k base/

# Check deployment status
kubectl get all -n taxonworks
```

## Post-Deployment

1. **Run database migrations**:
   ```bash
   kubectl exec -it deployment/taxonworks -n taxonworks -- rails db:migrate
   ```

2. **Create admin user**:
   ```bash
   kubectl exec -it deployment/taxonworks -n taxonworks -- rails console
   # In console: User.create!(email: 'admin@example.com', password: 'your-password', is_administrator: true)
   ```

3. **Check logs**:
   ```bash
   kubectl logs -f deployment/taxonworks -n taxonworks
   ```

## Database Operations

### Restoring from SQL Dump

To restore a TaxonWorks database from a SQL dump file:

1. **Identify the pods**:
   ```bash
   # Using kubectl alias (replace 'kdev' with your alias or kubectl)
   kdev get pods -n development | grep -E "(taxonworks|postgres)"
   ```

2. **Option A: Direct PostgreSQL restore (recommended for large dumps)**:
   ```bash
   # Copy dump to PostgreSQL pod
   kdev cp /path/to/dump.sql development/postgres-0:/tmp/dump.sql
   
   # Restore directly (check your PostgreSQL username from env vars)
   kdev exec postgres-0 -n development -- psql -U taxonworks -d taxonworks_production -f /tmp/dump.sql
   
   # Clean up
   kdev exec postgres-0 -n development -- rm /tmp/dump.sql
   ```

3. **Option B: Using Rails commands (recommended for smaller dumps)**:
   ```bash
   # Drop existing database (if needed)
   kdev exec [app-pod] -n development -- bundle exec rails db:drop:_unsafe
   
   # Create empty database
   kdev exec [app-pod] -n development -- bundle exec rails db:create
   
   # Copy dump file to app container
   kdev cp /path/to/dump.sql development/[app-pod]:/tmp/dump.sql
   
   # Restore using Rails
   kdev exec [app-pod] -n development -- sh -c "bundle exec rails dbconsole < /tmp/dump.sql"
   
   # Clean up
   kdev exec [app-pod] -n development -- rm /tmp/dump.sql
   ```

4. **For very large dumps (streaming approach)**:
   ```bash
   # Stream directly to PostgreSQL (requires -i flag)
   kdev exec -i postgres-0 -n development -- psql -U taxonworks -d taxonworks_production < /path/to/dump.sql
   ```

### Common Database Tasks

**Check database configuration**:
```bash
# View PostgreSQL environment variables
kdev exec postgres-0 -n development -- env | grep -E "(POSTGRES_|DB_)" | sort
```

**Restart Rails app (to drop connections)**:
```bash
# Quick restart by deleting pod
kdev delete pod [app-pod] -n development

# Or graceful restart
kdev rollout restart deployment taxonworks -n development
```

**Monitor restore progress**:
```bash
# Check database size
kdev exec postgres-0 -n development -- psql -U taxonworks -d taxonworks_production -c "SELECT pg_database_size('taxonworks_production')/1024/1024 AS size_mb;"
```

### Troubleshooting Database Operations

- **Exit code 137**: Out of memory - use PostgreSQL pod directly or increase memory limits
- **Exit code 143**: Process terminated (SIGTERM) - usually normal when stopping commands with Ctrl+C
- **Connection errors**: Restart the Rails app to drop stale connections
- **Protected environment error**: Use `db:drop:_unsafe` or set `DISABLE_DATABASE_ENVIRONMENT_CHECK=1`

## Troubleshooting

- **PVC not binding**: Check available storage classes with `kubectl get storageclass`
- **Pods not starting**: Check logs with `kubectl logs -n taxonworks <pod-name>`
- **Database connection issues**: Verify PostgreSQL is running and credentials match

## Customization

The deployment uses Kustomize for easy customization. You can create overlays for different environments:

```bash
k8s/new-cluster/
├── base/           # Base configuration
└── overlays/
    ├── dev/        # Development overrides
    └── prod/       # Production overrides
```