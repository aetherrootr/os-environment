[
  {
    labels: {
      bluetooth: 'exist',
      gpu: 'intel',
    },
    nodeNames: [
      'k8s-node-1',
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
