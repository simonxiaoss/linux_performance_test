myid=$1
zookeeper_server_path="/root/benchmark/zookeeper/zookeeper-3.4.8/bin/zkServer.sh"
if [[ $myid == ""  ]]
then
	echo "please specify myid"
	exit
fi

umount /mnt
if [ $? -ne 0 ]
then
    echo "/mnt is busy, exit."
    exit 0
fi

mkfs.ext4 /dev/sdb1 -F
mount /dev/sdb1 /mnt
mkdir -p /mnt/zookeeper && echo $myid > /mnt/zookeeper/myid
$zookeeper_server_path start-foreground
