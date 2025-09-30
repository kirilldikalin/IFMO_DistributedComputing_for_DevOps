# Отчёт по правкам

Пункт 1. Данные терялись при переходе на кластер  
Что сделано. Во второй плейбук добавлена миграция из single DB, дамп через docker exec, импорт в мастер, затем старт WP. Импорт идёт только если wp_options отсутствует  
Где смотреть. roles/db_cluster/tasks/main.yml, блоки:
- "Check legacy DB container presence"
- "Dump legacy DB to host file"
- "Import dump into MASTER (only if empty)"
- "Start WordPress after migration"

Пункт 2. Конфиги primary.cnf и replica.cnf не использовались  
Что сделано. Конфиги рендерятся и монтируются в контейнеры MySQL  
Где смотреть. templates master.cnf.j2 и replica.cnf.j2, монтирование:
- roles/db_cluster/tasks/main.yml строки с "/etc/mysql/conf.d/config.cnf:ro"

Пункт 3. Дублирующиеся переменные имён контейнеров  
Что сделано. Оставлены единые имена db_cluster_primary_container_name и db_cluster_replica_container_name. Все упоминания db_primary_container и db_replica_container убраны  
Где смотреть. group_vars/carrier/main.yml и роли, grep проверка ниже

Пункт 4. Захардкоженные настройки MariaDB и неиспользуемые переменные  
Что сделано. Переход на mysql:5.7 с GTID. Настройки берутся из списков mysql_master_cnf и mysql_replica_cnf, шаблоны j2 их используют  
Где смотреть. group_vars/carrier/main.yml и roles/db_cluster/templates/*.j2

Пункт 5. Небезопасный healthcheck с mysqladmin -p{{ password }}  
Что сделано. Убраны пароли из команд. Healthcheck в задачах не используется. Готовность БД через ansible.builtin.wait_for на порту. В проверках пароль передаётся через переменную окружения MYSQL_PWD  
Где смотреть. roles/db_cluster/tasks/main.yml, блоки Wait MASTER tcp ready и Wait REPLICA tcp ready
