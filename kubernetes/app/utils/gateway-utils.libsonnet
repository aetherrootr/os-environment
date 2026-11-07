// Shared edge Gateway is installed by the Ansible k8s_common role.
{
  gatewayName: 'edge',
  gatewayNamespace: 'infrastructure',

  rule(path, serviceName, port, pathType='PathPrefix', rewrite=null): {
    matches: [{ path: { type: pathType, value: path } }],
    backendRefs: [{ group: '', kind: 'Service', name: serviceName, port: port, weight: 1 }],
  } + (if rewrite == null then {} else {
    filters: [{ type: 'URLRewrite', urlRewrite: { path: {
      type: 'ReplaceFullPath', replaceFullPath: rewrite,
    } } }],
  }),

  routes(namespace, appName, serviceName, port, hostnameList,
         tls=true, withAuthProxy=false, basicAuthSecret=null,
         rules=null, requestTimeout='0s', extraLabels={}):
    local metadata(name) = { name: name, namespace: namespace, labels: { app: appName } + extraLabels };
    local route(name, listener, routeRules) = {
      apiVersion: 'gateway.networking.k8s.io/v1', kind: 'HTTPRoute',
      metadata: metadata(name),
      spec: {
        parentRefs: [{ group: 'gateway.networking.k8s.io', kind: 'Gateway',
                       name: $.gatewayName, namespace: $.gatewayNamespace, sectionName: listener }],
        hostnames: hostnameList,
        rules: routeRules,
      },
    };
    local target = [{ group: 'gateway.networking.k8s.io', kind: 'HTTPRoute', name: appName }];
    local appRules = if rules == null then [$.rule('/', serviceName, port)] else rules;
    {
      apiVersion: 'v1', kind: 'List',
      items: [route(appName, if tls then 'https' else 'http', [
        rule + { timeouts: { request: requestTimeout, backendRequest: requestTimeout } }
        for rule in appRules
      ])]
      + (if tls then [route(appName + '-http-redirect', 'http', [{
          matches: [{ path: { type: 'PathPrefix', value: '/' } }],
          filters: [{ type: 'RequestRedirect', requestRedirect: { scheme: 'https', port: 443, statusCode: 301 } }],
        }])] else [])
      + (if withAuthProxy then [
          // Public callback paths must never inherit the application auth policy.
          route(appName + '-auth-outpost', 'https', [$.rule(
            '/outpost.goauthentik.io', 'authentik-proxy-outpost-' + appName, 9000
          )]),
          {
            apiVersion: 'gateway.envoyproxy.io/v1alpha1', kind: 'SecurityPolicy',
            metadata: metadata(appName + '-proxy-auth'),
            spec: {
              targetRefs: target,
              extAuth: {
                failOpen: false,
                headersToExtAuth: ['cookie', 'x-forwarded-for', 'x-forwarded-proto', 'x-forwarded-host'],
                http: {
                  backendRefs: [{ group: '', kind: 'Service',
                                  name: 'authentik-proxy-outpost-' + appName, port: 9000, weight: 1 }],
                  // Authentik's Envoy endpoint returns login redirects itself.
                  path: '/outpost.goauthentik.io/auth/envoy',
                  headersToBackend: ['set-cookie', 'x-authentik-username', 'x-authentik-groups',
                                     'x-authentik-email', 'x-authentik-name', 'x-authentik-uid'],
                },
              },
            },
          },
        ] else [])
      + (if basicAuthSecret != null then [{
          apiVersion: 'gateway.envoyproxy.io/v1alpha1', kind: 'SecurityPolicy',
          metadata: metadata(appName + '-basic-auth'),
          spec: { targetRefs: target, basicAuth: { users: { group: '', kind: 'Secret', name: basicAuthSecret } } },
        }] else []),
    },
}
