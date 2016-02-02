#!/usr/bin/env bash

config_postgresql()
{
    yum -y install systemtap pam-devel tcl-devel python-devel
    wget 'https://ftp.postgresql.org/pub/source/v9.3.2/postgresql-9.3.2.tar.bz2'
    tar -jxvf postgresql-9.3.2.tar.bz2
    cd postgresql-9.3.2
    ./configure --prefix=/usr/local/pgsql --with-pgport=5432 \
    --with-perl --with-python --with-tcl --with-openssl \
    --with-pam  --without-ldap --with-libxml  --with-libxslt  \
    --enable-thread-safety  --with-wal-blocksize=16 \
    --with-blocksize=16 --enable-dtrace --enable-debug
    gmake world
    gmake install-world
    echo /usr/local/postgresql/lib >> /etc/ld.so.conf.d/postgresql.conf
    ldconfig
    useradd postgres
    su postgres
    cat >> ~/.bash_profile <<EOF
export PGHOME=/usr/local/pgsql
export PGDATA=/usr/local/pgsql/data
export PATH=$PGHOME/bin:$PATH
export MANPATH=$PGHOME/share/man:$MANPATH
export LD_LIBRARY_PATH=$PGHOME/lib:$LD_LIBRARY_PATH
EOF
    source ~/.bash_profile
    initdb -D /usr/local/pgsql/data
    nohup postgres -D /usr/local/pgsql/data >> /usr/local/pgsql/logfile 2>&1 &
}