#!/bin/bash

influx_server="152.66.245.170:8086"



while true
do
loadavg=$(cat /proc/loadavg)

  loadavg_1m=$(echo $loadavg|awk '{print $1}')
  loadavg_5m=$(echo $loadavg|awk '{print $2}')
  loadavg_15m=$(echo $loadavg|awk '{print $3}')

  loadavg_current_tasknum=$(echo $loadavg| awk '{print $4}')
  loadavg_most_recent_pid=$(echo $loadavg| awk '{print $5}')


  curl -i -XPOST "http://${influx_server}/write?db=cpustat" \
  --data-binary "load,desc=loadavg value=$(echo $loadavg_1m)"

  sleep 1s
done



