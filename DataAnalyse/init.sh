#!/usr/bin/env bash

function config_flume_server()
{
    wget 'http://mirrors.cnnic.cn/apache/flume/1.6.0/apache-flume-1.6.0-bin.tar.gz'
    tar -zxvf apache-flume-1.6.0-bin.tar.gz
    mv apache-flume-1.6.0-bin /usr/local/flume
    cd /usr/local/hadoop
    cp ./share/hadoop/common/hadoop-common-2.6.0.jar /usr/local/flume/lib/
    cp ./share/hadoop/common/lib/commons-configuration-1.6.jar /usr/local/flume/lib/
    cp ./share/hadoop/common/lib/hadoop-auth-2.6.0.jar /usr/local/flume/lib/
    cp ./share/hadoop/hdfs/hadoop-hdfs-2.6.0.jar /usr/local/flume/lib/
    cp ./share/hadoop/common/lib/htrace-core-3.0.4.jar /usr/local/flume/lib/

    cat > /usr/local/flume/conf/flume_directHDFS.conf <<EOF
# Define a memory channel called ch1 on agent1
agent1.channels.ch1.type = memory
agent1.channels.ch1.capacity = 100000
agent1.channels.ch1.transactionCapacity = 100000
agent1.channels.ch1.keep-alive = 30

# Define an Avro source called avro-source1 on agent1 and tell it
# to bind to 0.0.0.0:41414. Connect it to channel ch1.
#agent1.sources.avro-source1.channels = ch1
#agent1.sources.avro-source1.type = avro
#agent1.sources.avro-source1.bind = 0.0.0.0
#agent1.sources.avro-source1.port = 41414
#agent1.sources.avro-source1.threads = 5

#define source monitor a file
agent1.sources.avro-source1.type = exec
agent1.sources.avro-source1.shell = /bin/bash -c
agent1.sources.avro-source1.command = tail -F /usr/local/webserver/nginx/logs/test.log
agent1.sources.avro-source1.channels = ch1
agent1.sources.avro-source1.threads = 5

# Define a logger sink that simply logs all events it receives
# and connect it to the other end of the same channel.
agent1.sinks.log-sink1.channel = ch1
agent1.sinks.log-sink1.type = hdfs
agent1.sinks.log-sink1.hdfs.path = hdfs://127.0.0.1:8020/flumeTest
agent1.sinks.log-sink1.hdfs.writeFormat = Text
agent1.sinks.log-sink1.hdfs.fileType = DataStream
agent1.sinks.log-sink1.hdfs.rollInterval = 0
agent1.sinks.log-sink1.hdfs.rollSize = 0
agent1.sinks.log-sink1.hdfs.rollCount = 1000000
agent1.sinks.log-sink1.hdfs.batchSize = 1000
agent1.sinks.log-sink1.hdfs.txnEventMax = 1000
agent1.sinks.log-sink1.hdfs.callTimeout = 60000
agent1.sinks.log-sink1.hdfs.appendTimeout = 60000

# Finally, now that we've defined all of our components, tell
# agent1 which ones we want to activate.
agent1.channels = ch1
agent1.sources = avro-source1
agent1.sinks = log-sink1
EOF
    cat > /usr/local/flume/conf/flume_consolidation.conf << EOF
# collectorMainAgent
collectorMainAgent.channels = c2
collectorMainAgent.sources  = s2
collectorMainAgent.sinks    =k1 k2
# collectorMainAgent AvroSource
#
collectorMainAgent.sources.s2.type = avro
collectorMainAgent.sources.s2.bind = ecgp
collectorMainAgent.sources.s2.port = 41415
collectorMainAgent.sources.s2.channels = c2

# collectorMainAgent FileChannel
#
collectorMainAgent.channels.c2.type = file
collectorMainAgent.channels.c2.checkpointDir =/usr/local/opt/var/flume/fchannel/spool/checkpoint
collectorMainAgent.channels.c2.dataDirs = /usr/local/opt/var/flume/fchannel/spool/data,/usr/local/work/flume/fchannel/spool/data
collectorMainAgent.channels.c2.capacity = 200000000
collectorMainAgent.channels.c2.transactionCapacity=6000
collectorMainAgent.channels.c2.checkpointInterval=60000
# collectorMainAgent hdfsSink
collectorMainAgent.sinks.k2.type = hdfs
collectorMainAgent.sinks.k2.channel = c2
collectorMainAgent.sinks.k2.hdfs.path = hdfs://127.0.0.1:8020/flume%{dir}
collectorMainAgent.sinks.k2.hdfs.filePrefix =k2_%{file}
collectorMainAgent.sinks.k2.hdfs.inUsePrefix =_
collectorMainAgent.sinks.k2.hdfs.inUseSuffix =.tmp
collectorMainAgent.sinks.k2.hdfs.rollSize = 268435456
collectorMainAgent.sinks.k2.hdfs.rollCount = 0
collectorMainAgent.sinks.k2.hdfs.rollInterval = 600
collectorMainAgent.sinks.k2.hdfs.writeFormat = Text
collectorMainAgent.sinks.k2.hdfs.fileType = DataStream
collectorMainAgent.sinks.k2.hdfs.batchSize = 1000
collectorMainAgent.sinks.k2.hdfs.idleTimeout = 3600
#collectorMainAgent.sinks.k2.hdfs.minBlockReplicas = 1
collectorMainAgent.sinks.k1.type = hdfs
collectorMainAgent.sinks.k1.channel = c2
collectorMainAgent.sinks.k1.hdfs.path = hdfs://127.0.0.1:8020/flume%{dir}
collectorMainAgent.sinks.k1.hdfs.filePrefix =k1_%{file}
collectorMainAgent.sinks.k1.hdfs.inUsePrefix =_
collectorMainAgent.sinks.k1.hdfs.inUseSuffix =.tmp
collectorMainAgent.sinks.k1.hdfs.rollSize = 268435456
collectorMainAgent.sinks.k1.hdfs.rollCount = 0
collectorMainAgent.sinks.k1.hdfs.rollInterval = 600
collectorMainAgent.sinks.k1.hdfs.writeFormat = Text
collectorMainAgent.sinks.k1.hdfs.fileType = DataStream
collectorMainAgent.sinks.k1.hdfs.batchSize = 1000
collectorMainAgent.sinks.k1.hdfs.idleTimeout = 3600
#collectorMainAgent.sinks.k1.hdfs.minBlockReplicas = 1
EOF
    #/usr/local/flume/bin/flume-ng agent --conf /usr/local/flume/conf -f /usr/local/flume/conf/flume_directHDFS.conf -n agent1 -Dflume.root.logger=DEBUG,console
    /usr/local/flume/bin/flume-ng agent --conf /usr/local/flume/conf -f /usr/local/flume/conf/flume_consolidation.conf -n collectorMainAgent -Dflume.root.logger=DEBUG,console
}

