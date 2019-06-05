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
    r = random.randint(0,pow(2, bit_width)-1)

    # #if bit_width is shorter than the number of random numbers we need
    # #we need to prevent looping the recursion
    # if(len(list_of_random_numbers) < pow(2,bitwidth)-1):
    if r in list_of_random_numbers and len(list_of_random_numbers) < pow(2,bit_width)-1:
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
parser = argparse.ArgumentParser(description="Generate a certain number of random packets having different source IP and destination port (check out the arguments for details to have cross product)",
                                 usage="python full_random_attack_dport_srcip.py -n <Number of packets> -c",
                                 formatter_class=argparse.RawTextHelpFormatter)

# parser.add_argument('-l','--loop', nargs=1, required=True,
# help="Specify how many times you want to generate and send NUMBER_OF_PACKETS packets! Use -l 0 to only print the ports! Useful for generating input to other programs")
# parser.add_argument('-b','--bitwidth', nargs=1, required=False,default=["16"],
# help="Pay attention to uniqueness, i.e., n < pow(2,bitwidth) !")
parser.add_argument('-n','--nn', nargs=1, required=True,
help="Number of different values for each header field! E.g., -n 16 means 16 random IP addresses with 16 random ports (resulting in 16 packets)")

parser.add_argument('-a','--dst_port', action='store_true', required=False, dest='dst_port',
help="Enabling random dst_port generation")
parser.set_defaults(dst_port=False)

parser.add_argument('-b','--src_ip', action='store_true', required=False, dest='src_ip',
help="Enabling random src_ip generation")
parser.set_defaults(src_ip=False)

parser.add_argument('-c','--src_port', action='store_true', required=False, dest='src_port',
help="Enabling random src_port generation")
parser.set_defaults(src_port=False)


# parser.add_argument('-c','--crossproduct', action='store_true', required=False, dest='crossproduct',
# help="Enabling crossproduct - For each random IP there will be <number of packets> (set by -n argument) different ports resulting in <number of packets> times <number of packets> packets, e.g., -n 16 means 16*16 packets")
# parser.set_defaults(crossproduct=False)





args = parser.parse_args()
# loop=int(args.loop[0])
# bitwidth=int(args.bitwidth[0])
n=int(args.nn[0])
# w=args.crossproduct
dst_port=args.dst_port
src_ip=args.src_ip
src_port=args.src_port

if not dst_port and not src_ip and not src_port:
    print "ERROR: at least one of the header fields needs to be set to be randomized!"
    print "Use --help to study the arguments!"
    exit(-1)


# print "Number of packets to be generated:"
# if w:
#     print("{}".format(n*n))
# else:
#     print("{}".format(n))

if dst_port:
    dst_ports=generate_packets(n, 16)

if src_ip:
    tmp_ips=generate_packets(n, 32)
    ips=list()
    for i in tmp_ips:
        ips.append(convertInt2IP(i))

if src_port:
    src_ports=generate_packets(n, 16)


only_one_header=False
only_two_header=False
three_header=False

if (dst_port and not src_port and not src_ip) or (not dst_port and src_port and not src_ip) or (not dst_port and not src_port and src_ip):
    only_one_header=True
elif (dst_port and src_port and not src_ip) or (dst_port and not src_port and src_ip) or (not dst_port and src_port and src_ip):
    only_two_header=True
else:
    three_header=True



if only_one_header:
    # if w:
    #     if src_ip and dst_port and not src_port:
    #         for ip in ips:
    #             for port in dst_ports:
    #                     print ("src_ip={},dst_port={}").format(ip,port)
    #     if src_ip and src_port and not dst_port:
    #         for ip in ips:
    #             for port in src_ports:
    #                     print ("src_ip={},src_port={}").format(ip,port)
    #     if  not src_ip and dst_port
    #
    # else:
    if dst_port:
        for port in dst_ports:
            print ("dst_port={}").format(port)
    if src_port:
        for port in src_ports:
            print ("src_port={}").format(port)
    if src_ip:
        for ip in ips:
            print ("src_ip={}").format(ip)
elif only_two_header:
    if dst_port and src_ip:
        for i,ip in enumerate(ips):
            print ("src_ip={},dst_port={}").format(ip,dst_ports[i])
    elif dst_port and src_port:
        for i,port in enumerate(dst_ports):
            print ("dst_port={},src_port={}").format(port,src_ports[i])
    elif src_port and src_ip:
        for i,ip in enumerate(ips):
            print ("src_ip={},src_port={}").format(ip,src_ports[i])

else:
    for i,ip in enumerate(ips):
        print("src_ip={},dst_port={},src_port={}".format(ip,dst_ports[i],src_ports[i]))
