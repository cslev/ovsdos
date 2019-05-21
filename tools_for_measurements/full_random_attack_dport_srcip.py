#! /usr/bin/env python

# THIS PROGRAM IS INTENDED TO GENERATE RANDOM PACKETS ON A SPECIFIC HEADER
# FIELD, SAY DESTINATION PORT, AND SEND THEM OUT
# PARAMETERS: HEADER FIELD, HOW MANY RANDOM PACKETS, HOW MANY TIMES (LOOP TO
# SPREAD DEVIANCES OF ONE ATTACK USE CASE)


import sys
import os
from scapy.all import IP,UDP,TCP,Ether,sendp
import argparse
import random
import ipaddress

# PID=str(os.getpid())
# PID_FILE='full_random_attack.pid'
# file(PID_FILE, 'w').write(PID)


def getRandomIP():
    return str(ipaddress.IPv4Address(random.randint(1,0xffffffff)))

def convertInt2IP(integer_representation):
    return str(ipaddress.IPv4Address(integer_representation))

def generate_new_random_number(list_of_random_numbers, bit_width):
    '''
    list_of_random_numbers: list of already generated random numbers to avoid
    having the same number multiple times
    bit_width: on how many bits the random number should be generated
    '''
    r = random.randint(0,pow(2, bit_width))

    # #if bit_width is shorter than the number of random numbers we need
    # #we need to prevent looping the recursion
    # if(len(list_of_random_numbers) < pow(2,bitwidth)-1):
    if r in list_of_random_numbers:
        # print "regenerate as {} already exists".format(r)
        return generate_new_random_number(list_of_random_numbers, bit_width)
    else:
        return r


def generate_packets(n, bit_width):
    '''
    n: number of random numbers to generate
    bit_width: on how many bits the random number should be generated
    '''
    random_numbers=list()
    for i in range(0,n):
        random_numbers.append(generate_new_random_number(random_numbers, bit_width))

    return random_numbers

#
# def send(loop, port_list):
#     '''
#     This function practically sends out the packets with the generated random
#     ports 'loop' times
#     '''
#     for i in range(0,loop):
#         for port in port_list:
#             p=((Ether(src='00:11:22:33:44:55', dst='00:11:22:33:44:66')\
#                 /IP(src='10.0.0.1',dst='10.0.0.2')\
#                 /UDP(sport=12345,dport=port)))
#             # p.show()
#
#             sendp(p, iface=interface, verbose=False)
#
parser = argparse.ArgumentParser(description="Generate a certain number of unique random packets on a specified header field and repeat it for a certain number",
                                 usage="python full_random_attack.py -l LOOP -b BITWIDTH -n NUMBER_OF_PACKETS -i INTERFACE",
                                 formatter_class=argparse.RawTextHelpFormatter)
# parser.add_argument('-l','--loop', nargs=1, required=True,
# help="Specify how many times you want to generate and send NUMBER_OF_PACKETS packets! Use -l 0 to only print the ports! Useful for generating input to other programs")
# parser.add_argument('-b','--bitwidth', nargs=1, required=False,default=["16"],
# help="Pay attention to uniqueness, i.e., n < pow(2,bitwidth) !")
parser.add_argument('-n','--nn', nargs=1, required=True,
help="Number of different value for each header field! E.g., -n 16 means 16 random IP addresses combined with 16 random ports (resulting in 16*16 packets)")
# parser.add_argument('-i','--interface', nargs=1, required=False, default=["ns1_veth_ns"], help="Specify the interface, default is: ns1_veth_ns")
# parser.add_argument('-p','--print_only', action='store_true', required=False,
# help="Print out only the ports that generated - useful for other scripts as input (default: False)",
# dest='print_only')
# parser.set_defaults(print_only=False)



args = parser.parse_args()
# loop=int(args.loop[0])
# bitwidth=int(args.bitwidth[0])
n=int(args.nn[0])

#setting the interface
# interface=args.interface[0]

# print_only=args.print_only
# print print_only

#
# if n > pow(2,bitwidth):
#     print "ERROR - TOO MANY DIFFERENT NUMBERS ARE REQUIRED FOR THE GIVEN BIT WIDTH!"
#     print "!!!   n < pow(2,bitwidth) !!!"
#     exit(-1)



ports=generate_packets(n, 16)
tmp_ips=generate_packets(n, 32)
ips=list()
for i in tmp_ips:
    ips.append(convertInt2IP(i))

for i,port in enumerate(ports):
    print ("src_ip={},dst_port={}").format(ips[i],port)
# for p in ports:
#     print "dst_port={}".format(p)
# send(loop, ports)
