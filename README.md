
Работа через Makefile

```bash
make bootstrap-local
make lint
make lab1
make lab2
make verify
make verify-replication
```

Править переменные `inventory.ini` при необходимости. Все переменные в `group_vars/all.yml`

Входные точки
- `playbooks/lab1.yml` деплой WordPress и master БД
- `playbooks/lab2.yml` запуск slave и настройка репликации
- `playbooks/verify.yml` smoke по HTTP и состоянию compose
- `playbooks/verify_replication.yml` smoke записи и чтения со slave

Проверки всего и вся:

```bash
dikalinkirill@compute-vm-distributed-computing-test:~$ cd /opt/wordpress
dikalinkirill@compute-vm-distributed-computing-test:/opt/wordpress$ ROOT_PASS=$(python3 -c "import yaml;print(yaml.safe_load(open('/opt/wordpress/group_vars/all.yml'))['mysql_root_password'])")
dikalinkirill@compute-vm-distributed-computing-test:/opt/wordpress$ sudo docker compose exec -T db_slave \
  mysql -uroot -p"${ROOT_PASS}" \
  -e "SHOW SLAVE STATUS\G"
WARN[0000] /opt/wordpress/docker-compose.yml: the attribute `version` is obsolete, it will be ignored, please remove it to avoid potential confusion 
mysql: [Warning] Using a password on the command line interface can be insecure.
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: db_master
                  Master_User: repl_user
                  Master_Port: 3306
                Connect_Retry: 5
              Master_Log_File: mysql-bin.000003
          Read_Master_Log_Pos: 1106
               Relay_Log_File: relay-bin.000002
                Relay_Log_Pos: 809
        Relay_Master_Log_File: mysql-bin.000003
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: 
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 1106
              Relay_Log_Space: 1010
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 1
                  Master_UUID: c26da6d4-9fa0-11f0-9a98-7a63926f9f42
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 
            Executed_Gtid_Set: 
                Auto_Position: 0
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 
```

```bash
dikalinkirill@compute-vm-distributed-computing-test:/opt/wordpress$ sudo docker compose exec -T db_master \
  mysql -uroot -p"${ROOT_PASS}" \
  -e "CREATE TABLE IF NOT EXISTS wordpress.test_table (id INT PRIMARY KEY, ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
      INSERT INTO wordpress.test_table(id) VALUES (1)
      ON DUPLICATE KEY UPDATE ts = NOW();"
WARN[0000] /opt/wordpress/docker-compose.yml: the attribute `version` is obsolete, it will be ignored, please remove it to avoid potential confusion 
mysql: [Warning] Using a password on the command line interface can be insecure.


dikalinkirill@compute-vm-distributed-computing-test:/opt/wordpress$ sudo docker compose exec -T db_slave \
  mysql -uroot -p"${ROOT_PASS}" \
  -e "SELECT * FROM wordpress.test_table WHERE id = 1;"
WARN[0000] /opt/wordpress/docker-compose.yml: the attribute `version` is obsolete, it will be ignored, please remove it to avoid potential confusion 
mysql: [Warning] Using a password on the command line interface can be insecure.
id      ts
1       2025-10-02 15:15:35
```