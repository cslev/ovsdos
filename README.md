# OVS-DoS a.k.a. Tuple Space Explosion:  Denial-of-Service Attack Against a Software Packet Classifier
Accompanying material for our the paper presented at CoNEXT'19.
Summary and main website of the project can be found here [ovs-dos.comp.nus.edu.sg/](https://sites.google.com/view/tuple-space-explosion)

**L. Csikor**, D. M. Divakaran, M. S. Kang, A. Kőrösi, B. Sonkoly, D. Haja, D.P. Pezaros, S. Schmid, G. Rétvári, "Tuple Space Explosion: A Denial-of-Service Attack Against a Software Packet Classifier", In proc. of ACM CoNEXT'19, Orlando, FL, USA, 2019, https://dl.acm.org/citation.cfm?doid=3359989.3365431.

The material described below is also accompanying further public showcases including, but not limited to the following venues:

**L. Csikor**, Min Suk Kang, Dinil Mon Divakaran, “The Discrepancy of the Megaflow Cache in OVS, Part II.” in OVS+OVN Conference, Red Hat, Westford, MA, 2019, https://bit.ly/35fFoKD.

**L. Csikor** and G. Rétvári, “The Discrepancy of the Megaflow Cache in OVS,” in Open vSwitch Fall Conference, Club Auto Sport, Santa Clara, CA, 2018, https://bit.ly/34idgVQ.

**L. Csikor**, C. Rothenberg, D. P. Pezaros, S. Schmid, L. Toka, and G. Rétvári, “Policy Injection: A Cloud Dataplane DoS Attack,” in Proceedings of the ACM SIGCOMM 2018 Conference on Posters and Demos, Budapest, Hungary, 2018, pp. 147-149, https://dl.acm.org/citation.cfm?id=3234250. 

## Summary
Packet classification is one of the fundamental building blocks of various security primitives and thus it needs to be highly efficient and available. In this paper, we evaluate whether the de facto packet classification algorithm (i.e., Tuple Space Search scheme, TSS) used in many popular software networking stacks, e.g., Open vSwitch, VPP, HyperSwitch, is robust against low-rate denial-of-service (DoS) attacks.

We present the Tuple Space Explosion (TSE) attack that exploits the fundamental space/time complexity of the TSS algorithm. We demonstrate that the TSE attack can degrade the switch performance to as low as 12% of its full capacity with a very low packet rate (i.e., 0.7 Mbps) when the target packet classification only has simple policies, e.g., "allow a few flows but drop all others".

We also show that if the adversary has partial knowledge of the installed classification policies, she can virtually bring down the packet classifier with the same low attack rate.

The TSE attack, in general, does not generate any specific attack traffic patterns but some attack packets with randomly chosen IP headers and arbitrary message contents. This makes it particularly hard to build a signature of our attack traffic for detection. Since the TSE attack exploits the fundamental complexity characteristics of the TSS algorithm, unfortunately, there seems to be no complete mitigation of the problem. We thus suggest, as a long-term solution, to use other packet classification algorithms (e.g., hierarchical tries, HaRP, Hypercuts) that are not vulnerable to the TSE attack.

As a short-term solution, we propose MFCGuard, a monitoring system that carefully manages the entries in the tuple space to keep packet classification fast for the packets that are eventually accepted by the system. 

## Video showcasing the demo
**L. Csikor**, C. Rothenberg, D. P. Pezaros, S. Schmid, L. Toka, and G. Rétvári, “Policy Injection: A Cloud Dataplane DoS Attack,” in Proceedings of the ACM SIGCOMM 2018 Conference on Posters and Demos, Budapest, Hungary, 2018, pp. 147-149, https://dl.acm.org/citation.cfm?id=3234250. 

[![Link to Youtube showcase](https://img.youtube.com/vi/eRrk7mlFCas/0.jpg)](https://www.youtube.com/watch?v=eRrk7mlFCas)



## Pathway to reproduce
First of all, due to security consideration, the steps to reproduce the attack were lacking of some information.
After spending more than a year on the project and its dissemination, we have decided to share our findings and let everyone to have a hand-on experience with corner-case of the Tuple Space Search algorithm implemented in the MegaFlow Cache of Open vSwitch (OVS).
Second, we present here the topology and attack method that always achieves the 'best'/worst results, i.e., the **co-located TSE attack** (please refer to the paper)!
It does not mean you cannot reproduce the **general TSE attack**, but since it requires you to send random packets, the way how you do it is up to you - we did not provide any details to that here.

### Topology
The topology contains two servers running two virtualized services each. 
The packet classification at the hypervisors, i.e., the virtualized hypervisor switch is materialized by OVS, which is responsible to get and put the packets from and to the VMs ant outside world.
The virtual services are supposed to cast into a KVM system, but other approaches might produce the same results (it is hard to say to definitely produce the same results, as there are many sophisticated way of packet processing  if workloads are not separated properly). 

So, corresponding servers are directly (and physically!) connected through a cable.

## Step-by-step guide
Here, we assume you have the topology mentioned above. In this topology, we will refer to the servers as *dione* and *titan*.
While *dione* will host VMs *Victim1* and *Attacker1*, *titan* will host VMs *Victim2* and *Attacker2*.
Correspondingly, the OVS running on *dione*  simply forwards the packets back and forth to *titan*, while *titan* is the hypervisor that will implement the malicious flow rules that when fed with arbitrary packets will cause the tuple space explosion in its megaflow cache. 


Our servers' parameters:
*Ubuntu 18.04*

OVS installed from repository and OVS datapath came from the stock kernel modules, i.e., openvswitch's version is *2.9.0*, and the kernel's version is *4.15.0-32*

### IMPORTANT
**The following actions must be executed on both servers (practically, one after each other) unless otherwise stated!**

### Setup up the topology

#### Clone repository
```
git clone https://github.com/cslev/ovsdos
git submodule update --init --recursive
cd ovsdos/tools_for_measurement/
```

#### Stop running OVS (if any)
Since you have OVS installed from the repository, first you need to be sure it is not running by default!
You can look for it by `ps aux|grep ovs` and manually kill/exit all the related process, or just simply run:
```
./stop_ovs.sh
```
Don't worry if it gives you some error messages regarding to non-existing or non-running programs. It tryies to ill everything irrespectively to their status.

#### Start OVS
Start an ovs-vswitchd instance on the servers.
```
./start_ovs.sh -o ovsbr
```
The name **ovsbr** name is important!

This brings up a *vswitchd*, but no ports are added at this point. Virtio ports 
will be added by initiating the VMs.

#### Creating the VMs (from scratch)
 - install related packages (with the dependencies it requires)
```
sudo apt-get install qemu-kvm qemu-system-common qemu-system-x86 qemu-utils virt-manager
```
 - download the provided [debian9.qcow](https://drive.google.com/file/d/1UA2iNO3YA_T52OPYn_bjFxHSXz0L905T/view?usp=sharing) image
 - create a VM with *virt-manager* (GUI, for brevity)
 - set name to *victim*
 - setup a NAT interface to get internet access (default networking setup when you create a VM) as *git update* might be 
necessary later.
 - assign memory and CPU cores to your VM (in our setup: 4096 MB mem, 2 CPUs)
 - set the downloaded *debian9.qcow* image as VM harddisk
 - save and quit virt-manager

We need to edit the created XML files manually to create new interfaces that will be attached to the OVS bridge.
```
sudo virsh edit victim
```
 - Look for the interface description (hint: Ctrl+F: interface)
 - Add new interface below the one existing as follows:
 ```
 <interface type='bridge'>
   <mac address='52:54:00:71:b1:b6'/>
   <source bridge='ovsbr'/>
   <virtualport type='openvswitch'/>
   <model type='virtio'/>
   <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
</interface>
 ```
Important part is the *type* set to **bridge**, and the *source* set to **ovsbr**.

Choose different MAC addresses for the two interfaces to avoid MAC collision. For easier future reference, I do recommend to change the last byte of the MAC addressess to `:11` and `:22` for the NAT and the OVS interface, respectively.

**However, bear in mind that according to the *domain,bus,slot* and *function*, the primary and secondary interfaces might get swapped. This can result in the following:**
 1) that on the host system, your *vnet0* and *vnet1* will be used for the OVS port and for the NAT (internet access), respectively, not the other way around how this description assumes
 2) the default DHCP querying interface might not the right one (if it is configured), check */etc/network/interfaces* in each VM accordingly
 3) The flow rules corresponding to the interfaces and their order can also be swapped. Manual tweaking of */tools_for_measurement/simple_forwarding.flows* and */tools_for_measuremet/malicious_acl.flows* might be required. Once you have identified which *vnetX* interface is for what (i.e., for NAT and OVS port), use *ovs-ofctl show ovsbr* command to get the correct port identifiers. See example below:
 ```
ovs-ofctl show ovsbr

OFPT_FEATURES_REPLY (xid=0x2): dpid:00001c34da5e0ed8
n_tables:254, n_buffers:0
capabilities: FLOW_STATS TABLE_STATS PORT_STATS QUEUE_STATS ARP_MATCH_IP
actions: output enqueue set_vlan_vid set_vlan_pcp strip_vlan mod_dl_src mod_dl_dst mod_nw_src mod_nw_dst mod_nw_tos mod_tp_src mod_tp_dst
 1(vnet1): addr:fe:54:00:95:82:21
     config:     0
     state:      0
     current:    10MB-FD COPPER
     speed: 10 Mbps now, 0 Mbps max
 2(vnet3): addr:fe:54:00:63:5e:22
     config:     0
     state:      0
     current:    10MB-FD COPPER
     speed: 10 Mbps now, 0 Mbps max
 3(ens2): addr:1c:34:da:5e:0e:d8
     config:     0
     state:      0
     current:    AUTO_NEG
     advertised: 1GB-FD 10GB-FD AUTO_NEG AUTO_PAUSE
     supported:  1GB-FD 10GB-FD AUTO_NEG AUTO_PAUSE
     speed: 0 Mbps now, 10000 Mbps max
 LOCAL(ovsbr): addr:1c:34:da:5e:0e:d8
     config:     PORT_DOWN
     state:      LINK_DOWN
     speed: 0 Mbps now, 0 Mbps max
OFPT_GET_CONFIG_REPLY (xid=0x4): frags=normal miss_send_len=0

 ```
 In order to have them in the correct order, do this:
 
 The `<address...> `tag should be copied from the descriptor of the original NAT interface, but change (i.e., increase with one) the `function='0xY'`.
Usually, the function is set to `0x0` for the original NAT interface, so setting it to `0x1` should be fine!
(Note: this means that your interfaces in the VM would have the same base name (i.e., `enp1s0XX`) and the NAT interface will be `...f0`, while the OVS interface will be `...f1`.
 
 - Save and exit

This addition will instruct the VM to have a secondary virtual NIC that will be connected to the OVS bridge instance we have started in the first step (hence, the inportance of the bridge name *ovsbr*).

Now, your victim VM is ready. In order to have an attacker VM as well, just clone the whole system (via virt-manager or via virsh command)
 - name your cloned system as *attacker*
```
sudo virt-clone --original victim --name attacker --auto-clone
```

 - (edit XML and add a new interface for OVS as mentioned above, if it has not been cloned properly)


#### Start your VMs via virsh:
```
sudo virsh start victim
sudo virsh start attacker
```

#### Access and configure the VMs
Each VM has an SSH server installed for easy access, but you can use the virsh console 
to access them:
**SSH user/pass = user/alskdj** (then for root use the same password).
Alternatively, you can use virsh console to access the VMs (e.g., `$ sudo virsh console victim`)

1) Login and update tooles
Login to each VM and update the repository of the required tools (if there is 
no update, you are good to go).
In each VM, go to the downloaded github repo (mind `#` in the prompt, i.e., be *root* in the VM):
```
cd /root/ovsdos
git pull
git submodule update --remote --merge
```

2) Configure interfaces in the VMs as follows:
 - *Victim1*:   `ifconfig ens3 10.1.1.1/24 up`
 - *Victim2*:   `ifconfig ens3 10.1.1.2/24 up`
 - *Attacker1*: `ifconfig ens3 10.0.0.1/24 up`
 - *Attacker2*: `ifconfig ens3 10.0.0.2/24 up`
 
 
