---
openstack:
  auth_url: "http://{{ keystone_ip_node }}/identity"
  region_name: {{ regionName }}
  https_insecure: False
  users:
    - username: admin
      password: secret
      project_name: demo

