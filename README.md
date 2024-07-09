# Teleport k8s to ArgoCD 

This allows teleport k8s clusters to be used with argocd. The tool will take care of keeping the registration current.

## Configuration

### General

Basic configuration is done via environment variables

- `ARGOCD_DOMAIN` - Domain of your ArgoCd installation
- `ARGOCD_USERNAME` - ArgoCD username 
- `ARGOCD_PASSWORD` - ArgoCD password 
- `TELEPORT_DOMAIN` - Domain of your teleport instance

### Clusters

The clusters to sync are configured using a yaml file.
The file needs to be in `/config/clusters.yaml`

The `name` needs to correspond with the name in teleport.

An example:

```yaml
clusters:
  - name: my-k8s-cluster
    labels:
      foo: bar
      bar: baz
  - name: another-cluster
    labels:
      hello: world
  - name: no-labels-cluster
    labels: []
```
