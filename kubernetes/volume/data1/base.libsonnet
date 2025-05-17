local volumeUtils = import 'utils/volume-utils.libsonnet';

{
  volumeName:: 'data1',
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'List',
  items: std.prune([
    volumeUtils.generateStaticNfsPV(
      name=$.volumeName,
      nfsServer=volumeUtils.getNfsServer('data1'),
      path='/mnt/data1',
      accessModes=['ReadOnlyMany', 'ReadWriteMany'],
      storageClass='data1',
    ),
    volumeUtils.generatePVC(
      name=$.volumeName + '-pvc',
      namespace=$.namespace,
      storageClass='data1',
      volumeName=$.volumeName,
      accessModes=['ReadOnlyMany', 'ReadWriteMany'],
    ),
  ]),
}
