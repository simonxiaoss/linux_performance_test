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

$server_VM_Name = "Linux-VM-Server"
$client_VM_Name = "Linux-VM-Client"

$server_Host_ip = "LIS-Server-Host"
$client_Host_ip = "LIS-Client-Host"

$server_VM_ip = "192.168.4.1"
$client_VM_ip = "192.168.4.2"
$sshKey = "ID.ppk"

$distro_build_script = "build-ubuntu.sh"
$icabase_checkpoint = "DefaultKernel"
$test_kernel_prefix = "listestkernel"
$linux_next_base_checkpoint = "linux-next-base"

$test_folder = "V:\Test"
$linux_patch_folder = "\\my\linux\patches\folder\patch-test\2016-06-15"

$linuxnext="git://git.kernel.org/pub/scm/linux/kernel/git/davem/net-next.git"
$linuxnextfolder="net-next"

$benchmark_script = "run-ntttcp-and-tcping.sh"
