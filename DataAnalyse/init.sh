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

function config_hadoop()
{
    wget 'https://archive.apache.org/dist/hadoop/common/hadoop-2.2.0/hadoop-2.2.0.tar.gz'
    tar -zxvf hadoop-2.2.0.tar.gz
    mv hadoop-2.2.0 /usr/local/hadoop
    cd /usr/local/hadoop/etc/hadoop
    sed  -i 's/export JAVA_HOME=.*/export JAVA_HOME=\/usr\/local\/jdk/g' hadoop-env.sh
    cat > core-site.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
<property>
<name>fs.defaultFS</name>
<value>hdfs://127.0.0.1:8020</value>
<final>true</final>
</property>
<property>
<name>hadoop.tmp.dir</name>
<value>/usr/local/hadoop/tmp</value>
<final>true</final>
</property>
 <property>
   <name>dfs.namenode.checkpoint.dir</name>
   <value>/usr/local/hadoop/secondname</value>
 </property>
<property>
 <name>fs.trash.interval</name>
 <value>1440</value>
</property>
<property>
<name>mapreduce.framework.name</name>
<value>yarn</value>
</property>
<property>
  <name>io.compression.codecs</name>
  <value>org.apache.hadoop.io.compress.GzipCodec,org.apache.hadoop.io.compress.DefaultCodec,com.hadoop.compression.lzo.LzoCodec,com.hadoop.compression.lzo.LzopCodec,org.apache.hadoop.io.compress.BZip2Codec</value>
</property>
<property>
  <name>io.compression.codec.lzo.class</name>
  <value>com.hadoop.compression.lzo.LzoCodec</value>
</property>
<property>
  <name>io.native.lib.available</name>
  <value>true</value>
  <description>Should native hadoop libraries, if present, be used.</description>
</property>
</configuration>
EOF
    mkdir -p /usr/local/hadoop/tmp
    mkdir -p /usr/local/hadoop/secondname

    cat > hdfs-site.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
	<property>
		<name>dfs.namenode.name.dir</name>
		<value>/usr/local/hadoop/name</value>
		<final>true</final>
	</property>
	<property>
		<name>dfs.datanode.data.dir</name>
		<value>/usr/local/hadoop/data</value>
		<final>true</final>
	</property>
	<property>
		<name>dfs.replication</name>
		<value>1</value>
	</property>
	<property>
		<name>dfs.datanode.max.transfer.threads</name>
		<value>4096</value>
	</property>
	<property>
		<name>dfs.datanode.du.reserved</name>
		<value>93049856</value>
		<description>Reserved space in bytes per volume. Always leave this much space free for non dfs use.
		</description>
	</property>
	<property>
		<name>dfs.support.append</name>
		<value>true</value>
	</property>
</configuration>
EOF
    mkdir -p /usr/local/hadoop/name
    mkdir -p /usr/local/hadoop/data

    cat > mapred-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
 <property>
   <name>mapreduce.framework.name</name>
   <value>yarn</value>
 </property>
 <property>
   <name>mapred.system.dir</name>
   <value>/usr/local/hadoop/mapred/system</value>
   <final>true</final>
  </property>
 <property>
   <name>mapred.local.dir</name>
   <value>/usr/local/hadoop/mapred/local</value>
   <final>true</final>
 </property>
 <property>
    <name>mapreduce.jobtracker.address</name>
    <value>localhost:9001</value>
 </property>

<property>
    <name>mapreduce.jobtracker.http.address</name>
    <value>localhost:50030</value>
 </property>
<property>
    <name>mapreduce.jobhistory.address</name>
    <value>localhost:10020</value>
 </property>
 <property>
    <name>mapreduce.jobhistory.webapp.address</name>
    <value>localhost:19888</value>
 </property>
 <property>
    <name>mapreduce.jobhistory.intermediate-done-dir</name>
    <value>/mr-history/tmp</value>
 </property>
 <property>
    <name>mapreduce.jobhistory.done-dir</name>
    <value>/mr-history/done</value>
 </property>

 <property>
   <name>mapreduce.map.output.compress</name>
   <value>true</value>
 </property>
 <property>
   <name>mapreduce.map.output.compress.codec</name>
   <value>com.hadoop.compression.lzo.LzoCodec</value>
 </property>
 <property>
    <name>mapreduce.map.memory.mb</name>
    <value>400</value>
  </property>
 <property>
    <name>mapreduce.map.java.opts</name>
    <value>-Xmx400M</value>
 </property>
 <property>
    <name>mapreduce.reduce.memory.mb</name>
    <value>1500</value>
 </property>
 <property>
    <name>mapreduce.reduce.java.opts</name>
    <value>-Xmx1024M</value>
 </property>
 <property>
     <name>mapreduce.task.timeout</name>
     <value>7200000</value>
     <final>true</final>
 </property>
<property>
    <name>mapreduce.task.io.sort.factor</name>
    <value>100</value>
    <final>true</final>
  </property>
  <property>
    <name>mapreduce.task.io.sort.mb</name>
    <value>150</value>
    <final>true</final>
  </property>
  <property>
    <name>io.file.buffer.size</name>
    <value>65536</value>
    <final>true</final>
  </property>
  <property>
    <name>mapreduce.reduce.shuffle.parallelcopies</name>
    <value>5</value>
    <final>true</final>
  </property>
  <property>
    <name>mapreduce.reduce.merge.inmem.threshold</name>
    <value>0</value>
    <final>true</final>
  </property>
</configuration>
EOF
    mkdir -p /usr/local/hadoop/mapred/system
    mkdir -p /usr/local/hadoop/mapred/local
    sed -i  -e '/IFS=/a\export HADOOP_COMMON_LIB_NATIVE_DIR=\/usr\/local\/hadoop\/lib\/native\nexport HADOOP_OPTS="-Djava.library.path=\/usr\/local\/hadoop\/lib"' yarn-env.sh

    cat > yarn-site.xml <<EOF
<?xml version="1.0"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->
<configuration>

<!-- Site specific YARN configuration properties -->
 <property>
  <name>yarn.nodemanager.aux-services</name>
  <value>mapreduce_shuffle</value>
 </property>
 <property>
  <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
  <value>org.apache.mapred.ShuffleHandler</value>
 </property>
 <property>
  <name>yarn.resourcemanager.scheduler.class</name>
  <value>org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler</value>
  <description>In case you do not want to use the default scheduler</description>
 </property>
 <property>
    <name>yarn.resourcemanager.webapp.address</name>
    <value>localhost:8088</value>
  </property>
 <property>
    <name>yarn.resourcemanager.resource-tracker.address</name>
    <value>localhost:8025</value>
  </property>
  <property>
    <name>yarn.resourcemanager.scheduler.address</name>
    <value>localhost:8030</value>
  </property>
  <property>
    <name>yarn.resourcemanager.address</name>
    <value>localhost:8040</value>
  </property>
  <property>
    <name>yarn.nodemanager.localizer.address</name>
    <value>localhost:8041</value>
  </property>
 <property>
    <name>yarn.resourcemanager.admin.address</name>
    <value>localhost:8033</value>
  </property>

  <property>
    <name>yarn.nodemanager.resource.memory-mb</name>
    <value>5120</value>
  </property>
  <property>
    <name>yarn.scheduler.minimum-allocation-mb</name>
    <value>800</value>
  </property>

</configuration>
EOF
    /usr/local/hadoop/bin/hdfs namenode -format
    /usr/local/hadoop/sbin/start-yarn.sh
    /usr/local/hadoop/sbin/start-dfs.sh
}

