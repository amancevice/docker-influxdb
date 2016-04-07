#!/bin/bash

version=0.12.0

echo "Creating docker bridge network \"influxdb\""
docker network create --driver bridge influxdb

echo
echo "Starting node \"ix0\""
docker run --detach --name ix0 \
    --env INFLUX___META___BIND_ADDRESS='"ix0:8088"' \
    --env INFLUX___META___HTTP_BIND_ADDRESS='"ix0:8091"' \
    --env INFLUX___HTTP___BIND_ADDRESS='"ix0:8086"' \
    --hostname ix0 \
    --net influxdb \
    amancevice/influxdb:$version

echo
echo "CREATE DATABASE mydb"
echo "curl -G http://ix0:8086/query --data-urlencode \"q=CREATE DATABASE mydb\""
docker run --rm --net influxdb --entrypoint curl \
    amancevice/influxdb:$version -G http://ix0:8086/query --data-urlencode "q=CREATE DATABASE mydb" &> /dev/null

echo
echo "SHOW DATABASES:"
docker run --rm -it --net influxdb --entrypoint /usr/bin/influx \
    amancevice/influxdb:$version -host ix0 -execute "SHOW DATABASES"

echo
echo "WRITE POINT"
echo "curl -i -XPOST 'http://ix0:8086/write?db=mydb' --data-binary 'cpu_load_short,host=server01,region=us-west value=0.64 1434055562000000000'"
docker run --rm --net influxdb --entrypoint curl \
    amancevice/influxdb:$version -i -XPOST 'http://ix0:8086/write?db=mydb' --data-binary 'cpu_load_short,host=server01,region=us-west value=0.64 1434055562000000000' &> /dev/null

echo
echo "SELECT * FROM cpu_load_short;"
docker run --rm -it --net influxdb --entrypoint /usr/bin/influx \
    amancevice/influxdb:$version -host ix0 -database mydb -precision rfc3339 -execute "SELECT * FROM cpu_load_short;"


# Cleanup
echo "Removed node \"$(docker rm -f ix0)\""
docker network rm influxdb
echo "Removed network \"influxdb\""
