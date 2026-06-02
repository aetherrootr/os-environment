local certificateUtils = import 'utils/certificate-utils.libsonnet';

{
  namespace:: error 'namespace not set',
  name:: $.namespace + '-authentik-certificate',

  local domain = 'authentik.aetherrootr.com',

  apiVersion: 'apps/v1',
  kind: 'list',
  items: std.prune([
    certificateUtils.generateCertificate(
      name=$.name,
      namespace=$.namespace,
      dnsNames=[domain],
    ),
  ]),
}
