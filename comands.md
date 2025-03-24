### Команды для работы с кластером

**Замечание:** Все выполняется через `roach1`, однако при желании можно делать через любую живую ноду

**Загрузка схемы и данных yscb:**

```bash
docker exec -it roach1 cockroach workload init ycsb --splits=50 'postgresql://root@roach1:26257?sslmode=disable'
```

Эта рабочая нагрузка создает новую базу данных ycsb и таблицу пользовательской таблицы в этой базе данных и вставляет данные в таблицу. Флаг `--splits` указывает рабочей нагрузке на ручное разделение диапазонов не менее 50 раз.

Если по каким-то прицинам вылезла ошибка, то, возможно, это связано с тем. что какой-то из импортов просто завис или проблема с самой таблицей. Решить это можно следующими командами ():

Проверить статус импортных заданий:

```bash
docker exec -it roach1 cockroach sql --insecure --host=roach1:26257 -e "SHOW JOBS;"
```

Отменить зависший импорт:

```bash
docker exec -it roach1 cockroach sql --insecure --host=roach1:26257 -e "CANCEL JOB <JOB_ID>;"
```

Удалить зависшую таблицу:

```bash
docker exec -it roach1 cockroach sql --insecure --host=roach1:26257 -e "DROP TABLE IF EXISTS ycsb.public.usertable CASCADE;"
```

Проверить, удалилась ли таблица:

```bash
docker exec -it roach1 cockroach sql --insecure --host=roach1:26257 -e "SHOW TABLES FROM ycsb;"
```

**Выполнение рабочей нагрузки yscb:**

```bash
docker exec -it roach1 cockroach workload run ycsb --duration=5m --concurrency=5 --max-rate=500 --tolerate-errors 'postgresql://root@haproxy:26257?sslmode=disable'
```

Команда инициирует 5 одновременных клиентских рабочих нагрузок в течение 5 минут, но ограничивает общую нагрузку до 500 операций в секунду. Статистика по каждой операции выводится в стандартный вывод каждую секунду. 


**Установка времени, по истечении которого, узел считается мертвым:**

```bash
docker exec -it roach1 cockroach sql --insecure --host=haproxy:26257 --execute="SET CLUSTER SETTING server.time_until_store_dead = '30s';"
```

Если узел не отвечает в течение 30 секунд, то cockroachDB начинает репликацию данных

**Установка степени репликации:**

```bash
docker exec -it roach1 cockroach sql --execute="ALTER RANGE default CONFIGURE ZONE USING num_replicas=5;" --insecure --host=roach1:26257
```

Степень репликации установлена на 5
