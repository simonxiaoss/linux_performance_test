#!/bin/bash

test_threads_collection=(1 2 4 8 16 32 64 128 256)
server="192.168.40.111"
log_folder=logs
lua_oltp_path="/root/benchmark/sysbench/sysbench/tests/db/oltp.lua"

ssh root@${server} mkdir -p /root/benchmark/mariadb/$log_folder
#run Mariadb on server side
ssh root@${server} "/usr/local/mysql/bin/mysqld_safe --user=mysql --datadir=/mnt/mysql/data &" &
echo "Wait Mariadb startup for 30 seconds ..."
sleep 30
mysql_pid=$(ssh root@${server} pidof mysqld)
echo "mysqld pid is $mysql_pid"

echo "Prepare database for the test..."
sysbench --test=${lua_oltp_path} --mysql-host=${server} --mysql-user=lisa --mysql-password=lisapassword --mysql-db=test --oltp-table-size=100000000 prepare    
echo "Start the test..."

t=0
while [ "x${test_threads_collection[$t]}" != "x" ]
do
	threads=${test_threads_collection[$t]}
	
	echo "======================================"
	echo "Running Test: $threads" 
	echo "======================================"
	
	ssh root@${server} mkdir -p                   /root/benchmark/mariadb/$log_folder/$threads
	mkdir -p /root/benchmark/mariadb/$log_folder/$threads
	
	#start monitoring network IO activities
	ssh root@${server} "sar -n DEV 1 900   2>&1 > /root/benchmark/mariadb/$log_folder/$threads/$threads.sar.netio.log " & 
	#start monitoring disk IO activities
	ssh root@${server} "iostat -x -d 1 900 2>&1 > /root/benchmark/mariadb/$log_folder/$threads/$threads.iostat.diskio.log " &
	#start monitoring memory, swap, io, interrupts, cs, and CPU status
	ssh root@${server} "vmstat 1 900       2>&1 > /root/benchmark/mariadb/$log_folder/$threads/$threads.vmstat.memory.cpu.log " & 
	#start monitoring detailed CPU usage
	ssh root@${server} "mpstat -P ALL 1 900 2>&1 > /root/benchmark/mariadb/$log_folder/$threads/$threads.mpstat.cpu.log " & 
	#start monitoring thread CPU usage. 
	#we need to  get the pid from server side before executing this ssh command, otherwise, $(pidof mysql) will be evaluated on client side which returns NULL
	ssh root@${server} "pidstat -h -r -u -v -p $mysql_pid 1 900 2>&1 > /root/benchmark/mariadb/$log_folder/$threads/$threads.pidstat.cpu.log " & 
	
	sar -n DEV 1 900   2>&1 > /root/benchmark/mariadb/$log_folder/$threads/$threads.sar.netio.log &
	iostat -x -d 1 900 2>&1 > /root/benchmark/mariadb/$log_folder/$threads/$threads.iostat.diskio.log &
	vmstat 1 900       2>&1 > /root/benchmark/mariadb/$log_folder/$threads/$threads.vmstat.memory.cpu.log &
	mpstat -P ALL 1 900 2>&1 > /root/benchmark/mariadb/$log_folder/$threads/$threads.mpstat.cpu.log &
	# sleep 5 seconds, as sysbench is not running at this point
	( sleep 5 ; pidstat -h -r -u -v -p $(pidof sysbench) 1 900 2>&1 > /root/benchmark/mariadb/$log_folder/$threads/$threads.pidstat.cpu.log ) &
	
	sysbench --test=$lua_oltp_path --mysql-host=$server --mysql-user=lisa --mysql-password=lisapassword --mysql-db=test --max-time=300 --report-interval=5 --oltp-test-mode=complex --mysql-table-engine=innodb --oltp-read-only=off --max-requests=100000000 --num-threads=$threads run > ./$log_folder/$threads.sysbench-mariadb.run.log
	
	ssh root@${server} pkill -f sar
	ssh root@${server} pkill -f iostat
	ssh root@${server} pkill -f vmstat
	ssh root@${server} pkill -f mpstat
	ssh root@${server} pkill -f pidstat
	pkill -f sar
	pkill -f iostat
	pkill -f vmstat
	pkill -f mpstat
	pkill -f pidstat
	
	echo "sleep 60 seconds"
	sleep 60
	t=$(($t + 1))
	echo "$t"
done
