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
    apt-get install -y --no-install-recommends python3 python3-pip python3-wheel python3-apt
    python3 -m pip install --upgrade pip
    python3 -m pip install setuptools
    delete_pip_package_if_exists "ansible"
    delete_pip_package_if_exists "absible-base"

    #install ansible    
    python3 -m pip install ansible Jinja2
}

if [ ! -x /usr/bin/sudo ]; then
    apt-get update
    apt-get install -y --no-install_recommends sudo
fi

install_ansible
