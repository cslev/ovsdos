#!/bin/bash
#OVS_PATH="/home/csikor/openvswitch-2.5.1"
#OVS_PATH="/home/csikor/openvswitch-2.5.1"
OVS_PATH=""

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
  echo -e "${green}Example: sudo ./start_ovs.sh -o ovsbr ${none}"
  echo -e "\t\t-o <name>: name of the OVS bridge"

  exit
}

DBR=""

while getopts "h?o:" opt
do
  case "$opt" in
  h|\?)
    show_help
    ;;
  o)
    DBR=$OPTARG
    ;;
  *)
    show_help
   ;;
  esac
done

if [[ "$DBR" == "" ]]
then
  show_help
fi


ptcp_port=16633
echo -ne "${yellow}Adding OVS kernel module${none}"
sudo modprobe openvswitch 2>&1
echo -e "\t\t${bold}${green}[DONE]${none}"


echo -ne "${yellow}Delete preconfigured ovs data${none}"
sudo rm -rf /usr/local/etc/openvswitch/conf.db
echo -e "\t\t${bold}${green}[DONE]${none}"

echo -ne "${yellow}Create ovs database structure${none}"
sudo ovsdb-tool create /usr/local/etc/openvswitch/conf.db  /usr/local/share/openvswitch/vswitch.ovsschema
echo -e "\t\t${bold}${green}[DONE]${none}"

echo -ne "${yellow}Start ovsdb-server...${none}"
sudo ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock --remote=db:Open_vSwitch,Open_vSwitch,manager_options --pidfile --detach
echo -e "\t\t${bold}${green}[DONE]${none}"

echo -e "Initializing..."
sudo ovs-vsctl --no-wait init

echo -ne "${yellow}exporting environmental variable DB_SOCK${none}"
export DB_SOCK=/usr/local/var/run/openvswitch/db.sock
echo -e "${bold}${green}\t\t[DONE]${none}"

echo -ne "${yellow}start vswitchd...${none}"
sudo ovs-vswitchd unix:$DB_SOCK --pidfile --detach
echo -e "${bold}${green}\t\t[DONE]${none}"


echo -ne "${yellow}Create bridge (${DBR})${none}"
sudo ovs-vsctl add-br $DBR
echo -e "${bold}${green}\t\t[DONE]${none}"

echo -ne "${yellow}Deleting flow rules from ${DBR}${none}"
sudo ovs-ofctl del-flows $DBR
echo -e "${bold}${green}\t\t[DONE]${none}"


echo -ne "${yellow}Add passive controller listener port on ${ptcp_port}${none}"
sudo ovs-vsctl set-controller $DBR ptcp:$ptcp_port
echo -e "\t\t${bold}${green}[DONE]${none}"

echo -e "OVS (${DBR}) has been fired up!"
sudo ovs-vsctl show
echo -e "${none}"
