#!/usr/bin/env bash

# Bash color parameters
GREEN='\033[0;32m'
NC='\033[0m'

# Variables
CLUSTER_NAME="$(basename "$PWD" | sed 's/_//')-localCluster"
CLUSTER=$(k3d cluster list | grep "$CLUSTER_NAME")

# Create the k3d cluster
create_cluster() {
  if [ "$CLUSTER" ]; then
    echo "==> ${GREEN}Cluster:${NC} $CLUSTER"
  else
    echo "==> ${GREEN}Cluster does not exist, creating cluster${NC}"
    k3d cluster create "$CLUSTER_NAME" --agents 2
  fi
}

# Set k3d cluster context and deploy argocd
install_argocd() {
  echo
  kubectl config use-context "k3d-$CLUSTER_NAME"
  echo
  # Install argocd
  ARGO_NS=$(kubectl get ns argocd --ignore-not-found | grep -c "argocd")

  if [ "$ARGO_NS" != 0 ]; then
    echo "==> ${GREEN}ArgoCD is up and running, continue...${NC}"
  else
    echo "==> ${GREEN}Deploy ArgoCD...${NC}"
    # Get argocd
    ARGOCD=$(curl https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml)

    # Create the argocd namespace(s)
    kubectl create ns argocd

    # Install argocd
    echo "$ARGOCD" | kubectl apply -f - --namespace=argocd
    echo "==> ${GREEN}Waiting for ArgoCD to become available...${NC}"
  fi

  echo
  # Verify ArgoCD is available and deploy argocd apps
  kubectl -n argocd wait --for condition=Available --timeout=600s deployment/argocd-server

  # Update argocd congig map to allow synv waves to be restored for app of apps patern
  ARGOCD_CONGIG_MAP=$(
    cat <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
  labels:
    app.kubernetes.io/name: argocd-cm
    app.kubernetes.io/part-of: argocd
data:
  resource.customizations: |
    argoproj.io/Application:
      health.lua: |
        hs = {}
        hs.status = "Progressing"
        hs.message = ""
        if obj.status ~= nil then
          if obj.status.health ~= nil then
            hs.status = obj.status.health.status
            if obj.status.health.message ~= nil then
              hs.message = obj.status.health.message
            end
          end
        end
        return hs

EOF
  )

  echo "$ARGOCD_CONGIG_MAP" | kubectl apply -f -

  # Deploy argocd applications

}

# Access the ArgoCD web UI
access_argocd() {
  PORT=8079
  echo
  # Return ArgoCD initial password for the web UI
  PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo)
  echo "==> ${GREEN}ArgoCD UI login${NC}: username: ${GREEN}admin${NC} || password: ${GREEN}${PASS}${NC}"
  echo
  echo "==> ${GREEN}URL${NC}: http://localhost:${PORT}"
  echo

  # Port forward the ArgoCD web UI
  kubectl port-forward svc/argocd-server -n argocd ${PORT}:443 >/dev/null 2>&1 &
}

# Delete the k3d cluster
delete_cluster() {
  if [ "$CLUSTER" ]; then
    echo "==> ${GREEN}Cluster does exist, deleting cluster${NC}"
    k3d cluster delete "$CLUSTER_NAME"
  else
    echo "==> ${GREEN}Cluster does not exist${NC}"
  fi
}
