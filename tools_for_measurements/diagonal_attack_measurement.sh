#!/bin/bash

# THIS PROGRAM WILL ITERATE THROUGH ALL POSSIBLE PORT NUMBERS RANGING FROM 1 to 65535
# AND ADD EACH PORT NUMBER AS A FLOW RULE INTO THE OVS FLOW TABLE
# THEN, IT LAUNCHES A DIAGONAL ATTACK FOR 15 SECONDS AND SEE HOW THE OVS MEGAFLOW CACHE
# ENTRIES/MASKS CHANGE
# INTENDED CSV OUTPUT: port no., #megaflow masks

source colorized_output.sh

echo "port no, megaflow masks" > diagonal_measurement.csv
for i in {1..65535}
do
  c_print "blue" "[MAIN THREAD]\t Add flow rule with the following port number: $i    " 0
  ./add_custom_port_filter.sh ovsbr $i
  sleep 1
  c_print "green" "[DONE]"

  c_print "blue" "[MAIN THREAD]\t Launching the attack..."
  sudo ip netns exec ns1 python send_diagonal_attack_dstport.py &
  PID=$(cat diagonal_attack.pid)

  sleep 15s
  MASK_NUM=$(ovs-dpctl show|grep masks|grep total|awk '{print $3}'|cut -d ':' -f 2)

  c_print "blue" "[MAIN THREAD]\t Measurement with port number ${i} is done"
  c_print "yellow" "[MAIN THREAD]\t Killing attacker" 0
  sudo kill -9 $PID
  sudo kill -9 $PID
  c_print "green" "[DONE]"

  c_print "blue" "[MAIN THREAD]\t Saving results..." 0
  echo "${i}, ${MASK_NUM}" >> diagonal_measurement.csv
  c_print "green" "[DONE]"

  c_print "blue" "[MAIN THREAD]\t Waiting the flow caches to reset"
  for i in {1..11}
  do
    c_print "none" ". " 0
    sleep 1
  done
  c_print "green" "[DONE]"
  sleep 1
  c_print "blue" "[MAIN THREAD]\t Start over..."
done
