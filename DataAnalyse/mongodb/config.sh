#!/usr/bin/env bash

function backup()
{
    ./mongodump -h172.21.28.1 -port 27017 -d gcore -c expressmsg -o dump
    ./mongorestore -h 127.0.0.1 --port 27017 -d gcore --directoryperdb ./dump/gcore
:<<MULTILINECOMMENT
    db.mycollecttion.find().forEach(function(x){db.mycollecttion2.insert(x)}) 不好用
"errmsg" : "exception: BSONObj size: 0 (0x00000000) is invalid. Size must be between 0 and 16793600(16MB) First element: EOO",
 "code" : 10334,
 "ok" : 0
db.runCommand({"resync":1}) 从库重新复制
1 mongos 通过启动命令关联configdb
2 configdb 通过 mongos
sh.addShard("wccrep0/172.21.28.2:20000")关联repleset
3 repleset 通过其中一个节点，通过
use admin;
cfg={ _id:"wccrep0", members:[ {_id:0,host:'172.21.28.2:20000',priority:2}, {_id:1,host:'172.21.28.3:20000',priority:1},{_id:2,host:'172.21.28.4:20000',arbiterOnly:true}] };
rs.initiate(cfg);
rs.reconfig(cfg);
rs.addArb("172.21.28.4:22222");
4 添加sharding
db.runCommand({enableSharding:"gcore"}) #库
db.runCommand({shardCollection:"gcore.WCC_PCLottery_1",key:{"UDID":1}}); #表

唯一索引
db.things.ensureIndex({firstname: 1}, {unique: true});

db.collection.update( criteria, objNew, upsert, multi )
criteria:查询条件 $ne 不等于 $or $gte 大于等于 $lte小于等于
like ‘%bc%’ db.users.find( { user_id: /bc/ } )
like ‘bc%’ db.users.find( { user_id: /^bc/ } )
$exists: true
objNew: $set 增加字段 $unset 删除字段
upsert:默认false，不存在记录不插入，true则插入
multi:默认false，只更新第一条记录，true则全部更新


remp=function(x){db.wcc_online_d.remove({"stid":x.stid,"skuid":x.skuid});db.wcc_online_d.insert(x);}
db.wcc_online_d.ensureIndex({"skuid":1,"stid":1},{unique:1});
db.wcc_online_data.find().forEach(remp);
db.wcc_online_data.renameCollection("wcc_online_data_bk");
db.wcc_online_d.renameCollection("wcc_online_data")
db.wcc_online_data.ensureIndex({"create_time":1});
db.wcc_online_data.ensureIndex({"source_category_id":1});
db.wcc_online_data.ensureIndex({"update_time":1});
db.wcc_online_data.ensureIndex({"status":1});
db.wcc_online_data.ensureIndex({"skuid":1});

db.sources.update({"host":"114.80.139.66:27018"},{$set:{"host":"114.80.139.243:27018"}})

MULTILINECOMMENT
}