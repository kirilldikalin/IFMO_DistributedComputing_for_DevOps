# ЛР2 — WordPress + кластер БД (репликация MariaDB Primary→Replica)

## Цель

Развить решение из ЛР1, заменить одиночную БД у WordPress на кластер с репликацией, обеспечить синхронизацию данных и сохранить идемпотентность/оформление по требованиям курса.

## Архитектура (что получилось)

* **Сервис** WordPress (контейнер `wp-app`)
* **База** MariaDB **Primary** (`wp-db-primary`) и **Replica** (`wp-db-replica`)
* общая Docker-сеть `wpnet`
* **Подключение WordPress** к **Primary**
* **Репликация**, бинарные логи с Primary → Replica
* **Секреты** вынесены в `group_vars/.../vault.yml` (Ansible Vault)
* **Идемпотентность**, все шаги выполнены модулями (без `command/shell/exec` в задачах плейбука)
* сохранён формат инвентори, stdout и пр. (для автопроверок следующей ЛР)


## Проверки работоспособности 

### 1) Контейнеры запущены

```bash
ssh -i ~/.ssh/itmo/itmo_key distributedadmin@51.250.25.239 \
  "sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'"
```

```
kirilldikalin@MacBook-Air-Kirill-2 IFMO_DistributedComputing_for_DevOps % ssh -i ~/.ssh/itmo/itmo_key distributedadmin@51.250.25.239 \
  "sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'"

NAMES           IMAGE                  STATUS
wp-db-replica   mariadb:10.11          Up 12 hours (healthy)
wp-app          wordpress:6.6-apache   Up 14 hours
wp-db-primary   mariadb:10.11          Up 14 hours (healthy)
wp-db           mariadb:10.11          Up 21 hours (healthy)
```

### 2) Оба контейнера в одной сети

```bash
ssh -i ~/.ssh/itmo/itmo_key distributedadmin@51.250.25.239 \
  "sudo docker network inspect wpnet | jq '.[0].Containers | keys'"
```

```
kirilldikalin@MacBook-Air-Kirill-2 IFMO_DistributedComputing_for_DevOps % ssh -i ~/.ssh/itmo/itmo_key distributedadmin@51.250.25.239 \
  "sudo docker network inspect wpnet | jq '.[0].Containers | keys'"

[
  "450dd4e9560c46d119480ced122b8207f64312b6ee39156d461c572ecd8a09bd",
  "61ccdc502e5e6238bcb4918a9e2218ab9ae7e0edc5d8ecfa8e74099926e64a4f",
  "9f2a8c6d235bda4f22413447c00c2369c56af997a15d33e48aa0449a1bb03fcb",
  "cf992f3dcefd0dd0ad2c6ab17ff41ece6fee1a7b47e9d7f86a9ee0d976da7c2b"
]
```

### 3) HTTP smoke WordPress (ожидается 302 на инсталлятор)

```bash
curl -I http://51.250.25.239:8080
```

```
kirilldikalin@MacBook-Air-Kirill-2 IFMO_DistributedComputing_for_DevOps % curl -I http://51.250.25.239:8080
HTTP/1.1 302 Found
Date: Thu, 18 Sep 2025 10:20:49 GMT
Server: Apache/2.4.62 (Debian)
X-Powered-By: PHP/8.2.25
Expires: Wed, 11 Jan 1984 05:00:00 GMT
Cache-Control: no-cache, must-revalidate, max-age=0
X-Redirect-By: WordPress
Location: http://51.250.25.239:8080/wp-admin/install.php
Content-Type: text/html; charset=UTF-8
```

### 4) Репликация MySQL — статус на Replica

> В роли порты проброшены так: **Primary** → `127.0.0.1:3306`, **Replica** → `127.0.0.1:3307` на target-хосте.

```bash
ansible carrier -b -m community.mysql.mysql_info -a \
 "login_host=127.0.0.1 login_port=3307 login_user=root login_password='{{ db_root_password }}' filter=slave_status" \
 --vault-password-file ~/.ansible/vault_pass.txt
```

