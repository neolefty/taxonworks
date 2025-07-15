# TaxonWorks K8s AKS Deployment Status

## Current Status: Image Registry Issues

**Date**: July 15, 2025  
**Branch**: k8s-central  
**Last Commit**: 983966aafe - "Update to use shared-dev-storage PVC and fix image version"

## Problem Summary

TaxonWorks pods stuck in `ContainerCreating` state for 20+ hours due to image pull issues.

**Root Cause**: 
- Originally using non-existent image `sfgrp/taxonworks:0.3.12`
- Updated to `sfgrp/taxonworks:0.9.8` (exists on Docker Hub)
- Local registry `registry.48.216.156.172.sslip.io` returning 503 errors

## What's Working ✅

1. **Postgres Database**: Running successfully in development namespace
2. **Security Contexts**: Fixed PodSecurity violations for both apps
3. **Storage**: Using admin's `shared-dev-storage` PVC (ReadWriteMany, azurefile-csi)
4. **Networking**: Ingress configured for `taxonworks.48.216.156.172.sslip.io`
5. **Overlays**: AKS-specific constraints properly implemented

## Current Configuration

**Namespace**: development  
**PVC**: shared-dev-storage (admin's shared PVC)  
**Image**: sfgrp/taxonworks:0.9.8  
**Resources**: 256Mi request, 1Gi limit (admin's requirements)  
**Replicas**: 1  

## Issue Details

**Local Registry Problem**:
- `registry.48.216.156.172.sslip.io` returns 503 Service Temporarily Unavailable
- Tested from both local Mac and Linux (`ssh home`)
- Built fresh x86_64 image on Linux machine: `taxonworks:k8s-test`
- Push fails to local registry from both machines

**Alternative Approaches**:
1. **Use Docker Hub**: Update to working `sfgrp/taxonworks:0.9.8` image
2. **Fix Local Registry**: Admin needs to check registry service status
3. **Transfer Image**: Copy built image to local machine and push when registry is fixed

## Files Modified

```
k8s/new-cluster/
├── base/
│   └── kustomization.yml          # Updated image version to 0.9.8
├── overlays/aks/
│   ├── README.md                  # AKS deployment guide
│   ├── kustomization.yml          # Uses shared-dev-storage PVC
│   ├── shared-pvc.yml            # Reference to admin's shared PVC
│   ├── app.yml                   # Security context + resource limits
│   └── postgres.yml              # Security context for postgres
```

## Next Steps

1. **Ask Sam**: Is registry service `registry.48.216.156.172.sslip.io` running?
2. **Test Docker Hub**: Try deployment with `sfgrp/taxonworks:0.9.8` from Docker Hub
3. **Registry Fix**: Once registry is working, push `taxonworks:k8s-test` from Linux machine
4. **Update Deployment**: Use local registry image once available

## Commands to Test

```bash
# Check current pod status
kdev get pods -n development

# Test deployment with Docker Hub image
kdev apply -k k8s/new-cluster/overlays/aks/

# Check registry status (when working)
docker push registry.48.216.156.172.sslip.io/taxonworks:test

# Built image waiting on Linux machine
ssh home "docker images | grep taxonworks"
```

## Key Contacts

- **Sam**: Admin managing AKS cluster and local registry
- **Current constraints**: Single PVC, development namespace, minimal resources

## Success Criteria

- [ ] TaxonWorks pods running (not ContainerCreating)
- [ ] App accessible via `taxonworks.48.216.156.172.sslip.io`
- [ ] Database migrations completed
- [ ] Admin user created

---

*Last updated by Claude Code session on k8s-central branch*