#!/usr/bin/env bash
set -euo pipefail

# Установка ansible и зависимостей на локальной машине (control node)
if command -v apt >/dev/null 2>&1; then
  sudo apt update -y
  sudo apt install -y python3-venv python3-pip pipx git
elif command -v brew >/dev/null 2>&1; then
  brew update
  brew install pipx ansible yamllint
else
  echo "Установи вручную pipx и ansible"
fi

pipx ensurepath || true
if ! command -v ansible >/dev/null 2>&1; then
  pipx install --include-deps ansible-core
fi
pipx install ansible-lint || true
pipx install yamllint || true

ansible-galaxy collection install -r requirements.yml
echo "Bootstrap локально завершён."
