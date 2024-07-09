#!/bin/bash

# Global
echo "Refreshing Teleport Credentials..."
tbot start -c /config/tbot.yaml

echo "Login to ArgoCD..."
argocd login ${ARGOCD_DOMAIN} --username ${ARGOCD_USERNAME} --password ${ARGOCD_PASSWORD}

# Per cluster
yq '.clusters[].name' /config/clusters.yaml | while read -r CLUSTER; do

  echo "=== PROCESSING CLUSTER ${CLUSTER} ==="

  echo "Grabbing labels..."
  yq eval ".clusters[] | select(.name == \"${CLUSTER}\") | .labels | to_entries | map(.key + \"=\" + (.value )) | join(\",\")" /config/clusters.yaml

  echo "Extracting k8s user certificates..."
  tbot kube credentials --destination-dir=/k8s-configs/${CLUSTER}/ > /k8s-config/${CLUSTER}/creds.json

  echo "Write certs to files..."
  cat /k8s-configs/${CLUSTER}/creds.json | jq -r '.status.clientKeyData' > /k8s-configs/${CLUSTER}/client-key.pem
  cat /k8s-configs/${CLUSTER}/creds.json | jq -r '.status.clientCertificateData' > /k8s-configs/${CLUSTER}/client-cert.pem

  echo "Replace user in kubeconfig..."
  yq -i '.users[0].user = {}' /k8s-configs/${CLUSTER}/kubeconfig.yaml
  yq -i ".users[0].user.client-key = \"/k8s-config/${CLUSTER}/client-key.pem\"" /k8s-configs/${CLUSTER}/kubeconfig.yaml
  yq -i ".users[0].user.client-certificate = \"/k8s-config/${CLUSTER}/client-cert.pem\"" /k8s-configs/${CLUSTER}/kubeconfig.yaml

  echo "Register Cluster with ArgoCD.."
  argocd cluster add --kubeconfig /k8s-configs/${CLUSTER}/kubeconfig.yaml --name ${CLUSTER} ${TELEPORT_DOMAIN}-${CLUSTER}
done;
