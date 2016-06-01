#!/bin/bash

test_pipeline_collection=(1 8 16 32 64 128)
server="192.168.1.88"
redis_path_server="/root/benchmark/redis/redis-2.8.17/src"
redis_path_client="/root/benchmark/redis/redis-2.8.17/src"
redis_test_suites="set,get"
log_folder="/root/benchmark/redis/logs"

ssh root@${server} mkdir -p $log_folder
mkdir -p $log_folder

pkill -f redis-benchmark
ssh root@${server} pkill -f redis-server > /dev/nul

t=0
while [ "x${test_pipeline_collection[$t]}" != "x" ]
do
        pipelines=${test_pipeline_collection[$t]}
        echo "NEXT TEST: $pipelines pipelines"

        # prepare running redis-server
        ssh root@${server} mkdir -p                   $log_folder/$pipelines
        ssh root@${server} "sar -n DEV 1 900   2>&1 > $log_folder/$pipelines/$pipelines.sar.netio.log " &
        ssh root@${server} "iostat -x -d 1 900 2>&1 > $log_folder/$pipelines/$pipelines.iostat.diskio.log " &
        ssh root@${server} "vmstat 1 900       2>&1 > $log_folder/$pipelines/$pipelines.vmstat.memory.cpu.log " &
        ssh root@${server} $redis_path_server/redis-server > /dev/nul  &

        # prepare running redis-benchmark
        mkdir -p                   $log_folder/$pipelines
        sar -n DEV 1 900   2>&1  > $log_folder/$pipelines/$pipelines.sar.netio.log &
        iostat -x -d 1 900 2>&1  > $log_folder/$pipelines/$pipelines.iostat.diskio.log &
        vmstat 1 900       2>&1  > $log_folder/$pipelines/$pipelines.vmstat.memory.cpu.log &

        #start running the redis-benchmark on client
        sleep 20
        echo "-> start running"
        $redis_path_client/redis-benchmark -h $server -c 1000 -P $pipelines -t $redis_test_suites -d 4000 -n 10000000 > $log_folder/$pipelines/$pipelines.redis.set.get.log
        echo "-> done"
		
        #cleanup redis-server
        ssh root@${server} pkill -f sar
        ssh root@${server} pkill -f iostat
        ssh root@${server} pkill -f vmstat
        ssh root@${server} pkill -f redis-server > /dev/nul

        #cleanup redis-benchmark
        pkill -f sar
        pkill -f iostat
        pkill -f vmstat
        pkill -f redis-benchmark

        echo "sleep 60 seconds for next test"
        echo ""
		
        sleep 60
        t=$(($t + 1))
done
