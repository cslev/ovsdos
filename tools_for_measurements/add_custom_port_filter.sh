#!/bin/bash

source colorized_output.sh

function print_help {
  echo
  c_print "none" "Add random allow rule on destination port to OVS with a catch-all drop rule"
  c_print "none" "Usage:" 0
  c_print "bold" "./add_random_port_filter.sh <ovs-br-name> <port_no>"
  c_print "none" "Example for random well-known ports"
  c_print "none" "./add_random_port_filter.sh ovsbr 123"
  echo
  exit -1
}

# ============ PARSING ARGS ======
if [ $# -ne 2 ]
then
  c_print "red" "Insufficient number of attributes"
  print_help
fi

DBR=$1
PORT=$2

FLOW_RULE_FILE="malicious_acl_diagonal_attack.flows"
RPL="REPLACE"


c_print "yellow" "Removing existing flows from the table" 0
sudo ovs-ofctl del-flows $DBR
c_print "green" "[DONE]"


c_print "green" "Chosen port is ${PORT}"
c_print "none"  "Adding flow rules accordingly..." 0
sed  "s/${RPL}/${PORT}/" $FLOW_RULE_FILE > "${FLOW_RULE_FILE}.tmp"
sudo ovs-ofctl add-flows $DBR "${FLOW_RULE_FILE}.tmp"
c_print "green" "[DONE]"
