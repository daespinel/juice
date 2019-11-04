[[local|localrc]]
FORCE=yes
#USE_PYTHON3=true

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
enable_plugin neutron-interconnection https://daespinel:MimasTitanBarcoMazda.123@github.com/daespinel/neutron-inter.git
enable_plugin rally https://github.com/openstack/rally-openstack
#enable_plugin heat https://git.openstack.org/openstack/heat stable/stein

NETWORKING_BGPVPN_DRIVER="BGPVPN:BaGPipe:networking_bgpvpn.neutron.services.service_drivers.bagpipe.bagpipe_v2.BaGPipeBGPVPNDriver:default"

#enable_service h-eng h-api h-api-cfn h-api-cw
enable_service b-bgp
#BAGPIPE_DATAPLANE_DRIVER_IPVPN=ovs
BAGPIPE_DATAPLANE_DRIVER_EVPN=ovs
BAGPIPE_BGP_PEERS={{ansible_eno2.ipv4.address}}
BAGPIPE_API_HOST=localhost

disable_service c-vol
disable_service tempest
disable_service cinder
disable_service etcd3
disable_service dstat
disable_service n-net
#disable_service heat

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
bgpvpn_rtnn = {{rttLabels|string}}
username = neutron
password = secret
project = service
check_state_interval = 5

[[post-config|$NOVA_CONF]]

[glance]
api_servers = http://{{ansible_eno1.ipv4.address}}/image
region_name = {{ regionName}}



