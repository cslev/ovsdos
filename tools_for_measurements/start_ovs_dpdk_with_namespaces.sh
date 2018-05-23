#!/bin/bash
#OVS_PATH="/home/csikor/openvswitch-2.5.1"
OVS_PATH="/home/csikor/_freshest_env/ovs"
#COLORIZING
none='\033[0m'
bold='\033[01m'
disable='\033[02m'
underline='\033[04m'
reverse='\033[07m'
strikethrough='\033[09m'
invisible='\033[08m'

black='\033[30m'
red='\033[31m'
green='\033[32m'
orange='\033[33m'
blue='\033[34m'
purple='\033[35m'
cyan='\033[36m'
lightgrey='\033[37m'
darkgrey='\033[90m'
lightred='\033[91m'
lightgreen='\033[92m'
yellow='\033[93m'
lightblue='\033[94m'
pink='\033[95m'
lightcyan='\033[96m'


function show_help
{
  echo -e "${red}${bold}Arguments not set properly!${none}"
  echo -e "${green}Example: sudo ./start_ovs_kernel_with_namespaces.sh -o ovsbr -n 50 -i${none}"
  echo -e "\t\t-o <name>: name of the OVS bridge"
  echo -e "\t\t-n <number>: number of desired namespaces"
  echo -e "\t\t-i: indicating to install basic L3 forwaring rules${none}"
  echo -e "\t\t-c <number>: number of cores to use ${none}"
  exit
}

DBR=""
NS=""
INSTALL=false
CORE=""

while getopts "h?o:n:ic:" opt
do
  case "$opt" in
  h|\?)
    show_help
    ;;
  o)
    DBR=$OPTARG
    ;;
  n)
    NS=$OPTARG
    ;;
  i)
    INSTALL=true
    ;;
  c)
    CORE=$OPTARG
    ;;
  *)
    show_help
    ;;
  esac
done

if [[ "$DBR" == "" || "$NS" == "" || "$CORE" == "" ]]
then
  show_help
fi

#core setup
case $CORE in
  1)
    c=4
    r=1
  ;;
  2)
    c=6
    r=2
  ;;
  3)
    c=e
    r=3
  ;;
  4)
    c=1e
    r=4
  ;;
  5)
    c=3e
    r=5
  ;;
  6)
    c=7e
    r=6
  ;;
  *)
    c=4
    r=1
  ;;
esac

ptcp_port=6633




echo -ne "${yellow}Delete preconfigured ovs data${none}"
sudo rm -rf /usr/local/etc/openvswitch/conf.db
echo -e "\t\t${bold}${green}[DONE]${none}"

echo -ne "${yellow}Create ovs database structure${none}"
sudo $OVS_PATH/ovsdb/ovsdb-tool create /usr/local/etc/openvswitch/conf.db  $OVS_PATH/vswitchd/vswitch.ovsschema
echo -e "\t\t${bold}${green}[DONE]${none}"

echo -ne "${yellow}Start ovsdb-server...${none}"
sudo $OVS_PATH/ovsdb/ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock --remote=db:Open_vSwitch,Open_vSwitch,manager_options --pidfile --detach
echo -e "\t\t${bold}${green}[DONE]${none}"

echo -e "Initializing..."
sudo $OVS_PATH/utilities/ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
sudo $OVS_PATH/utilities/ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-lcore-mask=0xff
sudo $OVS_PATH/utilities/ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="4096,0"

echo -ne "${yellow}exporting environmental variable DB_SOCK${none}"
export DB_SOCK=/usr/local/var/run/openvswitch/db.sock
echo -e "${bold}${green}\t\t[DONE]${none}"

echo -ne "${yellow}start vswitchd...${none}"
sudo $OVS_PATH/vswitchd/ovs-vswitchd unix:$DB_SOCK --pidfile --detach
echo -e "${bold}${green}\t\t[DONE]${none}"

#echo "Create dpdk-bridge (dpdk_br)"
sudo $OVS_PATH/utilities/ovs-vsctl add-br $DBR -- set bridge $DBR datapath_type=netdev

echo "Add dpdk ports for ${DBR}"
sudo $OVS_PATH/utilities/ovs-vsctl add-port $DBR dpdk0 -- set Interface dpdk0 type=dpdk options:dpdk-devargs=0000:0b:00.0

echo "Pin OVS to the right cores (cm: ${c}) and set up RSS (${r})"
sudo $OVS_PATH/utilities/ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=$c
sudo $OVS_PATH/utilities/ovs-vsctl set interface dpdk0 options:n_rxq=$r 


echo -ne "${yellow}Deleting flow rules from ${DBR}${none}"
sudo $OVS_PATH/utilities/ovs-ofctl del-flows $DBR
echo -e "${bold}${green}\t\t[DONE]${none}"


echo -e "${yellow}Create namespaces and intefaces (${NS} pcs)...${none}"
for i in $(seq 1 $NS)
do
  sudo ip netns add "ns${i}"
  sudo ip link add "ns${i}_veth_root" type veth peer name "ns${i}_veth_ns"
  sudo ip link set "ns${i}_veth_ns" netns "ns${i}"
  sudo ip addr add "10.1.${i}.1" dev "ns${i}_veth_root"
  sudo ip netns exec "ns${i}" ifconfig "ns${i}_veth_ns" "10.1.${i}.2/8" up

  sudo ip link set dev "ns${i}_veth_root" up
#  sudo ip netns exec "ns${i}" ip link set dev "ns${i}_veth_ns" up
  echo -ne "${yellow}Add port ns_${i}_veth_root for ${DBR}${none}"
  sudo $OVS_PATH/utilities/ovs-vsctl add-port $DBR "ns${i}_veth_root"
  echo -e "\t\t${bold}${green}[DONE]${none}"
  if [[ "$INSTALL" = true ]]
  then
    echo -ne "${cyan}Add basic L3 forwaring rule for namespaces${none}"
    sudo $OVS_PATH/utilities/ovs-ofctl add-flow $DBR "ip,nw_dst=10.0.${i}.2,action=output:${i}"
    echo -e "\t${bold}${green}[DONE]${none}"
  fi
done


echo -ne "${yellow}Add basic ARP FLOOD rule${none}"
sudo $OVS_PATH/utilities/ovs-ofctl add-flow $DBR "priority=1000,arp,action=flood"
echo -e "\t\t${bold}${green}[DONE]${none}"

echo -ne "${yellow}Add passive controller listener port on ${ptcp_port}${none}"
sudo $OVS_PATH/utilities/ovs-vsctl set-controller $DBR ptcp:$ptcp_port
echo -e "\t\t${bold}${green}[DONE]${none}"


echo -e "${bold}${white}"
echo -e "One OVS switch is fired up under the name of ${DBR} and ${NS} namespaces are attached to them"
echo -e "For each namespace a veth-pair has been created under the name of ns[X]_veth_[root|ns], where"
echo -e "X is the id of the namespace, and the interfaces ending with root is in the root namespace, while"
echo -e "the interface ending with ns is in the corresponding namespace"
echo -e "IP addresses of the namespaces are 10.0.[X].2, where X is the ID of the namespace"
echo -e "The other end of the veth-pairs, i.e., the ns[X]_veth_root interfaces, are connected to the OVS."
echo -e "\nDPDK interfaces are not connected to namespaces or whatsoever; that part should be done manually!\n"

if [[ "$INSTALL" = true ]]
  then
    echo -e "Basic IP forwarding flow rules have been inserted"
fi

echo -e "${none}"
