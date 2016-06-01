#!/bin/bash
#all read
mystat="mystat"
test_suite_collection=("oltp" "dss" "simple" "normal" "normal" "normal")

t=0
for currenttest in "${test_suite_collection[@]}"
do
        echo "$currenttest"
		# DSS test runs longest time, which is 65 minutes. 4000 = 65 * 60 + 100buffer
        iostat -x -d 1 4000 sdb  2>&1 > /root/benchmark/orion/$t.$currenttest.iostat.diskio.log  &
        vmstat       1 4000      2>&1 > /root/benchmark/orion/$t.$currenttest.vmstat.memory.cpu.log  &

        ./orion_linux_x86-64 -run $currenttest -testname $mystat

        pkill -f iostat
        pkill -f vmstat

        echo "test completed. sleep 60 seconds and then try next test..."
        sleep 60
        t=$(($t + 1))
done


#all write
./orion_linux_x86-64 -run oltp -testname mystat -write 100
./orion_linux_x86-64 -run dss -testname mystat -write 100
./orion_linux_x86-64 -run advanced -size_small 8 -size_large 1024 -type rand -simulate concat -write 100 -duration 60 -matrix basic
./orion_linux_x86-64 -run advanced -size_small 8 -size_large 1024 -type rand -simulate concat -write 100 -duration 60 -matrix detailed
#redo the "normal" test
./orion_linux_x86-64 -run advanced -size_small 8 -size_large 1024 -type rand -simulate concat -write 100 -duration 60 -matrix detailed
./orion_linux_x86-64 -run advanced -size_small 8 -size_large 1024 -type rand -simulate concat -write 100 -duration 60 -matrix detailed

#read50% and write 50%
./orion_linux_x86-64 -run oltp -testname mystat -write 50 
./orion_linux_x86-64 -run dss -testname mystat -write 50
./orion_linux_x86-64 -run advanced -size_small 8 -size_large 1024 -type rand -simulate concat -write 50 -duration 60 -matrix basic
./orion_linux_x86-64 -run advanced -size_small 8 -size_large 1024 -type rand -simulate concat -write 50 -duration 60 -matrix detailed
#redo the "normal" test
./orion_linux_x86-64 -run advanced -size_small 8 -size_large 1024 -type rand -simulate concat -write 50 -duration 60 -matrix detailed
./orion_linux_x86-64 -run advanced -size_small 8 -size_large 1024 -type rand -simulate concat -write 50 -duration 60 -matrix detailed