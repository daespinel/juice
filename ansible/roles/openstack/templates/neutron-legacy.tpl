{% raw %}
#!/bin/bash
#
# lib/neutron
# functions - functions specific to neutron

# Dependencies:
# ``functions`` file
# ``DEST`` must be defined
# ``STACK_USER`` must be defined

# ``stack.sh`` calls the entry points in this order:
#
# - install_neutron_agent_packages
# - install_neutronclient
# - install_neutron
# - install_neutron_third_party
# - configure_neutron
# - init_neutron
# - configure_neutron_third_party
# - init_neutron_third_party
# - start_neutron_third_party
# - create_nova_conf_neutron
# - configure_neutron_after_post_config
# - start_neutron_service_and_check
# - check_neutron_third_party_integration
# - start_neutron_agents
# - create_neutron_initial_network
#
# ``unstack.sh`` calls the entry points in this order:
#
# - stop_neutron
# - stop_neutron_third_party
# - cleanup_neutron

# Functions in lib/neutron are classified into the following categories:
#
# - entry points (called from stack.sh or unstack.sh)
# - internal functions
# - neutron exercises
# - 3rd party programs


# Neutron Networking
# ------------------

# Make sure that neutron is enabled in ``ENABLED_SERVICES``.  If you want
# to run Neutron on this host, make sure that q-svc is also in
# ``ENABLED_SERVICES``.
#
# See "Neutron Network Configuration" below for additional variables
# that must be set in localrc for connectivity across hosts with
# Neutron.
#
# With Neutron networking the NETWORK_MANAGER variable is ignored.

# Settings
# --------


# Neutron Network Configuration
# -----------------------------

deprecated "Using lib/neutron-legacy is deprecated, and it will be removed in the future"

if is_service_enabled tls-proxy; then
    Q_PROTOCOL="https"
fi


# Set up default directories
GITDIR["python-neutronclient"]=$DEST/python-neutronclient


NEUTRON_DIR=$DEST/neutron
NEUTRON_FWAAS_DIR=$DEST/neutron-fwaas
NEUTRON_AUTH_CACHE_DIR=${NEUTRON_AUTH_CACHE_DIR:-/var/cache/neutron}

# Support entry points installation of console scripts
if [[ -d $NEUTRON_DIR/bin/neutron-server ]]; then
    NEUTRON_BIN_DIR=$NEUTRON_DIR/bin
else
    NEUTRON_BIN_DIR=$(get_python_exec_prefix)
fi

NEUTRON_CONF_DIR=/etc/neutron
NEUTRON_CONF=$NEUTRON_CONF_DIR/neutron.conf
export NEUTRON_TEST_CONFIG_FILE=${NEUTRON_TEST_CONFIG_FILE:-"$NEUTRON_CONF_DIR/debug.ini"}

# NEUTRON_DEPLOY_MOD_WSGI defines how neutron is deployed, allowed values:
# - False (default) : Run neutron under Eventlet
# - True : Run neutron under uwsgi
# TODO(annp): Switching to uwsgi in next cycle if things turn out to be stable
# enough
NEUTRON_DEPLOY_MOD_WSGI=$(trueorfalse False NEUTRON_DEPLOY_MOD_WSGI)

NEUTRON_UWSGI_CONF=$NEUTRON_CONF_DIR/neutron-api-uwsgi.ini

# Agent binaries.  Note, binary paths for other agents are set in per-service
# scripts in lib/neutron_plugins/services/
AGENT_DHCP_BINARY="$NEUTRON_BIN_DIR/neutron-dhcp-agent"
AGENT_L3_BINARY=${AGENT_L3_BINARY:-"$NEUTRON_BIN_DIR/neutron-l3-agent"}
AGENT_META_BINARY="$NEUTRON_BIN_DIR/neutron-metadata-agent"

# Agent config files. Note, plugin-specific Q_PLUGIN_CONF_FILE is set and
# loaded from per-plugin  scripts in lib/neutron_plugins/
Q_DHCP_CONF_FILE=$NEUTRON_CONF_DIR/dhcp_agent.ini
Q_L3_CONF_FILE=$NEUTRON_CONF_DIR/l3_agent.ini
Q_META_CONF_FILE=$NEUTRON_CONF_DIR/metadata_agent.ini

# Default name for Neutron database
Q_DB_NAME=${Q_DB_NAME:-neutron}
# Default Neutron Plugin
Q_PLUGIN=${Q_PLUGIN:-ml2}
# Default Neutron Port
Q_PORT=${Q_PORT:-9696}
# Default Neutron Internal Port when using TLS proxy
Q_PORT_INT=${Q_PORT_INT:-19696}
# Default Neutron Host
Q_HOST=${Q_HOST:-$SERVICE_HOST}
# Default protocol
Q_PROTOCOL=${Q_PROTOCOL:-$SERVICE_PROTOCOL}
# Default listen address
Q_LISTEN_ADDRESS=${Q_LISTEN_ADDRESS:-$(ipv6_unquote $SERVICE_LISTEN_ADDRESS)}
# Default admin username
Q_ADMIN_USERNAME=${Q_ADMIN_USERNAME:-neutron}
# Default auth strategy
Q_AUTH_STRATEGY=${Q_AUTH_STRATEGY:-keystone}
# RHEL's support for namespaces requires using veths with ovs
Q_OVS_USE_VETH=${Q_OVS_USE_VETH:-False}
Q_USE_ROOTWRAP=${Q_USE_ROOTWRAP:-True}
Q_USE_ROOTWRAP_DAEMON=$(trueorfalse True Q_USE_ROOTWRAP_DAEMON)
# Meta data IP
Q_META_DATA_IP=${Q_META_DATA_IP:-$(ipv6_unquote $SERVICE_HOST)}
# Allow Overlapping IP among subnets
Q_ALLOW_OVERLAPPING_IP=${Q_ALLOW_OVERLAPPING_IP:-True}
Q_NOTIFY_NOVA_PORT_STATUS_CHANGES=${Q_NOTIFY_NOVA_PORT_STATUS_CHANGES:-True}
Q_NOTIFY_NOVA_PORT_DATA_CHANGES=${Q_NOTIFY_NOVA_PORT_DATA_CHANGES:-True}
VIF_PLUGGING_IS_FATAL=${VIF_PLUGGING_IS_FATAL:-True}
VIF_PLUGGING_TIMEOUT=${VIF_PLUGGING_TIMEOUT:-300}

