local volumeUtils = import 'utils/volume-utils.libsonnet';

{
  volumeName:: 'data0',
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'List',
  items: std.prune([
    volumeUtils.generateStaticNfsPV(
      name=$.volumeName,
      nfsServer=volumeUtils.getNfsServer('data0'),
      path='/mnt/data0',
      accessModes=['ReadOnlyMany', 'ReadWriteMany'],
      storageClass='data0',
    ),
    volumeUtils.generatePVC(
      name=$.volumeName + '-pvc',
      namespace=$.namespace,
      storageClass='data0',
      volumeName=$.volumeName,
      accessModes=['ReadOnlyMany', 'ReadWriteMany'],
    ),
  ]),
}
