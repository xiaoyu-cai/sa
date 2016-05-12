#!/usr/bin/env bash
function preusers()
{

echo "Now create 6 groups named 'oinstall','dba','asmadmin','asmdba','asmoper','oper'"
echo "Plus 2 users named 'oracle','grid',Also setting the Environment"


groupadd -g 1000 oinstall
groupadd -g 1200 asmadmin
groupadd -g 1201 asmdba
groupadd -g 1202 asmoper
useradd -u 1100 -g oinstall -G asmadmin,asmdba,asmoper -d /home/grid -s /bin/bash -c "grid Infrastructure Owner" grid
echo "grid" | passwd --stdin grid

echo 'export PS1="`/bin/hostname -s`-> "'>> /home/grid/.bash_profile
echo "export TMP=/tmp">> /home/grid/.bash_profile
echo 'export TMPDIR=$TMP'>>/home/grid/.bash_profile
echo "export ORACLE_SID=+ASM1">> /home/grid/.bash_profile
echo "export ORACLE_BASE=/u01/app/grid">> /home/grid/.bash_profile
echo "export ORACLE_HOME=/u01/app/11.2.0/grid">> /home/grid/.bash_profile
echo "export ORACLE_TERM=xterm">> /home/grid/.bash_profile
echo "export NLS_DATE_FORMAT='yyyy/mm/dd hh24:mi:ss'" >> /home/grid/.bash_profile
echo 'export TNS_ADMIN=$ORACLE_HOME/network/admin'  >> /home/grid/.bash_profile
echo 'export PATH=/usr/sbin:$PATH'>> /home/grid/.bash_profile
echo 'export PATH=$ORACLE_HOME/bin:$PATH'>> /home/grid/.bash_profile
echo 'export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib'>> /home/grid/.bash_profile
echo 'export CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib'>> /home/grid/.bash_profile
echo "export EDITOR=vi" >> /home/grid/.bash_profile
echo "export LANG=en_US" >> /home/grid/.bash_profile
echo "export NLS_LANG=american_america.AL32UTF8" >> /home/grid/.bash_profile
echo "umask 022">> /home/grid/.bash_profile

groupadd -g 1300 dba
groupadd -g 1301 oper
useradd -u 1101 -g oinstall -G dba,oper,asmdba -d /home/oracle -s /bin/bash -c "Oracle Software Owner" oracle
echo "oracle" | passwd --stdin oracle

echo 'export PS1="`/bin/hostname -s`-> "'>> /home/oracle/.bash_profile
echo "export TMP=/tmp">> /home/oracle/.bash_profile
echo 'export TMPDIR=$TMP'>>/home/oracle/.bash_profile
echo "export ORACLE_HOSTNAME=node1.localdomain">> /home/oracle/.bash_profile
echo "export ORACLE_SID=devdb1">> /home/oracle/.bash_profile
echo "export ORACLE_BASE=/u01/app/oracle">> /home/oracle/.bash_profile
echo 'export ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1'>> /home/oracle/.bash_profile
echo "export ORACLE_UNQNAME=devdb">> /home/oracle/.bash_profile
echo 'export TNS_ADMIN=$ORACLE_HOME/network/admin'  >> /home/oracle/.bash_profile
echo "export ORACLE_TERM=xterm">> /home/oracle/.bash_profile
echo 'export PATH=/usr/sbin:$PATH'>> /home/oracle/.bash_profile
echo 'export PATH=$ORACLE_HOME/bin:$PATH'>> /home/oracle/.bash_profile
echo 'export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib'>> /home/oracle/.bash_profile
echo 'export CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib'>> /home/oracle/.bash_profile
echo "export EDITOR=vi" >> /home/oracle/.bash_profile
echo "export LANG=en_US" >> /home/oracle/.bash_profile
echo "export NLS_LANG=american_america.AL32UTF8" >> /home/oracle/.bash_profile
echo "export NLS_DATE_FORMAT='yyyy/mm/dd hh24:mi:ss'" >> /home/oracle/.bash_profile
echo "umask 022">> /home/oracle/.bash_profile

echo "The Groups and users has been created"
echo "The Environment for grid,oracle also has been set successfully"

}


