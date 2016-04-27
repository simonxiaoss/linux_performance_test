server_ip=$1
duration=60
server_ip=192.168.4.100
server_username=root
iperflocation="/root/runiperf/iperf-3.0.5/src/iperf3"
connections_per_iperf=4

#give more time to capture perf as start iperf3 needs time
# no. stats time tickets slower as capture sar/top result takes time
perfmonduration=$(( $duration ))  
threads=(1 2 4 8 16 32 64 128 256 512 1024 2000 3000 6000)
#threads=(16 32)
logs_dir=clientlogs
mkdir $logs_dir

i=0
while [ "x${threads[$i]}" != "x" ]
do
	port=8001
	echo "======================================"
	echo "Running Test: ${threads[$i]}"
	echo "======================================"

	touch reset.sig
	echo ${threads[$i]} > reset.sig
	scp reset.sig $server_username@${server_ip}:
	sleep 7

	number_of_connections=${threads[$i]}
	bash ./stats.sh $perfmonduration $logs_dir/${threads[$i]} &

	rm -rf the_generated_client.sh
	echo "./parallelcommands.sh " > the_generated_client.sh

	while [ $number_of_connections -gt $connections_per_iperf ]; do
		number_of_connections=$(($number_of_connections-$connections_per_iperf))
		echo " \"$iperflocation -c $server_ip -p $port -P $connections_per_iperf -t $duration > /dev/null \" " >> the_generated_client.sh
		port=$(($port + 1))
	done

	if [ $number_of_connections -gt 0 ]
	then
		echo " \"$iperflocation -c $server_ip -p $port -P $number_of_connections  -t $duration > /dev/null \" " >> the_generated_client.sh
	fi
	
	sed -i ':a;N;$!ba;s/\n/ /g'  ./the_generated_client.sh
	chmod 755 the_generated_client.sh

	cat ./the_generated_client.sh
	./the_generated_client.sh > /dev/null 

	i=$(($i + 1))

	echo "client test just finished. sleep 10 sec for next test..."
	sleep 10
done

