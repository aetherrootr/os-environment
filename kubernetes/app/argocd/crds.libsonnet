// Official YAML is vendored by jb at the revision pinned in jsonnetfile.lock.json.
local parseYaml = std.native('parseYaml');

{
  crds: parseYaml(importstr 'github.com/argoproj/argo-cd/manifests/crds/application-crd.yaml')
        + parseYaml(importstr 'github.com/argoproj/argo-cd/manifests/crds/applicationset-crd.yaml')
        + parseYaml(importstr 'github.com/argoproj/argo-cd/manifests/crds/appproject-crd.yaml'),
}
