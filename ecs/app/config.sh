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


function config_puppet()
{
    yum -y install puppet-server puppet
    puppet master --no-daemonize --verbose
    puppet agent --test --server ecgp --debug
    puppet cert list --all
    puppet cert sign --all
    puppet parser validate /etc/puppet/modules/test/manifests/init.pp
    puppet agent --test --server ecgp --noop
    puppet apply modules/test/manifests/init.pp
    erb -P -x -T '-' zabbix_agentd.conf.erb | ruby -c
}

function config_puppet_master()
{
    cat > /etc/puppet/puppet_bk.conf <<EOF
[main]
    logdir = /var/log/puppet
    rundir = /var/run/puppet
    ssldir = \$vardir/ssl
[master]
    pluginsync = true
    reports = log,foreman
    environment = production
    certname = ecgp
EOF
mkdir -p /etc/puppet/modules/tests/{manifests,templates,files}
}

function config_puppet_agent()
{
    cat > /etc/puppet/puppet.conf <<EOF
[main]
    logdir = /var/log/puppet
    rundir = /var/run/puppet
    ssldir = \$vardir/ssl
[agent]
    classfile = \$vardir/classes.txt
    localconfig = \$vardir/localconfig
    runinterval = 30
    listen = true
    report = true
    server = ecgp
EOF

}


function config_repo()
{
    yum -y install yum-downloadonly createrepo yum-arch
    mkdir -pv /data/mirrors/centos/6/{os,updates}/x86_64/RPMS
    yum -y install nginx --enablerepo=epel --downloadonly --downloaddir=/data/mirrors/centos/6/os/x86_64/RPMS/
    createrepo /data/mirrors/centos/6/os/x86_64/
    yum-arch -l /data/mirrors/centos/6/os/x86_64/
}