#!/usr/bin/env bash


function config_e()
{
    cd /usr/src
    wget 'https://download.elasticsearch.org/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/2.2.0/elasticsearch-2.2.0.tar.gz'
    tar -zxvf elasticsearch-2.2.0.tar.gz
    mv elasticsearch-2.2.0 /usr/local/elasticsearch
    /usr/local/elasticsearch/bin/plugin install mobz/elasticsearch-head
    /usr/local/elasticsearch/bin/plugin install lmenezes/elasticsearch-kopf
}

function config_l()
{
    cd /usr/src
    wget 'https://download.elastic.co/logstash/logstash/logstash-2.2.2.tar.gz'
    tar -zxvf logstash-2.2.2.tar.gz
    cd logstash-2.2.2
    bin/plugin list
    bin/logstash -e 'input{stdin{}}output{stdout{codec=>rubydebug}}'
    bin/logstash -e '
    input {
        stdin {
            codec => multiline { pattern => "^\[" negate => true what => "previous"
            }
        }
    }
    output{stdout{codec=>rubydebug}}'
}

function config_k()
{
    cd /usr/src
    wget 'https://download.elastic.co/kibana/kibana/kibana-4.4.2-linux-x64.tar.gz'
    tar -zxvf kibana-4.4.2-linux-x64.tar.gz
    mv kibana-4.4.2-linux-x64 /usr/local/kibana
}


function install_collectd()
{
    cd /usr/src
    wget 'http://120.52.72.52/collectd.org/c3pr90ntcsf0/files/collectd-5.4.2.tar.bz2'
    tar -jxvf collectd-5.4.2.tar.bz2

}

function config_ruby()
{
    yum -y install openssl*
    wget https://ruby.taobao.org/mirrors/ruby/ruby-2.1.2.tar.gz
    tar zxvf ruby-2.1.2.tar.gz
    cd ruby-2.1.2
    ./configure
    make && make install
    gem source -r https://rubygems.org/
    gem sources -a https://ruby.taobao.org/
    gem sources -l
}

function config_ftp()
{
    yum -y install vsftpd
    sestatus -b | grep ftp
    setsebool -P ftp_home_dir on
    setsebool -P allow_ftpd_full_access on
}

function config_supervisor()
{
    echo 'start config supervisor'
}

function config_iptables_zabbix()
{
    #echo "UserParameter=iptables.lines,sudo /sbin/iptables -L -n | /usr/bin/wc -l" > /opt/app/zabbix/etc/zabbix_agentd.conf.d/iptables.conf
    echo "UserParameter=iptables.lines,sudo /sbin/iptables -L -n | /usr/bin/wc -l" >> /opt/app/zabbix/etc/zabbix_agentd.conf.d/iptables.conf

    echo 'Defaults:zabbix   !requiretty' >> /etc/sudoers
    echo "zabbix  ALL=NOPASSWD: /sbin/iptables -L -n" >> /etc/sudoers
    killall zabbix_agentd
    /opt/app/zabbix/sbin/zabbix_agentd
    netstat -tnlp
}

function config_iptables_nagios()
{
    /etc/init.d/iptables status >> /tmp/iptables
    mv /bin/iptables.sh /bin/iptables.sh.bk
    curl op.sdo.com/download/prelin/iptables.sh -o /bin/iptables.sh
    chmod +x /bin/iptables.sh
    netstat -tnlp
    #/sbin/iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    #/sbin/iptables -A INPUT -p tcp --dport 443 -j ACCEPT

    echo "kern.=debug /var/log/iptables.log" >> /etc/syslog.conf
    /etc/init.d/syslog restart
    chmod +r /var/log/iptables.log

    curl op.sdo.com/download/prelin/check_iptables_drop.sh -o /opt/app/nrpe/libexec/check_iptables_drop.sh
    chmod +x /opt/app/nrpe/libexec/check_iptables_drop.sh
    chown nagios.nagios /opt/app/nrpe/libexec/check_iptables_drop.sh


    echo "command[check_iptables_drop]=/opt/app/nrpe/libexec/check_iptables_drop.sh" >> /opt/app/nrpe/etc/nrpe.cfg
    killall nrpe
    /opt/app/nrpe/bin/nrpe -c /opt/app/nrpe/etc/nrpe.cfg -d

:<<eof
/opt/nagios/etc/objects/Project/services.cfg

eofdefine service {
                service_description                   check_nrpe_iptables_drop
                check_command                         check_nrpe!check_iptables_drop
                host_name                             10.126.16.21
                check_period                          24x7
                notification_period                   24x7
                use                                   srv-pnp
                contact_groups                        +admins
}
eof
    /opt/nagios/bin/nagios -v /opt/nagios/etc/nagios.cfg
    /etc/init.d/nagios reload
}

0.0.0.0  -l root -p 58422