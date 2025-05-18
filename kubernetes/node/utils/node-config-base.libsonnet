{
  local generateNodeConfig(nodeGroup) = [
    {
      apiVersion: 'v1',
      kind: 'Node',
      metadata: {
        name: nodeName,
        [if std.objectHas(nodeGroup, 'labels') then 'labels']:
          nodeGroup.labels,
      },
      spec: {
        [if std.objectHas(nodeGroup, 'taints') then 'taints']:
          nodeGroup.taints,
      },
    }
    for nodeName in nodeGroup.nodeNames
  ],

  nodeGroupList:: error ('nodeGroupList is required'),

  apiVersion: 'app/v1',
  kind: 'List',
  items: std.flattenArrays(std.prune([
    generateNodeConfig(nodeGroup)
    for nodeGroup in $.nodeGroupList
  ])),
}
