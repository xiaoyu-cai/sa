#!/usr/bin/env bash

function install_config_dns()
{
    yum install -y bind*
    sed -i 's/listen-on port 53.*/listen-on port 53 { any; };/g' /etc/named.conf
    sed -i 's/allow-query.*/allow-query     { any; };/g' /etc/named.conf

echo  '
zone "alpha.wochacha.com" IN {
        type master;
        file "alpha.wochacha.com.zone";
};

zone "168.192.in-addr.arpa" IN {
        type master;
        file "192.168.zone";
}; ' >> /etc/named.rfc1912.zones

echo '
$TTL 1D
@       IN SOA  www.alpha.wochacha.com.   root (
                                        1       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
@       IN      NS      www.alpha.wochacha.com.
www     IN      A       192.168.1.9
pc     IN      A       192.168.1.9
mall     IN      A       192.168.1.9
ec     IN      A       192.168.1.9
' >> /var/named/chroot/var/named/alpha.wochacha.com.zone
echo '
$TTL 43200;
@   86400   IN  SOA alpha.wochahca.com. admin.bob.org. (
        201410070001;
        1h;
        5m;
        7d;
        1d;
)

    IN  NS  alpha.wochahca.com.
    IN  MX  10  mail1.bob.org.
    IN  MX  20  mail2.bob.org.
9.1  IN  PTR alpha.wochahca.com.
7.1  IN  PTR ec.alpha.wochahca.com.
7.1  IN  PTR mall.alpha.wochahca.com.
' >> /var/named/chroot/var/named/192.168.zone
/etc/init.d/named restart
}

function config_slave()
{
    yum install -y bind*
    sed -i 's/listen-on port 53.*/listen-on port 53 { any; };/g' /etc/named.conf
    sed -i 's/allow-query.*/allow-query     { any; };/g' /etc/named.conf
    sed -i 's/managed-keys-directory "\/var\/named\/dynamic";/managed-keys-directory "\/var\/named\/dynamic";\n\tnotify yes;\n\talso-notify{ 192.168.200.21; };/g'  /etc/named.conf
    echo   '
     zone "alpha.wochacha.com" IN {
        type slave;
        masters { 192.168.1.7; };
        file "slaves/alpha.wochacha.com.zone";
    }; ' >> /etc/named.conf

    /etc/init.d/named restart
}

function install_config_lvs()
{
    yum clean all
    yum -y install libnl* popt-devel popt-static
    wget http://www.linuxvirtualserver.org/software/kernel-2.6/ipvsadm-1.26.tar.gz
    tar -zxvf ipvsadm-1.26.tar.gz
    cd ipvsadm-1.26
    make install
    ipvsadm -l
    ipvsadm -C
    ipvsadm -A -t 1.1.1.1:80 -s rr
    ipvsadm -a -t 1.1.1.1:80 -r 192.168.1.2:80 -b
    yum -y install quagga
    cat > /etc/quagga/ospfd.conf << EOF
! -*- ospf -*-
!
! OSPFd sample configuration file
!
!
hostname ospfd
password zebra
!enable password please-set-at-here
!
log file /var/log/quagga/ospf.log
log stdout
log syslog
interface br0
ip ospf hello-interval 1
ip ospf dead-interval 4
router ospf
ospf router-id 192.168.0.1
log-adjacency-changes
auto-cost reference-bandwidth 1000
network 1.1.1.1/32 area 0.0.0.0
network 192.168.0.0/24 area 0.0.0.0
!router ospf
!  network 192.168.1.0/24 area 0
!
log stdout
EOF
    /etc/init.d/ospfd start
}

function install_config_varnish()
{
    yum -y install epel-release
    rpm --nosignature -i https://repo.varnish-cache.org/redhat/varnish-4.0.el6.rpm
    yum -y install varnish
    cat > /etc/varnish/default.vcl << EOF
backend web1 {
    .host = "172.16.10.7";
    .port = "80";
}
backend web2 {
    .host = "172.16.10.3";
    .port = "80";
}
backend app1 {
    .host = "172.16.10.7";
    .port = "8080";
}
backend app2 {
    .host = "172.16.10.3";
    .port = "8080";
}

director webserver  random {
    {.backend = web1;.weight  = 2;}
    {.backend = web2;.weight = 5;}
}
director appserver  random {
    {.backend = app1;.weight = 2;}
    {.backend = app2;.weight = 5;}
}

acl purgers {
    "127.0.0.1";
    "172.16.10.0"/16;
}

sub vcl_recv {

    if (req.http.x-forwarded-for) {
        set req.http.X-Forwarded-For = req.http.X-Forwarded-For "," client.ip;
    } else {
        set req.http.X-Forwarded-For = client.ip;
    }

    if (req.url ~ "\.php$"){
        set req.backend = appserver;
    }else{
        set req.backend = webserver;
    }

    if (req.request != "GET" &&
        req.request != "HEAD" &&
        req.request != "PUT" &&
        req.request != "POST" &&
        req.request != "TRACE" &&
        req.request != "OPTIONS" &&
        req.request != "DELETE") {
        return (pipe);
    }
    if (req.request != "GET" && req.request != "HEAD") {
        return (pass);
    }

    if (req.http.Authorization || req.http.Cookie) {
        return (pass);
    }

    if (req.request == "PURGE"){
        if(!client.ip ~ purgers){
            error 405 "Method not allowed";
        }
        return (lookup);
    }

    if (req.http.Accept-Encoding) {
        if (req.url ~ "\.(jpg|png|gif|gz|tgz|bz2|tbz|mp3|ogg)$") {
            remove req.http.Accept-Encoding;
        } else if (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } else if (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        } else {
            remove req.http.Accept-Encoding;
        }
    }
}

sub vcl_hit {
    if (req.request == "PURGE"){
        error 200 "Purged";
    }
}

sub vcl_miss {
    if (req.request == "PURGE"){
        error 404 "Not in cache";
    }
}

sub vcl_pass {
    if (req.request == "PURGE"){
        error 502 "PURGE on a passed object";
    }
}

sub vcl_fetch {

    if (req.request == "GET" && req.url ~ "\.html$") {
        set beresp.ttl = 300s;
        if (req.request == "GET" && req.url ~ "\.(png|xsl|xml|pdf|ppt|doc|docx|chm|rar|zip|bmp|jpeg|swf|ico|mp3|mp4|rmvb|ogg|mov|avi|wmv|swf|txt|png|gif|jpg|css|js|html|htm)$") {
            set beresp.ttl = 600s;
        }
        return (deliver);
    }
}

sub vcl_deliver {

    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }
}
EOF
    /usr/sbin/varnishd -P /var/run/varnish.pid -a :6081 -f /etc/varnish/default.vcl -T 127.0.0.1:6082 -t 120 -w 1,1000,120 -u varnish -g varnish -S /etc/varnish/secret -s file,/var/lib/varnish/varnish_storage.bin,1G
}