### Add the physical interface to OVS:
Finally, add a physical interface to OVS and bring it up. Note that this physical interface is connected to the other server.
Bring up physical interfaces on each server (our is named as *ens3f0* at both hypervisors).

First, bring it up!
```
sudo ifconfig ens3f0 up
```

Add to OVS:
```
sudo ovs-vsctl add-port ovsbr ens3f0
```

Disable NIC offloading and jumboframes on the physical interface to achieve the 'best' results in terms of service degradation (why? - in a nutshell, to not decrease substantially the packet per second processing requirements (details are in the paper)).
```
sudo apt-get install ethtool
sudo ethtool -K ens3f0 tx off rx off gso off gro off tso off (rso off)
```

If you have carried out the steps in the same chronological order, then your 
OVS instance will have port 1 connected to the VICTIM, port 2 to the ATTACKER, 
and port 3 to the hypervisor.

**Don't forget to repeat these steps on the other server you use as hypervisor.**

### Configure OVS bridges on both servers
On the first hypervisor (*dione*), only basic flow rules are added to send traffic back 
and forth. 

**Bear in mind to tweak the *.flows* if necessary according to the vnetX devices and the order of ports added to OVS bridge**

To reach this end:
```
sudo ovs-ofctl add-flows ovsbr ovsdos/tools_for_measurements/simple_forwarding.flows
```

