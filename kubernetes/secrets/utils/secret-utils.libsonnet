{
  generateBitwardenSecret(secretName, namespace, extraLabels={}, bwSecret=[]): {
    apiVersion: "k8s.bitwarden.com/v1",
    kind: "BitwardenSecret",
    metadata: {
      namespace: namespace,
      name: secretName,
      labels: {
        app: secretName,
      } + extraLabels,
    },
    spec: {
      organizationId: "56a05183-18ce-45c9-8035-b2dc0110db66",
      secretName: secretName,
      map: bwSecret,
      authToken: {
        secretName: "bw-auth-token",
        secretKey: "token",
      },
    },

  },

  generateBwSecret(bwSecretId, secretKeyName): {
    secretKeyName: secretKeyName,
    bwSecretId: bwSecretId,
  },
}
