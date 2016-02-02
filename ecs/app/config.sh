#!/usr/bin/env bash

function config_ansible()
{
    ansible common -m command -a 'uptime'
    ansible 192.168.200.61:192.168.200.43  -m script -a ./summary
    ansible 192.168.200.61:192.168.200.43 -m copy -a 'src=/root/summary dest=/tmp/ owner=root group=root mode=0755'
    ansible 192.168.200.61:192.168.200.43  -m shell -a '/tmp/summary'
    ansible common -m service -a 'name=ntpd state=restarted'
    ansible 192.168.200.61:192.168.200.43  -m service -a 'name=ntpd state=restarted'
    ansible 192.168.200.61:192.168.200.43  -m yum -a 'name=ntp state=present'
    ansible 192.168.200.61:192.168.200.43  -m yum -a 'name=ntp state=absent'
}

function config_ansible_playbook()
{
    ansible-playbook site.yml --syntax-check
    ansible-playbook site.yml --list-hosts
    ansible-playbook site.yml --step
    ansible-playbook site.yml -f 10
}