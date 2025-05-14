## Add a new Kubernetes app
```
./add_kubernetes_app.sh <kubernetes app name>
```

For example:
```
./add_kubernetes_app.sh kubernetes_dashboard
```

## Deploy the app to the Kubernetes cluster

### For applications based on jsonnet description

```
jb install
tk apply env/<prod/dev>.jsonnet
```

### For applications imported from helm

```
tk tool charts vendor
jb install
k apply env/<prod/dev>.jsonnet
```
