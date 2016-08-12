#!/bin/bash

log_folder=$1
log_suffix="memtier_benchmark.run.log"
test_threads_collection=(1 2 4 8 16 32 64 128 256 512 1008)
result_parsed=""
result_file="${log_folder}/report.log"

if [[ $log_folder == ""  ]]
then
	echo "please specify a log folder"
	exit
fi

#BEST RUN RESULTS
#========================================================================
#Type        Ops/sec     Hits/sec   Misses/sec      Latency       KB/sec
#------------------------------------------------------------------------
#Sets        2246.38          ---          ---      0.21700       150.88
#Gets        2246.38      2246.38         0.00      0.21800       187.69
#Totals      4492.77      2246.38         0.00      0.21800       338.57

function get_ops_per_sec(){
	while read line
	do
		if [[ "$line" == *"Totals"* ]]
		then
			echo "$line" |tr -s " " | awk -F' ' '{print $2}'
		fi
	done < $1
}

function get_latency(){
	while read line
	do
		if [[ "$line" == *"Totals"* ]]
		then
			echo "$line" |tr -s " " | awk -F' ' '{print $5}'
		fi
	done < $1
}

echo "==============================================================" >  $result_file
echo "Ops/sec"                                                        >> $result_file
echo "==============================================================" >> $result_file
echo "#test_connections	|	BEST	| WORSE	| AVERAGE"                >> $result_file
i=0
while [ "x${test_threads_collection[$i]}" != "x" ]
do
	current_test_threads=${test_threads_collection[$i]}
	log_file="$log_folder/${current_test_threads}.${log_suffix}"
	OPs_per_sec=$(get_ops_per_sec $log_file)
	echo $current_test_threads $OPs_per_sec                           >> $result_file
	i=$(($i + 1))
done

echo ""                                                               >> $result_file
echo ""                                                               >> $result_file

echo "==============================================================" >> $result_file
echo "Latency"                                                        >> $result_file
echo "==============================================================" >> $result_file
echo "#test_connections	|	BEST	| WORSE	| AVERAGE"                >> $result_file
i=0
while [ "x${test_threads_collection[$i]}" != "x" ]
do
	current_test_threads=${test_threads_collection[$i]}
	log_file="$log_folder/${current_test_threads}.${log_suffix}"
	latency=$(get_latency $log_file)
	echo $current_test_threads $latency                               >> $result_file
	i=$(($i + 1))
done

cat $result_file