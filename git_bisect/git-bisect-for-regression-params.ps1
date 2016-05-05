########################################################################
#
# Linux on Hyper-V and Azure Test Code, ver. 1.0.0
# Copyright (c) Microsoft Corporation
#
# All rights reserved. 
# Licensed under the Apache License, Version 2.0 (the ""License"");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0  
#
# THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS
# OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
# ANY IMPLIED WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR
# PURPOSE, MERCHANTABLITY OR NON-INFRINGEMENT.
#
# See the Apache Version 2.0 License for specific language governing
# permissions and limitations under the License.
#
########################################################################

$server_VM_Name = "sixiao-Ubuntu1510-Server"
$client_VM_Name = "sixiao-Ubuntu1510-Client"

$server_Host_ip = "LIS-PERF11-TH5"
$client_Host_ip = "LIS-PERF10-TH5"

$server_VM_ip = "192.168.4.109"
$client_VM_ip = "192.168.4.108"
$sshKey = "id_rsa.ppk"

$distro_build_script = "build-ubuntu.sh"
$icabase_checkpoint = "RegressionBase"
$linux_next_base_checkpoint = "linux-next-base"

$test_folder = "V:\Test"

$linuxnext="git://git.kernel.org/pub/scm/linux/kernel/git/davem/net-next.git"
$linuxnextfolder="net-next"
$lastKnownGoodcommit = "da7049f834c3582c1ed1a04889bda5b4121973c0"
$lastKnownBadcommit  = ""
$topCommitQuality = "BAD"

$benchmark_script = "git-bisect-for-regression-netvsc-ntttcp.ps1"