## Secret
We use Bitwarden to manage all our secrets. All secrets need to be created on the [web](https://vault.bitwarden.com/#/sm/56a05183-18ce-45c9-8035-b2dc0110db66) and obtained in the form of BitwardenSecret.

When we want to use bitwarden in a namespace, we need to get a new token on [this page](https://vault.bitwarden.com/#/sm/56a05183-18ce-45c9-8035-b2dc0110db66/machine-accounts/33581687-22d8-4d96-9523-b2dd01252a91/access) and inject it into the corresponding namespace using the following command.

```
kubectl create secret generic bw-auth-token -n <YOUR_NAMESPACE> --from-literal=token="<TOKEN_HERE>"
```
