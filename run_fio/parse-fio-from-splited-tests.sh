#!/bin/bash

#
# usage: ./parser.sh 4K
#

log_folder=$1
q_depth_collection=(1 2 4 8 16 32 64 128 256 512 1024)
io_mode_collection=(read randread write randwrite)

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

function get_bw(){
	while read line
	do
		# read : io=1915.2MB, bw=32669KB/s, iops=4083, runt= 60031msec
		if [[ "$line" == *"bw="* ]]
		then
			echo "$line" | awk -F'=' '{print $3}' | awk -F',' '{print $1}'
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

echo "#test_q-depth	 |	   iops	|	   latency" > $result_file
q_depth_index=0
while [ "x${q_depth_collection[$q_depth_index]}" != "x" ]
do
	current_q_depth=${q_depth_collection[$q_depth_index]}
	
	io_mode_index=0
	numbers_string=""
	latency_string=""
	while [ "x${io_mode_collection[$io_mode_index]}" != "x" ]
	do
		current_io_mode=${io_mode_collection[$io_mode_index]}
		#4K-1024-randread.fio.log
		fio_log_file="$log_folder/${log_folder}-${current_q_depth}-${current_io_mode}.fio.log"
		throughput=$(get_iops $fio_log_file)
		latency=$(get_latency $fio_log_file)
		numbers_string="$numbers_string $throughput"
		latency_string="$latency_string $latency"
		io_mode_index=$(($io_mode_index + 1))
	done

	echo  ${current_q_depth} ${numbers_string} ${latency_string} >> $result_file
	q_depth_index=$(($q_depth_index + 1))
done
cat $result_file
