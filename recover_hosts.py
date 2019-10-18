#!/usr/bin/env python3

import os
import subprocess


num2words = {1: 'One', 2: 'Two', 3: 'Three', 4: 'Four', 5: 'Five', \
             6: 'Six', 7: 'Seven', 8: 'Eight', 9: 'Nine', 10: 'Ten', \
            11: 'Eleven', 12: 'Twelve', 13: 'Thirteen', 14: 'Fourteen', \
            15: 'Fifteen', 16: 'Sixteen', 17: 'Seventeen', 18: 'Eighteen', \
            19: 'Nineteen', 20: 'Twenty', 30: 'Thirty', 40: 'Forty', \
            50: 'Fifty', 60: 'Sixty', 70: 'Seventy', 80: 'Eighty', \
            90: 'Ninety', 0: 'Zero'}

# Return the region name given an index
def n2w(n):
        try:
                return num2words[n]
        except KeyError:
                try:
                        return num2words[n-n%10] + num2words[n%10].lower()
                except KeyError:
                        return 'Number out of range'

# Retrieve the hosts granted in the reservation from OAR_NODE_FILE
retrieve_hosts_list = []
output = subprocess.check_output("cat $OAR_NODE_FILE", shell=True)
retrieve_hosts_list = output.split()
retrieve_hosts_list = list(dict.fromkeys(retrieve_hosts_list))

reflector_index = 0
client_index = 0
rtt_initial = 1000

# Write into the ansible hosts file to deploy the roles
host_file = open("ansible/hosts.ini","w+")
host_file.write("#[openstack]\n")


for i in range(6):
        rtt_for_neutron = str(rtt_initial) + "," + str(rtt_initial+1000-1)
        host_file.write("#Region" + str(n2w(i+1)) + " ansible_host=" + str(retrieve_hosts_list[i].decode('UTF-8')) + " regionName=Region" + str(n2w(i+1)) + " rttLabels=" + rtt_for_neutron + "\n")
        rtt_initial=rtt_initial + 1000

host_file.write("\n[routereflector]\n")
for i in range(6,9):
        host_file.write("RouterR" + str(n2w(i-5)) + " ansible_host=" + str(retrieve_hosts_list[i].decode('UTF-8')) + " routerName=RouterR" + str(n2w(i-5)) + " clients=" + str(client_index) + "\n")
        client_index = client_index + 2

host_file.write("\n[routeclient]\n")
for i in range(6):
        host_file.write("RouterC" + str(n2w(i+1))+" ansible_host=" + str(retrieve_hosts_list[i].decode('UTF-8')) + " routerName=RouterC" + str(n2w(i+1)) + " regionName=Region" + str(n2w(i+1)) + " reflector=" + str(reflector_index)+"\n")
        if ((i+1) % 2 == 0):
                reflector_index = reflector_index + 1

host_file.write("\n[routers]\n")
for i in range(9):
        host_file.write("Router"+str(n2w(i+1))+" ansible_host="+str(retrieve_hosts_list[i].decode('UTF-8'))+" routerName=Router"+str(n2w(i+1))+"\n")


host_file.close()

# Select the first keystone node master from the list
first_master = retrieve_hosts_list[0]
master_ip = subprocess.check_output("ssh root@"+ str(retrieve_hosts_list[0].decode('UTF-8'))+" ip a | grep eno1 | grep inet | cut -d/ -f1 | cut -d ' ' -f6-" ,shell=True).decode('UTF-8')[0:-1]

# Update the files where the keystone master IP node is called
replace_ip = subprocess.check_output("sed -i 's/keystone_ip_node:.*/keystone_ip_node: '"+ master_ip +"'/g' ansible/group_vars/all.yml ", shell=True)
replace_auth = subprocess.check_output("sed -i 's/OS_AUTH_URL:.*/OS_AUTH_URL: '"+ master_ip +"'/g' ansible/group_vars/all.yml ", shell=True)

