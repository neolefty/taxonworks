# Current Deployment Issue - AKS Registry Access

## Date: July 28, 2025

## Problem Summary
TaxonWorks pods are stuck in `ContainerCreating` state with NO image pull events in the pod description.

## Current Configuration

### Image Configuration
- **Registry**: `registry.48.216.156.172.sslip.io`
- **Image**: `taxonworks:k8s-test`
- **Full Image Path**: `registry.48.216.156.172.sslip.io/taxonworks:k8s-test`
- **Image Size**: 3.74GB
- **Architecture**: linux/amd64 (x86_64)

### Registry Status
- Registry is accessible from outside the cluster (returns 200 OK)
- Image exists in registry: confirmed via `curl -s https://registry.48.216.156.172.sslip.io/v2/taxonworks/tags/list`
- Registry appears to be Docker Registry v2

### Pod Details
```
Pod Name: taxonworks-844fcff4db-bkgbf
Namespace: development
Node: aks-nodepool1-16235633-vmss000016
Status: ContainerCreating
```

### Deployment Configuration (from kustomize)
```yaml
image: registry.48.216.156.172.sslip.io/taxonworks:k8s-test
imagePullPolicy: IfNotPresent
```

## Symptoms
1. Pod remains in `ContainerCreating` state indefinitely
2. NO image pull events appear in pod description (only "Scheduled" event)
3. No error messages in events
4. Container state shows only: `{"waiting": {"reason": "ContainerCreating"}}`

## What We've Verified
1. ✅ Registry is accessible from outside cluster
2. ✅ Image exists in registry
3. ✅ Image is correct architecture (amd64)
4. ✅ Deployment YAML has correct image path
5. ✅ PVC (shared-dev-storage) is bound and available
6. ✅ No issues with volume mounts

## Suspected Issues
1. **Network connectivity**: AKS nodes cannot reach `registry.48.216.156.172.sslip.io`
2. **DNS resolution**: Nodes cannot resolve the registry hostname
3. **TLS/Certificate**: Registry certificate not trusted by AKS nodes
4. **Firewall/Network Policy**: Traffic blocked between nodes and registry

## Questions for Sysadmin (Sam)

1. Can AKS nodes resolve and reach `registry.48.216.156.172.sslip.io`?
   - Test from node: `curl -I https://registry.48.216.156.172.sslip.io/v2/`

2. Are there any network policies or Azure NSGs blocking outbound HTTPS to the registry?

3. Is the registry's TLS certificate trusted by the AKS nodes?

4. Can you check kubelet logs on node `aks-nodepool1-16235633-vmss000016` for any errors?

5. Is there a specific image pull secret needed for this registry?

## Commands to Debug

From a node or privileged pod:
```bash
# Test DNS resolution
nslookup registry.48.216.156.172.sslip.io

# Test connectivity
curl -v https://registry.48.216.156.172.sslip.io/v2/

# Check if image is accessible
curl -s https://registry.48.216.156.172.sslip.io/v2/taxonworks/manifests/k8s-test
```

## Current Pod Status
```bash
kdev describe pod taxonworks-844fcff4db-bkgbf -n development
```

The key issue is that there are NO image pull attempts visible in the events, suggesting the problem occurs before the image pull is even attempted.