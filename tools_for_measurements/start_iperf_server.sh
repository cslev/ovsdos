#!/bin/bash

source colorized_output.sh
#none,bold,disable,underline,reverse,strikethrough,invisible,black,red, green,
#orange, blue, purple, cyan, lightgrey, darkgrey, lightred, lightgreen
#yellow, lightblue, pink, lightcyan

#c_print usage
#$1: color
# $2: text to print out
# $3: no_newline - if nothing is provided newline will be printed at the end
#				 - anything provided, NO newline is indicated

c_print yellow "Starting iperf in background mode" 1
iperf3 -s -i 1 -f g --logfile iperf.out &
c_print green "[DONE]"



while true
do
  curl -i -XPOST 'http://172.17.0.1:8086/write?db=iperf' \
  --data-binary "throughput,received=Gbit value=$(tail -n1 iperf.out |grep "Gbits/sec"|awk '{print $7}')"

  sleep 1s
done


