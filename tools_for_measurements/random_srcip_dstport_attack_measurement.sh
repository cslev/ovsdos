#!/bin/bash
source colorized_output.sh

function print_help {
  echo
  c_print "none" "Add random allow rule on destination port and another one on source IP address to OVS with a catch-all drop rule and send n*n random packets from already generated PCAP files (n=32,45,71,100,142). Do the whole thing 100 times!"
  c_print "none" "Usage:" 0
  c_print "bold" "./random_srcip_dstport_attack_measurement.sh"
  c_print "none" "Example:"
  c_print "none" "./random_srcip_dstport_attack_measurement.sh"
  echo
  exit -1
}

ITERATION=100

for i in 17 34 68 85 170 850 1700 2500 5000 7500 10000
do
  echo "i, megaflow_entries" > "random_srcip_dstport_attack_${i}.csv"

  for iter in $(seq 1 $ITERATION)
  do
    c_print "blue" "[MAIN THREAD]\t Add flow rule with a random port number"
    ./add_random_port_filter.sh ovsbr 1 65535
    sleep 1
    c_print "green" "[DONE]"

    c_print "blue" "[MAIN THREAD]\t Add flow rule with a random source IP address" 0
    RANDOM_IP=$(echo $((RANDOM%256)).$((RANDOM%256)).$((RANDOM%256)).$((RANDOM%256)))
    sudo ovs-ofctl add-flow ovsbr "table=0,priority=1000,udp,in_port=1,nw_dst=10.0.0.2,nw_src=${RANDOM_IP},actions=output:2"
    sleep 1
    c_print "green" "[DONE]"

    c_print "blue" "[MAIN THREAD]\t Starting the attack..."
    ip netns exec ns1 tcpreplay -l 2 -q -t -i ns1_veth_ns ../pcap_generator/random_srcip_dport/SIP_DP_${i}_${iter}.64bytes.pcap
    c_print "green" "[DONE]"

    c_print "blue" "[MAIN THREAD]\t Getting MFC entries/masks..."
    MASK_NUM=$(ovs-dpctl show|grep masks|grep total|awk '{print $3}'|cut -d ':' -f 2)

    c_print "blue" "[MAIN THREAD]\t ${iter} iteration is ready"
    c_print "green" "[MAIN THREAD]\t ${iter}, ${MASK_NUM}"
    echo "${iter}, ${MASK_NUM}" >> "random_srcip_dstport_attack_${i}.csv"

    c_print "blue" "[MAIN THREAD]\t Waiting the flow caches to reset (11 sec)"
    for iii in {1..11}
    do
      c_print "none" "." 0
      sleep 1
    done

  done
done