# The directory which contains files for Q_PLUGIN_EXTRA_CONF_FILES.
# /etc/neutron is assumed by many of devstack plugins.  Do not change.
_Q_PLUGIN_EXTRA_CONF_PATH=/etc/neutron

# List of config file names in addition to the main plugin config file
# To add additional plugin config files, use ``neutron_server_config_add``
# utility function.  For example:
#
#    ``neutron_server_config_add file1``
#
# These config files are relative to ``/etc/neutron``.  The above
# example would specify ``--config-file /etc/neutron/file1`` for
# neutron server.
declare -a -g Q_PLUGIN_EXTRA_CONF_FILES

# same as Q_PLUGIN_EXTRA_CONF_FILES, but with absolute path.
declare -a -g _Q_PLUGIN_EXTRA_CONF_FILES_ABS


Q_RR_CONF_FILE=$NEUTRON_CONF_DIR/rootwrap.conf
if [[ "$Q_USE_ROOTWRAP" == "False" ]]; then
    Q_RR_COMMAND="sudo"
else
    NEUTRON_ROOTWRAP=$(get_rootwrap_location neutron)
    Q_RR_COMMAND="sudo $NEUTRON_ROOTWRAP $Q_RR_CONF_FILE"
    if [[ "$Q_USE_ROOTWRAP_DAEMON" == "True" ]]; then
        Q_RR_DAEMON_COMMAND="sudo $NEUTRON_ROOTWRAP-daemon $Q_RR_CONF_FILE"
    fi
fi


# Distributed Virtual Router (DVR) configuration
# Can be:
# - ``legacy``   - No DVR functionality
# - ``dvr_snat`` - Controller or single node DVR
# - ``dvr``      - Compute node in multi-node DVR
#
Q_DVR_MODE=${Q_DVR_MODE:-legacy}
if [[ "$Q_DVR_MODE" != "legacy" ]]; then
    Q_ML2_PLUGIN_MECHANISM_DRIVERS=openvswitch,l2population
fi

# Provider Network Configurations
# --------------------------------

# The following variables control the Neutron ML2 plugins' allocation
# of tenant networks and availability of provider networks. If these
# are not configured in ``localrc``, tenant networks will be local to
# the host (with no remote connectivity), and no physical resources
# will be available for the allocation of provider networks.

# To disable tunnels (GRE or VXLAN) for tenant networks,
# set to False in ``local.conf``.
# GRE tunnels are only supported by the openvswitch.
ENABLE_TENANT_TUNNELS=${ENABLE_TENANT_TUNNELS:-True}

# If using GRE, VXLAN or GENEVE tunnels for tenant networks,
# specify the range of IDs from which tenant networks are
# allocated. Can be overridden in ``localrc`` if necessary.
TENANT_TUNNEL_RANGES=${TENANT_TUNNEL_RANGES:-1:1000}

# To use VLANs for tenant networks, set to True in localrc. VLANs
# are supported by the ML2 plugins, requiring additional configuration
# described below.
ENABLE_TENANT_VLANS=${ENABLE_TENANT_VLANS:-False}

# If using VLANs for tenant networks, set in ``localrc`` to specify
# the range of VLAN VIDs from which tenant networks are
# allocated. An external network switch must be configured to
# trunk these VLANs between hosts for multi-host connectivity.
#
# Example: ``TENANT_VLAN_RANGE=1000:1999``
TENANT_VLAN_RANGE=${TENANT_VLAN_RANGE:-}

# If using VLANs for tenant networks, or if using flat or VLAN
# provider networks, set in ``localrc`` to the name of the physical
# network, and also configure ``OVS_PHYSICAL_BRIDGE`` for the
# openvswitch agent or ``LB_PHYSICAL_INTERFACE`` for the linuxbridge
# agent, as described below.
#
# Example: ``PHYSICAL_NETWORK=default``
PHYSICAL_NETWORK=${PHYSICAL_NETWORK:-public}

# With the openvswitch agent, if using VLANs for tenant networks,
# or if using flat or VLAN provider networks, set in ``localrc`` to
# the name of the OVS bridge to use for the physical network. The
# bridge will be created if it does not already exist, but a
# physical interface must be manually added to the bridge as a
# port for external connectivity.
#
# Example: ``OVS_PHYSICAL_BRIDGE=br-eth1``
OVS_PHYSICAL_BRIDGE=${OVS_PHYSICAL_BRIDGE:-br-ex}

default_route_dev=$(ip route | grep ^default | awk '{print $5}')
die_if_not_set $LINENO default_route_dev "Failure retrieving default route device"
# With the linuxbridge agent, if using VLANs for tenant networks,
# or if using flat or VLAN provider networks, set in ``localrc`` to
# the name of the network interface to use for the physical
# network.
#
# Example: ``LB_PHYSICAL_INTERFACE=eth1``
LB_PHYSICAL_INTERFACE=${LB_PHYSICAL_INTERFACE:-$default_route_dev}

# When Neutron tunnels are enabled it is needed to specify the
# IP address of the end point in the local server. This IP is set
# by default to the same IP address that the HOST IP.
# This variable can be used to specify a different end point IP address
# Example: ``TUNNEL_ENDPOINT_IP=1.1.1.1``
TUNNEL_ENDPOINT_IP=${TUNNEL_ENDPOINT_IP:-$HOST_IP}

