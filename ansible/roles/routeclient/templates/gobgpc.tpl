[global.config]
  as = 64512
  router-id = "{{ansible_eno2.ipv4.address}}" ## Router client IP address

[[neighbors]]
  [neighbors.config]
     neighbor-address = "{{hostvars[groups['routereflector'][reflector]].ansible_eno1.ipv4.address}}" ## Route reflector IP address
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
     neighbor-address = "{{ip_eno1.stdout}}" ## Main IP address (bagpipe client)
     peer-as = 64512
  [neighbors.transport.config]
     passive-mode = true
  [neighbors.route-reflector.config]
     route-reflector-client = true
     route-reflector-cluster-id = "{{ansible_eno2.ipv4.address}}" ## Router client IP address
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




