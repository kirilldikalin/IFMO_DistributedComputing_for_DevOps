SHELL := /bin/bash

bootstrap-local:
	./scripts/bootstrap_control.sh

bootstrap-vm:
	./scripts/bootstrap_vm.sh

lint:
	yamllint . || true
	ansible-lint playbooks/*.yml || true

lab1:
	ansible-playbook -i inventory.ini playbooks/lab1.yml

lab2:
	ansible-playbook -i inventory.ini playbooks/lab2.yml

lab3:
	ansible-playbook -i inventory.ini playbooks/lab3.yml

verify:
	ansible-playbook -i inventory.ini playbooks/verify.yml

verify-replication:
	ansible-playbook -i inventory.ini playbooks/verify_replication.yml

run-all: lint lab1 lab2 lab3 verify verify-replication

down:
	-ssh $$(awk '/wordpress/{print $$1}' inventory.ini | head -1) 'cd /opt/wordpress && docker compose down -v' || true
