#!/bin/bash

#------- UPDATE MANUALLY THIS PART IF NEEDED --------#
# for some reason Lanner does not see the environment variable
RTE_SDK=/home/csikor/dpdk
RTE_TARGET=x86_64-native-linuxapp-gcc

#path to the executable 'binary' relative to your main dpdk directory
devbind_path="usertools/dpdk-devbind.py"


#ports
declare -A ports
ports=(
            #1G
            #[0]=enp10s0 - Omit first port as it is used to reach the device (DHCP port)
            [1]=eth2
            [2]=eth3
            [3]=eth4
	    #10G
            [4]=eth6
            [5]=eth5
        )

#drivers for ports
declare -A drivers
#Omit port 0 as it is used to reach the device (DHCP port)
for i in {1..3}
do
  drivers[$i]=tg3
done
drivers[4]=i40e
drivers[5]=i40e

dpdk_driver="igb_uio"

#pci ids
declare -A pci_ids
pci_ids=(
            #1G
            #[0]=0000:0a:00.0 - Omit port 0 as it is used to reach the device (DHCP port)
            [1]=0000:16:00.1
            [2]=0000:16:00.2
            [3]=0000:16:00.3
	    #10G
            [4]=0000:0b:00.0
            [5]=0000:0b:00.1
        )


num_of_ports=${#ports[@]}

#RTE_SDK and RTE_TARGET should be env. variable
#---------=================----------------



red="\033[1;31m"
green="\033[1;32m"
blue="\033[1;34m"
yellow="\033[1;33m"
cyan="\033[1;36m"
white="\033[1;37m"
none="\033[1;0m"
bold="\033[1;1m"



function print_help
{
  echo ""
  echo -e "${green}Usage: ./dpdk_handler.sh <status> <port_id>${none}"
  echo -e "${bold}status: enable/disable"
  echo -e "${bold}port_id: [1-5], ALL"
  echo -e "Example: enable DPDK for the first port: ./dpdk_handler.sh enable 1"
  echo -e "Example: disable DPDK for port 5: ./dpdk_handler disable 5"
  echo -e "${bold}UPDATE THE SCRIPT IF PCI IDs ARE NOT CORRECT!${none}"
  echo -e "${yellow}Note: Enabling/Disabling multiple interfaces requires multiple executions!${none}"
  echo -e "${bold}Known ports and their port_id:${none}"
  for i in "${!ports[@]}"
    do
      #bind the interfaces to the drivers
      echo -e "${bold}${i}${none}: ${ports[${i}]} (${pci_ids[${i}]})"
  done


  echo ""
  exit
}

if [ $# -lt 2 ]
then
  echo -e "${red}Not enough parameters${none}"
  print_help
  exit
fi

status=$(echo $1 | tr "[:upper:]" "[:lower:]")

port_id=$2

echo -e "${bold}"
echo -e "+============== ######### =================+"
echo -e "|     HANDLING DPDK ON interface ${port_id}\t\t|"
echo -e "+============== ######### =================+"
echo -e "${none}"


#--------======= ENABLE ======---------
if [ "$status" == "enable" ]
then
    #if enabling dpdk, we require modules
    echo -e "${green}Modprobe uio${none}"
    sudo modprobe uio 2>&1 #if already loaded we do not care about the error message

    echo -e "${green}Modprobe igb_uio${none}"
    sudo insmod ${RTE_SDK}/${RTE_TARGET}/kmod/igb_uio.ko 2> /dev/null #if already loaded we do not care about the error message

    driver_to_bind=$dpdk_driver

    if [ "$port_id" == "ALL" ]
    then
        for i in "${!ports[@]}"
        do
            #bind the interfaces to the drivers
            sudo ${RTE_SDK}/${devbind_path} --bind=$driver_to_bind ${pci_ids[${i}]}
            echo -e "Enabling DPDK on port ${i}"
        done

    else
        sudo ${RTE_SDK}/${devbind_path} --bind=$driver_to_bind ${pci_ids[${port_id}]}
    fi


#--------======= DISABLE ======---------
elif [ "$status" == "disable" ]
then
    driver_to_bind=${drivers[${port_id}]}

    if [ "$port_id" == "ALL" ]
    then
        for i in "${!ports[@]}"
        do
            #getting the kernel drivers
            driver_to_bind=${drivers[${i}]}
            #bind the interfaces to the drivers
            sudo ${RTE_SDK}/${devbind_path} --bind=$driver_to_bind ${pci_ids[${i}]}
            echo -e "Disabling DPDK on port ${i}"
        done

    else
        sudo ${RTE_SDK}/${devbind_path} --bind=$driver_to_bind ${pci_ids[${port_id}]}
    fi


#--------======= ERROR ======---------
else
    echo ""
    echo -e "${red}ERROR during parsing argument '${status}' given for <status>"
    print_help
fi






echo -e "\t\t\t\t${green}[DONE]${none}\n"
./get_dpdk_status.sh


echo ""

