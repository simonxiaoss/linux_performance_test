#!/bin/bash

log_folder=$1
test_qdepth_collection=(1 2 4 8 16 32 64 128 256 512 1024)
result_parsed=""
result_file="${log_folder}/report.log"

if [[ $log_folder == ""  ]]
then
    echo "please specify a log folder"
    exit
fi

function get_iops(){
	while read line
	do
		# read : io=1915.2MB, bw=32669KB/s, iops=4083, runt= 60031msec
		if [[ "$line" == *"iops"* ]]
		then
			echo "$line" | awk -F'=' '{print $4}' | awk -F',' '{print $1}'
		fi
	done < $1
}

function get_latency(){
	while read line
	do
		# clat (msec): min=1, max=302, avg=250.27, stdev=14.93
		if [[ "$line" == *"clat ("* ]]
		then
				printf "\t%s(%s)" $(echo "$line" | awk -F'=' '{print $4}' | awk -F',' '{print $1}') $(echo "$line" | awk -F'(' '{print $2}' | awk -F')' '{print $1}')
		fi
	done < $1
}

echo "#test_q-depth	 |	   iops	|	   latency" #> $result_file
i=0
while [ "x${test_qdepth_collection[$i]}" != "x" ]
do
	current_test_qdepth=${test_qdepth_collection[$i]}

	fio_log_file="$log_folder/${current_test_qdepth}.log"
	throughput=$(get_iops $fio_log_file)
	latency=$(get_latency $fio_log_file)
	echo  ${current_test_qdepth} ${throughput} ${latency} #>> $result_file

	i=$(($i + 1))
done