```json
yc-wp-1 | SUCCESS => {
    "changed": false,
    "connector_name": "pymysql",
    "connector_version": "1.0.2",
    "server_engine": "MariaDB",
    "slave_status": {
        "wp-db-primary": {
            "3306": {
                "repl": {
                    "Connect_Retry": 60,
                    "Exec_Master_Log_Pos": 1950,
                    "Gtid_IO_Pos": "",
                    "Last_Errno": 0,
                    "Last_Error": "",
                    "Last_IO_Errno": 0,
                    "Last_IO_Error": "",
                    "Last_SQL_Errno": 0,
                    "Last_SQL_Error": "",
                    "Master_Log_File": "primary-bin.000002",
                    "Master_SSL_Allowed": "No",
                    "Master_SSL_CA_File": "",
                    "Master_SSL_CA_Path": "",
                    "Master_SSL_Cert": "",
                    "Master_SSL_Cipher": "",
                    "Master_SSL_Crl": "",
                    "Master_SSL_Crlpath": "",
                    "Master_SSL_Key": "",
                    "Master_SSL_Verify_Server_Cert": "No",
                    "Master_Server_Id": 1,
                    "Parallel_Mode": "optimistic",
                    "Read_Master_Log_Pos": 1950,
                    "Relay_Log_File": "relay-bin.000002",
                    "Relay_Log_Pos": 768,
                    "Relay_Log_Space": 1071,
                    "Relay_Master_Log_File": "primary-bin.000002",
                    "Replicate_Do_DB": "",
                    "Replicate_Do_Domain_Ids": "",
                    "Replicate_Do_Table": "",
                    "Replicate_Ignore_DB": "",
                    "Replicate_Ignore_Domain_Ids": "",
                    "Replicate_Ignore_Server_Ids": "",
                    "Replicate_Ignore_Table": "",
                    "Replicate_Rewrite_DB": "",
                    "Replicate_Wild_Do_Table": "",
                    "Replicate_Wild_Ignore_Table": "",
                    "SQL_Delay": 0,
                    "SQL_Remaining_Delay": null,
                    "Seconds_Behind_Master": 0,
                    "Skip_Counter": 0,
                    "Slave_DDL_Groups": 1,
                    "Slave_IO_Running": "Yes",
                    "Slave_IO_State": "Waiting for master to send event",
                    "Slave_Non_Transactional_Groups": 0,
                    "Slave_SQL_Running": "Yes",
                    "Slave_SQL_Running_State": "Slave has read all relay log; waiting for more updates",
                    "Slave_Transactional_Groups": 2,
                    "Until_Condition": "None",
                    "Until_Log_File": "",
                    "Until_Log_Pos": 0,
                    "Using_Gtid": "No"
                }
            }
        }
    }
}
```

### 6) Линтер и повторный прогон

```bash
ansible-lint
ansible-playbook playbook2.yml --vault-password-file ~/.ansible/vault_pass.txt
```

