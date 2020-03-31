#!/usr/bin/env python3
import sys, getopt
from keystoneauth1.identity import v3
from keystoneauth1 import session
from keystoneauth1.adapter import Adapter
from keystoneclient.v3 import client as keystoneclient
import swagger_client
from swagger_client.configuration import Configuration
from swagger_client.rest import ApiException
import time
from random import seed
from random import randint
import random
import datetime


def main(argv):

    opts, args = getopt.getopt(argv,"s:",["size="])

    FIRST_REGION_NAME = "RegionOne"
    KEYSTONE_ENDPOINT = "http://{{keystone_ip_node}}/identity/v3"
    #KEYSTONE_ENDPOINT = "http://192.168.57.6/identity/v3"


    def get_session_object(auth_param):
        return session.Session(auth=auth_param)


    def get_auth_object(keystone_endpoint):
        return v3.Password(
            username="admin",
            password="secret",
            project_name="demo",
            auth_url=keystone_endpoint,
            user_domain_id="default",
            project_domain_id="default",
            include_catalog=True,
            # Allow fetching a new token if the current one is going to expire
            reauthenticate=True
        )


    auth = get_auth_object(KEYSTONE_ENDPOINT)
    sess = get_session_object(auth)

    # Authenticate
    auth.get_access(sess)
    auth_ref = auth.auth_ref
    #print("Auth token: %s" %auth_ref.auth_token)

    catalog_endpoints = auth_ref.service_catalog.catalog
    #print("Service catalog: %s" % catalog_endpoints)

    regions_list = []

    for obj in catalog_endpoints:
        if obj['name'] == 'neutron':
            for endpoint in obj['endpoints']:
                obj = {'region_name' : endpoint["region"], 'url' : endpoint["url"]}
                regions_list.append(obj)

    #print(regions_list)

    cidrs_region_network_information = {'10.0.0.0/24': [], '10.0.1.0/24': [], '10.0.2.0/24': [], '10.0.3.0/24': [], '10.0.4.0/24': [], '10.0.5.0/24': [], '10.0.6.0/24': [], '10.0.7.0/24': [], '10.0.8.0/24': [], '10.0.9.0/24': [], '10.0.10.0/24': [], '10.0.11.0/24': [], '10.0.12.0/24': [], '10.0.13.0/24': [], '10.0.14.0/24': [], '10.0.15.0/24': [], '10.0.16.0/24': [], '10.0.17.0/24': [], '10.0.18.0/24': [], '10.0.19.0/24': [], '10.0.20.0/24': [], '10.0.21.0/24': [], '10.0.22.0/24': [], '10.0.23.0/24': [], '10.0.24.0/24': [], '10.0.25.0/24': [], '10.0.26.0/24': [], '10.0.27.0/24': [], '10.0.28.0/24': [], '10.0.29.0/24': [], '10.0.30.0/24': [], '10.0.31.0/24': [], '10.0.32.0/24': [], '10.0.33.0/24': [], '10.0.34.0/24': [], '10.0.35.0/24': [], '10.0.36.0/24': [], '10.0.37.0/24': [], '10.0.38.0/24': [], '10.0.39.0/24': [], '10.0.40.0/24': [], '10.0.41.0/24': [], '10.0.42.0/24': [], '10.0.43.0/24': [], '10.0.44.0/24': [], '10.0.45.0/24': [], '10.0.46.0/24': [], '10.0.47.0/24': [], '10.0.48.0/24': []}

    #cidrs_region_network_information = {'10.0.0.0/24': [], '20.0.0.0/24': []}

    # For every region find the networks created with heat
    for i in range(len(regions_list)):
        region_name, region_endpoint = regions_list[i]['region_name'], regions_list[i]['url']
        net_adap = Adapter(
            auth=auth,
            session=sess,
            service_type='network',
            interface='public',
            region_name=region_name)

        per_region_net_list = net_adap.get('/v2.0/networks').json()
        region_network = per_region_net_list['networks']

        # For every network find the cidr of the subnetwork it has
        for index in range(len(region_network)):
            net_ID = region_network[index]['id']
            subnet_ID = region_network[index]['subnets'][0]

            per_net_subnet = net_adap.get('/v2.0/subnets/'+subnet_ID).json()
            subnet_cidr = per_net_subnet['subnet']['cidr']
            #print(subnet_cidr)
            test_object = {
                'region_name': region_name,
                'net_uuid': net_ID,
            }
            cidrs_region_network_information[subnet_cidr].append(test_object)

    #print(cidrs_region_network_information)

    test_type1 = "L3"
    test_type2 = "L2"
    
    test_sizes_temps = (opts[0][1])
    test_sizes = test_sizes_temps.split(',')
    test_number = 1
    configuration = Configuration()

    for elem in test_sizes:
        test_size = int(elem)
        if(test_type1 == "L3"):
            file_results = open("results/Results_" + test_type1 + "_" + str(test_size) + "_"  +str(datetime.datetime.now().strftime("%H:%M:%S")),"w+")
            #file_results.write("L3\n")
            #file_results.write(str(test_size)+"\n")
            #file_results.write(str(test_number)+"\n")
            for i in range(test_number):
                seed(datetime.datetime.now())
                selected_index = randint(1,len(regions_list))
                host = regions_list[selected_index-1]
                #print(host['region_name'])
                configuration.host = host['url'][0:-5] + "7575/api"
                api_instance = swagger_client.ServicesApi(
                    swagger_client.ApiClient(configuration))

                service = swagger_client.Service()  # Service | data for inter-site creation
                service.type = "L3"
                service.name = "Inter-site network test " + str(i)
                
                condition = True
                keys = []
                regions = []
                resources = []
                
                while (condition):
                    seed(datetime.datetime.now())
                    key = random.choice(list(cidrs_region_network_information))
                    condition1 = True
                    while(condition1):
                        seed(datetime.datetime.now())
                        second_element = random.randint(1,len(cidrs_region_network_information[key]))
                        element = cidrs_region_network_information[key][second_element-1]
                        if element['region_name'] == host['region_name']:
                            #print(key)
                            #print(element)
                            keys.append(key)
                            regions.append(element['region_name'])
                            resources.append(element['region_name']+","+element['net_uuid'])
                            condition = False
                            condition1 = False
                            break

                for j in range(test_size-1):
                    #print(j)
                    condition = True
                    condition1 = True
                    while (condition and condition1):
                        seed(datetime.datetime.now())
                        key = random.choice(list(cidrs_region_network_information))
                        seed(datetime.datetime.now())
                        second_element = random.randint(1,len(cidrs_region_network_information[key]))
                        element = cidrs_region_network_information[key][second_element-1]
                        if element['region_name'] not in regions and key not in keys :
                            #print(key)
                            #print(element)
                            keys.append(key)
                            regions.append(element['region_name'])
                            resources.append(element['region_name']+","+element['net_uuid'])
                            condition = False
                            condition1 = False
                            break

                print(i)
                print(resources)
                print(regions)
                print(keys)

                service.resources = resources

                #start = time.clock()
                start = time.time()
                try:
                    # Horizontal request to create an inter-site Service POST
                    api_response = api_instance.vertical_create_service(service)
                    #print(api_response['service_global'])
                except ApiException as e:
                    print("Exception when calling VerticalApi->vertical_create_service: %s\\n" % e)
                
                #end = time.clock()
                end = time.time()
                
                print(api_response["service_global"])
                print(start)
                print(end)
                print(end-start)
                file_results.write(str(end - start)+"\n")

                try:
                    delete_service = api_instance.vertical_delete_service(api_response['service_global'])
                except ApiException as e:
                    print("Exception when calling VerticalApi->vertical_create_service: %s\n" % e)

            file_results.close()


        if(test_type2 == "L2"):
            file_results = open("results/Results_" + test_type2 + "_" + str(test_size)  + "_" +str(datetime.datetime.now().strftime("%H:%M:%S")),"w+")
            for i in range(test_number):
                seed(datetime.datetime.now())
                selected_index = randint(1,len(regions_list))
                host = regions_list[selected_index-1]
                #print(host['region_name'])
                configuration.host = host['url'][0:-5] + "7575/api"
                api_instance = swagger_client.ServicesApi(
                    swagger_client.ApiClient(configuration))

                service = swagger_client.Service()  # Service | data for inter-site creation
                service.type = "L2"
                service.name = "Inter-site network test " + str(i)
                
                condition = True
                regions = []
                resources = []

                while (condition):
                    seed(datetime.datetime.now())
                    key = random.choice(list(cidrs_region_network_information))
                    condition1 = True
                    while(condition1):            
                        second_element = random.randint(1,len(cidrs_region_network_information[key]))
                        element = cidrs_region_network_information[key][second_element-1]
                        if element['region_name'] == host['region_name']:

                            regions.append(element['region_name'])
                            resources.append(element['region_name']+","+element['net_uuid'])
                            condition = False
                            condition1 = False
                            break

                for j in range(test_size-1):
                    #print(j)
                    condition = True
                    while (condition):
                        seed(datetime.datetime.now())
                        new_index = randint(1,len(regions_list))
                        new_host = regions_list[new_index-1]
                        #print(host['region_name'])
                        if new_host['region_name'] not in regions:
                            regions.append(new_host['region_name'])
                            resources.append(new_host['region_name']+",")
                            condition = False
                            break

                print(i)
                print(resources)
                print(regions)
                print(keys)

                service.resources = resources
                api_responde = ""
                start = time.time()
                try:
                    # Horizontal request to create an inter-site Service POST
                    api_response = api_instance.vertical_create_service(service)
                    #print(api_response['service_global'])
                except ApiException as e:
                    print("Exception when calling VerticalApi->vertical_create_service: %s\n" % e)

                end = time.time()
                print(api_response["service_global"])
                print(end-start)
                file_results.write(str(end - start)+"\n")

                try:
                    delete_service = api_instance.vertical_delete_service(api_response['service_global'])
                except ApiException as e:
                    print("Exception when calling VerticalApi->vertical_create_service: %s\n" % e)

            file_results.close()




if __name__ == "__main__":
   main(sys.argv[1:])