function install_config_haproxy()
{
    yum -y install haproxy
    sed -i 's/log         127.0.0.1 local2/log         127.0.0.1 local0/g' /etc/haproxy/haproxy.cfg
    mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bk
    cat > /etc/rsyslog.d/haproxy.conf <<EOF
\$ModLoad imudp
\$UDPServerRun 514
\$template Haproxy,"%msg%\n"
local0.=info /var/log/haproxy.log;Haproxy
local0.notice /var/log/haproxystatus.log;Haproxy
local0.* ~
EOF
    cat /etc/haproxy/haproxy.cfg << EOF
global
    log         127.0.0.1 local0

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

    stats socket /var/lib/haproxy/stats

defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000
listen webfarm *:81
       mode http
       stats enable
       stats uri /haproxy?stats
       stats realm Haproxy\ Statistics
       stats auth haproxy:stats
       balance roundrobin
       cookie LBN insert indirect nocache
       option httpclose
       option forwardfor
       server web01 192.168.1.9:80 cookie node1 check
       server web02 192.168.1.7:80 cookie node2 check
EOF
    /etc/init.d/haproxy start
}

function install_config_squid()
{
    yum -y install squid
    cat > /etc/squid/squid.conf << EOF
########## Base control ##########
cache_mgr admin@jedy.com
visible_hostname squid.jedy.com
http_port 0.0.0.0:82 accel vhost
icp_port 0
cache_mem 100 MB
cache_dir ufs /var/spool/squid 100 16 256
logformat combined %>a %ui %un [%tl] "%rm %ru HTTP/%rv" %>Hs %<st "%{Referer}>h" "%{User-Agent}>h" %Ss:%Sh
access_log /var/log/squid/access_log combined
cache_log /var/log/squid/cache_log
cache_store_log none
logfile_rotate 60                                                     # log轮循 60天
#error_directory /usr/local/squid/share/errors/zh-cn          # 错误页面的语言
#unlinkd_program /usr/local/squid/libexec/unlinkd                       # 指定文件删除进程的完整路径   我也没弄懂
strip_query_terms off                                                  #在日志中记录URL的完整路径包含“？”后面的参数。
#cache_vary on                                                           #支持http 1.1的动态压缩
acl apache rep_header Server ^Apache
#broken_vary_encoding allow apache
########## Performance control ##########
cache_swap_low 90
cache_swap_high 95                                                                                 #cache目录的限值，超过总容量的85%时会自动清理
maximum_object_size 4096 KB
minimum_object_size 0 KB
maximum_object_size_in_memory 2048 KB                              # 与内存有关的参数
ipcache_size 2048                                               # 缓存dns的正反向解析
ipcache_low 90
ipcache_high 95
cache_replacement_policy lru
memory_replacement_policy lru
#log_ip_on_direct on
log_mime_hdrs off
request_header_max_size 64 KB
request_body_max_size 0 KB
negative_ttl 5 minutes             # 错误页面缓存时间
connect_timeout 1 minute
read_timeout 1 minutes
request_timeout 1 minutes
client_lifetime 30 minutes
half_closed_clients on
#<refresh_pattern> <页面类型> <最小时间> <百分比> <最大时间>
refresh_pattern -i \.htm$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.html$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.shtml$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.shtm$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.xml$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.jpg$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.jpeg$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.png$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.gif$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.bmp$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.css$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.js$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.swf$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.doc$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.ppt$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.xls$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.pdf$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.cab$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.exe$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.zip$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.dll$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.rar$ 1440 90% 129600 reload-into-ims
refresh_pattern -i \.zip$ 1440 90% 129600 reload-into-ims
refresh_pattern . 0 0% 0
acl purge method PURGE
acl QUERY urlpath_regex cgi-bin .php .cgi .asp .jsp .do
##acl all src all                                 \squid 3.0后 默认设置好了，不用另加，否则起不来
acl testip src 127.0.0.1/32 192.168.10.0/24
acl testdst dstdomain .wochacha.com
###### Reverse proxy###########
#<cache_peer> <主机名称> <类别> <http_port> <icp_port> <其它参数>
cache_peer 192.168.1.7 parent 80 0 no-query originserver name=ec
cache_peer 192.168.1.9 parent 80 0 no-query originserver name=mall
cache_peer_domain ec ec.alpha.wochacha.com
cache_peer_domain mall mall.alpha.wochacha.com

#<cache_peer_access> <上层 Proxy > <allow|deny> <acl名称>
cache_peer_access ec allow all
cache_peer_access mall allow testip

########## Access control ############
http_access allow QUERY
#http_access allow purge master
http_access allow testdst
http_access deny all
cache deny QUERY
hierarchy_stoplist cgi-bin ?
acl CactiServer src 192.168.20.11
acl SNMP snmp_community public                       # 允许snmp通过
snmp_port 3401
snmp_access allow SNMP CactiServer
snmp_access deny all
EOF
}

function install_config_mycat()
{
    wget 'https://raw.githubusercontent.com/MyCATApache/Mycat-download/master/1.4-RELEASE/Mycat-server-1.4-release-20151019230038-linux.tar.gz' --no-check-certificate    tar -zxvf Mycat-server-2.0-dev-20151218210146-linux.tar.gz
    tar -zxvf Mycat-server-1.4-release-20151019230038-linux.tar.gz
    mv mycat /usr/local/mycat
}

function config_pycharm_debug()
{
    scp /Applications/PyCharm.app/Contents/debug-eggs/pycharm-debug.egg root@192.168.200.61:/usr/src/
    easy_install pycharm-debug.egg
}