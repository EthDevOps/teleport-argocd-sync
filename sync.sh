#!/bin/bash

# Global
echo "Generate teleport bot config..."
yq -i ".onboarding.token = \"${TELEPORT_TOKEN}\"" /etc/tbot.yaml
yq -i ".proxy_server = \"${TELEPORT_DOMAIN}:443\"" /etc/tbot.yaml

yq '.clusters[].name' /config/clusters.yaml | while read -r CLUSTER; do
  yq eval -i ".outputs += [{\"type\": \"kubernetes\", \"kubernetes_cluster\": \"${CLUSTER}\", \"roles\": [\"access\"], \"destination\": {\"type\": \"directory\", \"path\": \"/k8s-configs/${CLUSTER}\"}}]" /etc/tbot.yaml
done
echo "Refreshing Teleport Credentials..."
tbot start -c /etc/tbot.yaml

echo "Login to ArgoCD..."
argocd --grpc-web login ${ARGOCD_DOMAIN} --username ${ARGOCD_USERNAME} --password ${ARGOCD_PASSWORD}

# Per cluster
yq '.clusters[].name' /config/clusters.yaml | while read -r CLUSTER; do

  echo "=== PROCESSING CLUSTER ${CLUSTER} ==="

  mkdir -p /k8s-configs/${CLUSTER}

  echo "Grabbing labels..."
  LABELS=$(yq eval ".clusters[] | select(.name == \"${CLUSTER}\") | .labels | to_entries | map(\"--label \" + .key + \"=\" + .value) | join(\" \")" /config/clusters.yaml)

  echo "Extracting k8s user certificates..."
  tbot kube credentials --destination-dir=/k8s-configs/${CLUSTER} > /k8s-configs/${CLUSTER}/creds.json

  echo "Write certs to files..."
  cat /k8s-configs/${CLUSTER}/creds.json | jq -r '.status.clientKeyData' > /k8s-configs/${CLUSTER}/client-key.pem
  cat /k8s-configs/${CLUSTER}/creds.json | jq -r '.status.clientCertificateData' > /k8s-configs/${CLUSTER}/client-cert.pem

  echo "Replace user in kubeconfig..."
  yq -i '.users[0].user = {}' /k8s-configs/${CLUSTER}/kubeconfig.yaml
  yq -i ".users[0].user.client-key = \"/k8s-configs/${CLUSTER}/client-key.pem\"" /k8s-configs/${CLUSTER}/kubeconfig.yaml
  yq -i ".users[0].user.client-certificate = \"/k8s-configs/${CLUSTER}/client-cert.pem\"" /k8s-configs/${CLUSTER}/kubeconfig.yaml

  echo "$LABELS"

  echo "Register Cluster with ArgoCD.."
  argocd --grpc-web cluster add -y --upsert ${LABELS} --kubeconfig /k8s-configs/${CLUSTER}/kubeconfig.yaml --name ${CLUSTER} ${TELEPORT_DOMAIN}-${CLUSTER}
done;
