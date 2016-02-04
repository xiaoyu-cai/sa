#!/usr/bin/env bash

function config_epel()
{
    [ -f /etc/yum.repos.d/epel.repo ] && epel_exist=1 || epel_exist=0
    if [ $epel_exist = 1 ]; then
        echo "epel exist"
        exit
    fi
    wget 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm'
    rpm -ivh epel-release-latest-6.noarch.rpm
    sed -i 's/#baseurl=http:\/\/download.fedoraproject.org\/pub\/epel\/6\/$basearch/baseurl=http:\/\/download.fedoraproject.org\/pub\/epel\/6\/$basearch/g' /etc/yum.repos.d/epel.repo
    sed -i 's/mirrorlist=https:\/\/mirrors.fedoraproject.org\/metalink?repo=epel-6&arch=$basearch/#mirrorlist=https:\/\/mirrors.fedoraproject.org\/metalink?repo=epel-6&arch=$basearch/g' /etc/yum.repos.d/epel.repo
}

function config_limit(){

    conf_file="/etc/security/limits.conf"
    if [ -f $conf_file ]; then
        cat >> /etc/security/limits.conf <<EOF
*           soft    nproc           81920
*           hard    nproc           81920
*           soft    core            1024
*           hard    core            1024
*           soft    nofile          20480
*           hard    nofile          20480
EOF
    fi

}

function config_kernel()
{
mkdir -p /etc/sysctl.d/
cat > /etc/sysctl.d/http_tweak.conf <<EOF
net.netfilter.nf_conntrack_max = 6000000
net.netfilter.nf_conntrack_tcp_timeout_established = 1500
net.ipv4.tcp_max_tw_buckets = 131070
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 30
net.ipv4.ip_local_port_range = 1024    65000
net.ipv4.route.flush = 1
net.ipv4.conf.lo.arp_ignore=1
net.ipv4.conf.lo.arp_announce=2
net.ipv4.conf.all.arp_ignore=1
net.ipv4.conf.all.arp_announce=2
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF
    sysctl -p /etc/sysctl.d/http_tweak.conf > /dev/null
}

function config_network()
{
    echo ''
}


function config_glusterfs()
{
    echo 'start install glusterfs'
}



