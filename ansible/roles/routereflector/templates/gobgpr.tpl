[global.config]
  as = 64512
  router-id = "{{ip_eno1.stdout}}" # Router address

[[neighbors]]
  [neighbors.config]
{% if routerName == 'RouterROne'%}
     neighbor-address = "{{hostvars['RouterRTwo'].ansible_eno1.ipv4.address}}" # Neighbor router address
{% else %}
     neighbor-address = "{{hostvars['RouterROne'].ansible_eno1.ipv4.address}}" # Neighbor router address
{% endif %}
     peer-as = 64512
[[neighbors.afi-safis]]
  [neighbors.afi-safis.config]
      afi-safi-name = "l2vpn-evpn"
  [[neighbors.afi-safis]]
  [neighbors.afi-safis.config]
      afi-safi-name = "l3vpn-ipv4-unicast"
  [[neighbors.afi-safis]]
  [neighbors.afi-safis.config]
      afi-safi-name = "l3vpn-ipv4-flowspec"
  [[neighbors.afi-safis]]
  [neighbors.afi-safis.config]
      afi-safi-name = "rtc"


[[neighbors]]
  [neighbors.config]
{% if routerName == 'RouterRThree'%}
     neighbor-address = "{{hostvars['RouterRTwo'].ansible_eno1.ipv4.address}}" # Neighbor router address
{% else %}
     neighbor-address = "{{hostvars['RouterRThree'].ansible_eno1.ipv4.address}}" # Neighbor router address
{% endif %}
     peer-as = 64512
[[neighbors.afi-safis]]
  [neighbors.afi-safis.config]
      afi-safi-name = "l2vpn-evpn"
  [[neighbors.afi-safis]]
  [neighbors.afi-safis.config]
      afi-safi-name = "l3vpn-ipv4-unicast"
  [[neighbors.afi-safis]]
  [neighbors.afi-safis.config]
      afi-safi-name = "l3vpn-ipv4-flowspec"
  [[neighbors.afi-safis]]
  [neighbors.afi-safis.config]
      afi-safi-name = "rtc"

#Loop for clients
{% for cli in servers_route_clients if hostvars[cli].reflector == routerName %}
[[neighbors]]
  [neighbors.config]
     neighbor-address = "{{hostvars[cli].ansible_eno2.ipv4.address}}" # routeclient address
     peer-as = 64512
  [neighbors.transport.config]
     passive-mode = true
  [neighbors.route-reflector.config]
     route-reflector-client = true
     route-reflector-cluster-id = "{{ip_eno1.stdout}}"
  [[neighbors.afi-safis]]
  [neighbors.afi-safis.config]
      afi-safi-name = "l2vpn-evpn"
  [[neighbors.afi-safis]]
  [neighbors.afi-safis.config]
      afi-safi-name = "l3vpn-ipv4-unicast"
  [[neighbors.afi-safis]]
  [neighbors.afi-safis.config]
      afi-safi-name = "l3vpn-ipv4-flowspec"
  [[neighbors.afi-safis]]
  [neighbors.afi-safis.config]
    afi-safi-name = "rtc"

{% endfor %}
