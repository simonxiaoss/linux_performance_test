[int[]] $file_size_collection=16, 16, 160, 160
$fio="C:\fio.exe"

#move to the test disk
pushd e: 

################################
# IO SIZE
################################
foreach ($current_io_size in 4, 8, 128, 1024){
	$current_file_size=16
	if ($current_io_size -gt 100)
	{
        	$current_file_size=160
	}
	echo "Running IO size = ${current_io_size} K "
	$log_folder="C:\fiologs\${current_io_size}K"
	New-Item $log_folder -Force -ItemType Directory | Out-Null
	
	################################
	# Q DEPTH
	################################
	foreach ($current_q_depth in 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024){       
		if ( $current_q_depth -gt 8 ) {
			$actual_q_depth=$(($current_q_depth / 8))
			$num_jobs=8
	        }
		else {
			$actual_q_depth=$current_q_depth
			$num_jobs=1
		}
		echo "    Running q depth = ${current_q_depth} ( ${actual_q_depth} X ${num_jobs} )"
		
		################################
		# IO MODE
		################################
		foreach ($current_io_mode in "read", "randread", "write", "randwrite") {
			echo "        Running IO test = ${current_io_mode}"
			$log_file="${log_folder}/${current_io_size}K-${current_q_depth}-${current_io_mode}.fio.log"
			echo "FIO TEST COMMAND:" > ${log_file}
			echo "$fio --name=${current_io_mode} --bs=${current_io_size}k --ioengine=windowsaio --iodepth=${actual_q_depth} --size=${current_file_size}G --direct=1 --runtime=120 --numjobs=${num_jobs} --rw=${current_io_mode} --group_reporting" >> ${log_file}
			 iex "$fio --name=${current_io_mode} --bs=${current_io_size}k --ioengine=windowsaio --iodepth=${actual_q_depth} --size=${current_file_size}G --direct=1 --runtime=120 --numjobs=${num_jobs} --rw=${current_io_mode} --group_reporting"  >> ${log_file}
			sleep 1
		}
		sleep 1
	}	
	echo ""
	sleep 1
}
