#!/bin/bash

log_folder=$1
io_size_collection=(4 8 16 32 64 128 256 512 1024)
io_mode_collection=(seqwr seqrewr seqrd rndrd rndwr rndrw)

result_parsed=""
result_file="${log_folder}/report.log"

if [[ $log_folder == ""  ]]
then
    echo "please specify a log folder"
    exit
fi

function get_bw(){
	while read line
	do
		#60111.56 Requests/sec executed
		if [[ "$line" == *"Requests/sec executed"* ]]
		then
			echo "$line" | awk -F' ' '{print $1}'
		fi
	done < $1
}

echo "#test_io_size | seqwr  seqrewr  seqrd  rndrd  rndwr  rndrw" > $result_file
io_size_index=0
while [ "x${io_size_collection[$io_size_index]}" != "x" ]
do
	current_io_size=${io_size_collection[$io_size_index]}
	
	io_mode_index=0
	numbers_string=""
	latency_string=""
	while [ "x${io_mode_collection[$io_mode_index]}" != "x" ]
	do
		current_io_mode=${io_mode_collection[$io_mode_index]}
		#4K-seqrd.sysbench.fileio.log
		log_file="$log_folder/${current_io_size}K-${current_io_mode}.sysbench.fileio.log"
		throughput=$(get_bw $log_file)
		numbers_string="$numbers_string $throughput"
		io_mode_index=$(($io_mode_index + 1))
	done

	echo  ${current_io_size} ${numbers_string} >> $result_file
	io_size_index=$(($io_size_index + 1))
done
cat $result_file
