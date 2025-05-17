local volumeUtils = import 'utils/volume-utils.libsonnet';

{
  volumeName:: 'service-data',
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'List',
  items: std.prune([
    volumeUtils.generateStaticNfsPV(
      name=$.volumeName,
      nfsServer=volumeUtils.getNfsServer('service-data'),
      path='/media/service_data',
      accessModes=['ReadOnlyMany', 'ReadWriteMany'],
      storageClass='service-data',
    ),
    volumeUtils.generatePVC(
      name=$.volumeName + '-pvc',
      namespace=$.namespace,
      storageClass='service-data',
      volumeName=$.volumeName,
      accessModes=['ReadOnlyMany', 'ReadWriteMany'],
    ),
  ]),
}
