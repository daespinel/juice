[[local|localrc]]
FORCE=yes

HOST_IP={{ansible_eno1.ipv4.address}}
REGION_NAME={{ regionName }}
{% if regionName != 'RegionOne' %}
KEYSTONE_SERVICE_HOST={{ keystone_ip_node}}
KEYSTONE_AUTH_HOST={{ keystone_ip_node}}
KEYSTONE_REGION_NAME=RegionOne
{% endif %}
NEUTRON_CREATE_INITIAL_NETWORKS=False

LOGFILE=/opt/stack/logs/stack.sh.log
VERBOSE=True
LOGDAYS=1

ENABLE_IDENTITY_V2=False

DATABASE_PASSWORD=secret
RABBIT_PASSWORD=secret
SERVICE_PASSWORD=secret
ADMIN_PASSWORD=secret

enable_plugin networking-bgpvpn https://git.openstack.org/openstack/networking-bgpvpn.git stable/stein
enable_plugin networking-bagpipe https://git.openstack.org/openstack/networking-bagpipe.git stable/stein
## Need to change contraints and requirements https://opendev.org/openstack/networking-odl/commit/48f9f5782149cb0b04b71806d414330c1a3c4709
## delete line 29 of /usr/local/lib/python2.7/dist-packages/networking_sfc/db/flowclassifier_db.py where query is used
## delete line 32 of /usr/local/lib/python2.7/dist-packages/networking_sfc/db/sfc_db.py
## delete line 19 of /usr/local/lib/python2.7/dist-packages/networking_sfc/services/sfc/drivers/ovs/db.py
## sudo apt-get install openvswitch-switch
## Create a br-mpls bridge

enable_plugin neutron-interconnection https://daespinel:MimasTitanBarcoMazda.123@github.com/daespinel/neutron-inter.git

NETWORKING_BGPVPN_DRIVER="BGPVPN:BaGPipe:networking_bgpvpn.neutron.services.service_drivers.bagpipe.bagpipe_v2.BaGPipeBGPVPNDriver:default"


enable_service b-bgp
#BAGPIPE_DATAPLANE_DRIVER_IPVPN=ovs
BAGPIPE_DATAPLANE_DRIVER_EVPN=ovs
BAGPIPE_BGP_PEERS=10{{ansible_eno1.ipv4.address[3:]}}
BAGPIPE_API_HOST=localhost

disable_service c-vol
disable_service tempest
disable_service cinder
disable_service etcd3
disable_service dstat
disable_service n-net
disable_service heat

# Enable l2population for vxlan network
[[post-config|/$Q_PLUGIN_CONF_FILE]]

[ml2]
mechanism_drivers = openvswitch,linuxbridge,l2population

#[agent]
#tunnel_types=vxlan
#l2_population=True
#arp_responder=True

[[post-config|$NEUTRON_CONF]]

[neutron_interconnection]
region_name = {{ regionName }}
router_driver = bgpvpn
network_l3_driver = bgpvpn
network_l2_driver = bgpvpn
bgpvpn_rtnn = {{ rttLabels }}
username = neutron
password = secret
project = service




