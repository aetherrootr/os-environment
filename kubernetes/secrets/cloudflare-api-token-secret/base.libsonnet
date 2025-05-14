local secretUtils = import "utils/secret-utils.libsonnet";

{
    namespace:: "cert-manager",

    apiVersion: "apps/v1",
    kind: "list",
    items: [
        secretUtils.generateBitwardenSecret(
            secretName="cloudflare-api-token-secret",
            namespace=$.namespace,
            bwSecret=[
                secretUtils.generateBwSecret(
                    bwSecretId="e061d2c6-143d-43cc-987a-b2dd012e8344",
                    secretKeyName="api-token",
                )
            ],
        ),
    ],
}
