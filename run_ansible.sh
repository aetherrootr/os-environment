#!/bin/bash

set -e -x

bash install_ansible.sh

if [[ $# == 0 ]]; then
  # Use ',' to avoid 'localhost' being treated as a dir
  ansible-playbook -i 'localhost,' ansible/playbooks/dev_machine.yaml -v
else
  ansible-playbook -i 'localhost,' $* -v
fi
