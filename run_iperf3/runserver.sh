#!/bin/bash

iperflocation="/root/runiperf/iperf-3.0.5/src/iperf3"
resetfilelocation="/root/reset.sig"
totalduration=20000
individualduration=900
connections_per_iperf=4
number_of_connections=0
t=0

mkdir logs
#default the parameter
touch ${resetfilelocation}
echo 0 > ${resetfilelocation}

while [ $t -lt $totalduration ]; do
	#once received a reset/start singal from client side, do it
	if [ -f ${resetfilelocation} ];
	then
		number_of_connections=$(head -n 1 ${resetfilelocation})
		rm -rf ${resetfilelocation}
		echo "Reset iperf server..."
		pkill -f iperf3
		echo "iperf3 servers are killed."
		sleep 1 
	
		echo "Start new iperf3 instance..."
		number_of_iperf_instances=$((number_of_connections/connections_per_iperf+8001))
		#echo $number_of_iperf_instances
		#for i in {8001..8100}
		for ((i=8001; i<=$number_of_iperf_instances; i++))
		do	
			${iperflocation} -s -D -p $i
		done
		x=$(ps -aux | grep iperf | wc -l)
		echo "New iperf3 started: $x"
		
		mkdir ./logs/$number_of_connections
		
		sar -n DEV 1 $individualduration 2>&1 > ./logs/$number_of_connections/sar.log &
		vmstat 1 $individualduration     2>&1 > ./logs/$number_of_connections/vmstat.log &
	fi
	
	top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}' >> ./logs/$number_of_connections/top.log
	#ifstat eth0 | grep eth0 | awk '{print $6}' >> ifstatlog.log
	if [ $(($t % 10)) -eq 0 ];
	then
		echo $(netstat -nat | grep ESTABLISHED | wc -l) >> ./logs/$number_of_connections/connections.log
	fi

	sleep 1
	t=$(($t + 1))
	echo "$t"
done


