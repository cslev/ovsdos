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

function print_help {
	echo
	c_print "none" "Usage:" 0
	c_print "bold" "./start_attacker.sh <attacker_rate_in_pps> <iface> <attacker_pcap> <used_packet_size_in_bytes>"
	c_print "none" "Example"
	c_print "none" "./start_attacker.sh 1000 ens3 DP.64bytes.pcap 64"
	echo
	exit -1
}

# ============ PARSE ARGS ================
if [ $# -ne 4 ]
then
	c_print "red" "Insufficient number of attributes"
	print_help
fi

influx_server="152.66.245.170:8086"
rate=$1
iface=$2
pcap=$3
size=$4

attacker_throughput=$(echo "(${size}+20)*8*${rate}/1024/1024/1024" | bc -l)

tcpreplay -q -l 0 -i $iface -p $rate $pcap  &

while true
do
  curl -i -XPOST "http://${influx_server}/write?db=iperf" \
  --data-binary "attacker,rate=Gbit value=$(echo $attacker_throughput)"

  sleep 1s
done


