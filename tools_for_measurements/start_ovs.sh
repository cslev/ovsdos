#!/bin/bash
#set here which binaries you want to use!
OVS_PATH_SET=1 #if set to 0, then /usr/[local]/bin/ binaries will be used
OVS_MODULE_NAME="openvswitch"

# ALWAYS USE MODPROBE INSTEAD OF INSMOD
# IF YOU DO NOT KNOW HOW TO INSTALL A KERNEL MODULE THAT DOES NOT OVERWRITE YOUR CURRENT ONE
# CHECK THE INFO FILE IN THIS REPOSITORY sign_and_use_ovs_module.info!

OVS_PATH="/root/ovs"
OVSDB_PATH="${OVS_PATH}/ovsdb"
OVSVSWITCHD_PATH="${OVS_PATH}/vswitchd"
OVSUTILITIES_PATH="${OVS_PATH}/utilities"
OVS_MODPATH="${OVS_PATH}/datapath/linux/openvswitch.ko"

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
  echo -e "\t\t-n <name>: name of the OVS bridge"
  echo -e "\t\t-d <path_to_db.sock>: Path where db.sock will be created!"

  exit
}

DBR=""

while getopts "h?n:d:" opt
do
  case "$opt" in
  h|\?)
    show_help
    ;;
  n)
    DBR=$OPTARG
    ;;
  d)
   DB_SOCK=$OPTARG
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

if [[ "$DB_SOCK" == "" ]]
then
  echo -e "${yellow}No DB_SOCK has been set, using defaults (/usr/local/var/run/openvswitch/db.sock)${none}"
  DB_SOCK=/usr/local/var/run/openvswitch
fi

mkdir -p $DB_SOCK
DB_SOCK="${DB_SOCK}/db.sock"


ptcp_port=16633
echo -ne "${yellow}Adding OVS kernel module${none}"
sudo rmmod $OVS_MODULE_NAME > /dev/null 2>&1
if [ $OVS_PATH_SET -eq 0 ]
then
  sudo modprobe $OVS_MODULE_NAME  2>&1
else
#  sudo insmod $OVS_MODPATH 2>&1
  sudo modprobe $OVS_MODULE_NAME 2>&1

fi

echo -e "\t\t${bold}${green}[DONE]${none}"


echo -ne "${yellow}Delete preconfigured ovs data${none}"
if [ $OVS_PATH_SET -eq 0 ]
then
  sudo rm -rf /etc/openvswitch/conf.db 2>&1
else
  sudo rm -rf /usr/local/etc/openvswitch/conf.db 2>&1
fi
echo -e "\t\t${bold}${green}[DONE]${none}"

if [ $OVS_PATH_SET -eq 0 ]
then
  sudo mkdir -p /etc/openvswitch/
else
  sudo mkdir -p /usr/local/etc/openvswitch/
fi

echo -ne "${yellow}Create ovs database structure${none}"
if [ $OVS_PATH_SET -eq 0 ]
then
  sudo ovsdb-tool create /etc/openvswitch/conf.db  /usr/local/share/openvswitch/vswitch.ovsschema
else
  sudo $OVSDB_PATH/ovsdb-tool create /usr/local/etc/openvswitch/conf.db  $OVSVSWITCHD_PATH/vswitch.ovsschema
fi

echo -e "\t\t${bold}${green}[DONE]${none}"

if [ $OVS_PATH_SET -eq 0 ]
then
  sudo mkdir -p /var/run/openvswitch
else
  sudo mkdir -p /usr/local/var/run/openvswitch
fi

echo -ne "${yellow}Start ovsdb-server...${none}"
if [ $OVS_PATH_SET -eq 0 ]
then
  sudo ovsdb-server --remote=punix:$DB_SOCK --remote=db:Open_vSwitch,Open_vSwitch,manager_options --pidfile --detach
else
  sudo $OVSDB_PATH/ovsdb-server --remote=punix:$DB_SOCK --remote=db:Open_vSwitch,Open_vSwitch,manager_options --pidfile --detach
fi
echo -e "\t\t${bold}${green}[DONE]${none}"

echo -e "Initializing..."
if [ $OVS_PATH_SET -eq 0 ]
then
  sudo ovs-vsctl --no-wait init
else
  sudo $OVSUTILITIES_PATH/ovs-vsctl --no-wait init
fi


# CAN NOW BE SET AS RUNTIME ARGUMENT
#echo -ne "${yellow}exporting environmental variable DB_SOCK${none}"
#if [ $OVS_PATH_SET -eq 0 ]
#then
#  export DB_SOCK=/var/run/openvswitch/db.sock
#else
#  export DB_SOCK=/usr/local/var/run/openvswitch/db.sock
#fi
#echo -e "${bold}${green}\t\t[DONE]${none}"

echo -ne "${yellow}start vswitchd...${none}"
if [ $OVS_PATH_SET -eq 0 ]
then
  sudo ovs-vswitchd unix:$DB_SOCK --pidfile --detach
else
  sudo $OVSVSWITCHD_PATH/ovs-vswitchd unix:$DB_SOCK --pidfile --detach
fi
echo -e "${bold}${green}\t\t[DONE]${none}"


echo -ne "${yellow}Create bridge (${DBR})${none}"
if [ $OVS_PATH_SET -eq 0 ]
then
  sudo ovs-vsctl add-br $DBR
else
  sudo $OVSUTILITIES_PATH/ovs-vsctl add-br $DBR
fi
echo -e "${bold}${green}\t\t[DONE]${none}"

echo -ne "${yellow}Deleting flow rules from ${DBR}${none}"
if [ $OVS_PATH_SET -eq 0 ]
then
  sudo ovs-ofctl del-flows $DBR
else
  sudo $OVSUTILITIES_PATH/ovs-ofctl del-flows $DBR
fi
echo -e "${bold}${green}\t\t[DONE]${none}"


echo -ne "${yellow}Add passive controller listener port on ${ptcp_port}${none}"
if [ $OVS_PATH_SET -eq 0 ]
then
  sudo ovs-vsctl set-controller $DBR ptcp:$ptcp_port
else
  sudo $OVSUTILITIES_PATH/ovs-vsctl set-controller $DBR ptcp:$ptcp_port
fi
echo -e "\t\t${bold}${green}[DONE]${none}"

echo -e "OVS (${DBR}) has been fired up!"
if [ $OVS_PATH_SET -eq 0 ]
then
  sudo ovs-vsctl show
else
  sudo $OVSUTILITIES_PATH/ovs-vsctl show
fi
echo -e "${none}"
