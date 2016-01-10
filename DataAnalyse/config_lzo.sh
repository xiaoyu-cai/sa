#!/usr/bin/env bash

function config_lzo()
{
    cd /usr/src
    wget http://www.oberhumer.com/opensource/lzo/download/lzo-2.06.tar.gz
    tar -zxvf lzo-2.06.tar.gz
    cd lzo-2.06
    ./configure -enable-shared -prefix=/usr/local/hadoop/lzo/
    make install
    cd /usr/src
    wget https://github.com/twitter/hadoop-lzo/archive/master.zip
    unzip master
    export CFLAGS=-m64
    export CXXFLAGS=-m64
    export C_INCLUDE_PATH=/usr/local/hadoop/lzo/include
    export LIBRARY_PATH=/usr/local/hadoop/lzo/lib
    cd hadoop-lzo-master
    mvn clean package -Dmaven.test.skip=true
    cd target/native/Linux-amd64-64
    tar -cBf - -C lib . | tar -xBvf - -C ~
    cd /usr/src/hadoop-lzo-master
    cp ~/libgplcompression* $HADOOP_HOME/lib/native/
    cp target/hadoop-lzo-0.4.20-SNAPSHOT.jar $HADOOP_HOME/share/hadoop/common/
    lzop mapred-env.sh
    /usr/local/hadoop/bin/hdfs dfs -put mapred-env.sh.lzo /test
    /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/common/hadoop-lzo-0.4.20-SNAPSHOT.jar com.hadoop.compression.lzo.DistributedLzoIndexer /test
}