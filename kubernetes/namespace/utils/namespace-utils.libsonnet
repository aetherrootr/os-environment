local k = import "common/lib/k.libsonnet";

{
  tk: (k.core.v1),

  generateNamespace(name, extraLabels={}):
    $.tk.namespace.new(name)
    + $.tk.namespace.metadata.withLabels(extraLabels),
}