# With the openvswitch plugin, set to True in ``localrc`` to enable
# provider GRE tunnels when ``ENABLE_TENANT_TUNNELS`` is False.
#
# Example: ``OVS_ENABLE_TUNNELING=True``
OVS_ENABLE_TUNNELING=${OVS_ENABLE_TUNNELING:-$ENABLE_TENANT_TUNNELS}

# Use DHCP agent for providing metadata service in the case of
# without L3 agent (No Route Agent), set to True in localrc.
ENABLE_ISOLATED_METADATA=${ENABLE_ISOLATED_METADATA:-False}

# Add a static route as dhcp option, so the request to 169.254.169.254
# will be able to reach through a route(DHCP agent)
# This option require ENABLE_ISOLATED_METADATA = True
ENABLE_METADATA_NETWORK=${ENABLE_METADATA_NETWORK:-False}
# Neutron plugin specific functions
# ---------------------------------

# Please refer to ``lib/neutron_plugins/README.md`` for details.
if [ -f $TOP_DIR/lib/neutron_plugins/$Q_PLUGIN ]; then
    source $TOP_DIR/lib/neutron_plugins/$Q_PLUGIN
fi

# Agent metering service plugin functions
# -------------------------------------------

# Hardcoding for 1 service plugin for now
source $TOP_DIR/lib/neutron_plugins/services/metering

# L3 Service functions
source $TOP_DIR/lib/neutron_plugins/services/l3
# Use security group or not
if has_neutron_plugin_security_group; then
    Q_USE_SECGROUP=${Q_USE_SECGROUP:-True}
else
    Q_USE_SECGROUP=False
fi

# Save trace setting
_XTRACE_NEUTRON=$(set +o | grep xtrace)
set +o xtrace


# Functions
# ---------

