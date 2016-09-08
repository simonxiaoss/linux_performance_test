#!/bin/bash

log_folder=$1
zookeeper_bytes=$2
zookeeper_nodes=100000
test_threads_collection=(1 2 4 6 8 10)
result_parsed=""
result_file="${log_folder}/report.log"

if [[ $log_folder == ""  ]]
then
	echo "please specify a log folder"
	exit
fi

if [[ $zookeeper_bytes == ""  ]]
then
	echo "please specify zookeeper node size: 10 or 100 for example"
	exit
fi


#   Connecting to ubuntubm09:2181,ubuntubm10:2181,ubuntubm11:2181
#   Connected in 114 ms, handle is 0
#   Testing latencies on server ubuntubm09:2181,ubuntubm10:2181,ubuntubm11:2181 using asynchronous calls
#   created  100000 permanent znodes  in   4635 ms (0.046359 ms/op 21570.794418/sec)
#   set      100000           znodes  in   4613 ms (0.046138 ms/op 21673.990280/sec)
#   get      100000           znodes  in   5334 ms (0.053340 ms/op 18747.554759/sec)
#   deleted  100000 permanent znodes  in   4734 ms (0.047341 ms/op 21123.236591/sec)
#   created  100000 ephemeral znodes  in   4722 ms (0.047224 ms/op 21175.884223/sec)
#   watched  500000           znodes  in  25558 ms (0.051117 ms/op 19562.892917/sec)
#   deleted  100000 ephemeral znodes  in   4630 ms (0.046304 ms/op 21596.332123/sec)
#   notif    500000           watches in      0 ms (included in prior)
#   Latency test complete

function get_transactions_per_sec(){
	while read line
	do
		if [[ "$line" == *"$2"* ]]
		then
			echo "$line" |tr -s " " | awk -F'/' '{print $2}' | awk -F' ' '{print $2}' | awk -F'/' '{print $1}'
			break
		fi
	done < $1
}

echo "#conn	"	> $result_file
i=0
while [ "x${test_threads_collection[$i]}" != "x" ]
do
	current_test_threads=${test_threads_collection[$i]}
	
	total_create_permanent=0
	total_set=0
	total_get=0
	total_deleted=0
	total_watched=0
	num_logs=0
	for (( j=1; j<=$current_test_threads; j++ ))
	do	
		log_file="$log_folder/logs-${current_test_threads}clients-${zookeeper_bytes}bytes-${zookeeper_nodes}nodes/zookeeper_latency_${j}.log"
		if [ ! -f $log_file ]; then
			echo "File $log_file not found!"
			continue
		fi
		num_logs=$(echo $num_logs+1 | bc)
		total_create_permanent=$(echo $total_create_permanent+$(get_transactions_per_sec $log_file "created") | bc)
		total_set=$(echo $total_set+$(get_transactions_per_sec $log_file "set") | bc)
		total_get=$(echo $total_get+$(get_transactions_per_sec $log_file "get") | bc)
		total_deleted=$(echo $total_deleted+$(get_transactions_per_sec $log_file "deleted") | bc)
		total_watched=$(echo $total_watched+$(get_transactions_per_sec $log_file "watched") | bc)
	done
	
	printf "%s\t%s\t%s\t%s\t%s\t%s\n" ${current_test_threads} $(echo $total_create_permanent/$num_logs | bc) $(echo $total_set/$num_logs | bc) $(echo $total_get/$num_logs | bc) $(echo $total_deleted/$num_logs | bc) $(echo $total_watched/$num_logs | bc) >> $result_file

	i=$(($i + 1))
done

cat $result_file

