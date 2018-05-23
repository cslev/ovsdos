#!/bin/bash

echo  "Killing the whole process tree of OVS"

#magic command to get the main ancestor PIDs and kill them one by one
#for i in `pstree -p |grep ovs| grep -oP "(?<=\()[0-9]+(?=\))" | sort -r`
#for i in `ps aux|grep ovs|grep -v "grep --color=auto"`
#do
#  echo $i
#  sudo kill -9 $i
#done

sudo pkill ovsdb-server
sudo pkill ovs-vswitchd

echo -e "\t\t\t[DONE]"

echo -e "Removing openvswitch module..."

sudo rmmod openvswitch 2>/dev/null
echo -e "\t\t\t[DONE]"


#checking
echo "Check the following ps aux output:"
ps aux |grep ovs|grep -v "grep --color=auto" |grep -v "stop_ovs.sh"|grep -v "grep ovs"|grep -v "nano"

echo ""
