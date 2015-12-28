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

function install_config_mycat()
{
    wget 'https://raw.githubusercontent.com/MyCATApache/Mycat-download/master/1.4-RELEASE/Mycat-server-1.4-release-20151019230038-linux.tar.gz' --no-check-certificate    tar -zxvf Mycat-server-2.0-dev-20151218210146-linux.tar.gz
    tar -zxvf Mycat-server-1.4-release-20151019230038-linux.tar.gz
    mv mycat /usr/local/mycat
}