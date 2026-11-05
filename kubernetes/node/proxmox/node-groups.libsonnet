[
  {
    labels: {
      bluetooth: 'exist',
      gpu: 'intel',
      'service-data-mount': 'true',
      // Eligible for NFS-backed databases; this VM resides on the storage host.
      service_data_database: 'true',
    },
    nodeNames: [
      'k8s-node-1',
    ],
  },
  {
    labels: {
      bluetooth: 'none',
      gpu: 'none',
    },
    nodeNames: [
      'k8s-node-2',
    ],
  },
  {
    labels: {
      bluetooth: 'none',
      'node-role.kubernetes.io/control-plane': '',
    },
    nodeNames: [
      'k8s-master',
    ],
    taints: [
      {
        key: 'node-role.kubernetes.io/control-plane',
        effect: 'NoSchedule',
      },
    ],
  },
  {
    labels: {
      'reserved-app': 'qbittorrent',
    },
    nodeNames: [
      'vm-server-1',
    ],
    taints: [
      {
        key: 'reserved-app',
        value: 'qbittorrent',
        effect: 'NoSchedule',
      },
    ],
  }
]
