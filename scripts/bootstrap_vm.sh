#!/usr/bin/env bash
set -euo pipefail

# Превратить ВМ в control node и запускать всё локально на ВМ
sudo apt update -y
sudo apt install -y python3-venv python3-pip pipx git ansible-core

pipx ensurepath || true
pipx install ansible-lint || true
pipx install yamllint || true

ansible-galaxy collection install -r requirements.yml

cat > inventory.ini <<EOF
[wordpress]
localhost ansible_connection=local ansible_python_interpreter=/usr/bin/python3
EOF

echo "Bootstrap на ВМ завершён."
