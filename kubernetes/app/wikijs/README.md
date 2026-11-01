# Wiki.js

Production runs Wiki.js 3.0.1 with PostgreSQL 17. The previous Wiki.js 2.5.312
deployment and PostgreSQL 15 database remain available for recovery. The
`activeVersion` setting in `env/prod.jsonnet` selects the application serving
`wiki.corp.aetherrootr.com`; the inactive application's replicas are set to zero.

The databases use separate directories on the existing service-data PVC:

| Instance | PostgreSQL data | Application data | Database dumps |
| --- | --- | --- | --- |
| v2 | `wikijs/data` | `wikijs/token` | `wikijs/pg_backup` |
| v3 | `wikijs_v3/data` | `wikijs_v3/app` | `wikijs_v3/pg_backup` |

Both instances have a daily database backup. The shared off-site backup includes
both directories and excludes each PostgreSQL data directory, backing up logical
dumps instead. Migration packages are retained under
`wikijs_v3/migration/backup` with restricted filesystem permissions.

## Initial preparation

Before starting v3 with an empty database, create the `wikijs-v3-bootstrap`
Kubernetes Secret in `applications-and-services`, with `email` and `password`
keys. Use the existing primary administrator's email and a strong random initial
password. Keep the Secret private and out of Git. These values initialize an
empty database; they do not reset accounts in a populated or restored database.
The existing `wikijs-postgresdb-secret` supplies the database credentials.

`env/v3-prepare.jsonnet` deploys only the independent v3 application, database and
backup resources. It does not change the production ingress or stop v2:

```bash
jb install
tk apply env/v3-prepare.jsonnet
```

Use the official 2.x exporter and 3.x import API to migrate data. The 2026-11-02
migration ran the 2.5.317 exporter against a restored copy of the original
database, without starting the copy's authentication or Git synchronization.
The original v2 database was not upgraded in place.

Authentication modules, Git storage, proxy trust and guest access rules require
explicit migration; the upstream importer does not transfer them automatically.
Preserve the original OIDC callback while adding the new strict callback. Stop
v2 and disable its Git synchronization before enabling v3 synchronization.

The old `/finance/Money_market_funds` bookmark redirects to the normalized
`/finance/money-market-funds` path while v3 is active. Switching back to v2
removes that redirect and sends the original path to v2 again.

## Validation and rollback

Before switching the ingress, verify the package's ZIP checksums, stream counts,
attachment hashes, page renders, user/group mappings, OIDC authorization request
and a fresh v3 database dump. Check that source content has not changed since
the export; stop writes and repeat the export/import if necessary.

The initial migration contains 13 pages and 8 attachments. Six source history
entries belong to existing pages and can be imported; three entries belong to
deleted pages and remain in the original database and migration package.
Wiki.js 3 merges accounts with the same email address. One CKEditor page is
converted to Markdown for the visual editor, and the `zh` locale maps to `zh-CN`.

For an immediate rollback, set `activeVersion: 'v2'` in `env/prod.jsonnet` and
apply or synchronize that revision. This stops v3, starts v2 and restores both
ingress routes. The original v2 Git synchronization is deliberately disabled at
cutover; leave it disabled until the remote repository's contents have been
reviewed for compatibility. Preserve any content written to v3 after cutover
before reverting to the older snapshot. Never reuse the v2 PostgreSQL data
directory for PostgreSQL 17 or connect Wiki.js 3 to the v2 database.
