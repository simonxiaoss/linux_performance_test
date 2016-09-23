#!/bin/bash

io_size_collection=(4 8 16 32 64 128 256 512 1024)
io_mode_collection=(seqwr seqrewr seqrd rndrd rndwr rndrw)
log_folder="/root/sysbench/fileio/logs"

mkdir -p $log_folder
cd /mnt

echo "Prepare test files..."
sysbench --test=fileio --num-threads=8 --report-interval=5 --file-num=8 --file-total-size=16G prepare
echo "Test files created."

################################
# IO SIZE
################################
iosize_index=0
while [ "x${io_size_collection[$iosize_index]}" != "x" ]
do
	current_io_size=${io_size_collection[$iosize_index]}
	current_file_size=${file_size_collection[$iosize_index]}
	echo "Running IO size = ${current_io_size} K "
	
	################################
	# IO MODE
	################################
	io_mode_index=0
	while [ "x${io_mode_collection[$io_mode_index]}" != "x" ]
	do
		current_io_mode=${io_mode_collection[$io_mode_index]}
		echo "        Running IO test = ${current_io_mode}"
		log_file="${log_folder}/${current_io_size}K-${current_io_mode}.sysbench.fileio.log"
		echo "SYSBENCH TEST COMMAND:" > ${log_file}
		echo "sysbench --test=fileio --num-threads=8 --report-interval=30 --file-num=8 --file-block-size=${current_io_size}K --file-total-size=16G --file-test-mode=${current_io_mode} --file-io-mode=sync --file-extra-flags=direct --max-time=300 --max-requests=0 run" >> ${log_file}
		      sysbench --test=fileio --num-threads=8 --report-interval=30 --file-num=8 --file-block-size=${current_io_size}K --file-total-size=16G --file-test-mode=${current_io_mode} --file-io-mode=sync --file-extra-flags=direct --max-time=300 --max-requests=0 run  >> ${log_file}
		sleep 1
		io_mode_index=$(($io_mode_index + 1))
	done
		
	sleep 1
	iosize_index=$(($iosize_index + 1))
done

#echo "Prepare test files..."
#sysbench --test=fileio cleanup
#echo "Test files created."