## Secret

We use Bitwarden to manage all our secrets. All secrets need to be created on the [web](https://vault.bitwarden.com/#/sm/56a05183-18ce-45c9-8035-b2dc0110db66) and obtained in the form of BitwardenSecret.

### Initial credentials

When we want to use bitwarden in a namespace, we need to get a new token on [this page](https://vault.bitwarden.com/#/sm/56a05183-18ce-45c9-8035-b2dc0110db66/machine-accounts/33581687-22d8-4d96-9523-b2dd01252a91/access) and inject it into the corresponding namespace using the following command.

```bash
kubectl create secret generic bw-auth-token -n <YOUR_NAMESPACE> --from-literal=token="<TOKEN_HERE>"
```

Repeat this setup for each namespace that uses BitwardenSecret mappings. The
`bw-auth-token` is the initial credential that lets the Bitwarden operator access
Bitwarden; it must exist before the operator can create workload Secrets. Keep
the token outside Git and provision it independently of Argo CD.

### Management through Argo CD

Argo CD manages workload `BitwardenSecret` mappings through each existing
`<secret>/env/prod.jsonnet` entry. Register a mapping in the project's
[Secret registration list](../app/argocd/apps/projects/os-environment/secrets.libsonnet), using
`kubernetes/secrets/<secret>` as its `appPath` and the entry's namespace as its
`destinationNamespace`.

Merge the mapping and registration changes into `master`. Argo CD automatically
synchronizes both from Git. The Bitwarden operator creates and updates the
resulting Kubernetes Secrets from Bitwarden.
