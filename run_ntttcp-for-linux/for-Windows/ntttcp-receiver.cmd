mkdir C:\Users\Administrator\Desktop\log
c:\ntttcp.exe -v -w -cfi -sp -wa -wu 10 -cd 5 -a 16 -l 65536 -r -m   1,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-receiver-1.log
c:\ntttcp.exe -v -w -cfi -sp -wa -wu 10 -cd 5 -a 16 -l 65536 -r -m   2,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-receiver-2.log
c:\ntttcp.exe -v -w -cfi -sp -wa -wu 10 -cd 5 -a 16 -l 65536 -r -m   4,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-receiver-4.log
c:\ntttcp.exe -v -w -cfi -sp -wa -wu 10 -cd 5 -a 16 -l 65536 -r -m   8,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-receiver-8.log
c:\ntttcp.exe -v -w -cfi -sp -wa -wu 10 -cd 5 -a 16 -l 65536 -r -m  16,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-receiver-16.log
c:\ntttcp.exe -v -w -cfi -sp -wa -wu 10 -cd 5 -a 16 -l 65536 -r -m  32,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-receiver-32.log
c:\ntttcp.exe -v -w -cfi -sp -wa -wu 10 -cd 5 -a 16 -l 65536 -r -m  64,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-receiver-64.log
c:\ntttcp.exe -v -w -cfi -sp -wa -wu 10 -cd 5 -a 16 -l 65536 -r -m 128,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-receiver-128.log
c:\ntttcp.exe -v -w -cfi -sp -wa -wu 10 -cd 5 -a 16 -l 65536 -r -m 256,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-receiver-256.log
c:\ntttcp.exe -v -w -cfi -sp -wa -wu 10 -cd 5 -a 16 -l 65536 -r -m 512,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-receiver-512.log
c:\ntttcp.exe -v -w -cfi -sp -wa -wu 10 -cd 5 -a 16 -l 65536 -r -m 900,*,192.168.4.136 -t 100     > C:\Users\Administrator\Desktop\log\ntttcp-receiver-900.log
pause  