function _determine_config_server {
    if [[ "$Q_PLUGIN_EXTRA_CONF_PATH" != '' ]]; then
        if [[ "$Q_PLUGIN_EXTRA_CONF_PATH" = "$_Q_PLUGIN_EXTRA_CONF_PATH" ]]; then
            deprecated "Q_PLUGIN_EXTRA_CONF_PATH is deprecated"
        else
            die $LINENO "Q_PLUGIN_EXTRA_CONF_PATH is deprecated"
        fi
    fi
    if [[ ${#Q_PLUGIN_EXTRA_CONF_FILES[@]} > 0 ]]; then
        deprecated "Q_PLUGIN_EXTRA_CONF_FILES is deprecated.  Use neutron_server_config_add instead."
    fi
    for cfg_file in ${Q_PLUGIN_EXTRA_CONF_FILES[@]}; do
        _Q_PLUGIN_EXTRA_CONF_FILES_ABS+=($_Q_PLUGIN_EXTRA_CONF_PATH/$cfg_file)
    done

    local cfg_file
    local opts="--config-file $NEUTRON_CONF --config-file /$Q_PLUGIN_CONF_FILE"
    for cfg_file in ${_Q_PLUGIN_EXTRA_CONF_FILES_ABS[@]}; do
        opts+=" --config-file $cfg_file"
    done
    echo "$opts"
}

function _determine_config_l3 {
    local opts="--config-file $NEUTRON_CONF --config-file $Q_L3_CONF_FILE"
    echo "$opts"
}

# For services and agents that require it, dynamically construct a list of
# --config-file arguments that are passed to the binary.
function determine_config_files {
    local opts=""
    case "$1" in
        "neutron-server") opts="$(_determine_config_server)" ;;
        "neutron-l3-agent") opts="$(_determine_config_l3)" ;;
    esac
    if [ -z "$opts" ] ; then
        die $LINENO "Could not determine config files for $1."
    fi
    echo "$opts"
}

# configure_mutnauq()
# Set common config for all neutron server and agents.
function configure_mutnauq {
    _configure_neutron_common
    iniset_rpc_backend neutron $NEUTRON_CONF

    if is_service_enabled q-metering; then
        _configure_neutron_metering
    fi
    if is_service_enabled q-agt q-svc; then
        _configure_neutron_service
    fi
    if is_service_enabled q-agt; then
        _configure_neutron_plugin_agent
    fi
    if is_service_enabled q-dhcp; then
        _configure_neutron_dhcp_agent
    fi
    if is_service_enabled q-l3; then
        _configure_neutron_l3_agent
    fi
    if is_service_enabled q-meta; then
        _configure_neutron_metadata_agent
    fi

    if [[ "$Q_DVR_MODE" != "legacy" ]]; then
        _configure_dvr
    fi
    if is_service_enabled ceilometer; then
        _configure_neutron_ceilometer_notifications
    fi

    iniset $NEUTRON_CONF DEFAULT api_workers "$API_WORKERS"
    # devstack is not a tool for running uber scale OpenStack
    # clouds, therefore running without a dedicated RPC worker
    # for state reports is more than adequate.
    iniset $NEUTRON_CONF DEFAULT rpc_state_report_workers 0
}

function create_nova_conf_neutron {
    local conf=${1:-$NOVA_CONF}
    iniset $conf DEFAULT use_neutron True
    iniset $conf neutron auth_type "password"
    iniset $conf neutron auth_url "$KEYSTONE_AUTH_URI"
    iniset $conf neutron username "$Q_ADMIN_USERNAME"
    iniset $conf neutron password "$SERVICE_PASSWORD"
    iniset $conf neutron user_domain_name "$SERVICE_DOMAIN_NAME"
    iniset $conf neutron project_name "$SERVICE_PROJECT_NAME"
    iniset $conf neutron project_domain_name "$SERVICE_DOMAIN_NAME"
    iniset $conf neutron auth_strategy "$Q_AUTH_STRATEGY"
    iniset $conf neutron region_name "$REGION_NAME"

    if [[ "$Q_USE_SECGROUP" == "True" ]]; then
        LIBVIRT_FIREWALL_DRIVER=nova.virt.firewall.NoopFirewallDriver
        iniset $conf DEFAULT firewall_driver $LIBVIRT_FIREWALL_DRIVER
    fi

    # optionally set options in nova_conf
    neutron_plugin_create_nova_conf $conf

    if is_service_enabled q-meta; then
        iniset $conf neutron service_metadata_proxy "True"
    fi

    iniset $conf DEFAULT vif_plugging_is_fatal "$VIF_PLUGGING_IS_FATAL"
    iniset $conf DEFAULT vif_plugging_timeout "$VIF_PLUGGING_TIMEOUT"
}

# create_mutnauq_accounts() - Set up common required neutron accounts

# Tenant               User       Roles
# ------------------------------------------------------------------
# service              neutron    admin        # if enabled

# Migrated from keystone_data.sh
function create_mutnauq_accounts {
    local neutron_url
    if [ "$NEUTRON_DEPLOY_MOD_WSGI" == "True" ]; then
        neutron_url=$Q_PROTOCOL://$SERVICE_HOST/networking/
    else
        neutron_url=$Q_PROTOCOL://$SERVICE_HOST:$Q_PORT/
    fi

    if [[ "$ENABLED_SERVICES" =~ "q-svc" ]]; then

        create_service_user "neutron"

        get_or_create_service "neutron" "network" "Neutron Service"
        get_or_create_endpoint \
            "network" \
            "$REGION_NAME" "$neutron_url"
    fi
}

# init_mutnauq() - Initialize databases, etc.
function init_mutnauq {
    recreate_database $Q_DB_NAME
    time_start "dbsync"
    # Run Neutron db migrations
    $NEUTRON_BIN_DIR/neutron-db-manage --config-file $NEUTRON_CONF --config-file /$Q_PLUGIN_CONF_FILE upgrade head
    time_stop "dbsync"
}

# install_mutnauq() - Collect source and prepare
function install_mutnauq {
    # Install neutron-lib from git so we make sure we're testing
    # the latest code.
    if use_library_from_git "neutron-lib"; then
        git_clone_by_name "neutron-lib"
        setup_dev_lib "neutron-lib"
    fi

    git_clone $NEUTRON_REPO $NEUTRON_DIR $NEUTRON_BRANCH
    setup_develop $NEUTRON_DIR

    sudo cp /opt/stack/interconnection.py /usr/local/lib/python2.7/dist-packages/neutron_lib/api/definitions/interconnection.py
}

# install_neutron_agent_packages() - Collect source and prepare
function install_neutron_agent_packages_mutnauq {
    # radvd doesn't come with the OS. Install it if the l3 service is enabled.
    if is_service_enabled q-l3; then
        install_package radvd
    fi
    # install packages that are specific to plugin agent(s)
    if is_service_enabled q-agt q-dhcp q-l3; then
        neutron_plugin_install_agent_packages
    fi
}

# Finish neutron configuration
function configure_neutron_after_post_config {
    if [[ $Q_SERVICE_PLUGIN_CLASSES != '' ]]; then
        iniset $NEUTRON_CONF DEFAULT service_plugins $Q_SERVICE_PLUGIN_CLASSES
    fi
}

# Start running processes
function start_neutron_service_and_check {
    local service_port=$Q_PORT
    local service_protocol=$Q_PROTOCOL
    local cfg_file_options
    local neutron_url

    cfg_file_options="$(determine_config_files neutron-server)"

    if is_service_enabled tls-proxy; then
        service_port=$Q_PORT_INT
        service_protocol="http"
    fi
    # Start the Neutron service
    if [ "$NEUTRON_DEPLOY_MOD_WSGI" == "True" ]; then
        enable_service neutron-api
        run_process neutron-api "$NEUTRON_BIN_DIR/uwsgi --procname-prefix neutron-api --ini $NEUTRON_UWSGI_CONF"
        neutron_url=$Q_PROTOCOL://$Q_HOST/networking/
        enable_service neutron-rpc-server
        run_process neutron-rpc-server "$NEUTRON_BIN_DIR/neutron-rpc-server $cfg_file_options"
    else
        run_process q-svc "$NEUTRON_BIN_DIR/neutron-server $cfg_file_options"
        neutron_url=$service_protocol://$Q_HOST:$service_port
        # Start proxy if enabled
        if is_service_enabled tls-proxy; then
            start_tls_proxy neutron '*' $Q_PORT $Q_HOST $Q_PORT_INT
        fi
    fi
    echo "Waiting for Neutron to start..."

    local testcmd="wget ${ssl_ca} --no-proxy -q -O- $neutron_url"
    test_with_retry "$testcmd" "Neutron did not start" $SERVICE_TIMEOUT
}

# Control of the l2 agent is separated out to make it easier to test partial
# upgrades (everything upgraded except the L2 agent)
function start_mutnauq_l2_agent {
    run_process q-agt "$AGENT_BINARY --config-file $NEUTRON_CONF --config-file /$Q_PLUGIN_CONF_FILE"

    if is_provider_network && [[ $Q_AGENT == "openvswitch" ]]; then
        sudo ovs-vsctl --no-wait -- --may-exist add-port $OVS_PHYSICAL_BRIDGE $PUBLIC_INTERFACE
        sudo ip link set $OVS_PHYSICAL_BRIDGE up
        sudo ip link set br-int up
        sudo ip link set $PUBLIC_INTERFACE up
        if is_ironic_hardware; then
            for IP in $(ip addr show dev $PUBLIC_INTERFACE | grep ' inet ' | awk '{print $2}'); do
                sudo ip addr del $IP dev $PUBLIC_INTERFACE
                sudo ip addr add $IP dev $OVS_PHYSICAL_BRIDGE
            done
            sudo ip route replace $FIXED_RANGE via $NETWORK_GATEWAY dev $OVS_PHYSICAL_BRIDGE
        fi
    fi
}

function start_mutnauq_other_agents {
    run_process q-dhcp "$AGENT_DHCP_BINARY --config-file $NEUTRON_CONF --config-file $Q_DHCP_CONF_FILE"

    if is_service_enabled neutron-vpnaas; then
        :  # Started by plugin
    else
        run_process q-l3 "$AGENT_L3_BINARY $(determine_config_files neutron-l3-agent)"
    fi

    run_process q-meta "$AGENT_META_BINARY --config-file $NEUTRON_CONF --config-file $Q_META_CONF_FILE"
    run_process q-metering "$AGENT_METERING_BINARY --config-file $NEUTRON_CONF --config-file $METERING_AGENT_CONF_FILENAME"
}

# Start running processes, including screen
function start_neutron_agents {
    # Start up the neutron agents if enabled
    start_mutnauq_l2_agent
    start_mutnauq_other_agents
}

function stop_mutnauq_l2_agent {
    stop_process q-agt
}

# stop_mutnauq_other() - Stop running processes
function stop_mutnauq_other {
    if is_service_enabled q-dhcp; then
        stop_process q-dhcp
        pid=$(ps aux | awk '/[d]nsmasq.+interface=(tap|ns-)/ { print $2 }')
        [ ! -z "$pid" ] && sudo kill -9 $pid
    fi

    if [ "$NEUTRON_DEPLOY_MOD_WSGI" == "True" ]; then
        stop_process neutron-rpc-server
        stop_process neutron-api
    else
        stop_process q-svc
    fi

    if is_service_enabled q-l3; then
        sudo pkill -f "radvd -C $DATA_DIR/neutron/ra"
        stop_process q-l3
    fi

    if is_service_enabled q-meta; then
        sudo pkill -9 -f neutron-ns-metadata-proxy || :
        stop_process q-meta
    fi

    if is_service_enabled q-metering; then
        neutron_metering_stop
    fi

    if [[ "$Q_USE_ROOTWRAP_DAEMON" == "True" ]]; then
        sudo pkill -9 -f $NEUTRON_ROOTWRAP-daemon || :
    fi
}

# stop_neutron() - Stop running processes (non-screen)
function stop_mutnauq {
    stop_mutnauq_other
    stop_mutnauq_l2_agent
}

# _move_neutron_addresses_route() - Move the primary IP to the OVS bridge
# on startup, or back to the public interface on cleanup. If no IP is
# configured on the interface, just add it as a port to the OVS bridge.
function _move_neutron_addresses_route {
    local from_intf=$1
    local to_intf=$2
    local add_ovs_port=$3
    local del_ovs_port=$4
    local af=$5

    if [[ -n "$from_intf" && -n "$to_intf" ]]; then
        # Remove the primary IP address from $from_intf and add it to $to_intf,
        # along with the default route, if it exists.  Also, when called
        # on configure we will also add $from_intf as a port on $to_intf,
        # assuming it is an OVS bridge.

        local IP_REPLACE=""
        local IP_DEL=""
        local IP_UP=""
        local DEFAULT_ROUTE_GW
        DEFAULT_ROUTE_GW=$(ip -f $af r | awk "/default.+$from_intf\s/ { print \$3; exit }")
        local ADD_OVS_PORT=""
        local DEL_OVS_PORT=""
        local ARP_CMD=""

        IP_BRD=$(ip -f $af a s dev $from_intf scope global primary | grep inet | awk '{ print $2, $3, $4; exit }')

        if [ "$DEFAULT_ROUTE_GW" != "" ]; then
            ADD_DEFAULT_ROUTE="sudo ip -f $af r replace default via $DEFAULT_ROUTE_GW dev $to_intf"
        fi

        if [[ "$add_ovs_port" == "True" ]]; then
            ADD_OVS_PORT="sudo ovs-vsctl --may-exist add-port $to_intf $from_intf"
        fi

        if [[ "$del_ovs_port" == "True" ]]; then
            DEL_OVS_PORT="sudo ovs-vsctl --if-exists del-port $from_intf $to_intf"
        fi

        if [[ "$IP_BRD" != "" ]]; then
            IP_DEL="sudo ip addr del $IP_BRD dev $from_intf"
            IP_REPLACE="sudo ip addr replace $IP_BRD dev $to_intf"
            IP_UP="sudo ip link set $to_intf up"
            if [[ "$af" == "inet" ]]; then
                IP=$(echo $IP_BRD | awk '{ print $1; exit }' | grep -o -E '(.*)/' | cut -d "/" -f1)
                ARP_CMD="sudo arping -A -c 3 -w 4.5 -I $to_intf $IP "
            fi
        fi

        # The add/del OVS port calls have to happen either before or
        # after the address is moved in order to not leave it orphaned.
        $DEL_OVS_PORT; $IP_DEL; $IP_REPLACE; $IP_UP; $ADD_OVS_PORT; $ADD_DEFAULT_ROUTE; $ARP_CMD
    fi
}

# cleanup_mutnauq() - Remove residual data files, anything left over from previous
# runs that a clean run would need to clean up
function cleanup_mutnauq {

    if [[ -n "$OVS_PHYSICAL_BRIDGE" ]]; then
        _move_neutron_addresses_route "$OVS_PHYSICAL_BRIDGE" "$PUBLIC_INTERFACE" False True "inet"

        if [[ $(ip -f inet6 a s dev "$OVS_PHYSICAL_BRIDGE" | grep -c 'global') != 0 ]]; then
            # ip(8) wants the prefix length when deleting
            local v6_gateway
            v6_gateway=$(ip -6 a s dev $OVS_PHYSICAL_BRIDGE | grep $IPV6_PUBLIC_NETWORK_GATEWAY | awk '{ print $2 }')
            sudo ip -6 addr del $v6_gateway dev $OVS_PHYSICAL_BRIDGE
            _move_neutron_addresses_route "$OVS_PHYSICAL_BRIDGE" "$PUBLIC_INTERFACE" False False "inet6"
        fi

        if is_provider_network && is_ironic_hardware; then
            for IP in $(ip addr show dev $OVS_PHYSICAL_BRIDGE | grep ' inet ' | awk '{print $2}'); do
                sudo ip addr del $IP dev $OVS_PHYSICAL_BRIDGE
                sudo ip addr add $IP dev $PUBLIC_INTERFACE
            done
            sudo route del -net $FIXED_RANGE gw $NETWORK_GATEWAY dev $OVS_PHYSICAL_BRIDGE
        fi
    fi

    if is_neutron_ovs_base_plugin; then
        neutron_ovs_base_cleanup
    fi

    if [[ $Q_AGENT == "linuxbridge" ]]; then
        neutron_lb_cleanup
    fi

    # delete all namespaces created by neutron
    for ns in $(sudo ip netns list | grep -o -E '(qdhcp|qrouter|fip|snat)-[0-9a-f-]*'); do
        sudo ip netns delete ${ns}
    done
}


function _create_neutron_conf_dir {
    # Put config files in ``NEUTRON_CONF_DIR`` for everyone to find
    sudo install -d -o $STACK_USER $NEUTRON_CONF_DIR
}

# _configure_neutron_common()
# Set common config for all neutron server and agents.
# This MUST be called before other ``_configure_neutron_*`` functions.
function _configure_neutron_common {
    _create_neutron_conf_dir

    # Uses oslo config generator to generate core sample configuration files
    (cd $NEUTRON_DIR && exec ./tools/generate_config_file_samples.sh)

    cp $NEUTRON_DIR/etc/neutron.conf.sample $NEUTRON_CONF

    Q_POLICY_FILE=$NEUTRON_CONF_DIR/policy.json

    # allow neutron user to administer neutron to match neutron account
    # NOTE(amotoki): This is required for nova works correctly with neutron.
    if [ -f $NEUTRON_DIR/etc/policy.json ]; then
        cp $NEUTRON_DIR/etc/policy.json $Q_POLICY_FILE
        sed -i 's/"context_is_admin":  "role:admin"/"context_is_admin":  "role:admin or user_name:neutron"/g' $Q_POLICY_FILE
    else
        echo '{"context_is_admin":  "role:admin or user_name:neutron"}' > $Q_POLICY_FILE
    fi

    # Set plugin-specific variables ``Q_DB_NAME``, ``Q_PLUGIN_CLASS``.
    # For main plugin config file, set ``Q_PLUGIN_CONF_PATH``, ``Q_PLUGIN_CONF_FILENAME``.
    neutron_plugin_configure_common

    if [[ "$Q_PLUGIN_CONF_PATH" == '' || "$Q_PLUGIN_CONF_FILENAME" == '' || "$Q_PLUGIN_CLASS" == '' ]]; then
        die $LINENO "Neutron plugin not set.. exiting"
    fi

    # If needed, move config file from ``$NEUTRON_DIR/etc/neutron`` to ``NEUTRON_CONF_DIR``
    mkdir -p /$Q_PLUGIN_CONF_PATH
    Q_PLUGIN_CONF_FILE=$Q_PLUGIN_CONF_PATH/$Q_PLUGIN_CONF_FILENAME
    # NOTE(hichihara): Some neutron vendor plugins were already decomposed and
    # there is no config file in Neutron tree. They should prepare the file in each plugin.
    if [ -f "$NEUTRON_DIR/$Q_PLUGIN_CONF_FILE.sample" ]; then
        cp "$NEUTRON_DIR/$Q_PLUGIN_CONF_FILE.sample" /$Q_PLUGIN_CONF_FILE
    elif [ -f $NEUTRON_DIR/$Q_PLUGIN_CONF_FILE ]; then
        cp $NEUTRON_DIR/$Q_PLUGIN_CONF_FILE /$Q_PLUGIN_CONF_FILE
    fi

    iniset $NEUTRON_CONF database connection `database_connection_url $Q_DB_NAME`
    iniset $NEUTRON_CONF DEFAULT state_path $DATA_DIR/neutron
    iniset $NEUTRON_CONF DEFAULT use_syslog $SYSLOG
    iniset $NEUTRON_CONF DEFAULT bind_host $Q_LISTEN_ADDRESS
    iniset $NEUTRON_CONF oslo_concurrency lock_path $DATA_DIR/neutron/lock

    # NOTE(freerunner): Need to adjust Region Name for nova in multiregion installation
    iniset $NEUTRON_CONF nova region_name $REGION_NAME

    if [ "$VIRT_DRIVER" = 'fake' ]; then
        # Disable arbitrary limits
        iniset $NEUTRON_CONF quotas quota_network -1
        iniset $NEUTRON_CONF quotas quota_subnet -1
        iniset $NEUTRON_CONF quotas quota_port -1
        iniset $NEUTRON_CONF quotas quota_security_group -1
        iniset $NEUTRON_CONF quotas quota_security_group_rule -1
    fi

    # Format logging
    setup_logging $NEUTRON_CONF

    if is_service_enabled tls-proxy && [ "$NEUTRON_DEPLOY_MOD_WSGI" == "False" ]; then
        # Set the service port for a proxy to take the original
        iniset $NEUTRON_CONF DEFAULT bind_port "$Q_PORT_INT"
        iniset $NEUTRON_CONF oslo_middleware enable_proxy_headers_parsing True
    fi

    _neutron_setup_rootwrap
}

function _configure_neutron_dhcp_agent {

    cp $NEUTRON_DIR/etc/dhcp_agent.ini.sample $Q_DHCP_CONF_FILE

    iniset $Q_DHCP_CONF_FILE DEFAULT debug $ENABLE_DEBUG_LOG_LEVEL
    # make it so we have working DNS from guests
    iniset $Q_DHCP_CONF_FILE DEFAULT dnsmasq_local_resolv True
    iniset $Q_DHCP_CONF_FILE AGENT root_helper "$Q_RR_COMMAND"
    if [[ "$Q_USE_ROOTWRAP_DAEMON" == "True" ]]; then
        iniset $Q_DHCP_CONF_FILE AGENT root_helper_daemon "$Q_RR_DAEMON_COMMAND"
    fi

    if ! is_service_enabled q-l3; then
        if [[ "$ENABLE_ISOLATED_METADATA" = "True" ]]; then
            iniset $Q_DHCP_CONF_FILE DEFAULT enable_isolated_metadata $ENABLE_ISOLATED_METADATA
            iniset $Q_DHCP_CONF_FILE DEFAULT enable_metadata_network $ENABLE_METADATA_NETWORK
        else
            if [[ "$ENABLE_METADATA_NETWORK" = "True" ]]; then
                die "$LINENO" "Enable isolated metadata is a must for metadata network"
            fi
        fi
    fi

    _neutron_setup_interface_driver $Q_DHCP_CONF_FILE

    neutron_plugin_configure_dhcp_agent $Q_DHCP_CONF_FILE
}


function _configure_neutron_metadata_agent {
    cp $NEUTRON_DIR/etc/metadata_agent.ini.sample $Q_META_CONF_FILE

    iniset $Q_META_CONF_FILE DEFAULT debug $ENABLE_DEBUG_LOG_LEVEL
    iniset $Q_META_CONF_FILE DEFAULT nova_metadata_host $Q_META_DATA_IP
    iniset $Q_META_CONF_FILE DEFAULT metadata_workers $API_WORKERS
    iniset $Q_META_CONF_FILE AGENT root_helper "$Q_RR_COMMAND"
    if [[ "$Q_USE_ROOTWRAP_DAEMON" == "True" ]]; then
        iniset $Q_META_CONF_FILE AGENT root_helper_daemon "$Q_RR_DAEMON_COMMAND"
    fi
}

function _configure_neutron_ceilometer_notifications {
    iniset $NEUTRON_CONF oslo_messaging_notifications driver messagingv2
}

function _configure_neutron_metering {
    neutron_agent_metering_configure_common
    neutron_agent_metering_configure_agent
}

function _configure_dvr {
    iniset $NEUTRON_CONF DEFAULT router_distributed True
    iniset $Q_L3_CONF_FILE DEFAULT agent_mode $Q_DVR_MODE
}


# _configure_neutron_plugin_agent() - Set config files for neutron plugin agent
# It is called when q-agt is enabled.
function _configure_neutron_plugin_agent {
    # Specify the default root helper prior to agent configuration to
    # ensure that an agent's configuration can override the default
    iniset /$Q_PLUGIN_CONF_FILE agent root_helper "$Q_RR_COMMAND"
    if [[ "$Q_USE_ROOTWRAP_DAEMON" == "True" ]]; then
        iniset /$Q_PLUGIN_CONF_FILE  agent root_helper_daemon "$Q_RR_DAEMON_COMMAND"
    fi
    iniset $NEUTRON_CONF DEFAULT debug $ENABLE_DEBUG_LOG_LEVEL

    # Configure agent for plugin
    neutron_plugin_configure_plugin_agent
}

# _configure_neutron_service() - Set config files for neutron service
# It is called when q-svc is enabled.
function _configure_neutron_service {
    Q_API_PASTE_FILE=$NEUTRON_CONF_DIR/api-paste.ini
    cp $NEUTRON_DIR/etc/api-paste.ini $Q_API_PASTE_FILE

    # Update either configuration file with plugin
    iniset $NEUTRON_CONF DEFAULT core_plugin $Q_PLUGIN_CLASS

    iniset $NEUTRON_CONF DEFAULT debug $ENABLE_DEBUG_LOG_LEVEL
    iniset $NEUTRON_CONF oslo_policy policy_file $Q_POLICY_FILE
    iniset $NEUTRON_CONF DEFAULT allow_overlapping_ips $Q_ALLOW_OVERLAPPING_IP

    iniset $NEUTRON_CONF DEFAULT auth_strategy $Q_AUTH_STRATEGY
    _neutron_setup_keystone $NEUTRON_CONF keystone_authtoken

    # Configuration for neutron notifications to nova.
    iniset $NEUTRON_CONF DEFAULT notify_nova_on_port_status_changes $Q_NOTIFY_NOVA_PORT_STATUS_CHANGES
    iniset $NEUTRON_CONF DEFAULT notify_nova_on_port_data_changes $Q_NOTIFY_NOVA_PORT_DATA_CHANGES

    configure_auth_token_middleware $NEUTRON_CONF nova $NEUTRON_AUTH_CACHE_DIR nova

    # Configure plugin
    neutron_plugin_configure_service
}

# Utility Functions
#------------------

# _neutron_service_plugin_class_add() - add service plugin class
function _neutron_service_plugin_class_add {
    local service_plugin_class=$1
    if [[ $Q_SERVICE_PLUGIN_CLASSES == '' ]]; then
        Q_SERVICE_PLUGIN_CLASSES=$service_plugin_class
    elif [[ ! ,${Q_SERVICE_PLUGIN_CLASSES}, =~ ,${service_plugin_class}, ]]; then
        Q_SERVICE_PLUGIN_CLASSES="$Q_SERVICE_PLUGIN_CLASSES,$service_plugin_class"
    fi
}

# _neutron_ml2_extension_driver_add_old() - add ML2 extension driver
function _neutron_ml2_extension_driver_add_old {
    local extension=$1
    if [[ $Q_ML2_PLUGIN_EXT_DRIVERS == '' ]]; then
        Q_ML2_PLUGIN_EXT_DRIVERS=$extension
    elif [[ ! ,${Q_ML2_PLUGIN_EXT_DRIVERS}, =~ ,${extension}, ]]; then
        Q_ML2_PLUGIN_EXT_DRIVERS="$Q_ML2_PLUGIN_EXT_DRIVERS,$extension"
    fi
}

# mutnauq_server_config_add() - add server config file
function mutnauq_server_config_add {
    _Q_PLUGIN_EXTRA_CONF_FILES_ABS+=($1)
}

# _neutron_deploy_rootwrap_filters() - deploy rootwrap filters to $Q_CONF_ROOTWRAP_D (owned by root).
function _neutron_deploy_rootwrap_filters {
    if [[ "$Q_USE_ROOTWRAP" == "False" ]]; then
        return
    fi
    local srcdir=$1
    sudo install -d -o root -m 755 $Q_CONF_ROOTWRAP_D
    sudo install -o root -m 644 $srcdir/etc/neutron/rootwrap.d/* $Q_CONF_ROOTWRAP_D/
}

# _neutron_setup_rootwrap() - configure Neutron's rootwrap
function _neutron_setup_rootwrap {
    if [[ "$Q_USE_ROOTWRAP" == "False" ]]; then
        return
    fi
    # Wipe any existing ``rootwrap.d`` files first
    Q_CONF_ROOTWRAP_D=$NEUTRON_CONF_DIR/rootwrap.d
    if [[ -d $Q_CONF_ROOTWRAP_D ]]; then
        sudo rm -rf $Q_CONF_ROOTWRAP_D
    fi

    _neutron_deploy_rootwrap_filters $NEUTRON_DIR

    # Set up ``rootwrap.conf``, pointing to ``$NEUTRON_CONF_DIR/rootwrap.d``
    # location moved in newer versions, prefer new location
    if test -r $NEUTRON_DIR/etc/neutron/rootwrap.conf; then
        sudo install -o root -g root -m 644 $NEUTRON_DIR/etc/neutron/rootwrap.conf $Q_RR_CONF_FILE
    else
        sudo install -o root -g root -m 644 $NEUTRON_DIR/etc/rootwrap.conf $Q_RR_CONF_FILE
    fi
    sudo sed -e "s:^filters_path=.*$:filters_path=$Q_CONF_ROOTWRAP_D:" -i $Q_RR_CONF_FILE
    sudo sed -e 's:^exec_dirs=\(.*\)$:exec_dirs=\1,/usr/local/bin:' -i $Q_RR_CONF_FILE

    # Specify ``rootwrap.conf`` as first parameter to neutron-rootwrap
    ROOTWRAP_SUDOER_CMD="$NEUTRON_ROOTWRAP $Q_RR_CONF_FILE *"
    ROOTWRAP_DAEMON_SUDOER_CMD="$NEUTRON_ROOTWRAP-daemon $Q_RR_CONF_FILE"

    # Set up the rootwrap sudoers for neutron
    TEMPFILE=`mktemp`
    echo "$STACK_USER ALL=(root) NOPASSWD: $ROOTWRAP_SUDOER_CMD" >$TEMPFILE
    echo "$STACK_USER ALL=(root) NOPASSWD: $ROOTWRAP_DAEMON_SUDOER_CMD" >>$TEMPFILE
    chmod 0440 $TEMPFILE
    sudo chown root:root $TEMPFILE
    sudo mv $TEMPFILE /etc/sudoers.d/neutron-rootwrap

    # Update the root_helper
    iniset $NEUTRON_CONF agent root_helper "$Q_RR_COMMAND"
    if [[ "$Q_USE_ROOTWRAP_DAEMON" == "True" ]]; then
        iniset $NEUTRON_CONF agent root_helper_daemon "$Q_RR_DAEMON_COMMAND"
    fi
}

# Configures keystone integration for neutron service
function _neutron_setup_keystone {
    local conf_file=$1
    local section=$2

    create_neutron_cache_dir
    configure_auth_token_middleware $conf_file $Q_ADMIN_USERNAME $NEUTRON_AUTH_CACHE_DIR $section
}

function _neutron_setup_interface_driver {

    # ovs_use_veth needs to be set before the plugin configuration
    # occurs to allow plugins to override the setting.
    iniset $1 DEFAULT ovs_use_veth $Q_OVS_USE_VETH

    neutron_plugin_setup_interface_driver $1
}
# Functions for Neutron Exercises
#--------------------------------

function delete_probe {
    local from_net="$1"
    net_id=`_get_net_id $from_net`
    probe_id=`neutron-debug --os-tenant-name admin --os-username admin --os-password $ADMIN_PASSWORD probe-list -c id -c network_id | grep $net_id | awk '{print $2}'`
    neutron-debug --os-tenant-name admin --os-username admin probe-delete $probe_id
}

function _get_net_id {
    openstack --os-cloud devstack-admin --os-region-name="$REGION_NAME" --os-project-name admin --os-username admin --os-password $ADMIN_PASSWORD network list | grep $1 | awk '{print $2}'
}

function _get_probe_cmd_prefix {
    local from_net="$1"
    net_id=`_get_net_id $from_net`
    probe_id=`neutron-debug --os-tenant-name admin --os-username admin --os-password $ADMIN_PASSWORD probe-list -c id -c network_id | grep $net_id | awk '{print $2}' | head -n 1`
    echo "$Q_RR_COMMAND ip netns exec qprobe-$probe_id"
}

# ssh check
function _ssh_check_neutron {
    local from_net=$1
    local key_file=$2
    local ip=$3
    local user=$4
    local timeout_sec=$5
    local probe_cmd = ""
    probe_cmd=`_get_probe_cmd_prefix $from_net`
    local testcmd="$probe_cmd ssh -o StrictHostKeyChecking=no -i $key_file ${user}@$ip echo success"
    test_with_retry "$testcmd" "server $ip didn't become ssh-able" $timeout_sec
}

# Restore xtrace
$_XTRACE_NEUTRON

# Tell emacs to use shell-script-mode
## Local variables:
## mode: shell-script
## End:
{% endraw %}
