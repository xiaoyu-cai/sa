__author__ = 'xiaoyu'
import psutil
from subprocess import PIPE

def system_basic():
    print psutil.cpu_times()
    print psutil.cpu_count(logical=False)

    mem = psutil.virtual_memory()
    print mem.total

    print psutil.disk_partitions()
    print psutil.disk_usage('/')
    print psutil.disk_io_counters()
    print psutil.disk_io_counters(perdisk=True)

    print psutil.net_io_counters()
    print psutil.net_io_counters(pernic=True)


def process():
    print psutil.pids()
    p = psutil.Process(psutil.pids()[4])
    print p.name()+'\n'+p.exe()+'\n'+p.cwd()


if __name__ == '__main__':

# system_basic()
    process()
    p = psutil.Popen(["/usr/bin/python", "-c", "print('hello')"], stdout=PIPE)
    print p.name()+'\t'+p.username()
    print p.communicate()