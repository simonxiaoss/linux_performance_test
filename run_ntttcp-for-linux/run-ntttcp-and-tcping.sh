 #!/bin/bash
 
server_ip=192.168.4.99
server_username=azureuser
ntttcp_run_duration=65
tcping_run_duration=60
threads_n1=(1 2 4 8 16 32 64)
threads_64_nx=(2 4 8 16)
tcping_location=tcping
log_folder=logs
eth_name=eth0
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
while [ "x${threads_n1[$i]}" != "x" ]
do
	echo "======================================"
	echo "Running Test: ${threads_n1[$i]} X 1" 
	echo "======================================"
	
	ssh $server_username@$server_ip "pkill -f ntttcp"
	ssh $server_username@$server_ip "ntttcp -P ${threads_n1[$i]} -t ${ntttcp_run_duration}" &
	sleep 2
	$tcping_location -t 20 -n ${tcping_run_duration} $server_ip 22 > "./$log_folder/tcping-ntttcp-p${threads_n1[$i]}X1.log" &
	ntttcp -s${server_ip} -P ${threads_n1[$i]} -n 1 -t ${ntttcp_run_duration}  > "./$log_folder/ntttcp-p${threads_n1[$i]}X1.log"

	current_tx_bytes=$(get_tx_bytes)
	current_tx_pkts=$(get_tx_pkts)
	bytes_new=$(($current_tx_bytes-$previous_tx_bytes))
	pkts_new=$(($current_tx_pkts-$previous_tx_pkts))
	avg_pkt_size=$(echo "scale=2;$bytes_new/$pkts_new/1024" | bc)
	throughput=$(echo "scale=2;$bytes_new/$ntttcp_run_duration*8/1024/1024/1024" | bc)
	previous_tx_bytes=$current_tx_bytes
	previous_tx_pkts=$current_tx_pkts

	echo "throughput (gbps): $throughput"
	echo "average packet size: $avg_pkt_size"
	echo "${threads_n1[$i]}    $throughput    $avg_pkt_size" >> $eth_log 
	echo "current test finished. wait for next one... "

	i=$(($i + 1))
	sleep 5
done
	
i=0
while [ "x${threads_64_nx[$i]}" != "x" ]
do
	echo "======================================"
	echo "Running Test: 64 X ${threads_64_nx[$i]} "
	echo "======================================"

	ssh $server_username@$server_ip "pkill -f ntttcp"
	ssh $server_username@$server_ip "ntttcp -P 64 -t ${ntttcp_run_duration}" &
	sleep 2
	$tcping_location -t 20 -n ${tcping_run_duration} $server_ip 22 > "./$log_folder/tcping-ntttcp-p64X${threads_64_nx[$i]}.log" &
	ntttcp -s${server_ip} -P 64 -n ${threads_64_nx[$i]} -t ${ntttcp_run_duration}  > "./$log_folder/ntttcp-p64X${threads_64_nx[$i]}.log"
	
	current_tx_bytes=$(get_tx_bytes)
	current_tx_pkts=$(get_tx_pkts)
	bytes_new=$(($current_tx_bytes-$previous_tx_bytes))
	pkts_new=$(($current_tx_pkts-$previous_tx_pkts))
	avg_pkt_size=$(echo "scale=2;$bytes_new/$pkts_new/1024" | bc)
	throughput=$(echo "scale=2;$bytes_new/$ntttcp_run_duration*8/1024/1024/1024" | bc)
	previous_tx_bytes=$current_tx_bytes
	previous_tx_pkts=$current_tx_pkts

	echo "throughput (gbps): $throughput"
	echo "average packet size: $avg_pkt_size"
	echo "$((${threads_64_nx[$i]}*64))    $throughput    $avg_pkt_size" >> $eth_log
	echo "current test finished. wait for next one... "

	i=$(($i + 1))
	sleep 5
done
	 
ssh $server_username@$server_ip "pkill -f ntttcp"

echo "all done."

