#!/bin/bash
ovsbr="ovsbr"

ip_src_hole="10.0.0.1"
ip_dst_hole="10.0.0.2"
dst_port_hole="80"
src_port_hole="12345"

victim_port_1="dpdk0"
victim_port_2="dpdk1"
victim_ip_1="10.0.1.2"
victim_ip_2="10.0.2.2"
attacker_port_1="ns1_veth_root"
attacker_port_2="ns2_veth_root"


ovs-ofctl add-flow $ovsbr "priority=1000,ip,in_port=${victim_port_1},ip_src=${victim_ip_1},ip_dst=${victim_ip_2},actions=output:${victim_port_2}"
ovs-ofctl add-flow $ovsbr "priority=1000,ip,in_port=${victim_port_2},ip_src=${victim_ip_2},ip_dst=${victim_ip_1},actions=output:${victim_port_1}"
ovs-ofctl add-flow $ovsbr "priority=1000,arp,actions=FLOOD"

ovs-ofctl add-flow $ovsbr "priority=1000,udp, in_port=${attacker_port_1}, tp_dst=${dst_port_hole},actions=drop"
ovs-ofctl add-flow $ovsbr "priority=1000,udp, in_port=${attacker_port_1}, tp_src=${src_port_hole},actions=drop"
ovs-ofctl add-flow $ovsbr "priority=1000,ip, in_port=${attacker_port_1}, ip_src=${ip_src_hole},actions=drop"
ovs-ofctl add-flow $ovsbr "priority=1000,ip, in_port=${attacker_port_1}, ip_dst=${ip_dst_hole},actions=drop"
ovs-ofctl add-flow $ovsbr "priority=10,in_port=${attacker_port_1},actions=output:${attacker_port_2}"


