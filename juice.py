#!/usr/bin/env python

"""Tool to test the performances of MariaDB, Galera and CockroachDB with
OpenStack on Grid'5000

Usage:
    juice [-h | --help] [-v | --version] <command> [<args>...]

Options:
    -h --help      Show this help
    -v --version   Show version number

Commands:
    deploy         Claim resources from g5k and configure them
    openstack      Add OpenStack Keystone to the deployment
    rally          Benchmark the Openstack
    stress         Launch sysbench tests (after a deployment)
    emulate        Emulate network using tc
    backup         Backup the environment
    destroy        Destroy all the running dockers (not the resources)
    info           Show information of the actual deployment
    help           Show this help

Run 'juice COMMAND --help' for more information on a command
"""

import os
import subprocess
import logging
import sys
import pprint
import yaml
import json
import operator
import pickle

from docopt import docopt
from enoslib.api import generate_inventory
from enoslib.task import enostask, _save_env
from enoslib.infra.enos_g5k.provider import G5k
from enoslib.service import Monitoring
from enoslib.infra.enos_g5k.configuration import Configuration, NetworkConfiguration
from utils import (JUICE_PATH, ANSIBLE_PATH, SYMLINK_NAME, doc,
                   doc_lookup, run_ansible, g5k_deploy)

logging.basicConfig(level=logging.DEBUG)

tc = {
    "enable": True,
    "default_delay": "20ms",
    "default_rate": "1gbit",
    "constraints": [{
        "src": "openstack",
        "dst": "openstack",
        "delay": "10ms",
        "loss": "0",
    }],
    "groups": ['openstack'],
}

######################################################################
## SCAFFOLDING
######################################################################

#tags=['provide', 'inventory', 'scaffold'], env=None,
@doc()
@enostask()
def deploy(conf, provider='g5k', force_deployment=False, xp_name=None,
           tags=['provide', 'inventory', 'scaffold'], env=None,
           **kwargs):
    """
usage: juice deploy [--conf CONFIG_PATH] [--provider PROVIDER]
                    [--force-deployment]
                    [--xp-name NAME] [--tags TAGS...]

Claim resources from PROVIDER and configure them.

Options:
  --conf CONFIG_PATH    Path to the configuration file describing the
                        deployment [default: ./conf.yaml]
  --provider PROVIDER   Provider to target [default: g5k]
  --force-deployment    Force provider to redo the deployment
  --xp-name NAME        NAME of the folder generated by juice for this
                        new deployment.
  --tags TAGS           Only run tasks relative to the specific tags
                        [default: provide inventory scaffold]
    """
    # Read the configuration
    config_file = {}

    if isinstance(conf, str):
        # Get the config object from a yaml file
        with open(conf) as f:
            config_file = yaml.load(f)

        config = Configuration.from_dictionnary(config_file['g5k'])

    elif isinstance(conf, dict):
        # Get the config object from a dict
        config = conf
    else:
        # Data format error
        raise Exception(
            'conf is type {!r} while it should be a yaml file or a dict'.format(type(conf)))

    env['db'] = config_file.get('database', 'cockroachdb')
    env['monitoring'] = config_file.get('monitoring', True)
    env['config'] = config_file

    # Claim resources on Grid'5000
    if 'provide' in tags:
        if provider == 'g5k':
            env['provider'] = 'g5k'
            updated_env = g5k_deploy(config, env=xp_name, force_deploy=force_deployment)
            env.update(updated_env)
        else:
            raise Exception(
                'The provider {!r} is not supported or it lacks a configuration'.format(provider))

    # Generate the Ansible inventory file
    if 'inventory' in tags:
        env['inventory'] = os.path.join(env['resultdir'], 'hosts.ini')
        generate_own_inventory(env['roles'] , env['cwd'],
                           env['inventory'])
        _save_env(env)
#        print(env_['inventory'])
#        m = Monitoring(collector=env['roles']['openstack'],
#               agent=env['roles']['openstack'],
#               ui=env['roles']['openstack'])
#        m.deploy()


    # Deploy the resources, requires both g5k and inventory executions
    if 'scaffold' in tags:
        extra_vars = {'monitoring': env['monitoring']}
        run_ansible('tasks.yml')

@doc()
@enostask()
def backup(backup_dir='current/backup', env=None, **kwargs):
    """
usage: juice backup [--backup-dir DIRECTORY]

Backup the experiment
  --backup-dir DIRECTORY  Backup directory [default: current/backup]
    """
    backup_dir = os.path.abspath(backup_dir)
    os.path.isdir(backup_dir) or os.mkdir(backup_dir)

    extra_vars = {
        "enos_action": "backup",
        "db": env['db'],
        "backup_dir": backup_dir,
        "monitoring": env['monitoring'],
        "rally_nodes": env.get('rally_nodes', [])
    }
    run_ansible('scaffolding.yml', extra_vars=extra_vars)
    run_ansible('openstack.yml', extra_vars=extra_vars)
    run_ansible('rally.yml', extra_vars=extra_vars)


