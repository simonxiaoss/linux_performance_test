#!/bin/bash

log_folder=$1
log_suffix="sysbench-mariadb.run.log"
test_threads_collection=(1 2 4 8 16 32 64 128 256)
result_parsed=""
result_file="${log_folder}/report.log"

if [[ $log_folder == ""  ]]
then
	echo "please specify a log folder"
	exit
fi

#OLTP test statistics:
#    queries performed:
#        read:                            2062354
#        write:                           589244
#        other:                           294622
#        total:                           2946220
#    transactions:                        147311 (491.03 per sec.)
#    read/write requests:                 2651598 (8838.62 per sec.)
#    other operations:                    294622 (982.07 per sec.)
#    ignored errors:                      0      (0.00 per sec.)
#    reconnects:                          0      (0.00 per sec.)
#
#General statistics:
#    total time:                          300.0015s
#    total number of events:              147311
#    total time taken by event execution: 299.7764s
#    response time:
#         min:                                  1.51ms
#         avg:                                  2.03ms
#         max:                                 26.30ms
#         approx.  95 percentile:               3.06ms
#
#Threads fairness:
#    events (avg/stddev):           147311.0000/0.00
#    execution time (avg/stddev):   299.7764/0.00

#    transactions:                        147311 (491.03 per sec.)
function get_transactions_per_sec(){
	while read line
	do
		if [[ "$line" == *"transactions"* ]]
		then
			echo "$line" |tr -s " " | awk -F'(' '{print $2}' | awk -F' ' '{print $1}'
		fi
	done < $1
}

#         approx.  95 percentile:               3.06ms
function get_95percentile_latency(){
	while read line
	do
		if [[ "$line" == *"percentile"* ]]
		then
			echo "$line" |tr -s " " | awk -F' ' '{print $4}' | tr -d "ms"
		fi
	done < $1
}

echo "#conn		tps		95%-latency"             > $result_file
i=0
while [ "x${test_threads_collection[$i]}" != "x" ]
do
	current_test_threads=${test_threads_collection[$i]}
	log_file="$log_folder/${current_test_threads}.${log_suffix}"

	tps=$(get_transactions_per_sec $log_file)
	latency=$(get_95percentile_latency $log_file)

	printf "%s\t\t%s\t\t%s\n" ${current_test_threads} ${tps} ${latency} >> $result_file
	i=$(($i + 1))
done

cat $result_file
