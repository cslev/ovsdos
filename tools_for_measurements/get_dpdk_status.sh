#!/bin/bash

#------- UPDATE MANUALLY THIS PART IF NEEDED --------#
#path to the executable 'binary' relative to your main dpdk directory
devbind_path="usertools/dpdk-devbind.py"
#$RTE_SDK and $RTE_TARGET should be env. variable (e.g., defined in your .bashrc as 'clouduser' has)
#---------=================----------------

red="\033[1;31m"
green="\033[1;32m"
blue="\033[1;34m"
yellow="\033[1;33m"
cyan="\033[1;36m"
white="\033[1;37m"
none="\033[1;0m"
bold="\033[1;1m"

sudo ${RTE_SDK}/${devbind_path} --status | grep -vE "Other|Mem|<none>|Crypto|Eventd"| grep --color=auto -E "drv=igb_uio|$"

echo ""

