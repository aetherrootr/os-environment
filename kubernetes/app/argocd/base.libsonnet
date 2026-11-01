local applicationController = import 'application-controller.libsonnet';
local applicationsetController = import 'applicationset-controller.libsonnet';
local config = import 'config.libsonnet';
local crds = import 'crds.libsonnet';
local dexServer = import 'dex-server.libsonnet';
local networkPolicy = import 'network-policy.libsonnet';
local notificationsController = import 'notifications-controller.libsonnet';
local notifications = import 'notifications.libsonnet';
local redis = import 'redis.libsonnet';
local repoServer = import 'repo-server.libsonnet';
local server = import 'server.libsonnet';
local tanka = import 'plugins/tanka/base.libsonnet';
local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error 'namespace is required',
  image:: 'quay.io/argoproj/argocd:v3.5.6',
  hostname:: k8sUtils.getServiceHostname(serviceName='argocd'),
  notificationEmailUsername:: error 'notificationEmailUsername is required',

  local configResources = config {
    namespace: $.namespace,
    hostname: $.hostname,
  },

  local tankaResources = tanka { namespace: $.namespace },

  local networkPolicyResources = networkPolicy {
    namespace: $.namespace,
  },

  local applicationsetControllerResources = applicationsetController {
    namespace: $.namespace,
    image: $.image,
  },

  local dexServerResources = dexServer {
    namespace: $.namespace,
    image: $.image,
  },

  local notificationsControllerResources = notificationsController {
    namespace: $.namespace,
    image: $.image,
  },

  local notificationResources = notifications {
    namespace: $.namespace,
    hostname: $.hostname,
    emailUsername: $.notificationEmailUsername,
  },

  local redisResources = redis {
    namespace: $.namespace,
  },

  local repoServerResources = repoServer {
    namespace: $.namespace,
    image: $.image,
  },

  local serverResources = server {
    namespace: $.namespace,
    image: $.image,
    hostname: $.hostname,
  },

  local applicationControllerResources = applicationController {
    namespace: $.namespace,
    image: $.image,
  },

  apiVersion: 'v1',
  kind: 'List',
  // Preserve emptyDir: {} volumes, ingress: [{}] rules and empty OpenAPI schemas.
  // Recursive std.prune would remove these meaningful empty objects.
  items: crds.crds
         + configResources.config
         + tankaResources.config
         + networkPolicyResources.networkPolicy
         + applicationsetControllerResources.applicationsetController
         + dexServerResources.dexServer
         + notificationsControllerResources.notificationsController
         + notificationResources.notifications
         + redisResources.redis
         + repoServerResources.repoServer
         + serverResources.server
         + applicationControllerResources.applicationController,
}
