#!/usr/bin/env bash
set -euo pipefail
ansible-playbook -i inventory.ini playbooks/lab1.yml
ansible-playbook -i inventory.ini playbooks/lab2.yml
ansible-playbook -i inventory.ini playbooks/lab3.yml
ansible-playbook -i inventory.ini playbooks/verify.yml
ansible-playbook -i inventory.ini playbooks/verify_replication.yml
