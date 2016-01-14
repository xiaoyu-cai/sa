__author__ = 'xiaoyu'
from pykafka import KafkaClient
import Queue
import pydevd


def kafka_consumer():
    #pydevd.settrace('192.168.3.210', port=8888, stdoutToServer=True, stderrToServer=True)
    client = KafkaClient(hosts="127.0.0.1:9096")
    topic = client.topics['mytopic']
    consumer = topic.get_simple_consumer()
    for message in consumer:
        if message is not None:
            print message.offset, message.value


def balance_consumer():
    #pydevd.settrace('192.168.3.210', port=8888, stdoutToServer=True, stderrToServer=True)
    client = KafkaClient(hosts="127.0.0.1:9097")
    topic = client.topics['mytopic']
    balanced_consumer = topic.get_balanced_consumer(
        consumer_group='testgroup',
        auto_commit_enable=True,
        zookeeper_connect='127.0.0.1:2181'
    )
    for message in balanced_consumer:
        if message is not None:
            print message.offset, message.value


def kafka_producer():
    client = KafkaClient(hosts="127.0.0.1:9096")
    topic = client.topics['mytopic']
    with topic.get_sync_producer() as producer:
        for i in range(4):
            producer.produce('test message ' + str(i ** 2))


def kafka_report_producer():
    client = KafkaClient(hosts="127.0.0.1:9096")
    topic = client.topics['mytopic']
    with topic.get_producer(delivery_reports=True) as producer:
        count = 0
        while True:
            count += 1
            producer.produce('test msg', partition_key='{}'.format(count))
            if count % 10 ** 5 == 0:
                while True:
                    try:
                        msg, exc = producer.get_delivery_report(block=False)
                        if exc is not None:
                            print 'Failed to deliver msg {}: {}'.format(
                                msg.partition_key, repr(exc))
                        else:
                            print 'Successfully delivered msg {}'.format(
                                msg.partition_key)
                    except Queue.Empty:
                        break


if __name__ == '__main__':
    balance_consumer()