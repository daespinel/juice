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

  private_net11:
    type: OS::Neutron::Net
    properties:
      name: Network11

  private_subnet11:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net11 }
      cidr: 10.0.10.0/24

  private_net12:
    type: OS::Neutron::Net
    properties:
      name: Network12

  private_subnet12:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net12 }
      cidr: 10.0.11.0/24

  private_net13:
    type: OS::Neutron::Net
    properties:
      name: Network13

  private_subnet13:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net13 }
      cidr: 10.0.12.0/24

  private_net14:
    type: OS::Neutron::Net
    properties:
      name: Network14

  private_subnet14:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net14 }
      cidr: 10.0.13.0/24

  private_net15:
    type: OS::Neutron::Net
    properties:
      name: Network15

  private_subnet15:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net15 }
      cidr: 10.0.14.0/24

  private_net16:
    type: OS::Neutron::Net
    properties:
      name: Network16

  private_subnet16:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net16 }
      cidr: 10.0.15.0/24

  private_net17:
    type: OS::Neutron::Net
    properties:
      name: Network17

  private_subnet17:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net17 }
      cidr: 10.0.16.0/24

  private_net18:
    type: OS::Neutron::Net
    properties:
      name: Network18

  private_subnet18:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net18 }
      cidr: 10.0.17.0/24

  private_net19:
    type: OS::Neutron::Net
    properties:
      name: Network19

  private_subnet19:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net19 }
      cidr: 10.0.18.0/24

  private_net20:
    type: OS::Neutron::Net
    properties:
      name: Network20

  private_subnet20:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net20 }
      cidr: 10.0.19.0/24

  private_net21:
    type: OS::Neutron::Net
    properties:
      name: Network21

  private_subnet21:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net21 }
      cidr: 10.0.20.0/24

  private_net22:
    type: OS::Neutron::Net
    properties:
      name: Network22

  private_subnet22:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net22 }
      cidr: 10.0.21.0/24

  private_net23:
    type: OS::Neutron::Net
    properties:
      name: Network23

  private_subnet23:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net23 }
      cidr: 10.0.22.0/24

  private_net24:
    type: OS::Neutron::Net
    properties:
      name: Network24

  private_subnet24:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net24 }
      cidr: 10.0.23.0/24

  private_net25:
    type: OS::Neutron::Net
    properties:
      name: Network25

  private_subnet25:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net25 }
      cidr: 10.0.24.0/24

  private_net26:
    type: OS::Neutron::Net
    properties:
      name: Network26

  private_subnet26:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net26 }
      cidr: 10.0.25.0/24

  private_net27:
    type: OS::Neutron::Net
    properties:
      name: Network27

  private_subnet27:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net27 }
      cidr: 10.0.26.0/24

  private_net28:
    type: OS::Neutron::Net
    properties:
      name: Network28

  private_subnet28:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net28 }
      cidr: 10.0.27.0/24

  private_net29:
    type: OS::Neutron::Net
    properties:
      name: Network29

  private_subnet29:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net29 }
      cidr: 10.0.28.0/24

  private_net30:
    type: OS::Neutron::Net
    properties:
      name: Network30

  private_subnet30:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net30 }
      cidr: 10.0.29.0/24

  private_net31:
    type: OS::Neutron::Net
    properties:
      name: Network31

  private_subnet31:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net31 }
      cidr: 10.0.30.0/24

  private_net32:
    type: OS::Neutron::Net
    properties:
      name: Network32

  private_subnet32:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net32 }
      cidr: 10.0.31.0/24

  private_net33:
    type: OS::Neutron::Net
    properties:
      name: Network33

  private_subnet33:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net33 }
      cidr: 10.0.32.0/24

  private_net34:
    type: OS::Neutron::Net
    properties:
      name: Network34

  private_subnet34:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net34 }
      cidr: 10.0.33.0/24

  private_net35:
    type: OS::Neutron::Net
    properties:
      name: Network35

  private_subnet35:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net3( }
      cidr: 10.0.34.0/24

  private_net36:
    type: OS::Neutron::Net
    properties:
      name: Network36

  private_subnet36:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net36 }
      cidr: 10.0.35.0/24

  private_net37:
    type: OS::Neutron::Net
    properties:
      name: Network37

  private_subnet37:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net37 }
      cidr: 10.0.36.0/24

  private_net38:
    type: OS::Neutron::Net
    properties:
      name: Network38

  private_subnet38:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net38 }
      cidr: 10.0.37.0/24

  private_net39:
    type: OS::Neutron::Net
    properties:
      name: Network39

  private_subnet39:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net39 }
      cidr: 10.0.38.0/24

  private_net40:
    type: OS::Neutron::Net
    properties:
      name: Network40

  private_subnet40:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net40 }
      cidr: 10.0.39.0/24

  private_net41:
    type: OS::Neutron::Net
    properties:
      name: Network41

  private_subnet41:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net41 }
      cidr: 10.0.40.0/24

  private_net42:
    type: OS::Neutron::Net
    properties:
      name: Network42

  private_subnet42:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net42 }
      cidr: 10.0.41.0/24

  private_net43:
    type: OS::Neutron::Net
    properties:
      name: Network43

  private_subnet43:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net43 }
      cidr: 10.0.42.0/24

  private_net44:
    type: OS::Neutron::Net
    properties:
      name: Network44

  private_subnet44:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net44 }
      cidr: 10.0.43.0/24

  private_net45:
    type: OS::Neutron::Net
    properties:
      name: Network45

  private_subnet45:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net45 }
      cidr: 10.0.44.0/24

  private_net46:
    type: OS::Neutron::Net
    properties:
      name: Network46

  private_subnet46:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net46 }
      cidr: 10.0.45.0/24

  private_net47:
    type: OS::Neutron::Net
    properties:
      name: Network47

  private_subnet47:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net47 }
      cidr: 10.0.46.0/24

  private_net48:
    type: OS::Neutron::Net
    properties:
      name: Network48

  private_subnet48:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net48 }
      cidr: 10.0.47.0/24

  private_net49:
    type: OS::Neutron::Net
    properties:
      name: Network49

  private_subnet49:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net49 }
      cidr: 10.0.48.0/24



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
