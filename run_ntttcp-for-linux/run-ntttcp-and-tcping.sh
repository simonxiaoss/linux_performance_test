# please clone tools from here:
#    git clone https://github.com/Microsoft/ntttcp-for-linux
#    git clone https://github.com/simonxiaoss/tcping

server_ip=192.168.4.109
server_username=root
ntttcp_run_duration=65
tcping_run_duration=60
threads_n1=(1 2 4 8 16 32 64)
threads_64_nx=(2 4 8 16)

ssh $server_username@$server_ip "pkill -f ntttcp"

i=0
while [ "x${threads_n1[$i]}" != "x" ]
do
        echo "======================================"
        echo "Running Test: ${threads_n1[$i]} X 1"
        echo "======================================"

        ssh $server_username@$server_ip "pkill -f ntttcp"
        ssh $server_username@$server_ip "ntttcp -P ${threads_n1[$i]} -t ${ntttcp_run_duration}" &
        sleep 2
        tcping -t 20 -n ${tcping_run_duration} $server_ip 22 > "tcping-ntttcp-p${threads_n1[$i]}X1.log" &
        ntttcp -s${server_ip} -P ${threads_n1[$i]} -n 1 -t ${ntttcp_run_duration}  > "ntttcp-p${threads_n1[$i]}X1.log"

        i=$(($i + 1))
        echo "current test finished. wait for next one... "
        sleep 5
done

i=0
while [ "x${threads_64_nx[$i]}" != "x" ]
do
        echo "======================================"
        echo "Running Test: 64 X ${threads_64_nx[$i]} "
        echo "======================================"

        ssh $server_username@$server_ip "pkill -f ntttcp"
        ssh $server_username@$server_ip "ntttcp -P 64 -t ${ntttcp_run_duration}" &
        sleep 2
        tcping -t 20 -n ${tcping_run_duration} $server_ip 22 > "tcping-ntttcp-p64X${threads_64_nx[$i]}.log" &
        ntttcp -s${server_ip} -P 64 -n ${threads_64_nx[$i]} -t ${ntttcp_run_duration}  > "ntttcp-p64X${threads_64_nx[$i]}.log"

        i=$(($i + 1))
        echo "current test finished. wait for next one... "
        sleep 5
done

ssh $server_username@$server_ip "pkill -f ntttcp"

echo "all done."
