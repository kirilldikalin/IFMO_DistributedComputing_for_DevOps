# Лабораторная 2 WordPress и миграция на кластер MySQL GTID

## Состав
- playbook1.yml поднимает single DB + WordPress
- playbook2.yml поднимает кластер MySQL 5.7 GTID master-replica и делает миграцию из single, если он есть
- роли db, db_cluster, wordpress
- конфиги MySQL рендерятся из переменных и монтируются внутрь контейнеров

## Быстрый запуск
```bash
ansible-playbook -i inventory.yml playbook1.yml
# открой http://<хост>:8080/wp-admin/ и пройди установку при первом запуске
ansible-playbook -i inventory.yml playbook2.yml
````

## Миграция из single DB

При наличии контейнера legacy `wp-db` выполняется дамп и импорт в мастер
Импорт происходит только если таблица wp_options отсутствует

## Проверки

Контейнеры и порты

```bash
ansible -i inventory.yml all -m shell -a 'docker ps --no-trunc | egrep "mysql_master|mysql_replica|wordpress" || true'
```

Мастер отвечает, версия

```bash
ansible -i inventory.yml all -m shell -a 'docker exec -e MYSQL_PWD={{ mysql_root_password }} mysql_master mysql -uroot -N -e "SELECT VERSION()"'
```

```
yc-wp-1 | CHANGED | rc=0 >>
5.7.44-log
```

Статус репликации

```bash
ansible -i inventory.yml all -m shell -a 'docker exec -e MYSQL_PWD={{ mysql_root_password }} mysql_replica mysql -uroot -e "SHOW SLAVE STATUS\\G" | egrep -i "Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master" || true'
```

```
yc-wp-1 | CHANGED | rc=0 >>
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
        Seconds_Behind_Master: 0
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
```      

Смоук репликации

```bash
ansible -i inventory.yml all -m shell -a 'docker exec -e MYSQL_PWD={{ mysql_root_password }} mysql_master  mysql -uroot -e "CREATE DATABASE IF NOT EXISTS {{ wp_db_name }}; CREATE TABLE IF NOT EXISTS {{ wp_db_name }}.replica_smoke (k VARCHAR(16) PRIMARY KEY, v VARCHAR(64)); REPLACE INTO {{ wp_db_name }}.replica_smoke VALUES (\"smoke\",\"ok-$(date +%s)\")"'
ansible -i inventory.yml all -m shell -a 'docker exec -e MYSQL_PWD={{ mysql_root_password }} mysql_replica mysql -uroot -N -e "SELECT v FROM {{ wp_db_name }}.replica_smoke WHERE k=\"smoke\""'
```

```
yc-wp-1 | CHANGED | rc=0 >>
yc-wp-1 | CHANGED | rc=0 >>
ok-1759185608
```

Конфиги примонтированы

```bash
ansible -i inventory.yml all -m shell -a 'docker exec mysql_master  sh -lc "ls -l /etc/mysql/conf.d/config.cnf"'
ansible -i inventory.yml all -m shell -a 'docker exec mysql_replica sh -lc "ls -l /etc/mysql/conf.d/config.cnf"'
```

```
yc-wp-1 | CHANGED | rc=0 >>
-rw-r--r-- 1 root root 187 Sep 29 21:53 /etc/mysql/conf.d/config.cnf
yc-wp-1 | CHANGED | rc=0 >>
-rw-r--r-- 0 root root 169 Sep 29 22:11 /etc/mysql/conf.d/config.cnf
```

Редирект админки

```bash
ansible -i inventory.yml all -m shell -a 'WP_PORT=$(docker port wordpress 80/tcp 2>/dev/null | sed -E "s/.*:([0-9]+)$/\\1/"); curl -s -I "http://127.0.0.1:$WP_PORT/wp-admin/" | egrep -i "^HTTP|^Location"'
```

```
yc-wp-1 | CHANGED | rc=0 >>
HTTP/1.1 302 Found
Location: http://127.0.0.1:8080/wp-admin/install.php
```

Проверка wp_options на мастере

```bash
ansible -i inventory.yml all -m shell -a 'docker exec -e MYSQL_PWD={{ mysql_root_password }} mysql_master mysql -uroot -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='\''{{ wp_db_name }}'\'' AND table_name='\''wp_options'\''"'
```

```
yc-wp-1 | CHANGED | rc=0 >>
0
```

Идемпотентность

```bash
ansible-playbook -i inventory.yml playbook2.yml --diff
```

```
PLAY RECAP ********************************************************************************************************************************************
yc-wp-1                    : ok=31   changed=6    unreachable=0    failed=0    skipped=6    rescued=0    ignored=0   
```

Безопасность

```bash
find roles -type f ! -name '*.bak*' -print0 | xargs -0 grep -nE 'mysqladmin ping.*-p\{\{ *(db_root_password|mysql_root_password) *\}\}' || echo "OK, утечек пароля нет"
```

```
OK, утечек пароля нет
```

Нет небезопасных healthcheck и утечек пароля

```bash
find roles -type f ! -name '*.bak*' -print0 | xargs -0 grep -nE '^[[:space:]]*healthcheck:' || echo "OK, healthcheck в активных задачах нет"
find roles -type f ! -name '*.bak*' -print0 | xargs -0 grep -nE 'mysqladmin ping.*-p\{\{ *(db_root_password|mysql_root_password) *\}\}' || echo "OK, утечек пароля нет"
```

```
OK, healthcheck в активных задачах нет
OK, утечек пароля нет
```

Нет дублей старых переменных контейнеров

```bash
grep -R --line-number -E '\{\{\s*(db_primary_container|db_replica_container)\s*\}\}' . | grep -v '\.bak' || echo "OK, нет старых ссылок"
```

```
OK, нет старых ссылок
```