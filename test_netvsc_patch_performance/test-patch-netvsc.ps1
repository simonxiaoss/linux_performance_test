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

########################################################################
# Base VM requirements:
# vm: 2 NICs:
#    NIC1: connect to internet to clone linux-next
#    NIC2: private network for test if want to run network tests
# vm: git-core installed
# vm: NTTTCP-for-Linux installed for network throughput performance test. 
#     See NTTTCP-for-Linux here: https://github.com/Microsoft/ntttcp-for-linux
# vm: if ubuntu: apt-get install kernel-package, so that we can build kernel package
# vm: if ubuntu: apt-get install hv-kvp-daemon-init, or linux-cloud-tools-$(uname -r), to install kvp daemon
# vm: if ubuntu: apt-get install dos2unix
########################################################################
# Other base VM configuration considerations:
# 1) configure VM so that we can use provided *.ppk key file to run commands/copy files with the Linux VM
# 2) If multiple VMs required, for example, running network tests, then configure the VMs to make sure 
#    password/key is not required when scp file between them
# 3) Install above tools
# 4) Create a root checkpoint for those VMs (for example, Lisabase). And configure the params file: 
#    git-bisect-for-regression-params.ps1
########################################################################
# Test folder files:
#    /TEST
#        /bin
#             /plink.exe
#             /pscp.exe
#             /dos2unix.exe, and its dependencies as below. all of them can be found from git for Windows
#             /msys-2.0.dll
#             /msys-iconv-2.dll
#             /msys-intl-8.dll
#        /ssh
#             /id_rsa.ppk
#             /id_rsa.pub
#        /build-ubuntu.sh
#        /run-ntttcp-and-tcping.sh
#        /patch-test-params.ps1
#        /test-patch-netvsc.ps1
#        /TCUtils.ps1  #this can be found from https://github.com/LIS/lis-test/tree/master/WS2012R2/lisa/setupscripts/TCUtils.ps1
########################################################################
function TestPort([String] $ipv4, [int] $port)
{
    $test = New-Object Net.Sockets.TcpClient
    $test.Connect($ipv4,$port)
    if($test.Connected)
    {
        return $true
    }
    else
    {
        return $false
    }
}

function WaitVMState([String] $ipv4, [String] $sshKey, [string] $state )
{
    $file = "teststate.sig"
    Write-Host "INFO :wait for VM $ipv4 to the state: $state"

    $success = $false
    switch ($state){
        SHUT_DOWN {
            $continueLoop = 300
            Write-Host "Wait for up to 300 seconds ... "
            While( $success -eq $false -and $continueLoop -gt 0) {
                $continueLoop --
                if ($continueLoop % 60 -eq 0)
                {
                    Write-Host " "
                }
                Write-Host "." -NoNewLine
                
                Start-Sleep -Seconds 1
                $success = -not (TestPort $ipv4 22)
            }
            Write-Host "OK"
        }
        BOOT_UP {
            #sleep for sshd to start
            $continueLoop = 300
            Write-Host "Wait for up to 300 seconds ... "
            While( $success -eq $false -and $continueLoop -gt 0) {
                $continueLoop --
                if ($continueLoop % 60 -eq 0)
                {
                    Write-Host " "
                }
                Write-Host "." -NoNewLine
                
                Start-Sleep -Seconds 1
                $success = (TestPort $ipv4 22)
            }
            Write-Host "OK"
        }
        default {
            $continueLoop = 3000
            Write-Host "Wait for up to 3000 seconds ... "
            while ($true){
                Start-Sleep -Seconds 1
                $continueLoop --

                if ($continueLoop % 60 -eq 0)
                {
                    Write-Host " "
                }
                if (-not (TestPort $ipv4 22))
                {
                    Write-Host "!" -NoNewLine    # cannot connect to the VM's IP address, need to re-enable host side vNIC?
                    continue
                }
               
                $fileCopied = GetFileFromVM $ipv4 $sshKey $file $file
                if ($fileCopied -eq $true)
                {
                    $content = (Get-Content $file)
                    if ( (Get-Content $file).Contains($state) ) 
                    {
                        $success = $true
                        break
                    }
                    Write-Host "X" -NoNewLine   # file copied but the content is unexpected!
                }
                else
                {
                    Write-Host "." -NoNewLine   # just wait for the file created on the VM 
                }
            }
            Write-Host "OK"
        }
    }
    return $success
}

