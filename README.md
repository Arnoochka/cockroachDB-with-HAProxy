### CockoachDB с балансировщиком HAProxy

Для развертывания кластера необходимо иметь **docker** и **docker-compose**. Чтобы развернуть кластер, в текущей директории выполнить команду:

```bash
bash start_base.sh <num nodes>
```

Будут создан мост между контейнерами с именем `roachnet`, ноды с именами `roach1`...`roach<num nodes>`, а также контейнер `haproxy`. 

Для проверки того, что все ноды подключены к мосту необходимо выполнить команду:

```bash
docker network inspect roachnet
```

Проверить состояния всех узлов в кластере:

```bash
docker exec -it roach1 cockroach node status --insecure --host=roach1:26257
```

Дополнительные команды для работы с кластером можно найти в `commands.md`

**Важно:** Многие команды, которые вы встретите можно легко адаптировать под использование с этим кластером. Для этого необходимо добавить в начало `docker exec -it roach{i}`, где `roach{i}` и немного изменить порты и хосты. Пример:

Было:

```bash
cockroach workload init ycsb --splits=50 'postgresql://root@localhost:26000?sslmode=disable'

```

Стало:

```bash
docker exec -it roach1 cockroach workload init ycsb --splits=50 'postgresql://root@roach1:26257?sslmode=disable'
```