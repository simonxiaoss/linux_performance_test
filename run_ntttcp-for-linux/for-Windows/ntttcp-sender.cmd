mkdir C:\Users\Administrator\Desktop\log
c:\ntttcp.exe -v -w -cfi -sp -wu 10 -cd 5 -a 16 -l 65536 -s -m   1,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-sender-1.log
c:\ntttcp.exe -v -w -cfi -sp -wu 10 -cd 5 -a 16 -l 65536 -s -m   2,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-sender-2.log
c:\ntttcp.exe -v -w -cfi -sp -wu 10 -cd 5 -a 16 -l 65536 -s -m   4,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-sender-4.log
c:\ntttcp.exe -v -w -cfi -sp -wu 10 -cd 5 -a 16 -l 65536 -s -m   8,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-sender-8.log
c:\ntttcp.exe -v -w -cfi -sp -wu 10 -cd 5 -a 16 -l 65536 -s -m  16,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-sender-16.log
c:\ntttcp.exe -v -w -cfi -sp -wu 10 -cd 5 -a 16 -l 65536 -s -m  32,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-sender-32.log
c:\ntttcp.exe -v -w -cfi -sp -wu 10 -cd 5 -a 16 -l 65536 -s -m  64,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-sender-64.log
c:\ntttcp.exe -v -w -cfi -sp -wu 10 -cd 5 -a 16 -l 65536 -s -m 128,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-sender-128.log
c:\ntttcp.exe -v -w -cfi -sp -wu 10 -cd 5 -a 16 -l 65536 -s -m 256,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-sender-256.log
c:\ntttcp.exe -v -w -cfi -sp -wu 10 -cd 5 -a 16 -l 65536 -s -m 512,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-sender-512.log
c:\ntttcp.exe -v -w -cfi -sp -wu 10 -cd 5 -a 16 -l 65536 -s -m 900,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-sender-900.log
pause