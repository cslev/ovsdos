# Policy Injection: A Cloud Dataplane DoS Attack - SIGCOMM'18 DEMO
Accompanying material for the SIGCOMM'18 Demo - Policy Injection: A Cloud Dataplane DoS Attack

### ABSTRACT
Enterprises continue to migrate their services into the cloud on a massive scale, but the increasing attack surface has
become natural target for malevolent actors. We show policy injection, a novel algorithmic complexity attack enabling
a tenant to add specially tailored ACLs into the data center fabric by exploiting the built-in security mechanisms
cloud management systems (CMS) offer to mount a denial-of-service attack. Our insight is that certain ACLs, when fed
with special covert packets by an attacker, may be very difficult to evaluate, leading to an exhaustion of cloud resources.
We show how a tenant can inject seemingly harmless ACLs into the cloud data plane to abuse an algorithmic deficiency
in the most popular cloud hypervisor switch, Open vSwitch, and reduce its effective peak performance by 80-90%, and, in
certain cases, denying network access.

### Video showcasing the demo
[![Link to Youtube showcase](https://img.youtube.com/vi/eRrk7mlFCas/0.jpg)](https://www.youtube.com/watch?v=eRrk7mlFCas)


### Steps to reproduce
First of all, try to fire up a topology shown in the video. If you only have a single laptop, use the following helper scripts from the tools_for_measurements/ directory:

Here, we assume you have a running implementation of *Open vSwitch*, and have the basic *ip* tools for your Linux distro to be able to create networking namespaces connected via an OVS. For the synthetic use case, we are going to create 4 namespaces (2 victim and 2 attacker pods) connected to OVS.

1. first initiate OVS with the required number of 4 namespaces
```
$ sudo ./start_ovs_kernel_with_namespaces.sh -o ovsbr -n 4
```

2. Assuming that the victim's pods are connected to port 1 and 2, and the attacker's are connected to port 3 and 4, add the flow rules written in *classic_holepunch_rules* to the OVS bridge instance as follows (the file now implements the worst case scenario, install malicious ACL w.r.t. the IP source and destination address and L4 source and destination ports as well):
```
$ sudo ovs-ofctl -OOpenflow13 add-flows ovsbr classic_holepunch_rules
```
In order to reduce the attack surface, remove the corresponding lines from *classic_holepunch_rules* - it is pretty straighforward to do so.

3. To ensure everything is working properly, get into the victim's pods, i.e., her namespaces, in two different terminals by
```
$ sudo ./get_into_namespace.sh ns1
$ sudo ./get_into_namespace.sh ns2
```
and try to do an iperf/ping between the namespaces (*ns1* has the IP 10.0.1.2, while *ns2* has the IP 10.0.2.2)

4. Now, get into the third namespace, i.e., the attackers first pod, connected to port 3 of the OVS.
```
$ sudo ./get_into_namespace.sh ns2
```

5. generate malicios PCAP traces according to the malevolent ACL you have chosen in step 2.
In case your ACL only filters destination port 80 (abbreviated to scenario DP), the corresponding packets can be generated as follows:
```
(ns3)$ cd ovsdos/pcap_gen_ovs_dos
(ns3)$ ./pcap_generator_for_holepunch.py -t DP --dst_port 80
```
Note that the pcap generator script is capable to encode any further specific L2/L3 headers in order to be applicable in CMS systems like Kubernetes/OpenStack where packets with spoofed destination MAC and/or destination IP are filtered out first hand before hitting our malicious ACL.


For the other use cases, where the ACL consists of the source port and source IP as well, use a similar way to generate the malicious packet sequence.
```
(ns3)$ ./pcap_generator_for_holepunch.py -h
```
This will print out the necessary information for those use cases, in particular, the *type* for L4 source and destination port attack scenario use *-t SP_DP*, and if source IP is also needed, use *-t SIP_SP_DP* and define the corresponding headers the ACL is matching on, i.e., addtional --src_port and --src_ip.

Note that for synthetic test scenarios, both the ACL flow rules and the PCAP generator are capable to carry out the attack on the destination IP as well (even if CMS system would filter those packets out first hand):
 - see the penultimate flow rule in *classic_holepunch_rules*
 - use *-t SIP_DIP_SP_DP*
