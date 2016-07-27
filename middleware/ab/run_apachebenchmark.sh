#!/bin/bash

test_concurrency_collection=(1 2 4 8 16 32 64 128 256 512 1000)
test_total_requests_collection=(50000 50000 100000 100000 100000 100000 100000 100000 200000 200000 200000)
#test_total_requests_collection=(100000 200000 400000 400000 800000 1000000 1000000 1000000 2000000 2000000 2000000)
max_concurrency_per_ab=4
max_ab_instances=16
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
        current_concurrency=${test_concurrency_collection[$t]}
        total_requests=${test_total_requests_collection[$t]}
        echo "NEXT TEST: $current_concurrency concurrency of requests"

        # prepare running apache
        ssh root@${server} mkdir -p                   $log_folder/$current_concurrency
        ssh root@${server} "sar -n DEV 1 900   2>&1 > $log_folder/$current_concurrency/$current_concurrency.sar.netio.log " &
        ssh root@${server} "iostat -x -d 1 900 2>&1 > $log_folder/$current_concurrency/$current_concurrency.iostat.diskio.log " &
        ssh root@${server} "vmstat 1 900       2>&1 > $log_folder/$current_concurrency/$current_concurrency.vmstat.memory.cpu.log " &

        # prepare running apache-benchmark
        mkdir -p                   $log_folder/$current_concurrency
        sar -n DEV 1 900   2>&1  > $log_folder/$current_concurrency/$current_concurrency.sar.netio.log &
        iostat -x -d 1 900 2>&1  > $log_folder/$current_concurrency/$current_concurrency.iostat.diskio.log &
        vmstat 1 900       2>&1  > $log_folder/$current_concurrency/$current_concurrency.vmstat.memory.cpu.log &

        #start running the apache-benchmark on client
        sleep 4
        echo "-> start running"
#        ab -n $total_requests -r -c $current_concurrency http://${server}/test.dat > $log_folder/$current_concurrency/$current_concurrency.ab.log

        ab_instances=$(($current_concurrency / $max_concurrency_per_ab))
        if [ $ab_instances -eq 0 ]
        then
            ab_instances=1
        fi
        if [ $ab_instances -gt $max_ab_instances ] 
        then
			ab_instances=$max_ab_instances
        fi

        total_request_per_ab=$(($total_requests / $ab_instances))
        concurrency_per_ab=$(($current_concurrency / $ab_instances))

        rm -rf the_generated_client.sh
        echo "./parallelcommands.sh " > the_generated_client.sh

        i=0
        concurrency_left=$current_concurrency
        requests_left=$total_requests
        while [ $concurrency_left -gt $max_concurrency_per_ab ]; do
			concurrency_left=$(($concurrency_left - $concurrency_per_ab))
			requests_left=$(($requests_left - $total_request_per_ab))
			echo " \"ab -n $total_request_per_ab -r -c $concurrency_per_ab http://${server}/test.dat  \" " >> the_generated_client.sh
			i=$(($i + 1))
        done

        if [ $concurrency_left -gt 0 ]
        then
            echo " \"ab -n $requests_left -r -c $concurrency_left http://${server}/test.dat \" " >> the_generated_client.sh
        fi
	
        sed -i ':a;N;$!ba;s/\n/ /g'  ./the_generated_client.sh
        chmod 755 the_generated_client.sh

        cat ./the_generated_client.sh
        ./the_generated_client.sh > /dev/null 

        echo "-> done"
		
        #cleanup apache
        ssh root@${server} pkill -f sar    > /dev/null
        ssh root@${server} pkill -f iostat > /dev/null
        ssh root@${server} pkill -f vmstat > /dev/null

        #cleanup apache-benchmark
        pkill -f sar    > /dev/null
        pkill -f iostat > /dev/null
        pkill -f vmstat > /dev/null
        pkill -f ab     > /dev/null

        echo "sleep 2 seconds for next test"
        echo ""
		
        sleep 2
        t=$(($t + 1))
done

