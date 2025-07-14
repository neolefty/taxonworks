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