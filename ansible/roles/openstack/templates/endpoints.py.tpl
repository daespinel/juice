#!/usr/bin/python3

from keystoneauth1.identity import v3
from keystoneauth1 import session
from keystoneclient.v3 import client as keystoneclient

FIRST_REGION_NAME = "RegionOne"
KEYSTONE_ENDPOINT = "http://{{keystone_ip_node}}/identity/v3"

def get_session_object(auth_param):
    return session.Session(auth=auth_param)

def get_keystone_catalog(keystone_endpoint):
    auth = get_auth_object(keystone_endpoint)
    sess = get_session_object(auth)
    # Auth process
    auth.get_access(sess)
    auth_ref = auth.auth_ref
    return auth_ref.service_catalog.catalog

def get_keystone_client(keystone_endpoint, region):
    sess = get_session_object(get_auth_object(keystone_endpoint))
    return keystoneclient.Client(
        session=sess,
        region_name=region
    )

def get_auth_object(keystone_endpoint, username, password, project):
    return v3.Password(
        username=username,
        password=password,
        project_name=project,
        auth_url=keystone_endpoint,
        user_domain_id="default",
        project_domain_id="default",
        include_catalog=True,
        reauthenticate=True
    )

region_name_endpoints = {}
catalog_endpoints = get_keystone_catalog(KEYSTONE_ENDPOINT)

for obj in catalog_endpoints :
  if obj['name'] == 'neutron':
    for endpoint in obj['endpoints']:
      region_name_nedpoints[endpoint['region']] = endpoint['url'].split(':')[0]