function config_flume_client()
{
    wget 'http://mirrors.cnnic.cn/apache/flume/1.6.0/apache-flume-1.6.0-bin.tar.gz'
    tar -zxvf apache-flume-1.6.0-bin.tar.gz
    mv apache-flume-1.6.0-bin /usr/local/flume
    cat > /usr/local/flume/conf/flume_consolidation.conf <<EOF
# clientMainAgent
clientMainAgent.channels = c1
clientMainAgent.sources  = s1
clientMainAgent.sinks    = k1 k2
# clientMainAgent sinks group
clientMainAgent.sinkgroups = g1
# clientMainAgent Spooling Directory Source
clientMainAgent.sources.s1.type = spooldir
clientMainAgent.sources.s1.spoolDir  =/usr/local/nginx/logs
clientMainAgent.sources.s1.fileHeader = true
clientMainAgent.sources.s1.deletePolicy =never
clientMainAgent.sources.s1.batchSize =1000
clientMainAgent.sources.s1.channels =c1
clientMainAgent.sources.s1.deserializer.maxLineLength =1048576
# clientMainAgent FileChannel
clientMainAgent.channels.c1.type = file
clientMainAgent.channels.c1.checkpointDir = /var/flume/fchannel/spool/checkpoint
clientMainAgent.channels.c1.dataDirs = /var/flume/fchannel/spool/data
clientMainAgent.channels.c1.capacity = 200000000
clientMainAgent.channels.c1.keep-alive = 30
clientMainAgent.channels.c1.write-timeout = 30
clientMainAgent.channels.c1.checkpoint-timeout=600
# clientMainAgent Sinks
# k1 sink
clientMainAgent.sinks.k1.channel = c1
clientMainAgent.sinks.k1.type = avro
# connect to CollectorMainAgent
clientMainAgent.sinks.k1.hostname = ecgp
clientMainAgent.sinks.k1.port = 41415
# k2 sink
clientMainAgent.sinks.k2.channel = c1
clientMainAgent.sinks.k2.type = avro
# connect to CollectorBackupAgent
clientMainAgent.sinks.k2.hostname = ecgp
clientMainAgent.sinks.k2.port = 41415
# clientMainAgent sinks group
clientMainAgent.sinkgroups.g1.sinks = k1 k2
# load_balance type
clientMainAgent.sinkgroups.g1.processor.type = load_balance
clientMainAgent.sinkgroups.g1.processor.backoff   = true
clientMainAgent.sinkgroups.g1.processor.selector  = random
EOF
    /usr/local/flume/bin/flume-ng agent --conf /usr/local/flume/conf -f /usr/local/flume/conf/flume_consolidation.conf -n clientMainAgent -Dflume.root.logger=DEBUG,console
}

function config_zookeeper()
{
    wget 'http://archive.apache.org/dist/zookeeper/zookeeper-3.4.5/zookeeper-3.4.5.tar.gz'
    tar -zxvf zookeeper-3.4.5.tar.gz
    mv zookeeper-3.4.5 /usr/local/zookeeper
    cat > /usr/local/zookeeper/conf/zoo.cfg <<EOF
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/usr/local/zookeeper/data
dataLogDir=/usr/local/zookeeper/logs
clientPort=2181
EOF
    /usr/local/zookeeper/bin/zkServer.sh start
}

function config_hbase()
{
    wget 'http://archive.apache.org/dist/hbase/hbase-0.96.0/hbase-0.96.0-hadoop2-bin.tar.gz'
    tar -zxvf hbase-0.96.0-hadoop2-bin.tar.gz
    mv hbase-0.96.0-hadoop2 /usr/local/hbase

}