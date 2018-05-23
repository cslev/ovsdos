#!/bin/bash

none="0m"

declare -A colors
colors=(
  [0]="31m"
  [1]="32m"
  [2]="33m"
  [3]="34m"
  [4]="35m"
  [5]="36m"
  [6]="93m"
  [7]="95m"
)


if [ $# -lt 1 ]
then
  echo -e "\033[${colors[0]}Usage: ./get_into_namespace.sh <namespace>\033[${none}"
  exit -1
fi


ns=$1


num_colors=${#colors[@]}
rnd=$(echo $((0 + RANDOM % $num_colors)))
c=${colors[${rnd}]}

bash_file="ns_bashrc"

cat $bash_file | sed "s/<NS>/${ns}/" |sed "s/<COLOR>/$c/" > tmp_${ns}.bashrc
sudo ip netns exec $ns bash --rcfile tmp_${ns}.bashrc