function InitVmUp([String] $vmName, [String] $hvServer, [string] $checkpointName)
{
    $v = Get-VM $vmName -ComputerName $hvServer
    if ($v -eq $null)
    {
        Write-Host "Error: ResetVM cannot find the VM $vmName on HyperV server $hvServer"  -ForegroundColor Red
        return
    }
    if ($v.State -ne "Off")
    {
        Stop-VM $vmName -ComputerName $hvServer -force –TurnOff | out-null
    }
    $v = Get-VM $vmName -ComputerName $hvServer
    if ($v.State -ne "Off")
    {
        Write-Host "Error: ResetVM cannot stop the VM $vmName on HyperV server $hvServer" -ForegroundColor Red
    }

    $snaps = Get-VMSnapshot $vmName -ComputerName $hvServer
    $snapshotFound = $false
    foreach($s in $snaps)
    {
        if ($s.Name -eq $checkpointName)
        {
            write-Host "INFO : ResetVM VM $vmName to checkpoint $checkpointName"
            Restore-VMSnapshot $s -Confirm:$false | out-null
            $snapshotFound = $true
            break
        }
    }

    $v = Get-VM $vmName -ComputerName $hvServer
    if ($snapshotFound)
    {
        if ($v.State -eq "Paused")
        {
            Stop-VM $vmName -ComputerName $hvServer -Force | out-null
        }
    }
    else
    {
        Write-Host "Error: ResetVM cannot find the checkpoint $checkpointName for the VM $vmName on HyperV server $hvServer"  -ForegroundColor Red
    }

    $continueLoop = 10
    $vmUp = $false
    While( ($continueLoop -gt 0) -and ($vmUp  -eq $false)) {
        Start-VM $vmName -ComputerName $hvServer | out-null
        $v = Get-VM $vmName -ComputerName $hvServer
        if ($v.State -eq "Running")
        {
            Write-Host "INFO : VM $vmName has been started"
            $vmUp = $true
            break
        }
        else
        {
            Write-Host "WARN : VM $vmName failed to start" -ForegroundColor Yellow
        }
        $continueLoop --
    }
    if ($vmUp  -eq $false){
        Write-Host "Error: VM $vmName failed to start" -ForegroundColor Red
        exit -1
    }

    # Source the TCUtils.ps1 file
    . .\TCUtils.ps1

    $continueLoop = 60
    $ipv4 = $null
    While( ($continueLoop -gt 0) -and ($ipv4 -eq $null)) {
        $ipv4 = GetIPv4 $vmName $hvServer
        Write-Host "." -NoNewLine
        Start-Sleep -Seconds 5
        $continueLoop -= 5
    }

    Write-Host "INFO : get ip for VM $vmName : $ipv4"
	if ($ipv4 -ne $null)
	{
        #sleep for sshd to start
		$continueLoop = 60
		While( ($continueLoop -gt 0) -and ( (TestPort $ipv4 22) -ne $true )) {      
			Write-Host "." -NoNewLine
			Start-Sleep -Seconds 5
			$continueLoop -= 5
		}
        Write-Host "OK"   
	}
}

function CheckVmKernelVersion([String] $ipv4, [String] $sshKey)
{
    # Source the TCUtils.ps1 file
    . .\TCUtils.ps1
    SendCommandToVM      $ipv4 $sshKey "uname -r > teststate.sig"
    # make sure above command executing finished
    Start-Sleep -Seconds 5  
    SendCommandToVM      $ipv4 $sshKey "echo KERNEL_VERSION >> teststate.sig"
    WaitVMState $ipv4 $sshKey "KERNEL_VERSION" 

    GetFileFromVM $ipv4 $sshKey "teststate.sig" "teststate.sig"
    return (Get-Content "teststate.sig")
}

############################################
############################################
#
# THIS IS THE BEGIN OF THIS SCRIPT
#
############################################
############################################
# source the test parameter file
if((test-path ".\patch-test-params.ps1") -eq $false )
{
    write-host "patch-test-params.ps1 not found"
    exit -1
}
. .\patch-test-params.ps1

if((test-path ".\TCUtils.ps1") -eq $false )
{
    write-host "TCUtils.ps1 not found"
    exit -1
}
. .\TCUtils.ps1

if((test-path $linux_patch_folder) -eq $false )
{
    write-host "$linux_patch_folder not found"
    exit -1
}

