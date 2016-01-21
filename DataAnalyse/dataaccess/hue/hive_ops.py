__author__ = 'xiaoyu'
import pyhs2


def hive_connect():
    conn = pyhs2.connect(host='127.0.0.1',port=10000,authMechanism="PLAIN", user='hive', password='', database='default')
    cur = conn.cursor()
    cur.execute("show tables")
    for i in cur.fetch():
        print i
    cur.close()
    conn.close()