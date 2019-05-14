#!/bin/bash

# THIS PROGRAM WILL GENERATE A RANDOM PORT NUMBER AND ADDS IT AS A FILTERING
# FLOW RULE INTO THE FLOW TABLE OF OPEN VSWITCH.
# THEN, IT GENERATES k DIFFERENT RANDOM PORT NUMBER AND THEIR CORRESPONDING
# ATTACKING SEUQENCE ACCORDING TO
#
# L. CSIKOR, G. RETVARI, 'The Discrepancy of the Megaflow Cache in OVS' at the Open vSwitch # # Fall Conference in San Jose in December 2018

#
# THEN, ATTACK IS CARRIED OUT IN ITS REGULAR WAY, BUT NOW THE ATTACK SEQUENCE
# HAS BASICALLY NOTHING TO DO WITH THE INSTALLED FLOW RULE.
# THE AIM IS TO INVESTIGATE THE EFFECT OF RANDOMNESS!

# ALL IN ALL THE STEPS ARE THE FOLLOWING:
# - GENERATE RANDOM PORT NUMBER X IN THE FLOW TABLE
# - GERENATE l (1,...,N) RANDOM PORT NUMBERS Y_l AND THEIR CORRESPONDING ATTACKING
#   SEQUENCE AND 'PLAY' AGAINST THE FLOW RULE
# - EVALUATE HOW RANDOM ATTACK PERFORMS

# REPEAT EACH CASE OF l 100 TIMES!
# INTENDED CSV OUTPUT: i, rnd_port_no_rule, rnd_port_numbers, num_packets, megaflow_entries

# ============ ASSUMPTIONS ===========
# 1) Open vSwitch bridge is running with name 'ovsbr' (without quotes).
# 2) Two network namespaces are connected to ovsbr, namely ns1 and ns2.
# 3) The attack is coming from ns1, and its NIC name is ns1_veth_ns.
# 4) Wireshark, tcpreplay is installed in the base system to merge pcap files and replay them
# ------------------------------------

source colorized_output.sh
PCAP_GENERATOR_SCRIPT=../pcap_gen_ovs_dos/pcap_generator_for_holepunch.py

declare -A RANDOM_PORT_TO_ATTACK

function generate_random_number () {
# This function generates a random port number to attack between RANGE1 and RANGE2
# as the function's first two arguments.
# Then, according to the third argument (NUM) of the function, NUM different
# random ports will also be generated in the same range.
# The first random number will be stored in variable RANDOM_PORT_TO_ACL, while
# the NUM different random ports will be stored in the RANDOM_PORT_TO_ATTACK array!
  RANGE1=$1
  RANGE2=$2
  num_random_ports=$3

  # echo $RANGE1
  # echo $RANGE2
  # echo $NUM
  #
  # echo
  DIFF=$(($RANGE2-$RANGE1+1))

  RANDOM_PORT_TO_ACL=$(($(($RANDOM%$DIFF))+$RANGE1))

  for i in $(seq 1 $num_random_ports)
  do
    # echo "generating random number (${i})..."
    RANDOM_PORT_TO_ATTACK[$i]=$(($(($RANDOM%$DIFF))+$RANGE1))
  done

  num_of_ports=${#RANDOM_PORT_TO_ATTACK[@]}
  # c_print "yellow" "Number of different ports to attack: ${num_of_ports}"
  c_print "yellow" "RANDOM PORT TO ACL:"
  c_print "none" $RANDOM_PORT_TO_ACL
  c_print "yellow" "RANDOM PORTS TO ATTACK:"
  for i in $(seq 1 $num_random_ports)
  do
    c_print "none" "${RANDOM_PORT_TO_ATTACK[${i}]}"
  done
}
# ------------------------------

function print_help {
  echo
  # c_print "none" "Add random allow rule on destination port to OVS with a catch-all drop rule"
  c_print "none" "Usage:" 0
  c_print "bold" "./random_attack_measurement.sh  <number_of_random_ports_to_attack> <iterations>"
  c_print "none" "Example:"
  c_print "none" "./random_attack_measurement.sh 2 100"
  echo
  exit -1
}
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


echo "i, rnd_ACL_port, rnd_ATTACK_ports, megaflow_entries" > "random_attack_measurement_port_num_${NUMBER_OF_RANDOM_PORTS_TO_ATTACK}.csv"

for iter in $(seq 1 $ITERATION)
do
  c_print "yellow" "Generating numbers for iteration ${iter} out of ${ITERATION}"
  generate_random_number 1 65535 $NUMBER_OF_RANDOM_PORTS_TO_ATTACK

  c_print "blue" "[MAIN THREAD]\t Add flow rule with the following port number: ${PORT}    "
  ./add_custom_port_filter.sh ovsbr $RANDOM_PORT_TO_ACL
  sleep 1
  c_print "green" "[DONE]"

  rm -rf tmp_*pcap

  c_print "blue" "[MAIN THREAD]\t Generating pcap file for random port:"
  RANDOM_PORT_TO_ATTACK_AS_ONE_STRING=""
  for i in $(seq 1 $NUMBER_OF_RANDOM_PORTS_TO_ATTACK)
  do
    c_print "none" "${RANDOM_PORT_TO_ATTACK[${i}]}"
    if [ -z "$RANDOM_PORT_TO_ATTACK_AS_ONE_STRING" ]
    then
      RANDOM_PORT_TO_ATTACK_AS_ONE_STRING="${RANDOM_PORT_TO_ATTACK[${i}]}"
    else
      RANDOM_PORT_TO_ATTACK_AS_ONE_STRING="${RANDOM_PORT_TO_ATTACK_AS_ONE_STRING}+${RANDOM_PORT_TO_ATTACK[${i}]}"
    fi
    python $PCAP_GENERATOR_SCRIPT -t DP -f "${RANDOM_PORT_TO_ATTACK[${i}]}" -o "tmp_${i}"
    c_print "green" "[DONE]"
  done

  c_print "blue" "[MAIN_THREAD]\t Merging pcap files to one..." 0
  mergecap -a -w tmp_merged.pcap tmp_*.64*pcap
  c_print "green" "[DONE]"

  c_print "blue" "[MAIN THREAD]\t Launching the attack..."
  sudo ip netns exec ns1 tcpreplay -q -l 10 -i ns1_veth_ns -t tmp_merged.pcap
  c_print "green" "[DONE]"

  c_print "blue" "[MAIN THREAD]\t Getting MFC entries/masks..."
  MASK_NUM=$(ovs-dpctl show|grep masks|grep total|awk '{print $3}'|cut -d ':' -f 2)

  c_print "blue" "[MAIN THREAD]\t Measurement with port number ${RANDOM_PORT_TO_ATTACK[${i}]} is done"

  c_print "green" "[MAIN THREAD] ${iter}, ${RANDOM_PORT_TO_ACL}, ${RANDOM_PORT_TO_ATTACK_AS_ONE_STRING}, ${MASK_NUM}"

  echo "${iter}, ${RANDOM_PORT_TO_ACL}, ${RANDOM_PORT_TO_ATTACK_AS_ONE_STRING}, ${MASK_NUM}" >> "random_attack_measurement_port_num_${NUMBER_OF_RANDOM_PORTS_TO_ATTACK}.csv"
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
