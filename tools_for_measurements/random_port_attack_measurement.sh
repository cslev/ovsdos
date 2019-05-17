#!/bin/bash

# THIS PROGRAM WILL GENERATE A RANDOM PORT NUMBER AND ADDS IT AS A FILTERING
# FLOW RULE INTO THE FLOW TABLE OF OPEN VSWITCH.
# THEN, IT GENERATES k DIFFERENT RANDOM PORT NUMBER AND SENDS THEM TOWARDS THE
# FLOW TABLE

# THE AIM IS TO INVESTIGATE THE EFFECT OF RANDOMNESS!

# ============ ASSUMPTIONS ===========
# 1) Open vSwitch bridge is running with name 'ovsbr' (without quotes).
# 2) Two network namespaces are connected to ovsbr, namely ns1 and ns2.
# 3) The attack is coming from ns1, and its NIC name is ns1_veth_ns.
# 4) scapy, python-scapy are installed in the base system to merge pcap files and replay them
# ------------------------------------


source colorized_output.sh


# ============ MAIN ============
# FIRST ARGUMENT: Number of different random port numbers to generate attacking trace to
# SECOND ARGUMENT: Number of iterations (to spread the results evenly due to randomness)
NUMBER_OF_RANDOM_PORTS_TO_ATTACK=$1
ITERATION=$2
# ============ PARSING ARGS ======
if [ $# -ne 2 ]
then
  c_print "red" "Insufficient number of attributes"
  print_help
fi


for i in $(seq 1 $NUMBER_OF_RANDOM_PORTS_TO_ATTACK)
do
  echo "i, megaflow_entries" > "random_attack_measurement_portnum_${i}.csv"

  for iter in $(seq 1 $ITERATION)
  do
    c_print "blue" "[MAIN THREAD]\t Add flow rule with a random port number    "
    ./add_random_port_filter.sh ovsbr 1 65535
    sleep 1
    c_print "green" "[DONE]"

    c_print "blue" "[MAIN THREAD]\t Starting the attack..."
    ip netns exec ns1 python full_random_attack.py -l 2 -b 16 -n $i -i ns1_veth_ns
    c_print "green" "[DONE]"

    c_print "blue" "[MAIN THREAD]\t Getting MFC entries/masks..."
    MASK_NUM=$(ovs-dpctl show|grep masks|grep total|awk '{print $3}'|cut -d ':' -f 2)

    c_print "blue" "[MAIN THREAD]\t ${iter} iteration is ready"
    c_print "green" "[MAIN THREAD]\t ${iter}, ${MASK_NUM}"
    echo "${iter}, ${MASK_NUM}" >> "random_port_to_attack_measurement_port_num_${i}.csv"
  done

  c_print "green" "[MAIN THREAD]\t Measurement with ${i} random ports is done"
  c_print "blue" "[MAIN THREAD]\t Start over..."

done
