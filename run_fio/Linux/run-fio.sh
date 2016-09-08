fio_path="/root/benchmark/fio/fio-2.1.10"
log_folder="$fio_path/../logs"
mkdir -p $log_folder
$fio_path/fio $fio_path/examples/lis-test.fio1 > $log_folder/1.log
$fio_path/fio $fio_path/examples/lis-test.fio2 > $log_folder/2.log
$fio_path/fio $fio_path/examples/lis-test.fio4 > $log_folder/4.log
$fio_path/fio $fio_path/examples/lis-test.fio8 > $log_folder/8.log
$fio_path/fio $fio_path/examples/lis-test.fio16 > $log_folder/16.log
$fio_path/fio $fio_path/examples/lis-test.fio32 > $log_folder/32.log
$fio_path/fio $fio_path/examples/lis-test.fio64 > $log_folder/64.log
$fio_path/fio $fio_path/examples/lis-test.fio128 > $log_folder/128.log
$fio_path/fio $fio_path/examples/lis-test.fio256 > $log_folder/256.log
$fio_path/fio $fio_path/examples/lis-test.fio512 > $log_folder/512.log
$fio_path/fio $fio_path/examples/lis-test.fio1024 > $log_folder/1024.log