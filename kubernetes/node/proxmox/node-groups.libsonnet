[
  {
    labels: {
      bluetooth: 'exist',
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
]