function config_hbase()
{
    wget 'http://archive.apache.org/dist/hbase/hbase-0.96.0/hbase-0.96.0-hadoop2-bin.tar.gz'
    tar -zxvf hbase-0.96.0-hadoop2-bin.tar.gz
    mv hbase-0.96.0-hadoop2 /usr/local/hbase
    cat > /usr/local/hbase/conf/hbase-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
/**
*
* Licensed to the Apache Software Foundation (ASF) under one
* or more contributor license agreements.  See the NOTICE file
* distributed with this work for additional information
* regarding copyright ownership.  The ASF licenses this file
* to you under the Apache License, Version 2.0 (the
* "License"); you may not use this file except in compliance
* with the License.  You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/
-->
<configuration>
		<property>
				<name>hbase.rootdir</name>
				<value>hdfs://127.0.0.1:8020/hbase</value>
		</property>
		<property>
				<name>hbase.cluster.distributed</name>
				<value>true</value>
		</property>
		<property>
				<name>hbase.zookeeper.quorum</name>
				<value>127.0.0.1</value>
		</property>
		<property>
				<name>zookeeper.session.timeout</name>
				<value>60000</value>
		</property>
		<property>
				<name>hbase.zookeeper.property.clientPort</name>
				<value>2181</value>
		</property>
		<property>
				<name>hbase.tmp.dir</name>
				<value>/usr/local/hbase/tmp</value>
				<description>Temporary directory on the local filesystem.</description>
		</property>
		<property>
				<name>hbase.client.keyvalue.maxsize</name>
				<value>10485760</value>
		</property>
		<property>
				<name>hbase.regionserver.lease.period</name>
				<value>240000</value>
		</property>
</configuration>
EOF
    cd /usr/local/hbase/lib
    \cp /usr/local/hadoop/share/hadoop/common/lib/hadoop-annotations-2.2.0.jar .
    \rm hadoop-annotations-2.1.0-beta.jar
    \cp /usr/local/hadoop/share/hadoop/common/lib/hadoop-auth-2.2.0.jar .
    \cp /usr/local/hadoop/share/hadoop/common/hadoop-common-2.2.0.jar .
    \cp /usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-2.2.0.jar .
    \cp /usr/local/hadoop/share/hadoop/hdfs/hadoop-hdfs-2.2.0-tests.jar .
    \rm hadoop-hdfs-2.1.0-beta-tests.jar
    \cp /usr/local/hadoop/share/hadoop/common/hadoop-lzo-0.4.20-SNAPSHOT.jar .
    \rm hadoop-mapreduce-client-*
    \cp /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-* .
    \cp /usr/local/hadoop/share/hadoop/yarn/hadoop-yarn-api-2.2.0.jar .
    \rm hadoop-yarn-api-2.1.0-beta.jar
    \cp /usr/local/hadoop/share/hadoop/yarn/hadoop-yarn-client-2.2.0.jar .
    \rm hadoop-yarn-client-2.1.0-beta.jar
    \cp /usr/local/hadoop/share/hadoop/yarn/hadoop-yarn-common-2.2.0.jar .
    \rm hadoop-yarn-common-2.1.0-beta.jar
    \cp /usr/local/hadoop/share/hadoop/yarn/hadoop-yarn-server-common-2.2.0.jar .
    \rm hadoop-yarn-server-common-2.1.0-beta.jar
    \cp /usr/local/hadoop/share/hadoop/yarn/hadoop-yarn-server-nodemanager-2.2.0.jar .
    \rm hadoop-yarn-server-nodemanager-2.1.0-beta.jar
    /usr/local/hbase/bin/start-hbase.sh
}