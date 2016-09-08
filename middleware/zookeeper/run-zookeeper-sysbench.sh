#!/bin/bash

servers_in_cluster=(ubuntubm09 ubuntubm10 ubuntubm11)

watch_multiple=5
num_zk_client=10
znode_size=10
znode_count=1000000
log_folder=logs-10clients-10bytes-1000000nodes

for server in "${servers_in_cluster[@]}"
do
	echo "configure logging on: $server" 
	java_pid=$(ssh root@${server} pidof java)
	echo "Java pid: $java_pid"

	ssh root@${server} mkdir -p                   /root/benchmark/zookeeper/$log_folder
	
	#start monitoring network IO activities
	ssh root@${server} "sar -n DEV 1 900   2>&1 > /root/benchmark/zookeeper/$log_folder/sar.netio.log " & 
	#start monitoring disk IO activities
	ssh root@${server} "iostat -x -d 1 900 2>&1 > /root/benchmark/zookeeper/$log_folder/iostat.diskio.log " &
	#start monitoring memory, swap, io, interrupts, cs, and CPU status
	ssh root@${server} "vmstat 1 900       2>&1 > /root/benchmark/zookeeper/$log_folder/vmstat.memory.cpu.log " & 
	#start monitoring detailed CPU usage
	ssh root@${server} "mpstat -P ALL 1 900 2>&1 > /root/benchmark/zookeeper/$log_folder/mpstat.cpu.log " & 
	#start monitoring thread CPU usage. 
	#we need to  get the pid from server side before executing this ssh command, otherwise, $(pidof mysql) will be evaluated on client side which returns NULL
	ssh root@${server} "pidstat -h -r -u -v -p $java_pid 1 900 2>&1 > /root/benchmark/zookeeper/$log_folder/pidstat.cpu.log " & 
	cluster_string=$cluster_string$","$server":2181"
done
cluster_string=$(echo $cluster_string | cut -b 2-)

mkdir -p                   /root/benchmark/zookeeper/$log_folder
sar -n DEV 1 900   2>&1  > /root/benchmark/zookeeper/$log_folder/sar.netio.log &
iostat -x -d 1 900 2>&1  > /root/benchmark/zookeeper/$log_folder/iostat.diskio.log &
vmstat 1 900       2>&1  > /root/benchmark/zookeeper/$log_folder/vmstat.memory.cpu.log &
mpstat -P ALL 1 900 2>&1 > /root/benchmark/zookeeper/$log_folder/mpstat.cpu.log &
# sleep 5 seconds, as sysbench is not running at this point
#( sleep 5 ; pidstat -h -r -u -v -p $(pidof python) 1 900 2>&1 > /root/benchmark/zookeeper/$log_folder/pidstat.cpu.log ) &

#run test with multiple clients concurrently
for (( client_id=1; client_id<=$num_zk_client; client_id++ ))
do
	echo  "Run Test on $client_id: --cluster=$cluster_string --znode_size=$znode_size --znode_count=$znode_count --timeout=5000 --watch_multiple=$watch_multiple --root_znode=/TESTNODE$client_id"
	./zk-smoketest/zk-latencies.py --cluster=$cluster_string --znode_size=$znode_size --znode_count=$znode_count --timeout=5000 --watch_multiple=$watch_multiple --root_znode=/TESTNODE$client_id > /root/benchmark/zookeeper/$log_folder/zookeeper_latency_$client_id.log &
done

read -p "Press [Enter] key to start tearing down the test if all threads finished ..."

pkill -f sar
pkill -f iostat
pkill -f vmstat
pkill -f mpstat
#pkill -f pidstat
	

for server in "${servers_in_cluster[@]}"
do
	echo "stop logging from: $server" 

	ssh root@${server} pkill -f sar
	ssh root@${server} pkill -f iostat
	ssh root@${server} pkill -f vmstat
	ssh root@${server} pkill -f mpstat
	ssh root@${server} pkill -f pidstat
done

