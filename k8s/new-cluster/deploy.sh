#!/bin/bash

# TaxonWorks Kubernetes Deployment Script
# Usage: ./deploy.sh [kubeconfig-path]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if kubeconfig path is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Please provide kubeconfig path${NC}"
    echo "Usage: $0 /path/to/kubeconfig"
    exit 1
fi

KUBECONFIG_PATH=$1
export KUBECONFIG=$KUBECONFIG_PATH

echo -e "${GREEN}Using kubeconfig: $KUBECONFIG_PATH${NC}"

# Function to check if resource exists
resource_exists() {
    kubectl get $1 $2 -n $3 &> /dev/null
}

# Step 1: Verify cluster access
echo -e "\n${YELLOW}Step 1: Verifying cluster access...${NC}"
kubectl get nodes
echo -e "${GREEN}✓ Cluster access verified${NC}"

# Step 2: Check for required tools
echo -e "\n${YELLOW}Step 2: Checking required tools...${NC}"
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}kubectl is required but not installed.${NC}" >&2; exit 1; }
command -v kustomize >/dev/null 2>&1 || { echo -e "${RED}kustomize is required but not installed.${NC}" >&2; exit 1; }
echo -e "${GREEN}✓ All required tools found${NC}"

# Step 3: Check if secret file exists
echo -e "\n${YELLOW}Step 3: Checking for secret configuration...${NC}"
if [ ! -f "base/secret.yml" ]; then
    echo -e "${RED}Error: base/secret.yml not found!${NC}"
    echo "Please copy base/secret-template.yml to base/secret.yml and fill in your values"
    exit 1
fi
echo -e "${GREEN}✓ Secret file found${NC}"

# Step 4: Check storage classes
echo -e "\n${YELLOW}Step 4: Checking available storage classes...${NC}"
kubectl get storageclass
echo -e "${YELLOW}Make sure to update PVC definitions with appropriate storageClassName${NC}"

# Step 5: Create namespace
echo -e "\n${YELLOW}Step 5: Creating namespace...${NC}"
if resource_exists namespace taxonworks ""; then
    echo -e "${YELLOW}Namespace 'taxonworks' already exists${NC}"
else
    kubectl create namespace taxonworks
    echo -e "${GREEN}✓ Namespace created${NC}"
fi

# Step 6: Deploy resources
echo -e "\n${YELLOW}Step 6: Deploying resources...${NC}"
echo "This will deploy:"
echo "  - ConfigMap and Secrets"
echo "  - PostgreSQL database with PostGIS"
echo "  - Persistent Volume Claims"
echo "  - TaxonWorks application"
echo "  - Ingress configuration"

read -p "Continue with deployment? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 1
fi

# Deploy using kustomize
echo -e "\n${YELLOW}Deploying resources...${NC}"
kubectl apply -k base/

# Step 7: Wait for PostgreSQL to be ready
echo -e "\n${YELLOW}Step 7: Waiting for PostgreSQL to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=postgres -n taxonworks --timeout=300s

# Step 8: Wait for TaxonWorks to be ready
echo -e "\n${YELLOW}Step 8: Waiting for TaxonWorks to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=taxonworks -n taxonworks --timeout=600s

# Step 9: Show deployment status
echo -e "\n${YELLOW}Step 9: Deployment Status${NC}"
echo -e "\n${GREEN}Pods:${NC}"
kubectl get pods -n taxonworks
echo -e "\n${GREEN}Services:${NC}"
kubectl get svc -n taxonworks
echo -e "\n${GREEN}PVCs:${NC}"
kubectl get pvc -n taxonworks
echo -e "\n${GREEN}Ingress:${NC}"
kubectl get ingress -n taxonworks

echo -e "\n${GREEN}Deployment complete!${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Update the Ingress host in base/ingress.yml with your domain"
echo "2. Configure DNS to point to your ingress controller"
echo "3. Run database migrations:"
echo "   kubectl exec -it deployment/taxonworks -n taxonworks -- rails db:migrate"
echo "4. Create initial admin user:"
echo "   kubectl exec -it deployment/taxonworks -n taxonworks -- rails console"