#!/bin/bash

log_folder=$1
ntttcp_log_prefix="ntttcp-sender-p"
lagscope_log_prefix="lagscope-ntttcp-p"
test_threads_collection=(1 2 4 8 16 32 64 128 256 512 1024 2048 4096 6144 8192 10240)
max_server_threads=64
result_parsed=""
result_file="${log_folder}/report.log"

if [[ $log_folder == ""  ]]
then
	echo "please specify a log folder"
	exit
fi

function get_throughput(){
	while read line
	do
		if [[ "$line" == *"throughput"* ]]
		then
			echo "$line" | awk -F'\t:' '{print $2}' | sed 's/Gbps//'
		fi
	done < $1
}

function get_cyclesperbyte(){
	while read line
	do
		if [[ "$line" == *"cycles/byte"* ]]
		then
			echo "$line" | awk -F'\t:' '{print $2}' 
		fi
	done < $1
}

function get_latency(){
	while read line
	do
		if [[ "$line" == *"Average"* ]]
		then
			echo "$line" | awk -F'=' '{print $4}' | awk -F'us' '{print $1}'
		fi
	done < $1
}

echo "#test_connections	throughput_gbps	cycles/bytes	average_tcp_latency" > $result_file
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
	
	ntttcp_log_file="$log_folder/${ntttcp_log_prefix}${num_threads_P}X${num_threads_n}.log"
	lagscope_log_file="$log_folder/${lagscope_log_prefix}${num_threads_P}X${num_threads_n}.log"

	throughput=$(get_throughput $ntttcp_log_file)
	cyclesperbytes=$(get_cyclesperbyte $ntttcp_log_file)
	latency=$(get_latency $lagscope_log_file)

	if  [ "x$throughput" == "x" ]
	then
		throughput=0
	fi
	
	if  [ "x$cyclesperbytes" == "x" ]
	then
		cyclesperbytes=0
	fi
	
	if [ "x$latency" == "x" ]
	then
		latency=0
	fi
	
	printf "%4s  %8.2f %8.2f %8.2f\n" ${current_test_threads} ${throughput} ${cyclesperbytes} ${latency} >> $result_file

	i=$(($i + 1))
done

cat $result_file

