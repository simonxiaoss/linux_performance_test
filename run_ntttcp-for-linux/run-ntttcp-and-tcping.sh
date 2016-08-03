 #!/bin/bash
 
log_folder=$1
server_ip=$2
server_username=$3
test_run_duration=60
test_threads_collection=(1 2 4 8 16 32 64 128 256 512 1024)
max_server_threads=64
eth_name=eth0

if [[ $log_folder == ""  ]]
then
	log_folder=logs
fi

if [[ $server_ip == ""  ]]
then
	server_ip=192.168.4.169
fi


if [[ $server_username == ""  ]]
then
	server_username=root
fi

if [ "$(which ntttcp)" == "" ]; then
	rm -rf ntttcp-for-linux
	git clone https://github.com/Microsoft/ntttcp-for-linux
	cd ntttcp-for-linux/src
	make && make install
	cd ../..
fi

if [ "$(which lagscope)" == "" ]; then
	rm -rf lagscope
	git clone https://github.com/Microsoft/lagscope
	cd lagscope/src
	make && make install
	cd ../..
fi

eth_log="./$log_folder/eth_report.log"

function get_tx_bytes(){
	# RX bytes:66132495566 (66.1 GB)  TX bytes:3067606320236 (3.0 TB)
	ifconfig $eth_name | grep "TX bytes"   | awk -F':' '{print $3}' | awk -F' ' ' {print $1}'
}

function get_tx_pkts(){
	# TX packets:543924452 errors:0 dropped:0 overruns:0 carrier:0
	ifconfig $eth_name | grep "TX packets" | awk -F':' '{print $2}' | awk -F' ' ' {print $1}'
}

mkdir $log_folder
rm -rf $eth_log 
echo "#test_connections    throughput_gbps    average_packet_size" > $eth_log 

ssh $server_username@$server_ip "pkill -f ntttcp"
previous_tx_bytes=$(get_tx_bytes)
previous_tx_pkts=$(get_tx_pkts)
i=0
while [ "x${test_threads_collection[$i]}" != "x" ]
do
	current_test_threads=${test_threads_collection[$i]}
	if [ $current_test_threads -lt $max_server_threads ]
	then
		num_threads_P=$current_test_threads
		num_threads_n=1
	else
		num_threads_P=$max_server_threads
		num_threads_n=$(($current_test_threads / $num_threads_P))
	fi
	
	echo "======================================"
	echo "Running Test: $num_threads_P X $num_threads_n" 
	echo "======================================"
	
	ssh $server_username@$server_ip "pkill -f ntttcp"
	ssh $server_username@$server_ip "ntttcp -P $num_threads_P -t ${test_run_duration}" &

	ssh $server_username@$server_ip "pkill -f lagscope"
	ssh $server_username@$server_ip "lagscope -r" &
	
	sleep 2
	lagscope -s$server_ip -t ${test_run_duration} -V > "./$log_folder/lagscope-ntttcp-p${num_threads_P}X${num_threads_n}.log" &
	ntttcp -s${server_ip} -P $num_threads_P -n $num_threads_n -t ${test_run_duration}  > "./$log_folder/ntttcp-p${num_threads_P}X${num_threads_n}.log"

	current_tx_bytes=$(get_tx_bytes)
	current_tx_pkts=$(get_tx_pkts)
	bytes_new=$(($current_tx_bytes-$previous_tx_bytes))
	pkts_new=$(($current_tx_pkts-$previous_tx_pkts))
	avg_pkt_size=$(echo "scale=2;$bytes_new/$pkts_new/1024" | bc)
	throughput=$(echo "scale=2;$bytes_new/$test_run_duration*8/1024/1024/1024" | bc)
	previous_tx_bytes=$current_tx_bytes
	previous_tx_pkts=$current_tx_pkts

	echo "throughput (gbps): $throughput"
	echo "average packet size: $avg_pkt_size"
	printf "%4s  %8.2f  %8.2f\n" ${current_test_threads} $throughput $avg_pkt_size >> $eth_log

	echo "current test finished. wait for next one... "
	i=$(($i + 1))
	sleep 5
done
	
	 
ssh $server_username@$server_ip "pkill -f ntttcp"
ssh $server_username@$server_ip "pkill -f lagscope"

echo "all done."

