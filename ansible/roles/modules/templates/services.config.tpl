[DEFAULT]
host = {{ ansible_eno1.ipv4.address }}
region_name = {{ regionName }}
username = admin
password = secret
project = demo
auth_url = http://{{ ansible_eno1.ipv4.address }}/identity/v3