if((test-path $distro_build_script) -eq $false )
{
    write-host "$distro_build_script not found"
    exit -1
}

if((test-path $benchmark_script) -eq $false )
{
    write-host "$benchmark_script not found"
    exit -1
}

 
############################################
# Init VM with linux-next clone.
# Make a base linux-next snapshot
############################################
InitVmUp $server_VM_Name $server_Host_ip $icabase_checkpoint
InitVmUp $client_VM_Name $client_Host_ip $icabase_checkpoint

Write-Host "INFO: Clone linux upstream code to VM $client_VM_ip ... "
SendCommandToVM      $client_VM_ip $sshKey "rm -rf *.patch"
SendCommandToVM      $client_VM_ip $sshKey "rm -rf $linuxnextfolder && git clone $linuxnext $linuxnextfolder && echo INIT_FINISHED > ./teststate.sig "
WaitVMState          $client_VM_ip $sshKey "INIT_FINISHED" 

Checkpoint-VM -Name $client_VM_Name -ComputerName $client_Host_ip -SnapshotName $linux_next_base_checkpoint -Confirm:$False

########################################################################################
# Build and run tests
########################################################################################
$logid = "defaultupstream"
$run = 2  #only run test 2 times: defaultupstream kernel and patchedupstream kernel
while ($run -gt 0)
{
    ############################################
    # Cleanup VM environment
    ############################################    
    SendCommandToVM      $client_VM_ip $sshKey "rm -rf linux-image*.deb"
    SendCommandToVM      $server_VM_ip $sshKey "rm -rf linux-image*.deb"

    ############################################
    # Build on client VM
    ############################################
    $clientkernelbuildlog = "client-build-$logid.log"
    $serverkernelbuildlog = "server-build-$logid.log"
    $testlog              = "run-test-$logid.log"
    $kernel_image_name = $("linux-image-" + $logid + ".deb")

    echo "echo BUILDTAG=$logid > build.tag"                    > .\run-kernelbuild.sh
    echo "mv ./$distro_build_script ./$linuxnextfolder "      >> .\run-kernelbuild.sh
    echo "cd ./$linuxnextfolder "                             >> .\run-kernelbuild.sh
    echo "./$distro_build_script > ../$clientkernelbuildlog"  >> .\run-kernelbuild.sh
    echo "cd .. "                                             >> .\run-kernelbuild.sh
    echo "echo BUILD_FINISHED > ./teststate.sig        "      >> .\run-kernelbuild.sh

    SendFileToVM     $client_VM_ip $sshKey ./run-kernelbuild.sh  "run-kernelbuild.sh"  $true
    SendFileToVM     $client_VM_ip $sshKey $distro_build_script   $distro_build_script $true
    SendCommandToVM  $client_VM_ip $sshKey "dos2unix *.sh && chmod 755 *.sh && ./run-kernelbuild.sh"
    WaitVMState      $client_VM_ip $sshKey "BUILD_FINISHED" 

    Write-Host "INFO :New kernel has been installed on $client_VM_Name. Copy log files and the new kernel back from the VM"
    GetFileFromVM    $client_VM_ip $sshKey   $clientkernelbuildlog  $clientkernelbuildlog
    GetFileFromVM    $client_VM_ip $sshKey   "linux-image*.deb"     $kernel_image_name

    ############################################
    # install the kernel on Server VM
    ############################################

    echo "mkdir ./$linuxnextfolder "                           > .\run-kernelinstall.sh
    echo "mv ./$distro_build_script ./$linuxnextfolder "      >> .\run-kernelinstall.sh
    echo "cd ./$linuxnextfolder "                             >> .\run-kernelinstall.sh
    echo "./$distro_build_script > ../$serverkernelbuildlog"  >> .\run-kernelinstall.sh
    echo "cd .. "                                             >> .\run-kernelinstall.sh
    echo "echo BUILD_FINISHED    > ./teststate.sig     "      >> .\run-kernelinstall.sh

    SendCommandToVM  $server_VM_ip $sshKey "rm -rf *.deb"
    SendFileToVM     $server_VM_ip $sshKey ./run-kernelinstall.sh   "run-kernelinstall.sh" $true
    SendFileToVM     $server_VM_ip $sshKey $distro_build_script     $distro_build_script   $true
    SendFileToVM     $server_VM_ip $sshKey $kernel_image_name       $kernel_image_name     $true
    SendCommandToVM  $server_VM_ip $sshKey "dos2unix *.sh && chmod 755 *.sh && ./run-kernelinstall.sh" 
    WaitVMState      $server_VM_ip $sshKey "BUILD_FINISHED" 

    Write-Host "INFO :New kernel has been installed on $server_VM_Name. Copy log files and the new kernel back from the VM"
    GetFileFromVM    $server_VM_ip $sshKey   $serverkernelbuildlog  $serverkernelbuildlog

    ############################################
    # kernel ready, make a checkpoint for debug purpose
    ############################################
    Checkpoint-VM -Name $server_VM_Name -ComputerName $server_Host_ip -SnapshotName $($linux_next_base_checkpoint+$logid) -Confirm:$False
    Checkpoint-VM -Name $client_VM_Name -ComputerName $client_Host_ip -SnapshotName $($linux_next_base_checkpoint+$logid) -Confirm:$False
    
    ############################################
    # restart the server and client VMs to boot from new kernel
    ############################################
    Restart-VM -ComputerName $server_Host_ip -VMName $server_VM_Name -Force
    Restart-VM -ComputerName $client_Host_ip -VMName $client_VM_Name -Force

    ############################################
    # is this kernel good to bootup?
    ############################################
    $newKernelUp = $false
    $newKernelUp = WaitVMState $server_VM_ip $sshKey "BOOT_UP" 
    if ($newKernelUp -eq $true)
    {
        $returnObjs = CheckVmKernelVersion $server_VM_ip $sshKey
        $currentKernelVersion = $returnObjs[-2]
        Write-Host "INFO :Expect kernel: lisperfregression$logid"
        Write-Host "INFO :Actual boot kernel: $currentKernelVersion"
        if ( -not $currentKernelVersion.Contains( $("lisperfregression" + $logid)) )
        {
            $newKernelUp = $false
        }
    }
    
    if ($newKernelUp -eq $true)
    {
        $newKernelUp = WaitVMState $client_VM_ip $sshKey "BOOT_UP" 
        if ($newKernelUp -eq $true)
        {
            $returnObjs = CheckVmKernelVersion $client_VM_ip $sshKey
            $currentKernelVersion = $returnObjs[-2]
            Write-Host "INFO :Expect kernel: lisperfregression$logid"
            Write-Host "INFO :Actual boot kernel: $currentKernelVersion"
            if ( -not $currentKernelVersion.Contains( $("lisperfregression" + $logid)) )
            {
                $newKernelUp = $false
            }
        }
    }
    
    ############################################
    # fail test if new kernel cannot bootup
    ############################################
    if ($newKernelUp -eq $false)
    {
        Write-Host "ERROR :New kernel is not boot up" -ForegroundColor Red
        exit -1
    }

    ############################################
    # Test this kernel
    ############################################
    Write-Host "INFO :running the test script ..."
    SendFileToVM     $client_VM_ip $sshKey $benchmark_script     $benchmark_script   $true
    SendCommandToVM  $client_VM_ip $sshKey "chmod 755 *.sh && ./$benchmark_script $logid >$testlog  && echo TEST_FINISHED > ./teststate.sig"
    WaitVMState      $client_VM_ip $sshKey "TEST_FINISHED" 

    ############################################
    # copy test log files back
    ############################################
    $ntttcp_client_log = "ntttcp-testlog-client-$logid.tar"
    $ntttcp_server_log = "ntttcp-testlog-server-$logid.tar"
    SendCommandToVM  $client_VM_ip $sshKey "tar -cvf $ntttcp_client_log $logid "
    SendCommandToVM  $server_VM_ip $sshKey "tar -cvf $ntttcp_server_log $logid "

    Start-Sleep -Seconds 30  #wait tar to complete

    GetFileFromVM    $client_VM_ip $sshKey   $ntttcp_client_log $ntttcp_client_log 
    GetFileFromVM    $server_VM_ip $sshKey   $ntttcp_server_log $ntttcp_server_log 

    ############################################
    # Prepare next run
    ############################################
    $logid = "patchedupstream"
    $run = $run--

    ############################################
    # send all patches to client VM
    ############################################
    $patchfiles = Get-ChildItem $linux_patch_folder
    for ($i=0; $i -lt $patchfiles.Count; $i++) {
        SendFileToVM     $client_VM_ip $sshKey $patchfiles[$i].FullName  $patchfiles[$i].Name  $true
    }
}