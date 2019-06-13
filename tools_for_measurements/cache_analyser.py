#! /usr/bin/env python3

# THIS PROGRAM IS INTENDED ANALYSE THE OVS MEGAFLOW CACHE DATA AND
# PRINT THEM OUT IN A MASKED/WILDCARDED WAY TO EASE THE UNDERSTANDING
# ACCORDING TO THE FLOW RULES YOU HAVE, YOU NEED TO INDICATE WHICH
# HEADERS ARE CONCERNED TO MAKE THE PARSER WORK PROPERLY


# import syss
# import os
import argparse
# import random
import ipaddress
import textwrap


def not_implemented(cache_file):
    print("This function is not implemented yet. Sorry :(")
    exit(-2)

def DP(cache_file):
    return

def get_wildcarded_rule(key, mask, bit_width):
    #convert key and mask to binary (they are strings in the beginning)
    # bear in mind the bit_width for padding
    key_bin  = format(int(key), str('0')+str(bit_width)+str('b'))

    mask_bin = format(int(mask), str('0')+str(bit_width)+str('b'))
    key_bin_list = list(key_bin)

    number_of_wildcarded_bits = 0
    for i,bit in enumerate(mask_bin):
        if bit == '0':
            key_bin_list[i] = '*'
            number_of_wildcarded_bits+=1
    masked_key = ''.join(key_bin_list)

    return (masked_key, number_of_wildcarded_bits)

def _SP_DP_analyzer(corresponding_part, only_sp=False, only_dp=False):
    '''
    This helper function should be called when the udp() part of the cache entry has been parsed
    Last parameters are needed when the use case does not need source port or destination port, but its value is masked resulting in calculatint its number of masked bits to the sum of all masked bits
    For example, in SIP_DP scenario SP might be 0/0xe000 which adds 13 extra numbers to the sum of all masked bits
    '''
    #example:
    #corresponding_part = 'udp(src=13312/0xfc00,dst=64/0xfff0'
    port_data=corresponding_part[4:]
    #check src port existance
    srt_port=""
    dst_port=""
    port_data = port_data.split(',')
    number_of_wildcarded_bits = 0
    #check data
    if (port_data[0]).startswith('src'):
        src_port = port_data[0].split('=')[1] #src=
        try:
            dst_port = port_data[1].split('=')[1] #dst=
        except IndexError:
            print("no dst_port")
            dst_port = "0/0x0000"
    else:
        #there was no src= at all
        src_port = '0/0x0000'
        dst_port = port_data[0].split('=')[1] #dst=

    # SRC PORT
    #let's do the masking
    src_key_mask = src_port.split('/')
    src_key=src_key_mask[0]
    #maybe there was no mask so getting the mask will be
    #handled via try-catch
    try:
        src_mask=src_key_mask[1]
    except IndexError:
        src_mask='0xffff'

    src_mask = int(src_mask,16)
    src_wildcarded = get_wildcarded_rule(src_key,
                                         src_mask,
                                         16)
    #src_wildcarded is a LIST)
    num_src_wildcarded_bits = src_wildcarded[1]
    src_wildcarded = src_wildcarded[0]

    #DST PORT
    dst_key_mask=dst_port.split('/')
    dst_key=dst_key_mask[0]
    #maybe there was no mask so getting the mask will be
    #handled via try-catch
    try:
        dst_mask=dst_key_mask[1]
    except IndexError:
        dst_mask='0xffff'

    dst_mask = int(dst_mask,16)
    dst_wildcarded = get_wildcarded_rule(dst_key,
                                         dst_mask,
                                         16)
    #dst_wildcarded is a LIST)
    num_dst_wildcarded_bits = dst_wildcarded[1]
    dst_wildcarded = dst_wildcarded[0]

    # check wildcarded bit number
    if only_sp:
        number_of_wildcarded_bits+=num_src_wildcarded_bits
    elif only_dp:
        number_of_wildcarded_bits+=num_dst_wildcarded_bits
    else:
        number_of_wildcarded_bits=num_src_wildcarded_bits+num_dst_wildcarded_bits

    return (src_port, src_mask,
            dst_port, dst_mask,
            src_wildcarded,
            dst_wildcarded,
            number_of_wildcarded_bits)



