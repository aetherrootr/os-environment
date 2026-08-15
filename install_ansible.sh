#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
readonly ANSIBLE_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/os-environment-ansible"
readonly ANSIBLE_VENV="${ANSIBLE_HOME}/venv"
readonly USER_BIN_DIR="${HOME}/.local/bin"

run_privileged() {
  if [[ ${EUID} -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "sudo is required to install system packages"
    exit 1
  fi
}

install_with_apt() {
  run_privileged apt-get update
  run_privileged apt-get install -y --no-install-recommends \
    ca-certificates python3 python3-pip python3-venv sshpass
  PYTHON_BIN="$(command -v python3)"
}

install_with_dnf() {
  run_privileged dnf install -y \
    ca-certificates python3 python3-pip sshpass
  PYTHON_BIN="$(command -v python3)"
}

install_with_brew() {
  if [[ ${EUID} -eq 0 ]]; then
    echo "Homebrew installation must not run as root"
    exit 1
  fi

  brew install python@3.12
  if ! command -v sshpass >/dev/null 2>&1; then
    brew install sshpass
  fi
  PYTHON_BIN="$(brew --prefix python@3.12)/bin/python3.12"
}

if command -v apt-get >/dev/null 2>&1; then
  install_with_apt
elif command -v dnf >/dev/null 2>&1; then
  install_with_dnf
elif command -v brew >/dev/null 2>&1; then
  install_with_brew
else
  echo "Unsupported package manager: install apt-get, dnf, or Homebrew"
  exit 1
fi

readonly PYTHON_MINOR="$("${PYTHON_BIN}" -c 'import sys; print(sys.version_info.minor)')"
case "${PYTHON_MINOR}" in
  10)
    readonly ANSIBLE_VERSION="2.16.19"
    ;;
  11)
    readonly ANSIBLE_VERSION="2.18.18"
    ;;
  12|13|14)
    readonly ANSIBLE_VERSION="2.21.3"
    ;;
  *)
    echo "Unsupported Python version: $("${PYTHON_BIN}" --version 2>&1)"
    echo "Python 3.10 through 3.14 is required"
    exit 2
    ;;
esac

mkdir -p "${ANSIBLE_HOME}" "${USER_BIN_DIR}"

if [[ ! -x "${ANSIBLE_VENV}/bin/ansible" ]] || \
   ! "${ANSIBLE_VENV}/bin/python" -c \
     'import importlib.metadata, sys; sys.exit(importlib.metadata.version("ansible-core") != sys.argv[1])' \
     "${ANSIBLE_VERSION}"; then
  "${PYTHON_BIN}" -m venv --clear "${ANSIBLE_VENV}"
  "${ANSIBLE_VENV}/bin/pip" install --upgrade pip
  "${ANSIBLE_VENV}/bin/pip" install "ansible-core==${ANSIBLE_VERSION}"
fi

"${ANSIBLE_VENV}/bin/ansible-galaxy" collection install \
  --requirements-file "${SCRIPT_DIR}/ansible/galaxy_requirements.yaml"

for executable in ansible ansible-config ansible-galaxy ansible-inventory ansible-playbook; do
  ln -sfn "${ANSIBLE_VENV}/bin/${executable}" "${USER_BIN_DIR}/${executable}"
done

echo "Installed ansible-core ${ANSIBLE_VERSION} using $("${PYTHON_BIN}" --version 2>&1)"
echo "Ansible commands are available in ${USER_BIN_DIR}"
if [[ ":${PATH}:" != *":${USER_BIN_DIR}:"* ]]; then
  echo "Add ${USER_BIN_DIR} to PATH before running Ansible"
fi
