local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';

{
importFromHelmChart(projectPath,
                    name,
                    chart,
                    conf):
    tanka.helm.new(projectPath).template(
        name,
        chart,
        conf,
    ),
}
