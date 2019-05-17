#! /usr/bin/env python

# THIS PROGRAM IS INTENDED TO GENERATE ALL POSSIBLE UDP PACKETS WHICH THE FIRST
# k BITS ARE DIFFERENT FOR, WHILE THE REST IS DON'T CARE (SAY, 0).
# IN OTHER WORDS, FOR k=2:
# 00**************
# 01**************
# 10**************
# 11**************

import sys
import os
from scapy.all import IP,UDP,TCP,Ether,sendp
import argparse

PID=str(os.getpid())
PID_FILE='all_k_bit.pid'
file(PID_FILE, 'w').write(PID)


def generate_packets(k, bit_width):
    '''
    k: the number of bits to generate all possibilities
    bit_width: the header length
    '''
    first_k_bits=list()
    for i in range(0,pow(2,k)):
        first_k_bits.append(format(i,'0'+str(k)+'b'))


    trailer=''
    for i in range(1,bit_width-k+1):
        trailer+='0'

    for i,j in enumerate(first_k_bits):
        # concatenating k and bit_width-k bits
        # transform binary strings back to integers at the same time
        first_k_bits[i]=int((j+trailer),2)

    return first_k_bits

def send(loop, port_list):
    for i in range(0,loop):
        for port in port_list:
            p=((Ether(src='00:11:22:33:44:55', dst='00:11:22:33:44:66')\
                /IP(src='10.0.0.1',dst='10.0.0.2')\
                /UDP(sport=12345,dport=port)))
            # p.show()

            sendp(p, iface=interface, verbose=False)


parser = argparse.ArgumentParser(description="Usage of all K bitwidth on dst port generator",
                                 usage="python generate_all_k_bitwidth_dst_port.py -l LOOP -b BITWIDTH -k NUMBER_OF_BITS_TO_HAVE_ALL_POSSIBILITES -i INTERFACE",
                                 formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument('-l','--loop',nargs=1,required=True)
parser.add_argument('-b','--bitwidth',nargs=1,required=False,default=["16"])
parser.add_argument('-k','--kk',nargs=1,required=True)
parser.add_argument('-i','--interface',nargs=1,required=False,default=["ns1_veth_ns"],
help="Specify the interface, default is: ns1_veth_ns")

args = parser.parse_args()
loop=int(args.loop[0])
bitwidth=int(args.bitwidth[0])
k=int(args.kk[0])

#setting the interface
interface=args.interface[0]

print generate_packets(k,bitwidth)
send(loop, generate_packets(k, bitwidth))



#whenever processing jumps here we delete pid file as not required anymore
os.unlink(PID_FILE)
