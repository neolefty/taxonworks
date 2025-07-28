# AKS Quick Start

This overlay is configured for Azure Kubernetes Service (AKS) deployment with specific constraints.

## AKS Constraints

This overlay addresses the following AKS environment limitations:
- **Single Shared PVC**: Uses only the existing `shared-dev-storage` PVC (15Gi, RWX)
- **Single Namespace**: All resources deploy to "development" namespace
- **No Additional PVCs**: Base PVCs are removed via patches to prevent creation

## Prerequisites

1. AKS cluster with kubectl access
2. Storage class that supports `ReadWriteMany` (e.g., Azure Files)
3. Ingress controller installed (e.g., nginx-ingress)

## Quick Deployment

1. **Configure secrets**:
   ```bash
   cd k8s/new-cluster
   cp base/secret-template.yml base/secret.yml
   # Edit base/secret.yml with your values
   ```

2. **Update domain settings**:
   - Edit `overlays/aks/configmap.yml` with your domain
   - Edit `overlays/aks/ingress.yml` with your domain

3. **Set storage class**:
   ```bash
   # Edit overlays/aks/pv-claims.yml
   # Uncomment and set storageClassName (e.g., azurefile-csi)
   ```

4. **Push image to local registry**:
   ```bash
   # Tag your local image
   docker tag taxonworks:k8s-test registry.48.216.156.172.sslip.io/taxonworks:k8s-test
   
   # Push to registry
   docker push registry.48.216.156.172.sslip.io/taxonworks:k8s-test
   
   # Verify image exists
   curl -s https://registry.48.216.156.172.sslip.io/v2/taxonworks/tags/list
   ```

5. **Deploy**:
   ```bash
   kubectl apply -k k8s/new-cluster/overlays/aks/
   ```

## Post-Deployment

1. **Monitor deployment progress**:
   ```bash
   # Watch pod status continuously
   kubectl get pods -n development -w
   
   # Check deployment status
   kubectl get all -n development
   
   # Check specific pod details if issues occur
   kubectl describe pod <pod-name> -n development
   ```

2. **View application logs**:
   ```bash
   # Follow logs from the deployment (automatically follows active pod)
   kubectl logs -f deployment/taxonworks -n development
   
   # Or follow logs from specific pod
   kubectl logs -f <pod-name> -n development
   ```

3. **Run migrations**:
   ```bash
   kubectl exec -it deployment/taxonworks -n development -- rails db:migrate
   ```

4. **Create admin user**:
   ```bash
   kubectl exec -it deployment/taxonworks -n development -- rails console
   # In console: User.create!(email: 'admin@example.com', password: 'password', is_administrator: true)
   ```

## Recommended AKS Storage Classes

- `azurefile-csi` - Azure Files (supports ReadWriteMany)
- `azurefile-csi-premium` - Premium Azure Files
- `default` - May work but check access modes

Check available classes:
```bash
kubectl get storageclass
```

## Troubleshooting

- **PVC not binding**: Verify storage class supports ReadWriteMany
- **Pods pending**: Check resource quotas and node capacity
- **Ingress not working**: Verify ingress controller is installed and domain DNS