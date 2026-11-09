# Open WebUI

Zen billing source, tests, installer and image builds are maintained separately in
`aetherrootr/open-webui-zen-billing` (local checkout: `~/work/open-webui-zen-billing`).
This directory owns only deployment configuration and existing Secret references.

`zen-billing.libsonnet` adds an Argo CD PostSync Job. The Job runs the versioned
component image and installs its native Open WebUI functions after Open WebUI is
healthy. No Python source is embedded in this repository or a ConfigMap. Repeated
installation preserves existing function configuration and billing records.

Before merging this deployment change:

1. Push the component repository and its `v0.1.0` tag.
2. Wait for its GitHub Actions tests and GHCR publication to succeed.
3. Confirm the image path in `zen-billing.libsonnet` matches the actual repository. Use
   a digest for immutable production pinning if available.
4. If the GHCR package is private, set `imagePullSecrets` in `zen-billing.libsonnet` to the cluster's
   existing pull Secret names, using `{ name: '...' }` entries. Keep credentials
   in Bitwarden/Kubernetes Secrets, never Git.
5. Review the deployment PR and merge manually. Argo CD follows `master`.

The Job reuses `open-webui-postgres-secret/password` and the read-only persisted
Open WebUI signing-key file; it does not require additional billing credentials.
The component requires a running Open WebUI v0.12.5 instance with an existing
administrator. It creates a short-lived admin token for native function APIs and
has no Kubernetes API token mounted.

Users select **Zen 费用报表** and send `查看本月费用` or a month such as `2026-11`.
Admins see all users; ordinary users see their own records. The existing
`zen_user_cost_entry` table is preserved. The component README documents the
accounting scope and the distinction between reported and estimated costs.

The image is not published yet when this change is first prepared locally. Do not
apply the Job until the release exists. Preview functions already installed through
native APIs remain usable in the meantime. Legacy preview resources named
`open-webui-zen-cost-plugins` and `open-webui-install-zen-cost-plugins` can be removed
after the image installer has been verified; the database ledger must be retained.

Render without deploying:

```sh
tk show kubernetes/app/open-webui/env/prod.jsonnet
```
