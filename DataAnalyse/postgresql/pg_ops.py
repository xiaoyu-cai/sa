#!/usr/bin/env python
# -*- coding: utf-8 -*-

#导入日志及psycopg2模块
import logging
import logging.config
import psycopg2
#import pydevd

#日志配置文件名
LOG_FILENAME = 'logging.conf'

#日志语句提示信息
LOG_CONTENT_NAME = 'pg_log'

logging.basicConfig(level=logging.DEBUG,
                format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
                datefmt='%a, %d %b %Y %H:%M:%S',
                filename='myapp.log',
                filemode='w')

def log_init(log_config_filename, logname):
    '''
    Function:日志模块初始化函数
    Input：log_config_filename:日志配置文件名
           lognmae:每条日志前的提示语句
    Output: logger
    author: socrates
    date:2012-02-13
    '''
    logging.config.fileConfig(log_config_filename)
    logger = logging.getLogger(logname)
    return logger

def operate_postgre_tbl_product():
    '''
    Function:操作pg数据库函数
    Input：NONE
    Output: NONE
    author: socrates
    date:2012-02-13
    '''  
    logging.debug("operate_postgre_tbl_product enter...")
    
    #连接数据库  
    try:
        pgdb_conn = psycopg2.connect(database = 'dev', user = 'dev', password = 'dev', host = '192.168.200.61')
    except Exception, e:
         print e.args[0]
         logging.error("conntect postgre database failed, ret = %s" % e.args[0])
         return    
     
    logging.info("conntect postgre database(kevin_test) succ.")
    
    pg_cursor = pgdb_conn.cursor()
        
    #删除表
    sql_desc = "DROP TABLE IF EXISTS tbl_product3;"
    try:
        pg_cursor.execute(sql_desc)
    except Exception, e:
        print 'drop table failed'
        logging.error("drop table failed, ret = %s" % e.args[0])
        pg_cursor.close()
        pgdb_conn.close()  
        return
    pgdb_conn.commit()
    
    logging.info("drop table(tbl_product3) succ.")
  
    #创建表
    sql_desc = '''CREATE TABLE tbl_product3(
        i_index INTEGER,
        sv_productname VARCHAR(32)
        );'''
    try:    
        pg_cursor.execute(sql_desc)
    except Exception, e:
        print 'create table failed'
        logging.error("create table failed, ret = %s" % e.args[0])
        pg_cursor.close()
        pgdb_conn.close()  
        return
    pgdb_conn.commit()      
   
    logging.info("create table(tbl_product3) succ.")
      
    #插入记录   
    sql_desc = "INSERT INTO tbl_product3(sv_productname) values('apple')"
    try:
        pg_cursor.execute(sql_desc)
        pg_cursor.execute(sql_desc)
    except Exception, e:
        print 'insert record into table failed'
        logging.error("insert record into table failed, ret = %s" % e.args[0])
        pg_cursor.close()
        pgdb_conn.close()  
        return    
    pgdb_conn.commit()
     
    #pgdb_logger.info("insert record into table(tbl_product3) succ.")

    #查询表方法一        
    sql_desc = "select * from tbl_product3"
    try:
        pg_cursor.execute(sql_desc)
    except Exception, e:
        print 'select record from  table tbl_product3 failed'
        logging.error("select record from  table tbl_product3 failed, ret = %s" % e.args[0])
        pg_cursor.close()
        pgdb_conn.close()  
        return      
      
    for row in pg_cursor:
        print row 
        logging.info("%s", row)
    
    print '*' * 20    
    #查询表方法二     
    sql_desc = "select * from tbl_test_port"
    try:
        pg_cursor.execute(sql_desc)
    except Exception, e:
        print 'select record from  table tbl_test_port failed'
        logging.error("select record from  table tbl_test_port failed, ret = %s" % e.args[0])
        pg_cursor.close()
        pgdb_conn.close()  
        return  
            
    for row in pg_cursor.fetchall():
        print row 
        logging.info("%s", row)
     
    #关闭数据库连接     
    pg_cursor.close()
    pgdb_conn.close()       
    
    logging.debug("operate_sqlite3_tbl_product leaving...")

if __name__ == '__main__': 
    #pydevd.settrace('192.168.3.210', port=8888, stdoutToServer=True, stderrToServer=True)
    #初始化日志系统
    #pgdb_logger = log_init(LOG_FILENAME, LOG_CONTENT_NAME)
    
    #操作数据库
    operate_postgre_tbl_product()
    
