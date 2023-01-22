#!/bin/bash

set -e -x

if  [[ $EUID -ne 0 ]]; then
  echo "This Script must be run as root"
  exit 1
fi

if [ ! -x /usr/bin/lsb_release ]; then
  apt-get update
  apt-get install -y --no-install-recommands lsb_release
fi

readonly UBUNTU_VERSION="$(lsb_release -sc)"
if [[ "$UBUNTU_VERSION" != xenial && "$UBUNTU_VERSION" != bionic && "$UBUNTU_VERSION" != focal ]]; then
  echo "This scipt only supports Ubuntu 16.04 or Ubuntu 18.04 or Ubuntu 20.04."
  exit 2
fi

ansible_version="2.13.7"
jinjia2_version="3.1.2"

function delete_pip_package_if_exists() {
  package_name=$1
  if python3 -m pip show $package_name; then
      python3 -m pip uninstall $package_name -y
  fi
}

function install_ansible {
  apt-get update

  # Delete unexpected ansible
  apt-get remove ansible -y
  # Here we use sshpass to manage our passwords,
  # although it is not a secure way to store our passwords,
  # but as a suite of tools for private use it is an acceptable security risk.
  # https://stackoverflow.com/questions/33469770/security-of-sshpass
  apt-get install -y --no-install-recommends python3 python3-pip python3-wheel python3-apt sshpass
  python3 -m pip install --upgrade pip
  python3 -m pip install setuptools
  delete_pip_package_if_exists "ansible"
  delete_pip_package_if_exists "absible-base"

  #install ansible    
  python3 -m pip install ansible Jinja2
}

function install_ansible_depend {
  ansible-galaxy install -r ansible/galaxy_requirements.yaml
}

if [ ! -x /usr/bin/sudo ]; then
  apt-get update
  apt-get install -y --no-install_recommends sudo
fi

if [ ! -x /usr/local/bin/ansible ]; then
  install_ansible
fi

if [ $(ansible --version | head -1 | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+") != "${ansible_version}" ]; then
  install_ansible
fi

install_ansible_depend