function predir()
{
echo "Now create the necessary directory for oracle,grid users and change the authention to oracle,grid users..."
mkdir -p /u01/app/grid
mkdir -p /u01/app/11.2.0/grid
mkdir -p /u01/app/oracle
chown -R oracle:oinstall /u01
chown -R grid:oinstall /u01/app/grid
chown -R grid:oinstall /u01/app/11.2.0
chmod -R 775 /u01
echo "The necessary directory for oracle,grid users and change the authention to oracle,grid users has been finished"
}

function prelimits()
{
echo "Now modify the /etc/security/limits.conf,but backup it named /etc/security/limits.conf.bak before"
cp /etc/security/limits.conf /etc/security/limits.conf.bak
echo "oracle soft nproc 2047" >>/etc/security/limits.conf
echo "oracle hard nproc 16384" >>/etc/security/limits.conf
echo "oracle soft nofile 1024" >>/etc/security/limits.conf
echo "oracle hard nofile 65536" >>/etc/security/limits.conf
echo "grid soft nproc 2047" >>/etc/security/limits.conf
echo "grid hard nproc 16384" >>/etc/security/limits.conf
echo "grid soft nofile 1024" >>/etc/security/limits.conf
echo "grid hard nofile 65536" >>/etc/security/limits.conf
echo "Modifing the /etc/security/limits.conf has been succeed."
}

function prelogin()
{
echo "Now modify the /etc/pam.d/login,but with a backup named /etc/pam.d/login.bak"
cp /etc/pam.d/login /etc/pam.d/login.bak

echo "session required /lib/security/pam_limits.so" >>/etc/pam.d/login
echo "session required pam_limits.so" >>/etc/pam.d/login

echo "Modifing the /etc/pam.d/login has been succeed."
}

function preprofile()
{
echo "Now modify the  /etc/profile,but with a backup named  /etc/profile.bak"
cp /etc/profile /etc/profile.bak
echo 'if [ $USER = "oracle" ]||[ $USER = "grid" ]; then' >>  /etc/profile
echo 'if [ $SHELL = "/bin/ksh" ]; then' >> /etc/profile
echo 'ulimit -p 16384' >> /etc/profile
echo 'ulimit -n 65536' >> /etc/profile
echo 'else' >> /etc/profile
echo 'ulimit -u 16384 -n 65536' >> /etc/profile
echo 'fi' >> /etc/profile
echo 'fi' >> /etc/profile
echo "Modifing the /etc/profile has been succeed."
}

function presysctl()
{
echo "Now modify the /etc/sysctl.conf,but with a backup named /etc/sysctl.bak"
cp /etc/sysctl.conf /etc/sysctl.conf.bak

echo "fs.aio-max-nr = 1048576" >> /etc/sysctl.conf
echo "fs.file-max = 6815744" >> /etc/sysctl.conf
echo "kernel.shmall = 2097152" >> /etc/sysctl.conf
echo "kernel.shmmax = 1054472192" >> /etc/sysctl.conf
echo "kernel.shmmni = 4096" >> /etc/sysctl.conf
echo "kernel.sem = 250 32000 100 128" >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 9000 65500" >> /etc/sysctl.conf
echo "net.core.rmem_default = 262144" >> /etc/sysctl.conf
echo "net.core.rmem_max = 4194304" >> /etc/sysctl.conf
echo "net.core.wmem_default = 262144" >> /etc/sysctl.conf
echo "net.core.wmem_max = 1048586" >> /etc/sysctl.conf
echo "net.ipv4.tcp_wmem = 262144 262144 262144" >> /etc/sysctl.conf
echo "net.ipv4.tcp_rmem = 4194304 4194304 4194304" >> /etc/sysctl.conf

echo "Modifing the /etc/sysctl.conf has been succeed."
echo "Now make the changes take effect....."
sysctl -p
}

preusers
predir
prelimits
prelogin
preprofile
presysctl