On the second hypervisor's (*titan*) OVS switch, install the specially crafted malicious 
flow table as below.
This contains the malicious ACL plus three simple flow rules (matching on the src and dst IPs and flooding ARPs, for brevity) for accommodating the victims' traffic between the servers.
```
sudo ovs-ofctl add-flows ovsbr ovsdor/tools_for_measurements/malicious_acl.flows
```

### Visualizing the whole experiment for easier understanding

#### Installing the necessary tools 
**NOTE, THE INSTALLING AND CONFIGURATION STEPS BELOW SHOULD ONLY BE DONE ONCE ON *titan* (WHERE THE MALICIOUS FLOW RULES ARE INSTALLED), AND ANY LATER EXPERIMENTS WILL NOT REQUIRE TO REINSTALL AND RECONFIGURE THESE THINGS ON THE HYPERVISORS**

**InfluxDB**

It might sound too fancy, but don't skip this step as further helper scripts assume that you want to visualize the results.

Download *influxdb*:
```
sudo curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
sudo  source /etc/lsb-release
sudo echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | tee /etc/apt/sources.list.d/influxdb.list
```
and install it:
```
sudo apt-get update
sudo apt-get install influxdb
```
Start influxdb:
```
sudo service influxdb start
```

Connect to influxdb via the cli to initialize the database:
```
sudo influx
```

