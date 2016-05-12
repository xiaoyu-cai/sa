#!/usr/bin/env bash
COLOR_RED="\033[0;31m"
COLOR_YELLOW="\033[0;33m"
COLOR_GREEN="\033[0;32m"
COLOR_RESET="\033[0m"

function copy_file_to_deploy()
{
    scp -P9004 ecs/phy/deploy_zabbix.sh allen.cai@java.wochacha.com:/home/allen.cai/
    scp deploy_zabbix.sh root@172.11.12.22:/usr/local/zabbix/bin/
    chmod 755 /usr/local/zabbix/bin/deploy_zabbix.sh
}

function install_zabbix()
{
    cd /usr/src
    wget 'http://jaist.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.0.1/zabbix-3.0.1.tar.gz'
    tar -zxvf zabbix-3.0.1.tar.gz
    cd zabbix-3.0.1
    yum -y install mysql-devel net-snmp-devel curl-devel
    ./configure --prefix=/usr/local/zabbix --enable-server --enable-agent --enable-proxy --with-mysql --with-net-snmp --with-libcurl
    make
    mv /usr/local/zabbix /usr/local/zabbix_1.8
    make install
    mkdir -p /etc/zabbix/scripts
    mkdir -p /var/log/zabbix
    chown -R zabbix.zabbix /var/log/zabbix
    chmod -R 755 /var/log/zabbix
}

function desploy_zabbix_agent()
{
    echo -e "$COLOR_YELLOW start deploy zabbix agentd $COLOR_RESET"
    echo -e "$COLOR_YELLOW agentd ip is $1 $COLOR_RESET"
    ip=$1

    ssh root@$ip killall zabbix_agentd

    scp /usr/local/zabbix/etc/zabbix_agentd.conf root@$ip:/usr/local/zabbix/etc/
    ssh root@$ip sed -i "s/Hostname.*/Hostname=$(hostname)/g" /usr/local/zabbix/etc/zabbix_agentd.conf

    scp /usr/local/zabbix/etc/zabbix_agentd.conf.d/* root@$ip:/usr/local/zabbix/etc/zabbix_agentd.conf.d/

    ssh root@$ip mkdir -p /etc/zabbix/scripts
    scp /etc/zabbix/scripts/* root@$ip:/etc/zabbix/scripts/


    ssh root@$ip /usr/local/zabbix/sbin/zabbix_agentd


    echo -e "$COLOR_GREEN agentd $1 install done $COLOR_RESET"

}

desploy_zabbix_agent $1