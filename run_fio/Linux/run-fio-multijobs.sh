#!/bin/bash

################################
# Run FIO with multiple jobs for large q depth, to avoid single fio saturate its CPU
# the "avgqu-sz" seen from system is accumulated from all fio jobs
#
# assume:
#   a) fio installed
#   b) an exclusive disk is formatted and mounted to /mnt
#
# tests covered:
#   a) IO size: 4K, 8K, 128K and 1M (from iostat, avgrq-sz is limited to 128K?)
#   b) qdepth: from 1, to 1024 (for larger qdepth, use multiple fio jobs)
################################

io_size_collection=(4 8 128 1024)
file_size_collection=(16 16 160 160)
q_depth_collection=(1 2 4 8 16 32 64 128 256 512 1024)
io_mode_collection=(read randread write randwrite)

cd /mnt

################################
# IO SIZE
################################
iosize_index=0
while [ "x${io_size_collection[$iosize_index]}" != "x" ]
do
	current_io_size=${io_size_collection[$iosize_index]}
	current_file_size=${file_size_collection[$iosize_index]}
	echo "Running IO size = ${current_io_size} K "
	log_folder="/root/fio/logs/${current_io_size}K"
	mkdir -p $log_folder

	
	################################
	# Q DEPTH
	################################
	q_depth_index=0
	while [ "x${q_depth_collection[$q_depth_index]}" != "x" ]
	do
		current_q_depth=${q_depth_collection[$q_depth_index]}
		if [ $current_q_depth -gt 8 ] 
		then
			actual_q_depth=$(($current_q_depth / 8))
			num_jobs=8
		else 
			actual_q_depth=$current_q_depth
			num_jobs=1
		fi
		echo "    Running q depth = ${current_q_depth} ( ${actual_q_depth} X ${num_jobs} )"
		
		################################
		# IO MODE
		################################
		io_mode_index=0
		while [ "x${io_mode_collection[$io_mode_index]}" != "x" ]
		do
			current_io_mode=${io_mode_collection[$io_mode_index]}
			echo "        Running IO test = ${current_io_mode}"
			log_file="${log_folder}/${current_io_size}K-${current_q_depth}-${current_io_mode}.fio.log"
			echo "FIO TEST COMMAND:" > ${log_file}
			echo "fio --name=${current_io_mode} --bs=${current_io_size}k --ioengine=libaio --iodepth=${actual_q_depth} --size=${current_file_size}G --direct=1 --runtime=120 --numjobs=${num_jobs} --rw=${current_io_mode} --group_reporting" >> ${log_file}
			      fio --name=${current_io_mode} --bs=${current_io_size}k --ioengine=libaio --iodepth=${actual_q_depth} --size=${current_file_size}G --direct=1 --runtime=120 --numjobs=${num_jobs} --rw=${current_io_mode} --group_reporting  >> ${log_file}
			sleep 1
			io_mode_index=$(($io_mode_index + 1))
		done
			
		sleep 1
		q_depth_index=$(($q_depth_index + 1))
	done

    echo ""
    sleep 1
    iosize_index=$(($iosize_index + 1))
done
