#!/usr/bin/env python3

import argparse
from scapy.all import *
#from scapy.layers.inet import IPv6, TCP
from random import shuffle
import struct
import ipaddress
import pprint

parser = argparse.ArgumentParser()
parser.add_argument('--src-mac', '-s', type=str, required=True,
                    help='Source MAC address')
parser.add_argument('--dst-mac', '-d', type=str, required=True,
                    help='Destination MAC address')
parser.add_argument('--src-ip', type=str, required=True,
                    help='Source IPv6 address')
parser.add_argument('--dst-ip', type=str, required=True,
                    help='Destination IPv6 address (SPOOFED)')
parser.add_argument('--dst-tcp', type=str, required=True,
                    help='Destination TCP port (SPOOFED)')
parser.add_argument('--protocol', type=str, required=False,
                    help='Destination  port protocol: UDP or TCP (default: TCP)',
        		    default=["tcp"])
parser.add_argument('--output', '-o', type=str, help='Output file',
                    default='/dev/stdout')
parser.add_argument('--shuffle', dest='shuffle',
                    help='Randomize packet order',
                    action='store_true')
parser.set_defaults(shuffle=False)
args = parser.parse_args()

p=[]

src_ip = ipaddress.IPv6Address(args.src_ip)
dst_tcp = int(args.dst_tcp)
proto = args.protocol[0]
proto = proto.lower()
print(proto)
if proto != "tcp" or proto != "udp":
    print("Protocol {} is unknown".format(proto))
    exit(-1)

exit(-1)
# src
src_ip_int  = int(src_ip)
src_ip_list = [ord(x) for x in list(struct.unpack("!16c", src_ip.packed))]

# pprint.pprint(src_ip_list)

for i in range(16):
    n = list(bin(src_ip_list[i])[2:].zfill(8))
    for j in range(8):
        s = src_ip_list[:]
        s[i] = s[i] - (1 << (7-j)) if int(n[j]) == 1 else s[i] + (1 << (7-j))
        spoof_sip = ipaddress.IPv6Address(bytes(s))

        # pprint.pprint(str(spoof_sip))
        # pprint.pprint(args.dst_ip)
        
        # dst port
        m = list(bin(dst_tcp)[2:].zfill(16))
        for k in range(16):
            # print("%s" % (bin(tcp_dst - (1 << (15-j)) if int(n[j]) == 1 else tcp_dst + (1 << (15-j)))[2:].zfill(16)))
            # print("%s" % (tcp_dst - (1 << (15-j)) if int(n[j]) == 1 else tcp_dst + (1 << (15-j))))
            spoof_dp = dst_tcp - (1 << (15-k)) if int(m[k]) == 1 else \
                       dst_tcp + (1 << (15-k))

            if proto == "tcp":
                p.append(Ether(src=args.src_mac, dst=args.dst_mac)/ \
                        IPv6(src=str(spoof_sip), dst=args.dst_ip)/ \
                        TCP(sport=20, dport=int(spoof_dp))/ \
                        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
            else:
                p.append(Ether(src=args.src_mac, dst=args.dst_mac) / \
                        IPv6(src=str(spoof_sip), dst=args.dst_ip) / \
                        UDP(sport=20, dport=int(spoof_dp)) / \
                        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")

            # p.append(IPv6(src=str(spoof_sip), dst=args.dst_ip)/ \
            #          TCP(sport=20, dport=int(spoof_dp))/ \
            #          "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
            
sys.stderr.write("Number of packets generated: %d\n" % len(p))

if args.shuffle == True:
    shuffle(p)

# for x in p: x.show()
wrpcap(args.output, p)

sys.exit(0)

