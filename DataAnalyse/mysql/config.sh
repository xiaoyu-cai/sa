#!/usr/bin/env bash

function config()
{
    wget --no-check-certificate  'http://www.sourceforge.net/projects/boost/files/boost/1.59.0/boost_1_59_0.tar.gz'
    tar -zxvf boost_1_59_0.tar.gz -C /usr/local/
    mv /usr/local/boost_1_59_0 /usr/local/boost
    groupadd mysql
    useradd mysql -g mysql
    echo "mysql" | passwd --stdin mysql

    yum -y install cmake ncurses-devel
    tar -zxvf mysql-boost-5.7.12.tar.gz
    cd mysql-5.7.12

    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
    -DMYSQL_UNIX_ADDR=/usr/local/mysql/mysql.sock \
    -DMYSQL_DATADIR=/usr/local/mysql/data \
    -DENABLED_LOCAL_INFILE=1 \
    -DDEFAULT_CHARSET=utf8 \
    -DDEFAULT_COLLATION=utf8_general_ci \
    -DWITH_EXTRA_CHARSETS:STRING=utf8,gbk \
    -DWITH_MYISAM_STORAGE_ENGINE=1 \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
    -DWITH_MEMORY_STORAGE_ENGINE=1 \
    -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
    -DWITH_READLINE=1 \
    -DENABLED_LOCAL_INFILE=1 \
    -DENABLE_DTRACE=0 \
    -DMYSQL_USER=mysql \
    -DMYSQL_TCP_PORT=3306 \
    -DDOWNLOAD_BOOST=1 \
    -DWITH_BOOST=/usr/local/boost

    cp support-files/mysql.server /etc/init.d/mysqld
    chmod +x /etc/init.d/mysqld
    mkdir /usr/local/mysql/data
    chown -R mysql.mysql  /usr/local/mysql/data
    mkdir /usr/local/mysql/log
    chown -R mysql.mysql  /usr/local/mysql/log
    /usr/local/mysql/bin/mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data
    #A temporary password is generated for root@localhost: #(yI98fmwa&&
    cat > /etc/my.cnf << EOF
[client]
port = 3306
socket = /usr/local/mysql/log/mysql.sock
default-character-set = utf8
[mysqld]
port = 3306
socket = /usr/local/mysql/log/mysql.sock
basedir = /usr/local/mysql
datadir = /usr/local/mysql/data
pid-file = /usr/local/mysql/log/mysql.pid
user = mysql
bind-address = 0.0.0.0
server-id = 1
init-connect = 'SET NAMES utf8'
character-set-server = utf8
#skip-name-resolve
#skip-networking
back_log = 300
max_connections = 1000
max_connect_errors = 6000
open_files_limit = 65535
table_open_cache = 128
max_allowed_packet = 4M
binlog_cache_size = 1M
max_heap_table_size = 8M
tmp_table_size = 16M
read_buffer_size = 2M
read_rnd_buffer_size = 8M
sort_buffer_size = 8M
join_buffer_size = 8M
key_buffer_size = 4M
thread_cache_size = 8
query_cache_type = 1
query_cache_size = 8M
query_cache_limit = 2M
ft_min_word_len = 4
log_bin = mysql-bin
binlog_format = mixed
expire_logs_days = 30
log_error = /usr/local/mysql/log/mysql-error.log
slow_query_log = 1
long_query_time = 1
slow_query_log_file = /usr/local/mysql/log/mysql-slow.log
performance_schema = 0
explicit_defaults_for_timestamp
#lower_case_table_names = 1
skip-external-locking
default_storage_engine = InnoDB
#default-storage-engine = MyISAM
innodb_file_per_table = 1
innodb_open_files = 500
innodb_buffer_pool_size = 64M
innodb_write_io_threads = 4
innodb_read_io_threads = 4
innodb_thread_concurrency = 0
innodb_purge_threads = 1
innodb_flush_log_at_trx_commit = 2
innodb_log_buffer_size = 2M
innodb_log_file_size = 32M
innodb_log_files_in_group = 3
innodb_max_dirty_pages_pct = 90
innodb_lock_wait_timeout = 120
bulk_insert_buffer_size = 8M
myisam_sort_buffer_size = 8M
myisam_max_sort_file_size = 10G
myisam_repair_threads = 1
interactive_timeout = 28800
wait_timeout = 28800
[mysqldump]
quick
max_allowed_packet = 16M
[myisamchk]
key_buffer_size = 8M
sort_buffer_size = 8M
read_buffer = 4M
write_buffer = 4M
EOF
    #ALTER USER 'root'@'localhost' IDENTIFIED BY '123456'
}

function config_percona()
{
    wget --no-check-certificate 'https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-2.3.4/source/tarball/percona-xtrabackup-2.3.4.tar.gz'
    tar -zxvf percona-xtrabackup-2.3.4.tar.gz
    wget http://sphinxsearch.com/files/sphinx-2.0.8-1.rhel6.x86_64.rpm
    yum localinstall --nogpgchec sphinx-2.0.8-1.rhel6.x86_64.rpm
    yum -y install libaio-devel libgcrypt-devel  libcurl-devel libev-devel
    yum install -y sphinx python-sphinx
    yun  install -y python-sphinx-doc
    cmake -DBUILD_CONFIG=xtrabackup_release
}