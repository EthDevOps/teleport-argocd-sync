# Teleport k8s to ArgoCD 

This allows teleport k8s clusters to be used with argocd. The tool will take care of keeping the registration current.

## Configuration

You need to create a teleport bot and pass the token to the syncer

as the token is only valid once you need to mount a volume to `/var/lib/teleport` to persist the new certs

### General

Basic configuration is done via environment variables

- `ARGOCD_DOMAIN` - Domain of your ArgoCd installation
- `ARGOCD_USERNAME` - ArgoCD username 
- `ARGOCD_PASSWORD` - ArgoCD password 
- `TELEPORT_DOMAIN` - Domain of your teleport instance
- `TELEPORT_TOKEN` - The inital join token for the Teleport Bot

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
