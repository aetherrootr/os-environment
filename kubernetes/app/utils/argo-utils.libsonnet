{
  generateApplication(namespace,
                      appName,
                      projectName,
                      source,
                      destination,
                      syncPolicy=null,
                      ignoreDifferences=[]): {
    apiVersion: 'argoproj.io/v1alpha1',
    kind: 'Application',
    metadata: {
      name: appName,
      namespace: namespace,
    },
    spec: {
            project: projectName,
            source: source,
            destination: destination,
          } + (if syncPolicy != null then { syncPolicy: syncPolicy } else {})
          + (if std.length(ignoreDifferences) > 0 then { ignoreDifferences: ignoreDifferences } else {}),
  },

  generateAppProject(namespace,
                     projectName,
                     sourceRepos,
                     destinations,
                     clusterResourceWhitelist,
                     namespaceResourceWhitelist,
                     namespaceResourceBlacklist=null,
                     description='',
                     annotations={}): {
    apiVersion: 'argoproj.io/v1alpha1',
    kind: 'AppProject',
    metadata: {
      name: projectName,
      namespace: namespace,
    } + (if std.length(annotations) > 0 then { annotations: annotations } else {}),
    spec: {
      description: description,
      sourceRepos: sourceRepos,
      destinations: destinations,
      clusterResourceWhitelist: clusterResourceWhitelist,
      namespaceResourceWhitelist: namespaceResourceWhitelist,
    } + (if namespaceResourceBlacklist != null then { namespaceResourceBlacklist: namespaceResourceBlacklist } else {}),
  },
}