Create databases as follows:
For the throughput results:
```
> create database iperf
```
For CPU and system statistics (telegraf install will be discussed later):
```
> create database telegraf
```
For watching OVS datapath cache statistics:
```
> create database ovs_cache
```
Quit influx

**TELEGRAPH monitoring tool**

Install telegraf via the provided .deb file (or download another one for your 
distribution):
```
sudo  cd ovsdos/tools_for_measurements/
sudo dpkg -i telegraf_0.10.2-1_amd64.deb
```

Open *telegraf.conf* and set your influxdb's url to *localhost:8086* (or any other 
you have set when you have installed influx - the one above is the default).


### Start scripts and tools for visualization
**INFLUXDB**

Should be running by default after the installation

**TELEGRAPH monitoring tool**

Start the telegraf monitoring system:
```
sudo telegraf -config telegraf.conf
```
**OVS cache monitoring script**

Start to monitor the cache-statistics of the OVS instance running on the second hypervisor (*titan*), where the malicious flow rules has been installed:
```
sudo cd ovsdos/tools_for_measurements/
sudo ./start_ovs_cache_log.sh
```


**GRAFANA, i.e., let's see the thing**

Download and run our containerized grafana image (available at dockerhub)
```
sudo docker run -d --name ovsdos_grafana -p 3000:3000 cslev/ovsdos_grafana
```
OR if you have already done once before, a corresponding docker image will exist on your system.
In this case, just start the container
```
sudo docker start ovsdos_grafana
```
This will run the container in the background, exposing TCP port 3000 for (remote) web access.
Grafana userinterface username/pass: admin/alskdj

