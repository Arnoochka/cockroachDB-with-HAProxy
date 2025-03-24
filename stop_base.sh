docker ps -a --filter "name=roach" -q | xargs -r docker stop
docker ps -a --filter "name=roach" -q | xargs -r docker rm
docker volume ls --filter "name=roach" -q | xargs -r docker volume rm

docker stop haproxy
docker rm haproxy

docker network rm roachnet