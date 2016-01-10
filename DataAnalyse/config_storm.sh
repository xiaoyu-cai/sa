#!/usr/bin/env bash

function config_storm()
{
    wget 'http://mirror.bit.edu.cn/apache/storm/apache-storm-0.9.3/apache-storm-0.9.3.tar.gz'
    tar -zxvf apache-storm-0.9.3.tar.gz
    mv apache-storm-0.9.3 /usr/local/storm
    cat > /usr/local/storm/conf/storm.yaml <<EOF
java.library.path: "/usr/local/lib:/opt/local/lib:/usr/lib"

storm.local.dir: "/usr/local/storm"
storm.zookeeper.servers:
    - "127.0.0.1"
storm.zookeeper.port: 2181
storm.zookeeper.root: "/storm"
storm.zookeeper.session.timeout: 20000
storm.zookeeper.connection.timeout: 15000
storm.zookeeper.retry.times: 5
storm.zookeeper.retry.interval: 1000
storm.zookeeper.retry.intervalceiling.millis: 30000
storm.cluster.mode: "distributed" # can be distributed or local
storm.local.mode.zmq: false
storm.thrift.transport: "backtype.storm.security.auth.SimpleTransportPlugin"
storm.messaging.transport: "backtype.storm.messaging.netty.Context"

nimbus.host: "127.0.0.1"
nimbus.thrift.port: 6627
nimbus.thrift.max_buffer_size: 1048576
nimbus.childopts: "-Xmx1024m"
nimbus.task.timeout.secs: 30
nimbus.supervisor.timeout.secs: 60
nimbus.monitor.freq.secs: 10
nimbus.cleanup.inbox.freq.secs: 600
nimbus.inbox.jar.expiration.secs: 3600
nimbus.task.launch.secs: 120
nimbus.reassign: true
nimbus.file.copy.expiration.secs: 600
nimbus.topology.validator: "backtype.storm.nimbus.DefaultTopologyValidator"

ui.port: 8089
ui.childopts: "-Xmx768m"

logviewer.port: 8000
logviewer.childopts: "-Xmx128m"
logviewer.appender.name: "A1"


drpc.port: 3772
drpc.worker.threads: 64
drpc.queue.size: 128
drpc.invocations.port: 3773
drpc.request.timeout.secs: 600
drpc.childopts: "-Xmx768m"

transactional.zookeeper.root: "/transactional"
transactional.zookeeper.servers: null
transactional.zookeeper.port: null

supervisor.slots.ports:
    - 6700
    - 6701
    - 6702
    - 6703
supervisor.childopts: "-Xmx256m"
supervisor.worker.start.timeout.secs: 120
supervisor.worker.timeout.secs: 30
supervisor.monitor.frequency.secs: 3
supervisor.heartbeat.frequency.secs: 5
supervisor.enable: true

worker.childopts: "-Xmx768m"
worker.heartbeat.frequency.secs: 1

task.heartbeat.frequency.secs: 3
task.refresh.poll.secs: 10

zmq.threads: 1
zmq.linger.millis: 5000
zmq.hwm: 0


storm.messaging.netty.server_worker_threads: 1
storm.messaging.netty.client_worker_threads: 1
storm.messaging.netty.buffer_size: 5242880 #5MB buffer
storm.messaging.netty.max_retries: 30
storm.messaging.netty.max_wait_ms: 1000
storm.messaging.netty.min_wait_ms: 100

topology.enable.message.timeouts: true
topology.debug: false
topology.optimize: true
topology.workers: 1
topology.acker.executors: null
topology.tasks: null
topology.message.timeout.secs: 30
topology.skip.missing.kryo.registrations: false
topology.max.task.parallelism: null
topology.max.spout.pending: null
topology.state.synchronization.timeout.secs: 60
topology.stats.sample.rate: 0.05
topology.builtin.metrics.bucket.size.secs: 60
topology.fall.back.on.java.serialization: true
topology.worker.childopts: null
topology.executor.receive.buffer.size: 1024 #batched
topology.executor.send.buffer.size: 1024 #individual messages
topology.receiver.buffer.size: 8 # setting it too high causes a lot of problems (heartbeat thread gets starved, throughput plummets)
topology.transfer.buffer.size: 1024 # batched
topology.tick.tuple.freq.secs: null
topology.worker.shared.thread.pool.size: 4
topology.disruptor.wait.strategy: "com.lmax.disruptor.BlockingWaitStrategy"
topology.spout.wait.strategy: "backtype.storm.spout.SleepSpoutWaitStrategy"
topology.sleep.spout.wait.strategy.time.ms: 1
topology.error.throttle.interval.secs: 10
topology.max.error.report.per.interval: 5
topology.kryo.factory: "backtype.storm.serialization.DefaultKryoFactory"
topology.tuple.serializer: "backtype.storm.serialization.types.ListDelegateSerializer"
topology.trident.batch.emit.interval.millis: 500
EOF
    nohup /usr/local/storm/bin/storm nimbus >/dev/null 2>&1 &
    nohup /usr/local/storm/bin/storm supervisor >/dev/null 2>&1 &
    nohup /usr/local/storm/bin/storm ui >/dev/null 2>&1 &
}