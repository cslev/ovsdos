#!/bin/bash
# THIS SCRIPT IS FOR EXAMINING  MFC ENTRY GROWTH WITH RANDOM PACKETS!
# ENVIRONMENT USED FOR THIS CASE IS ONLY A SINGLE SERVER WITH NAMESPACES

# WHENEVER THE AVERAGE NUMBER OF MFC ENTRIES ARE GATHERED, THE PCAPS CAN BE USED
# FOR MORE COMPLEX ENVIRONMENTS (E.G., KVM, OPENSTACK, KUBERNETES
# ============ ASSUMPTIONS ===========
# 1) Open vSwitch bridge is running with name 'ovsbr' (without quotes).
# 2) Two network namespaces are connected to ovsbr, namely ns1 and ns2.
# 3) The attack is coming from ns1, and its NIC name is ns1_veth_ns.
# 4) scapy, python-scapy are installed in the base system to merge pcap files and replay them
# ------------------------------------

source colorized_output.sh

function print_help {
  echo
  c_print "none" "Add random allow rule on destination port, source port and one on source IP address to OVS with a catch-all drop rule and send n random packets generated online (n=,17,34,68,85,170,850,1700,2500, 5000, 7500, 10000, 25000, 50000). Do the whole thing 100 times!"
  c_print "none" "Usage:" 0
  c_print "bold" "./random_srcip_dstport_srcport_attack_measurement.sh"
  c_print "none" "Example:"
  c_print "none" "./random_srcip_dstport_srcport_attack_measurement.sh"
  echo
  exit -1
}

ITERATION=100
R1=1
R2=65535

for i in 17 34 68 85 170 850 1700 2500  5000 7500 10000 25000 50000
do
  echo "i, megaflow_entries" > "random_srcip_dstport_srcport_attack_${i}.csv"

  mkdir -p ../pcap_generator/random_srcip_dport_sport/
  for iter in $(seq 1 $ITERATION)
  do

    c_print "blue" "[MAIN THREAD]\t Generate random packet sequence"
    python full_random_header_generator.py -n $i -abc > ../pcap_generator/random_srcip_dport_sport/SIP_SP_DP_${i}_${iter}.csv
    c_print "blue" "[MAIN THREAD]\t Generate pcap file from packet sequence"
    python ../pcap_generator/pcap_generator_from_csv.py -i ../pcap_generator/random_srcip_dport_sport/SIP_SP_DP_${i}_${iter}.csv --dst_ip 10.0.0.2 -o ../pcap_generator/random_srcip_dport_sport/SIP_SP_DP_${i}_${iter}
    c_print "green" "[DONE]"

    c_print "blue" "[MAIN THREAD]\t Add flow rule with a random port numbers"
    DIFF=$(($R2-$R1+1))
    R=$(($(($RANDOM%$DIFF))+$R1))
    sudo ovs-ofctl del-flows ovsbr
    sudo ovs-ofctl add-flow ovsbr "table=0,priority=1000,udp,in_port=1,nw_dst=10.0.0.2,tp_dst=${R},actions=output:2"
    sleep 1

    DIFF=$(($R2-$R1+1))
    R=$(($(($RANDOM%$DIFF))+$R1))
    sudo ovs-ofctl add-flow ovsbr "table=0,priority=1000,udp,in_port=1,nw_dst=10.0.0.2,tp_src=${R},actions=output:2"
    sleep 1
    c_print "green" "[DONE]"

    c_print "blue" "[MAIN THREAD]\t Add flow rule with a random source IP address" 0
    RANDOM_IP=$(echo $((RANDOM%256)).$((RANDOM%256)).$((RANDOM%256)).$((RANDOM%256)))
    sudo ovs-ofctl add-flow ovsbr "table=0,priority=1000,udp,in_port=1,nw_dst=10.0.0.2,nw_src=${RANDOM_IP},actions=output:2"
    sleep 1
    c_print "green" "[DONE]"

    c_print "blue" "[MAIN THREAD]\t Starting the attack..."
    ip netns exec ns1 tcpreplay -l 2 -q -t -i ns1_veth_ns ../pcap_generator/random_srcip_dport/SIP_SP_DP_${i}_${iter}.64bytes.pcap
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
