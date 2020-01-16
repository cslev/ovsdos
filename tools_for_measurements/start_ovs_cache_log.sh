#!/bin/bash

influx_server="localhost:8086"


while true
do
  maskinfo=$(ovs-dpctl show| grep -v port|grep -v system|sed "s/\t//g")
#maskinfo:
#lookups: hit:10362274947 missed:199883 lost:95531 flows: 3 masks: hit:94965047107 total:2 hit/pkt:9.16

  lookuphit=$(echo $maskinfo|awk '{print $2}'|cut -d ':' -f 2)
  lookupmissed=$(echo $maskinfo|awk '{print $3}'|cut -d ':' -f 2)
  lookuplost=$(echo $maskinfo|awk '{print $4}'|cut -d ':' -f 2)

  flows=$(echo $maskinfo|grep flows|awk '{print $6}')

  maskshit=$(echo $maskinfo|awk '{print $8}'|cut -d ':' -f 2)
  maskstotal=$(echo $maskinfo|awk '{print $9}'|cut -d ':' -f 2)
  maskshitperpacket=$(echo $maskinfo|grep masks|awk '{print $10}'|cut -d ':' -f 2)

  curl -i -XPOST "http://${influx_server}/write?db=ovs_cache" \
  --data-binary "data,host=localhost lookuphit=$(echo $lookuphit),lookupmissed=$(echo $lookupmissed),lookuplost=$(echo $lookuplost),flows=$(echo $flows),maskshit=$(echo $maskshit),maskstotal=$(echo $maskstotal),maskshitperpacket=$(echo $maskshitperpacket)"

  sleep 1s
done
