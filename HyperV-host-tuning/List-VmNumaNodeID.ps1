$user = [Security.Principal.WindowsIdentity]::GetCurrent();

if ((New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator) -eq $false)
{
    Write-Host "Please run as Administrator"
}
else
{
    foreach ($VM in $VMs)
    {
        $VMName = $VM.Name
        $numa = ((get-counter -ListSet "Hyper-V VM Vid Partition").PathsWithInstances | where {$_ -like "*$VMName*preferred numa node index*"} | get-counter).CounterSamples.CookedValue
        Write-Host "$VMName runs on NUMA NODE: $numa"
    }
}   

pause
