{
  generateServiceAccount(name, namespace): {
    apiVersion: "v1",
    kind: "ServiceAccount",
    metadata: {
      name: name,
      namespace: namespace,
    },
  },
}
