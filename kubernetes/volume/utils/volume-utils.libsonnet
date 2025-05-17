local k = import 'common/lib/k.libsonnet';

{
  tk: (k.core.v1),

  generateStaticNfsPV(name,
                      nfsServer,
                      path,
                      storageClass,
                      accessModes=[],
                      annotations=null,
                      extraLabels={},
                      persistentVolumeReclaimPolicy='Retain'):
    assert std.member(name, '_') != true : "Invalid name: '" + name + "'. Underscore '_' is not allowed.";
    $.tk.persistentVolume.new(name)
    + (if annotations != null then $.tk.persistentVolume.metadata.withAnnotations(annotations) else {})
    + $.tk.persistentVolume.metadata.withLabels({ pvName: name, type: 'nfs' } + extraLabels)
    + $.tk.persistentVolume.spec.withCapacity({ storage: '1Gi' })
    + $.tk.persistentVolume.spec.withAccessModes(accessModes)
    + $.tk.persistentVolume.spec.withStorageClassName(storageClass)
    + $.tk.persistentVolume.spec.withPersistentVolumeReclaimPolicy(persistentVolumeReclaimPolicy)
    + $.tk.persistentVolume.spec.nfs.withPath(path)
    + $.tk.persistentVolume.spec.nfs.withServer(nfsServer)
    + $.tk.persistentVolume.spec.nfs.withReadOnly(false),

  generatePVC(name, namespace, storageClass, accessModes=['ReadWriteMany'], volumeName='', volumeMode='', storageSize='1Gi'):
    $.tk.persistentVolumeClaim.new(name)
    + $.tk.persistentVolumeClaim.metadata.withNamespace(namespace)
    + $.tk.persistentVolumeClaim.spec.withStorageClassName(storageClass)
    + $.tk.persistentVolumeClaim.spec.withAccessModes(accessModes)
    + $.tk.persistentVolumeClaim.spec.resources.withRequests({ storage: storageSize })
    + (if volumeName != '' then $.tk.persistentVolumeClaim.spec.withVolumeName(volumeName) else {})
    + (if volumeMode != '' then $.tk.persistentVolumeClaim.spec.withVolumeMode(volumeMode) else {}),

  getNfsServer(nfsName)::
    assert std.member(nfsName, '_') != true : "Invalid name: '" + nfsName + "'. Underscore '_' is not allowed.";
    std.strReplace(nfsName, '-', '_') + '_nfs.corp.aetherrootr.com',
}
