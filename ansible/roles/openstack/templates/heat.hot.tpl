heat_template_version: 2013-05-23

description:
  This Heat template creates 10 networks and their respective subnetworks

resources:
  private_net1:
    type: OS::Neutron::Net
    properties:
      name: Network1

  private_subnet1:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net1 }
      cidr: 10.0.0.0/24

  private_net2:
    type: OS::Neutron::Net
    properties:
      name: Network2

  private_subnet2:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net2 }
      cidr: 10.0.1.0/24

  private_net3:
    type: OS::Neutron::Net
    properties:
      name: Network3

  private_subnet3:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net3 }
      cidr: 10.0.2.0/24

  private_net4:
    type: OS::Neutron::Net
    properties:
      name: Network4

  private_subnet4:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net4 }
      cidr: 10.0.3.0/24

  private_net5:
    type: OS::Neutron::Net
    properties:
      name: Network5

  private_subnet5:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net5 }
      cidr: 10.0.4.0/24

  private_net6:
    type: OS::Neutron::Net
    properties:
      name: Network6

  private_subnet6:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net6 }
      cidr: 10.0.5.0/24

  private_net7:
    type: OS::Neutron::Net
    properties:
      name: Network7

  private_subnet7:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net7 }
      cidr: 10.0.6.0/24

  private_net8:
    type: OS::Neutron::Net
    properties:
      name: Network8

  private_subnet8:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net8 }
      cidr: 10.0.7.0/24

  private_net9:
    type: OS::Neutron::Net
    properties:
      name: Network9

  private_subnet9:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net9 }
      cidr: 10.0.8.0/24

  private_net10:
    type: OS::Neutron::Net
    properties:
      name: Network10

  private_subnet10:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net10 }
      cidr: 10.0.9.0/24


  server_security_group:
    type: OS::Neutron::SecurityGroup
    properties:
      name: security_group
      rules: [
        {remote_ip_prefix: 0.0.0.0/0,
        direction: egress,
        protocol: tcp,
        port_range_min: 1,
        port_range_max: 65535},
        {remote_ip_prefix: 0.0.0.0/0,
        direction: ingress,
        protocol: tcp,
        port_range_min: 1,
        port_range_max: 65535},
        {remote_ip_prefix: 0.0.0.0/0,
        direction: egress,
        protocol: udp,
        port_range_min: 1,
        port_range_max: 65535},
        {remote_ip_prefix: 0.0.0.0/0,
        direction: ingress,
        protocol: udp,
        port_range_min: 1,
        port_range_max: 65535},
        {remote_ip_prefix: 0.0.0.0/0,
        direction: egress,
        protocol: icmp},
        {remote_ip_prefix: 0.0.0.0/0,
        direction: ingress,
        protocol: icmp}]