@doc()
@enostask()
def destroy(env=None, hard=False, **kwargs):
    """
usage: juice destroy

Destroy all the running dockers (not destroying the resources), requires g5k
and inventory executions
    """
    extra_vars = {}
    # Call destroy on each component
    extra_vars.update({
        'monitoring': env.get('monitoring', True),
        "db": env.get('db', 'cockroachdb'),
        "rally_nodes": env.get('rally_nodes', []),
        "enos_action": "destroy"
    })
    run_ansible('scaffolding.yml', extra_vars=extra_vars)
    run_ansible('openstack.yml', extra_vars=extra_vars)
    run_ansible('rally.yml', extra_vars=extra_vars)


######################################################################
## Scaffolding ++
######################################################################

@doc()
@enostask()
def openstack(env=None, **kwargs):
    """
usage: juice openstack

Launch OpenStack.
    """
    # Generate inventory
    extra_vars = {
        "db": env['db'],
    }
    # use deploy of each role
    extra_vars.update({"enos_action": "deploy"})
    run_ansible('openstack.yml', extra_vars=extra_vars)


######################################################################
## Stress
######################################################################


@doc()
@enostask()
def stress(env=None, **kwargs):
    """
usage: juice stress

Launch sysbench tests.
    """
    # Generate inventory
    extra_vars = {
        "registry": env["config"]["registry"],
        "db": env.get('db', 'cockroachdb'),
        "enos_action": "stress"
    }
    # use deploy of each role
    run_ansible('stress.yml', extra_vars=extra_vars)


@doc()
@enostask()
def rally(files, directory, high, env=None, **kwargs):
    """
usage: juice rally [--files FILE... | --directory DIRECTORY] [--high]

Benchmark the Openstack

  --files FILE           Files to use for rally scenarios (name must be a path
from rally scenarios folder).
  --directory DIRECTORY  Directory that contains rally scenarios. [default:
keystone]
  --high                 Use high mode or not
    """
    logging.info("Launching rally using scenarios: %s" % (', '.join(files)))
    logging.info("Launching rally using all scenarios in %s directory.",
                 directory)

    database_nodes = [host.address for role, hosts in env['roles'].items()
                                   if role.startswith('database')
                                   for host in hosts]

    # In high mode: runs rally in all database nodes, in light mode:
    # runs rally on one database node. In light mode, we pick the
    # second database node (ie, `database_node[1]`) to not run rally
    # on the same node than the one that contains mariadb.
    rally_nodes = database_nodes if high else database_nodes[1]
    env['rally_nodes'] = rally_nodes

    extra_vars = {
        "rally_nodes": rally_nodes
    }
    if files:
        extra_vars.update({"rally_files": files})
    else:
        extra_vars.update({"rally_directory": directory})

    # use deploy of each role
    extra_vars.update({"enos_action": "deploy"})
    run_ansible('rally.yml', extra_vars=extra_vars)


######################################################################
## Other
######################################################################


@doc(tc)
@enostask()
def emulate(tc=tc, env=None, **kwargs):
    """
usage: juice emulate

Emulate network using: {0}
    """
    inventory = env["inventory"]
    roles = env["roles"]
    logging.info("Emulates using constraints: %s" % tc)
    #emulate_network(roles, inventory, tc)
    env["latency"] = tc['constraints'][0]['delay']


@doc()
@enostask()
def validate(env=None, **kwargs):
    """
usage: juice validate

Validate network. Doesn't work for now since there is no flent installed
    """
    inventory = env["inventory"]
    roles = env["roles"]
    #validate_network(roles, inventory)


@doc(SYMLINK_NAME)
@enostask()
def info(env, out, **kwargs):
    """
usage: enos info [-e ENV|--env=ENV] [--out=FORMAT]

Show information of the `ENV` deployment.

Options:
  -e ENV --env=ENV         Path to the environment directory. You should use
                           this option when you want to link a
                           specific experiment [default: {0}].
  --out FORMAT             Output the result in either json, pickle or
                           yaml format.
    """
    if not out:
        pprint.pprint(env)
    elif out == 'json':
        print(json.dumps(env, default=operator.attrgetter('__dict__')))
    elif out == 'pickle':
        print(pickle.dumps(env))
    elif out == 'yaml':
        print(yaml.dump(env))
    else:
        print("--out doesn't suppport %s output format" % out)
        print(info.__doc__)

@doc()
def help(**kwargs):
    """
usage: juice help

Show the help message
    """
    print(__doc__)


