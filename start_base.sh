#!/bin/sh

network=roachnet
image=cockroachdb/cockroach:v25.1.2
listen_port=26357
haproxy_cfg="haproxy.cfg"
num_nodes=$1

docker pull $image
docker network create $network

# Переменная для хранения списка нод в кластере
join_nodes=""

# Генерируем конфиг HAProxy
cat <<EOF > $haproxy_cfg
global
    log stdout local0
    maxconn 4096

defaults
    log global
    mode tcp
    timeout connect 5s
    timeout client 50s
    timeout server 50s

frontend cockroachdb_front
    bind *:26257
    default_backend cockroachdb_back

backend cockroachdb_back
    balance roundrobin
EOF

for ((i=1; i<=num_nodes; i++)); do
    node_name="roach$i"
    sql_port=$((26256 + i))

    # Добавляем сервер в конфиг HAProxy
    echo "    server $node_name $node_name:$sql_port check" >> $haproxy_cfg

    # Создаем Docker-том для ноды
    if [[ -n "$join_nodes" ]]; then
        join_nodes="$join_nodes,$node_name:$listen_port"
    else
        join_nodes="$node_name:$listen_port"
    fi
    docker volume create $node_name
done

echo " " >> $haproxy_cfg

# Запуск нод CockroachDB
for ((i=1; i<=num_nodes; i++)); do
    node_name="roach$i"
    node_hostname="roach$i"
    sql_port=$((26256 + i))
    http_port=$((8079 + i))

    docker run -d \
    --name=$node_name \
    --hostname=$node_hostname \
    --net=$network \
    -p $sql_port:$sql_port \
    -p $http_port:$http_port \
    -v "$node_name:/cockroach/cockroach-data" \
    $image start \
      --advertise-addr=$node_name:$listen_port \
      --http-addr=$node_name:$http_port \
      --listen-addr=$node_name:$listen_port \
      --sql-addr=$node_name:$sql_port \
      --insecure \
      --join=$join_nodes
done

docker exec -it roach1 ./cockroach --host=roach1:$listen_port init --insecure

# Пересобираем HAProxy с обновленным конфигом
docker build -t my-haproxy .
docker run -d --name haproxy --net=roachnet -v $(pwd)/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg my-haproxy