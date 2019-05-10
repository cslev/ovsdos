#!/bin/bash

# THIS PROGRAM WILL ITERATE THROUGH ALL POSSIBLE PORT NUMBERS RANGING FROM 1 to 65535
# AND ADD EACH PORT NUMBER AS A FLOW RULE INTO THE OVS FLOW TABLE
# THEN, IT LAUNCHES A DIAGONAL ATTACK FOR 15 SECONDS AND SEE HOW THE OVS MEGAFLOW CACHE
# ENTRIES/MASKS CHANGE
# INTENDED CSV OUTPUT: port no., #megaflow masks

source colorized_output.sh

echo "port no, megaflow masks" > diagonal_measurement.csv
for PORT in {1..65535}
do
  c_print "blue" "[MAIN THREAD]\t Add flow rule with the following port number: ${PORT}    "
  ./add_custom_port_filter.sh ovsbr $PORT
  sleep 1
  c_print "green" "[DONE]"

  c_print "blue" "[MAIN THREAD]\t Launching the attack..."
  sudo ip netns exec ns1 python send_diagonal_attack_dstport.py & 2>&1
  PID=$(cat diagonal_attack.pid)

  c_print "blue" "[MAIN THREAD]\t Waiting megaflow cache to be populated (15 sec)" 0
  for i in {1..15}
  do
    c_print "none" "." 0
    sleep 1
  done
  c_print "green" "[DONE]"

  c_print "blue" "[MAIN THREAD]\t Getting MFC entries/masks..."
  MASK_NUM=$(ovs-dpctl show|grep masks|grep total|awk '{print $3}'|cut -d ':' -f 2)

  c_print "blue" "[MAIN THREAD]\t Measurement with port number ${PORT} is done"
  c_print "yellow" "[MAIN THREAD]\t Killing attacker" 0
  sudo kill -9 $PID
  sudo kill -9 $PID
  c_print "green" "[DONE]"

  c_print "green" "[MAIN THREAD] ${PORT}, ${MASK_NUM}"
  c_print "blue" "[MAIN THREAD]\t Saving results..." 0
  echo "${PORT}, ${MASK_NUM}" >> diagonal_measurement.csv
  c_print "green" "[DONE]"

  c_print "blue" "[MAIN THREAD]\t Waiting the flow caches to reset (11 sec)"
  for i in {1..11}
  do
    c_print "none" "." 0
    sleep 1
  done
  c_print "green" "[DONE]"
  sleep 1
  c_print "blue" "[MAIN THREAD]\t Start over..."
done