def SP_DP(cache_file):
    cache = open(cache_file, 'r')
    # output will be look like this:
    print("src_key/mask,\tdst_key/mask,\tsrc_wildcarded,\t\tdst_wildcarded,\t\t(number of wildcarded bits)")
    # one line in the cache raw data looks like this:
    #recirc_id(0),in_port(2),eth(),eth_type(0x0800),ipv4(src=10.0.0.1,dst=10.0.0.2,proto=17,frag=no),udp(src=12344,dst=16384/0xc000), packets:46316, bytes:2778960, used:0.001s, actions:3
    #iterate through the lines
    for line in cache:
        if line:
            line_segments=line.split('),')
            for i in line_segments:
                if i.startswith('udp'):
                    results = _SP_DP_analyzer(i)

                    src_port                  = results[0]
                    src_mask                  = results[1]
                    dst_port                  = results[2]
                    dst_mask                  = results[3]
                    src_wildcarded            = results[4]
                    dst_wildcarded            = results[5]
                    number_of_wildcarded_bits = results[6]
                    #prettify output
                    src_port=src_port+str(',')
                    if(src_mask=='0xffff'):
                        #there was no mask so 2 TABs are needed
                        src_port=src_port+str('\t')

                    #same thing for dst port
                    dst_port=dst_port+str(',')
                    if(dst_mask=='0xffff'):
                        #there was no mask so 2 TABs are needed
                        dst_port=dst_port+str('\t')

                    print("{}\t{}\t{},\t{}\t\t  (k={})".format(src_port, dst_port, src_wildcarded,dst_wildcarded, number_of_wildcarded_bits))




def _SIP_DP_analyzer(corresponding_part):
    '''
    This helper function should be called when the udp() part of the cache entry has been parsed
    '''

    # print("SIP_DP analyzer")

    #example:
    #corresponding_part = 'udp(src=13312/0xfc00,dst=64/0xfff0'
    ipv4_data=corresponding_part[5:]
    #check src port existance
    srt_ipv4=""
    dst_ipv4=""
    ipv4_data = ipv4_data.split(',')
    if (ipv4_data[0]).startswith('src'):
        src_ipv4 = ipv4_data[0].split('=')[1] #src=
        try:
            #if src_ipv4 is set, maybe dst_ip as well
            dst_ipv4 = ipv4_data[1].split('=')[1] #dst=
        except IndexError:
            dst_ipv4 = "0.0.0.0/0.0.0.0"
    else:
        src_ipv4 = "0.0.0.0/0.0.0.0"
        dst_ipv4 = ipv4_data[0].split('=')[1] #dst=

    # SRC IP
    #let's do the masking
    src_key_mask = src_ipv4.split('/')
    src_key=src_key_mask[0]
    #maybe there was no mask so getting the mask will be
    #handled via try-catch
    try:
        src_mask=src_key_mask[1]
    except IndexError:
        src_mask='255.255.255.255'


    # convert IP to Int
    src_key  = int(ipaddress.IPv4Address(src_key))
    src_mask_int = int(ipaddress.IPv4Address(src_mask))
    src_wildcarded = get_wildcarded_rule(src_key,
                                         src_mask_int,
                                         32)
    #src_wildcarded is a LIST)
    number_of_wildcarded_bits = src_wildcarded[1]
    src_wildcarded = src_wildcarded[0]



    #DST PORT
    dst_key_mask=dst_ipv4.split('/')
    dst_key=dst_key_mask[0]
    #maybe there was no mask so getting the mask will be
    #handled via try-catch
    try:
        dst_mask=dst_key_mask[1]
    except IndexError:
        dst_mask='255.255.255.255'

    dst_key  = int(ipaddress.IPv4Address(dst_key))
    dst_mask_int = int(ipaddress.IPv4Address(dst_mask))
    dst_wildcarded = get_wildcarded_rule(dst_key,
                                         dst_mask_int,
                                         32)

    #dst_wildcarded is a LIST)
    number_of_wildcarded_bits += dst_wildcarded[1]
    dst_wildcarded = dst_wildcarded[0]

    return (src_ipv4, src_mask,
            dst_ipv4, dst_mask,
            src_wildcarded,
            dst_wildcarded,
            number_of_wildcarded_bits)


