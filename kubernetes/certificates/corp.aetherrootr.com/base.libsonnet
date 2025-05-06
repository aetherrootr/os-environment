local certificateUtils = import 'utils/certificate-utils.libsonnet';

{
    namespace:: error 'namespace not set',
    name:: $.namespace + '-wildcard-certificate',

    local domain =  '*.corp.aetherrootr.com',

    apiVersion: 'apps/v1',
    kind: 'list',
    items: std.prune([
        certificateUtils.generateCertificate(
            name=$.name,
            namespace=$.namespace,
            dnsNames=[domain],
        )
    ]),
}
