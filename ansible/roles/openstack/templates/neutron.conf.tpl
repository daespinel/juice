[neutron_interconnection]
region_name = {{ regionName }}
router_driver = bgpvpn
network_l3_driver = bgpvpn
network_l2_driver = bgpvpn
bgpvpn_rtnn = {{ rttLabels }}
username = neutron
password = secret
project = service

