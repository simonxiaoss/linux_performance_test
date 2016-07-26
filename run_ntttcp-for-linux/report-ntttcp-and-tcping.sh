#!/bin/bash

log_folder=$1
ntttcp_log_prefix="ntttcp-p"
lagscope_log_prefix="lagscope-ntttcp-p"
threads_n1=(1 2 4 8 16 32 64)
threads_64_nx=(2 4 8 16)
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

function get_latency(){
	while read line
	do
		if [[ "$line" == *"Average"* ]]
		then
			echo "$line" | awk -F'=' '{print $4}' | awk -F'ms' '{print $1}'
		fi
	done < $1
}

echo "#test_connections	throughput_gbps	average_tcp_latency" > $result_file
i=0
while [ "x${threads_n1[$i]}" != "x" ]
do
	ntttcp_log_file="$log_folder/${ntttcp_log_prefix}${threads_n1[$i]}X1.log"
	lagscope_log_file="$log_folder/${lagscope_log_prefix}${threads_n1[$i]}X1.log"
	echo "${threads_n1[$i]}X1"

	throughput=$(get_throughput $ntttcp_log_file)
	latency=$(get_latency $lagscope_log_file)
	printf "%4s  %8.2f  %8.2f\n" ${threads_n1[$i]} ${throughput} ${latency} >> $result_file

	i=$(($i + 1))
done

i=0
while [ "x${threads_64_nx[$i]}" != "x" ]
do
	ntttcp_log_file="$log_folder/${ntttcp_log_prefix}64X${threads_64_nx[$i]}.log"
	lagscope_log_file="$log_folder/${lagscope_log_prefix}64X${threads_64_nx[$i]}.log"
	echo "64X${threads_64_nx[$i]}"

	throughput=$(get_throughput $ntttcp_log_file)
	latency=$(get_latency $lagscope_log_file)
	printf "%4s  %8.2f  %8.2f\n" $((${threads_64_nx[$i]}*64)) ${throughput} ${latency} >> $result_file

	i=$(($i + 1))
done


