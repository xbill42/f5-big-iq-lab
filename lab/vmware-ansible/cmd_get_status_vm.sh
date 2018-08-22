#!/bin/bash
# Uncomment set command below for code debuging bash
#set -x

echo -e "\nTIME: $(date +"%H:%M")"

cd /home/f5/vmware-ansible

ansible-playbook -i notahost, get_status_vm.yaml

# parse JSON
jq '.virtual_machines' vmfact.json

rm -f vmfact.json