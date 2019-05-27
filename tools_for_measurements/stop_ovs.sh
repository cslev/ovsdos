#!/bin/bash

echo -ne "Removing 'ovsbr' bridge from the system..."
sudo ovs-vsctl --if-exists del-br ovsbr
echo -e "\t\t\t[DONE]"


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

echo -e "Killing namespaces if there are any"
for i in $(ip netns list|awk '{print $1}')
do
  ip netns delete $i
done
echo -e "\t\t\t[DONE]"


echo -e "Removing default DP in kernel..."
sudo ovs-dpctl del-dp system@ovs-system
echo -e "\t\t\t[DONE]"



#checking
echo "Check the following ps aux output:"
ps aux |grep ovs|grep -v "grep --color=auto" |grep -v "stop_ovs.sh"|grep -v "grep ovs"|grep -v "nano"

echo ""
