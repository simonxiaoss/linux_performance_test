#!/bin/bash

test_concurrency_collection=(1 2 4 8 16 32 64 128 256 512 1000)
test_total_requests_collection=(100000 200000 400000 400000 800000 1000000 1000000 1000000 2000000 2000000 2000000)
server="192.168.4.169"
log_folder="/root/benchmark/ab/logs"

ssh root@${server} mkdir -p $log_folder
mkdir -p $log_folder

pkill -f ab
ssh root@${server} service apache2 stop
ssh root@${server} service apache2 start

t=0
while [ "x${test_concurrency_collection[$t]}" != "x" ]
do
        pipelines=${test_concurrency_collection[$t]}
		total_requests=${test_total_requests_collection[$t]}
        echo "NEXT TEST: $pipelines concurrency of requests"

        # prepare running apache
        ssh root@${server} mkdir -p                   $log_folder/$pipelines
        ssh root@${server} "sar -n DEV 1 900   2>&1 > $log_folder/$pipelines/$pipelines.sar.netio.log " &
        ssh root@${server} "iostat -x -d 1 900 2>&1 > $log_folder/$pipelines/$pipelines.iostat.diskio.log " &
        ssh root@${server} "vmstat 1 900       2>&1 > $log_folder/$pipelines/$pipelines.vmstat.memory.cpu.log " &

        # prepare running apache-benchmark
        mkdir -p                   $log_folder/$pipelines
        sar -n DEV 1 900   2>&1  > $log_folder/$pipelines/$pipelines.sar.netio.log &
        iostat -x -d 1 900 2>&1  > $log_folder/$pipelines/$pipelines.iostat.diskio.log &
        vmstat 1 900       2>&1  > $log_folder/$pipelines/$pipelines.vmstat.memory.cpu.log &

        #start running the apache-benchmark on client
        sleep 10
        echo "-> start running"
        ab -n $total_requests -r -c $pipelines http://${server}/test.dat > $log_folder/$pipelines/$pipelines.ab.log
        echo "-> done"
		
        #cleanup apache
        ssh root@${server} pkill -f sar
        ssh root@${server} pkill -f iostat
        ssh root@${server} pkill -f vmstat

        #cleanup apache-benchmark
        pkill -f sar
        pkill -f iostat
        pkill -f vmstat
        pkill -f ab

        echo "sleep 10 seconds for next test"
        echo ""
		
        sleep 10
        t=$(($t + 1))
done
