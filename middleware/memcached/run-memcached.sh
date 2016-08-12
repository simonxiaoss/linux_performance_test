#!/bin/bash

test_threads_collection=(1 2 4 8 16 32 64 128 256 512 1008)
server="192.168.4.169"
max_threads=16
log_folder=logs

ssh root@${server} mkdir -p /root/benchmark/memcached/$log_folder
ssh root@${server} "memcached -u root" &

t=0
while [ "x${test_threads_collection[$t]}" != "x" ]
do
	threads=${test_threads_collection[$t]}
	if [ $threads -lt $max_threads ]
	then
		num_threads=$threads
		num_client_per_thread=1
		total_request=1000000
	else
		num_threads=$max_threads
		num_client_per_thread=$(($threads / $num_threads))
		total_request=100000
	fi
	
	echo "======================================"
	echo "Running Test: $threads = $num_threads X $num_client_per_thread" 
	echo "======================================"
	
	ssh root@${server} mkdir -p                   /root/benchmark/memcached/$log_folder/$threads
	mkdir -p /root/benchmark/memcached/$log_folder/$threads
	
	ssh root@${server} "sar -n DEV 1 900   2>&1 > /root/benchmark/memcached/$log_folder/$threads/$threads.sar.netio.log " & 
	ssh root@${server} "iostat -x -d 1 900 2>&1 > /root/benchmark/memcached/$log_folder/$threads/$threads.iostat.diskio.log " &
	ssh root@${server} "vmstat 1 900       2>&1 > /root/benchmark/memcached/$log_folder/$threads/$threads.vmstat.memory.cpu.log " & 
	sar -n DEV 1 900   2>&1 > /root/benchmark/memcached/$log_folder/$threads/sar.netio.log &
	iostat -x -d 1 900 2>&1 > /root/benchmark/memcached/$log_folder/$threads/iostat.netio.log &
	vmstat 1 900       2>&1 > /root/benchmark/memcached/$log_folder/$threads/vmstat.netio.log &
	
	memtier_benchmark  -s ${server} -p 11211 -P memcache_text -x 3 -n $total_request -t $num_threads -c $num_client_per_thread -d 4000 --ratio 1:1 --key-pattern S:S > ./$log_folder/$threads.memtier_benchmark.run.log
	
	ssh root@${server} pkill -f sar
	ssh root@${server} pkill -f iostat
	ssh root@${server} pkill -f vmstat
	pkill -f sar
	pkill -f iostat
	pkill -f vmstat
	
	echo "sleep 60 seconds"
	sleep 60
	t=$(($t + 1))
	echo "$t"
done