def generate_own_inventory(roles, directory, inventory):

  logging.info("Creating custom inventory")
  
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

  def sorted_roles(roles, tag):
    list_roles = [k.to_dict()['address'] for k in roles[tag]]
    size = len(list_roles)
    for i in range(size):
      for j in range(size):
        first_elem = int((list_roles[i].split('-')[1]).split('.')[0])
        second_elem = int((list_roles[j].split('-')[1]).split('.')[0])

        if first_elem < second_elem:
          temp = list_roles[i]
          list_roles[i] = list_roles[j]
          list_roles[j] = temp

    return list_roles


  # Retrieve the hosts granted in the reservation from OAR_NODE_FILE

  retrieve_hosts_list = roles
  #retrieve_hosts_list = list(dict.fromkeys(retrieve_hosts_list))

  reflector_index = 0
  client_index = 0
  rtt_initial = 500

  sorted_role_list = {}
  sorted_role_list['openstack'] = sorted_roles(roles, "openstack")
  sorted_role_list['routereflector'] = sorted_roles(roles, "routereflector")
  sorted_role_list['routeclient'] = sorted_roles(roles, "routeclient")
  sorted_role_list['modules'] = sorted_roles(roles, "modules")
  print(sorted_role_list)

  # Write into the ansible hosts file to deploy the roles
  host_file = open(inventory,"w+")
  host_file.write("[openstack]\n")

  for i in range(len(sorted_role_list['openstack'])):
          host = sorted_role_list['openstack'][i]
          rtt_for_neutron = str(rtt_initial) + "," + str(rtt_initial+500-1)
          host_file.write("Region" + str(n2w(i+1)) + " ansible_host=" + host + " regionName=Region" + str(n2w(i+1)) + " rttLabels=\'" + rtt_for_neutron + "\'\n")
          rtt_initial=rtt_initial + 500

  host_file.write("\n[routereflector]\n")
  for i in range(len(sorted_role_list['routereflector'])):
          host = sorted_role_list['routereflector'][i]
          host_file.write("RouterR" + str(n2w(i+1)) + " ansible_host=" + host + " routerName=RouterR" + str(n2w(i+1)) + " clients=" + str(client_index) + "\n")
          client_index = client_index + 16
#          client_index = client_index + 3

  host_file.write("\n[routeclient]\n")
  for i in range(len(roles['routeclient'])):
          host = sorted_role_list['routeclient'][i]
          host_file.write("RouterC" + str(n2w(i+1))+" ansible_host=" + host + " routerName=RouterC" + str(n2w(i+1)) + " regionName=Region" + str(n2w(i+1)) + " reflector=" + str(reflector_index)+"\n")
          if ((i+1) % 16 == 0):
#          if ((i+1) % 3 == 0):
                  reflector_index = reflector_index + 1

  host_file.write("\n[routers]\n")
  for i in range(len(sorted_role_list['routereflector'])):
          host = sorted_role_list['routereflector'][i]
          host_file.write("Router"+str(n2w(i+1))+" ansible_host=" + host + " routerName=Router"+str(n2w(i+1))+"\n")
  for i in range(len(sorted_role_list['routeclient'])):
          host = sorted_role_list['routeclient'][i]
          host_file.write("Router"+str(n2w(i+len(sorted_role_list['routereflector'])))+" ansible_host=" + host + " routerName=Router"+str(n2w(i+len(sorted_role_list['routereflector'])))+"\n")

  host_file.write("\n[modules]\n")
  for i in range(len(sorted_role_list['modules'])):
          host = sorted_role_list['modules'][i]
          host_file.write("Region"+str(n2w(i+1))+" ansible_host=" + host + " regionName=" + "Region"+str(n2w(i+1))  + "\n")

  host_file.close()

  # We need to delete the information contained into os_log file
  clear_file = subprocess.check_output("> " + directory + "/ansible/roles/openstack/templates/os_list.txt.tpl ", shell=True) 
  # SSH with every host in order to take the IP address and save it for future keystone endpoints patching
  for i in range(len(sorted_role_list['openstack'])):
    host = sorted_role_list['openstack'][i]
    master_ip = subprocess.check_output("ssh root@" + host + " ip a | grep eno1 | grep inet | cut -d/ -f1 | cut -d ' ' -f6-" ,shell=True).decode('UTF-8')[0:-1]
    # Update the files where the keystone data is being saved
    new_ip = subprocess.check_output("echo 'Region"+ str(n2w(i+1)) +":" + master_ip + "' >>" + directory + "/ansible/roles/openstack/templates/os_list.txt.tpl ", shell=True)
    # replace_auth = subprocess.check_output("sed -i 's/OS_AUTH_URL:.*/OS_AUTH_URL: '"+ master_ip +"'/g' " + directory  + "/ansible/group_vars/all.yml ", shell=True)



if __name__ == '__main__':
    args = docopt(__doc__,
                  version='juice version 1.0.0',
                  options_first=True)

    argv = [args['<command>']] + args['<args>']

    doc_lookup(args['<command>'], argv)