Now, you can access the grafana webinterface at (http://your_hypervisor_ip:3000).
Click on the existing dashboard OVS_DOS.

As telegraf is already running, the topmost plot is already having valid data points corresponding to the system status. It monitors the system load and the softirq load; latter corresponds to packet processing from the NIC. Besides, as OVS cache-monitoring is also running, the corresponding second plot shows the current number of flows and masks in the megaflow cache as well.

OK, now monitoring is ready, proceed with the next steps.


### Start benign traffic
#### Start iperf server
On *titan*, login into *Victim2*. 
Start iperf server via the provided script (it will also send some data to *influxdb*, thereby making it visible in Grafana)
```
sudo cd /root/ovsdos/tools_for_measurements/
sudo ./start_iperf_server.sh
```

At the beginning, this will print out some meaningless error messages as below:
{"error":"unable to parse 'throughput,received=Gbit value=': missing field value"}
This is caused by that no client is connected to the iperf server yet and 
there is no measured data. Just ignore.

#### Start iperf client
On *dione* login/get into *Victim1*.
Start iperf client in a relatively infinite loop (via -t 10000 option)
```
sudo iperf3 -c 10.1.1.2 -t 10000
```
Now, in *Victim2*, the error message should have disappeared and throughput data should show up in *Victim1* in the Grafana panel.

### Prepare for the attack
Finally, we have reached the attack part :)
Now, we are ready to create some specially crafted packet sequence which will be then sent to the OVS instance running on the second hypervisor and will lead to a huge performance impact once subjected to the above malicious ACLs.
Login to *Attacker1* (on *dione*) and create packet sequences as follows:
```
sudo cd ovsdos/pcap_gen_ovs_dos
sudo ./pcap_generator_for_holepunch.py -t DP -o DP
sudo ./pcap_generator_for_holepunch.py -t SP_DP -o SP_DP
sudo ./pcap_generator_for_holepunch.py -t SIP_SP_DP -o SIP_SP_DP
sudo ./pcap_generator_for_holepunch.py -t SIP_DP -o SIP_DP
```
Each *-t XX* corresponds to which header field is used to attack on which ACL rule/header field: **DP** attacks only on the *destination port* and should have minor impact, while **SIP_SP_DP** attacks on the *source IP*, the *source port* and the *destination port* at the same time and should cause a complete denial of service.



#### Launch the attack
When packet traces are ready, let's play and send them from  towards *titan* where the OVS is residing with the malicious flow rules.
For brevity, we only use the **SIP_DP** trace as it is the most ubiquitous scenario that can be exploited in Kubernetes and Openstack, as injecting ACLs for filtering on the destination port and the source IP is allowed by each Cloud Management System by default.

When the attacker will send the malicious traffic, it uses *tcpreplay*! However, again for monitoring purposes, the corresponding *tcpreplay* command in bundled into a *script (start_attacker.sh)* that send some data to the *influxdb* running on the other hypervisor (*titan*).
Therefore, the *Attacker1* (on *dione*) needs access to the second hypervisor (again, *titan*) for logging purposes.
Since all VMs were configured in a way to have internet access, this should not be a problem.

However, the IP address of *titan* needs to be defined for the scripts.
To do this, open *start_attacker.sh* and set the *influx_server* variable properly.
```
sudo cd ovsdos/tools_for_measurements/
sudo  nano start_attacker.sh
```

Then, launch the attack via the script as follows:
```
sudo ./start_attacker.sh 100 ens3 ../pcap_gen_ovs_dos/SIP_DP.64bytes.pcap 64
```

Note that the first argument specifies the attacker's packet rate (*100 pps* (SIC!)); second argument defines the interface used to send the traffic (*ens3* in our running example); third argument is the location of the PCAP file, while the fourth is used to tell the script that the packet size in the PCAP is 64 bytes (this is used for calculating the attacker's sending throughput to visualize it in Grafana on *titan*).

After launching the attack, go to your Grafana plots, where everything can be seen clearly.
Briefly, here is what should happen:
1) Average CPU load increases,
2) softirq load, i.e., packet processing by the ovs datapath should become 
much larger,
3) number of megaflow entries and masks in the flow cache increases, which 
means flow cache load increases as well and OVS will need more time to 
classify each packet,
4) hroughput between the victims drastically drops, even though the attackers 
sending rate is barely seen.

#### Stop attack script 
(via Ctrl+C) and for sure, try to kill *tcpreplay* manually, too.
```
sudo pkill tcpreplay
```
As the megaflow cache is back to normal (wait 10 secs at least as the entires have 10 secs of expiration time), CPU/softirq 
load decreases, number of flows and masks returns to normal, an throughput becomes the usual (~10Gbit/s in our system).

