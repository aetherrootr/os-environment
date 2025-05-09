Get a kubernetes dashboard access token
```
kubectl -n kubernetes-dashboard get secret dashboard-admin-token -o jsonpath='{.data.token}' | base64 -d && echo
```
