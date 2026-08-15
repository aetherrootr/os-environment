#!/bin/bash

set -euo pipefail

bash install_ansible.sh
export PATH="${HOME}/.local/bin:${PATH}"

if [[ $# == 0 ]]; then
  # Use ',' to avoid 'localhost' being treated as a dir
  ansible-playbook -i 'localhost,' ansible/playbooks/dev_machine.yaml -v
else
  ansible-playbook -i 'localhost,' "$@" -v
fi
