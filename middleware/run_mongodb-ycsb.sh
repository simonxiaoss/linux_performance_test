#!/bin/bash

test_threads_collection=(1 2 4 8 16 32 64 128)
server="192.168.4.168"

ssh root@${server} mkdir -p /root/benchmark/mongodb/logs
pkill -f ycsb

t=0
while [ "x${test_threads_collection[$t]}" != "x" ]
do
	threads=${test_threads_collection[$t]}
	ssh root@${server} mkdir -p                   /root/benchmark/mongodb/logs/$threads
	ssh root@${server} "sar -n DEV 1 900   2>&1 > /root/benchmark/mongodb/logs/$threads/$threads.sar.netio.log " & 
	ssh root@${server} "iostat -x -d 1 900 2>&1 > /root/benchmark/mongodb/logs/$threads/$threads.iostat.diskio.log " &
	ssh root@${server} "vmstat 1 900 2>&1 > /root/benchmark/mongodb/logs/$threads/$threads.vmstat.memory.cpu.log " & 
	#./ycsb-0.5.0/bin/ycsb load mongodb-async -s -P workloadAzure -p mongodb.url=mongodb://192.168.4.88:27017/ycsb?w=0 -threads $threads > ./logs/$threads/$threads.ycsb.load.log
	./ycsb-0.5.0/bin/ycsb  run  mongodb-async -s -P workloadAzure -p mongodb.url=mongodb://${server}:27017/ycsb?w=0 -threads $threads > ./$threads.ycsb.run.log
	ssh root@${server} pkill -f sar
	ssh root@${server} pkill -f iostat
	ssh root@${server} pkill -f vmstat
	
	echo "sleep 60 seconds"
	sleep 60
	t=$(($t + 1))
	echo "$t"
done
