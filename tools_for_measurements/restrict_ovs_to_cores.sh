#!/bin/bash


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
  echo -e "${green}Example: sudo ./restrict_ovs_to_cores.sh -n <driver> [-c <00,00000004>] ${none}"
  echo -e "\t\t-n <name>: name of the driver (e.g., mlx5)"
  echo -e "\t\t-c <core_mask>: Core mask used to pin the IRQs!"

  exit
}

while getopts "h?n:c:" opt
do
  case "$opt" in
  h|\?)
    show_help
    ;;
  n)
    DRIVER=$OPTARG
    ;;
  c)
    CPU_MASK=$OPTARG
    ;;
  *)
    show_help
   ;;
  esac
done

if [[ "$DRIVER" == "" ]]
then
  show_help
fi


num_irq=0
echo -e "Getting the IRQs and their pinning for driver ${DRIVER}"
for i in $(cat /proc/interrupts|grep ${DRIVER}|awk '{print $1}'|cut -d ":" -f 1)
do
  pinning=$(cat /proc/irq/$i/smp_affinity)
  echo -e "${green}${i}:${none} ${bold}${pinning}${none}"
  num_irq=`expr $num_irq + 1`
done
echo -e "${green}[DONE]${none}"

echo -e "${yellow}${bold}THE CPU_MASK YOU HAVE SET SHOULD MATCH ANY OF THE ABOVE!${none}"


if [[ "$CPU_MASK" == "" ]]
then
  echo -e "CPU_MASK is not set!"
  exit
fi

echo -e "Pinning the IRQs according to ${CPU_MASK}"
for i in $(cat /proc/interrupts|grep ${DRIVER}|awk '{print $1}'|cut -d ":" -f 1)
do
  j=$(($i%2))
  echo -e "${blue}[DEBUG] modulo: ${j}${none}"
  if [ $j -ne 0 ]
  then
    echo "00,00000002" > /proc/irq/$i/smp_affinity
  else
    echo "00,00000004" > /proc/irq/$i/smp_affinity
  fi
done
echo -e "${green}[DONE]${none}"