def SIP_DP(cache_file):
    cache = open(cache_file, 'r')

    # output will be look like this:
    print("src_ip/mask,\t\t\t" \
          "dst_ip/mask," \
          "src_port/mask," \
          "dst_port/mask, "\
          "src_ip_wildcarded,\t\t  " \
          "dst_ip_wildcarded,\t\t    " \
          "src_port_wildcarded, " \
          "dst_port_wildcarded,\t" \
          "(number of wildcarded bits)")


    # one line in the cache raw data looks like this:
    # recirc_id(0),in_port(2),eth(),eth_type(0x0800),ipv4(src=10.0.8.0/255.255.248.0,dst=10.0.0.2,proto=17,frag=no),udp(src=0/0xe000,dst=128/0xff80), packets:13253, bytes:795180, used:0.001s, actions:drop

    relevant_header=False
    # #iterate through the lines
    for line in cache:
        if line:
            line_segments=line.split('),')
            for i in line_segments:
                # src_ipv4                       = "N/A"
                # src_ipv4_mask                  = "N/A"
                # dst_ipv4                       = "N/A"
                # dst_ipv4_mask                  = "N/A"
                # src_ipv4_wildcarded            = "N/A"
                # dst_ipv4_wildcarded            = "N/A"
                # number_of_wildcarded_bits_ipv4 = "N/A"
                # src_port                       = "N/A"
                # src_port_mask                  = "N/A"
                # dst_port                       = "N/A"
                # dst_port_mask                  = "N/A"
                # src_port_wildcarded            = "N/A"
                # dst_port_wildcarded            = "N/A"
                # number_of_wildcarded_bits_port = "N/A"
                # number_of_wildcarded_bits      = "N/A"
                if i.startswith('ipv4'):
                    # print("IPV4")
                    relevant_header = True
                    ipv4_results = _SIP_DP_analyzer(i)
                    src_ipv4                       = ipv4_results[0]
                    src_ipv4_mask                  = ipv4_results[1]
                    dst_ipv4                       = ipv4_results[2]
                    dst_ipv4_mask                  = ipv4_results[3]
                    src_ipv4_wildcarded            = ipv4_results[4]
                    dst_ipv4_wildcarded            = ipv4_results[5]
                    number_of_wildcarded_bits_ipv4 = ipv4_results[6]


                    #prettify output
                    # src_ipv4=src_ipv4+str(',')
                    # if(src_ipv4_mask=='255.255.255.255'):
                    #     #there was no mask so 2 TABs are needed
                    #     src_ipv4=src_ipv4+str('\t')
                    #
                    # #same thing for dst port
                    # dst_ipv4=dst_ipv4+str(',')
                    # if(dst_ipv4_mask=='255.255.255.255'):
                    #     #there was no mask so 2 TABs are needed
                    #     dst_ipv4=dst_ipv4+str('\t')

                    # print(src_ipv4,dst_ipv4)
                    # exit(-1)
                    continue

                if i.startswith('udp'):
                    relevant_header = True
                    port_results = _SP_DP_analyzer(i,only_dp=True)
                    src_port                       = port_results[0]
                    src_port_mask                  = port_results[1]
                    dst_port                       = port_results[2]
                    dst_port_mask                  = port_results[3]
                    src_port_wildcarded            = port_results[4]
                    dst_port_wildcarded            = port_results[5]
                    number_of_wildcarded_bits_port = port_results[6]
                else:
                    # print("i= {} -not good".format(i))
                    relevant_header=False
                    continue


                # if number_of_wildcarded_bits != "N/A":
                number_of_wildcarded_bits = int(number_of_wildcarded_bits_port) + int(number_of_wildcarded_bits_ipv4)

                #prettify output (IP)
                padding=",\t"
                if (len(src_ipv4) < 23):
                    padding+=str('\t')
                    if src_ipv4_mask == "255.255.255.255":
                        padding+=str('\t')

                src_ipv4 = src_ipv4+padding

                #prettify output (post)
                # print (len(dst_port))
                padding = ",\t"
                # print(len(dst_port))
                if (len(dst_port) < 11):
                    padding+=str('\t')
                    if (len(dst_port) < 4):
                        padding+=str('\t')

                dst_port+=padding

                if relevant_header:
                    print("{} {}, " \
                          "{} {} " \
                          "{} {}, " \
                          "{}\t{}, " \
                          "\t(k={})".format(src_ipv4,
                                          dst_ipv4,
                                          src_port,
                                          dst_port,
                                          src_ipv4_wildcarded,
                                          dst_ipv4_wildcarded,
                                          src_port_wildcarded,
                                          dst_port_wildcarded,
                                          number_of_wildcarded_bits))



