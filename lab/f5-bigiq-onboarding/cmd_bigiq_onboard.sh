#!/bin/bash
# Uncomment set command below for code debugging bash
#set -x
# Uncomment set command below for code debugging ansible
#DEBUG_arg="-vvvv"

env="udf"
#env="sjc2"

ip_cm1="$(cat inventory/group_vars/$env-bigiq-cm-01.yml| grep bigiq_onboard_server | awk '{print $2}')"
pwd_cm1="$(cat inventory/group_vars/$env-bigiq-cm-01.yml| grep bigiq_onboard_new_admin_password | awk '{print $2}')"
ip_dcd1="$(cat inventory/group_vars/$env-bigiq-dcd-01.yml| grep bigiq_onboard_server | awk '{print $2}')"
pwd_dcd1="$(cat inventory/group_vars/$env-bigiq-dcd-01.yml| grep bigiq_onboard_new_admin_password | awk '{print $2}')"

ansible-galaxy install f5devcentral.bigiq_onboard --force

if [[  $env == "udf" ]]; then
  ansible-playbook -i inventory/$env-hosts bigiq_onboard.yaml $DEBUG_arg
else
  ansible-playbook -i inventory/$env-hosts .bigiq_onboard_$env.yaml $DEBUG_arg
fi

# Add DCD to CM
curl https://s3.amazonaws.com/big-iq-quickstart-cf-templates-aws/6.0.1.1/scripts.tar.gz > scripts.tar.gz
rm -rf scripts 
tar --strip-components=1 -xPvzf scripts.tar.gz 2> /dev/null &

echo "Type BIG-IQ CM root password:"
ssh-copy-id root@$ip_cm1
echo "Type BIG-IQ DCD root password:"
ssh-copy-id root@$ip_dcd1

scp -rp scripts root@$ip_cm1:/root
ssh root@$ip_cm1 << EOF
  cd /root/scripts
  set-basic-auth on
  /usr/local/bin/python2.7 ./add-dcd.py --DCD_IP_ADDRESS $ip_dcd1 --DCD_USERNAME admin --DCD_PWD $pwd_dcd1
  sleep 5
  /usr/local/bin/python2.7 ./activate-dcd-services.py --DCD_IP_ADDRESS $ip_dcd1 --SERVICES asm access dos websafe ipsec afm
EOF

# Add devices
perl ./bulkDiscovery.pl -c inventory/$env-bigip.csv -l -s -q admin:$pwd_cm1