```
kirilldikalin@MacBook-Air-Kirill-2 IFMO_DistributedComputing_for_DevOps % ansible-lint

INFO     Identified /Users/kirilldikalin/work/ITMO/IFMO_DistributedComputing_for_DevOps as project root due .git directory.
INFO     Collection paths was patched to include extra directories /Users/kirilldikalin/.ansible/collections,/usr/share/ansible/collections,/opt/homebrew/opt/python@3.13/Frameworks/Python.framework/Versions/3.13/lib/python3.13/site-packages,/opt/homebrew/lib/python3.13/site-packages,/opt/homebrew/Cellar/ansible-lint/25.9.0/libexec/lib/python3.13/site-packages
INFO     Set ANSIBLE_LIBRARY=/Users/kirilldikalin/work/ITMO/IFMO_DistributedComputing_for_DevOps/.ansible/modules:/Users/kirilldikalin/.ansible/plugins/modules:/usr/share/ansible/plugins/modules
INFO     Set ANSIBLE_COLLECTIONS_PATH=/Users/kirilldikalin/work/ITMO/IFMO_DistributedComputing_for_DevOps/.ansible/collections:/Users/kirilldikalin/.ansible/collections:/usr/share/ansible/collections:/opt/homebrew/opt/python@3.13/Frameworks/Python.framework/Versions/3.13/lib/python3.13/site-packages:/opt/homebrew/lib/python3.13/site-packages:/opt/homebrew/Cellar/ansible-lint/25.9.0/libexec/lib/python3.13/site-packages
INFO     Set ANSIBLE_ROLES_PATH=/Users/kirilldikalin/work/ITMO/IFMO_DistributedComputing_for_DevOps/.ansible/roles:roles:/Users/kirilldikalin/work/ITMO/IFMO_DistributedComputing_for_DevOps/roles
INFO     Running ansible-galaxy collection install -v -r /Users/kirilldikalin/work/ITMO/IFMO_DistributedComputing_for_DevOps/requirements.yml
INFO     Loading ignores from .gitignore
INFO     Loading ignores from .gitignore
INFO     Executing syntax check on playbook verify_replication.yml (0.61s)
INFO     Executing syntax check on role roles/wordpress (0.68s)
INFO     Executing syntax check on role roles/db (0.72s)
INFO     Executing syntax check on playbook playbook1.yml (0.74s)
INFO     Executing syntax check on playbook playbook2.yml (0.74s)
INFO     Executing syntax check on role roles/db_cluster (0.75s)
INFO     Executing syntax check on role roles/docker (0.75s)
INFO     Executing syntax check on playbook playbook3.yml (0.78s)
INFO     Executing syntax check on playbook playbook4.yml (0.42s)
INFO     Executing syntax check on role roles/network (0.38s)
INFO     Executing syntax check on playbook verify.yml (0.43s)
WARNING  Ignored exception from ArgsRule.matchtasks while processing roles/db_cluster/tasks/main.yml (tasks): [Errno 63] File name too long: '{"ANSIBLE_MODULE_ARGS": {"name": "{{ db_repl_user }}", "host": "%", "password": "{{ db_repl_password }}", "priv": "*.*:REPLICATION SLAVE", "state": "present", "login_host": "{{ db_cluster_mysql_login_host_primary }}", "login_port": "{{ db_cluster_mysql_login_port_primary }}", "login_user": "{{ db_cluster_mysql_login_user }}", "login_password": "{{ db_root_password }}"}}'
WARNING  Ignored exception from JinjaRule.matchyaml while processing group_vars/carrier/vault.yml (vars): Decryption failed (no vault secrets were found that could decrypt).
WARNING  Ignored exception from VariableNamingRule.matchyaml while processing group_vars/carrier/vault.yml (vars): Decryption failed (no vault secrets were found that could decrypt).
WARNING  Ignored exception from ArgsRule.matchtasks while processing verify.yml (playbook): [Errno 63] File name too long: '{"ANSIBLE_MODULE_ARGS": {"login_host": "{{ mysql_login_host_primary }}", "login_port": "{{ mysql_login_port_primary }}", "login_user": "{{ mysql_login_user }}", "login_password": "{{ db_root_password }}", "query": ["CREATE DATABASE IF NOT EXISTS {{ wordpress_db_name }}", "CREATE TABLE IF NOT EXISTS {{ wordpress_db_name }}.replica_smoke (k VARCHAR(16) PRIMARY KEY, v VARCHAR(64) NOT NULL)", "REPLACE INTO {{ wordpress_db_name }}.replica_smoke (k, v) VALUES (\'smoke\', \'{{ smoke_value }}\')"]}}'

Passed: 0 failure(s), 0 warning(s) in 23 files processed of 30 encountered. Last profile that met the validation criteria was 'production'.
kirilldikalin@MacBook-Air-Kirill-2 IFMO_DistributedComputing_for_DevOps % 
kirilldikalin@MacBook-Air-Kirill-2 IFMO_DistributedComputing_for_DevOps % ansible-playbook playbook2.yml --vault-password-file ~/.ansible/vault_pass.txt

PLAY [Deploy WP with MariaDB primary-replica] *********************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************
ok: [yc-wp-1]

TASK [Target] *****************************************************************************************************************************************
ok: [yc-wp-1] => {
    "msg": "Target yc-wp-1 51.250.25.239"
}

TASK [docker : Find any Docker apt list files in sources.list.d (remote)] *****************************************************************************
ok: [yc-wp-1]

TASK [docker : Remove found Docker apt list files (remote)] *******************************************************************************************
changed: [yc-wp-1] => (item={'path': '/etc/apt/sources.list.d/docker.list', 'mode': '0644', 'isdir': False, 'ischr': False, 'isblk': False, 'isreg': True, 'isfifo': False, 'islnk': False, 'issock': False, 'uid': 0, 'gid': 0, 'size': 110, 'inode': 2184, 'dev': 64769, 'nlink': 1, 'atime': 1758190129.6017747, 'mtime': 1758190128.124767, 'ctime': 1758190128.124767, 'gr_name': 'root', 'pw_name': 'root', 'wusr': True, 'rusr': True, 'xusr': False, 'wgrp': False, 'rgrp': True, 'xgrp': False, 'woth': False, 'roth': True, 'xoth': False, 'isuid': False, 'isgid': False})

TASK [docker : Remove any Docker lines from /etc/apt/sources.list (remote)] ***************************************************************************
ok: [yc-wp-1]

TASK [docker : Ensure prerequisites packages are present (no cache refresh)] **************************************************************************
ok: [yc-wp-1]

TASK [docker : Ensure keyrings dir exists] ************************************************************************************************************
ok: [yc-wp-1]

TASK [docker : Download Docker GPG key (ascii)] *******************************************************************************************************
ok: [yc-wp-1]

TASK [docker : Convert Docker key to gpg (idempotent)] ************************************************************************************************
ok: [yc-wp-1]

TASK [docker : Add Docker apt repository (with signed-by)] ********************************************************************************************
changed: [yc-wp-1]

TASK [docker : Refresh APT cache] *********************************************************************************************************************
changed: [yc-wp-1]

TASK [docker : Install Docker CE] *********************************************************************************************************************
ok: [yc-wp-1]

TASK [docker : Enable and start Docker] ***************************************************************************************************************
ok: [yc-wp-1]

TASK [network : Create Docker network] ****************************************************************************************************************
ok: [yc-wp-1]

TASK [db_cluster : Ensure PyMySQL for MySQL modules] **************************************************************************************************
ok: [yc-wp-1]

TASK [db_cluster : Ensure primary volume] *************************************************************************************************************
ok: [yc-wp-1]

TASK [db_cluster : Ensure replica volume] *************************************************************************************************************
ok: [yc-wp-1]

TASK [db_cluster : Run MariaDB PRIMARY] ***************************************************************************************************************
ok: [yc-wp-1]

TASK [db_cluster : Wait PRIMARY healthy] **************************************************************************************************************
ok: [yc-wp-1]

TASK [db_cluster : Ensure replication user on PRIMARY] ************************************************************************************************
ok: [yc-wp-1]

TASK [db_cluster : Get MASTER STATUS via module] ******************************************************************************************************
ok: [yc-wp-1]

TASK [db_cluster : Set facts from MASTER STATUS] ******************************************************************************************************
ok: [yc-wp-1]

TASK [db_cluster : Run MariaDB REPLICA] ***************************************************************************************************************
ok: [yc-wp-1]

TASK [db_cluster : Wait REPLICA healthy] **************************************************************************************************************
ok: [yc-wp-1]

TASK [db_cluster : Stop replication on REPLICA if running] ********************************************************************************************
ok: [yc-wp-1]

TASK [db_cluster : Reset replication config on REPLICA] ***********************************************************************************************
changed: [yc-wp-1]

TASK [db_cluster : Configure replication on REPLICA (CHANGE MASTER TO)] *******************************************************************************
changed: [yc-wp-1]

TASK [db_cluster : Start replication on REPLICA] ******************************************************************************************************
changed: [yc-wp-1]

TASK [db_cluster : Ensure REPLICA read_only ON] *******************************************************************************************************
ok: [yc-wp-1]

TASK [db_cluster : Check REPLICA status is running] ***************************************************************************************************
ok: [yc-wp-1]

TASK [db_cluster : Assert IO and SQL threads are running] *********************************************************************************************
ok: [yc-wp-1] => {
    "changed": false,
    "msg": "All assertions passed"
}

TASK [Ensure WP is deployed after DB cluster] *********************************************************************************************************
included: wordpress for yc-wp-1

TASK [wordpress : Ensure WP volume] *******************************************************************************************************************
ok: [yc-wp-1]

TASK [wordpress : Run WordPress container] ************************************************************************************************************
ok: [yc-wp-1]

TASK [HTTP check WordPress] ***************************************************************************************************************************
ok: [yc-wp-1]

PLAY RECAP ********************************************************************************************************************************************
yc-wp-1                    : ok=35   changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```


## Что учел из ваших комментариев

* Заменены все `command/shell/exec` в задачах на штатные **идемпотентные** модули
* Сохранён формат инвентаря и формат вывода плейбука (для автотестов ЛР4, но разберу когда дойду)
* Секреты — в `vault.yml`, пароль — во внешнем файле
* Для `Docker apt repo` реализована корректная очистка старых источников и единый `apt_repository` с `signed-by`, чтобы не ловить конфликт `Signed-By`