def SIP_SP_DP(cache_file):
    return

parser = argparse.ArgumentParser(description="Analyse OVS MFC cache by filtering on specific header fields and convert the entries in a wildcarded way (e.g., 00010101********) to ease the understanding",
                                 usage="python cache_analyser.py -t [HEADER_TYPE] -i [INPUT_FILE]",
                                 formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument('-t','--type',nargs=1,
                    help=textwrap.dedent('''\
                         Specify the type: DP, SP_DP, SIP_DP, DIP_SP_DP, SIP_DIP_SP_DP.
                         \033[1mDP\033[0m will punch a hole only on the dst_port (udp) -> 17 packets!
                         \033[1mSP_DP\033[0m will punch holes on dst_port (UDP) and src_port (UDP) -> 17x17 packets
                         \033[1mSIP_DP\033[0m will punch holes on dst_port (UDP) and src_ip -> 17x33 packets
                         \033[1mSIP_SP_DP\033[0m will punch holes on dst_port (UDP), src_port (UDP) and dst_ip -> 17x17x33 packets
                         \033[1mSIP_DIP_DP\033[0m will punch holes on dst_port (UDP), dst_ip and src_ip -> 17x33x33
                         \033[1mSIP_DIP_SP_DP\033[0m will punch holes on dst_port (UDP), src_port (UDP), dst_ip and src_ip -> 17x17x33x33 packets'''),
                    required=True,default=["DP"])
parser.add_argument('-i','--input',nargs=1,
                    help="Specify the input file of the saved MFC cache entries!",
                    required=True, default=[None])




args = parser.parse_args()
# print args
type = args.type[0]
types = [
        'DP',
        'SP_DP',
        'SIP_DP',
        'SIP_DIP_DP',
        'SIP_SP_DP',
        'SIP_DIP_SP_DP'
        ]


dispatcher = {
            'DP':not_implemented, #DP
            'SP_DP' : SP_DP,
            'SIP_DP' : SIP_DP,
            'SIP_DIP_DP' : not_implemented,#SIP_DIP_DP,
            'SIP_SP_DP' : SIP_SP_DP,
            'SIP_DIP_SP_DP' : not_implemented, #SIP_DIP_SP_DP
}

if type not in types:
    print("Type has not set properly. Accepted fields:")
    print(types)
    exit(-1)

input = args.input[0]
if input is None:
    # this should never happen due to required parameter of input, but still :)
    print("Input file is not set!")
    exit(-1)

dispatcher[type](input)
