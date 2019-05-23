#!/bin/bash

source colorized_output.sh

function print_help {
  echo
  c_print "none" "Add random allow rule on destination port to OVS with a catch-all drop rule"
  c_print "none" "Usage:" 0
  c_print "bold" "./add_random_port_filter.sh <ovs-br-name> <lower_range> <upper_range> <REMOVE_OLD?=0/1>"
  c_print "none" "Example for adding a random port filter in the well-known ports' range without removing old flows"
  c_print "none" "./add_random_port_filter.sh ovsbr 1 1024 0"
  echo
  exit -1
}

# ============ PARSING ARGS ======
if [ $# -eq 4 ]
then
  c_print "red" "Insufficient number of attributes"
  print_help
fi

DBR=$1
R1=$2
R2=$3
REMOVE_OLD=$4

FLOW_RULE_FILE="malicious_acl_diagonal_attack.flows"
RPL="REPLACE"


DIFF=$(($R2-$R1+1))
R=$(($(($RANDOM%$DIFF))+$R1))

if [ $REMOVE_OLD -eq 1 ]
then
  c_print "yellow" "Removing existing flows from the table" 0
  sudo ovs-ofctl del-flows $DBR
  c_print "green" "[DONE]"
fi

c_print "green" "Chosen random port is ${R}"
c_print "none"  "Adding flow rules accordingly..." 0
sed  "s/${RPL}/${R}/" $FLOW_RULE_FILE > "${FLOW_RULE_FILE}.tmp"
sudo ovs-ofctl add-flows $DBR "${FLOW_RULE_FILE}.tmp"
c_print "green" "[DONE]"
