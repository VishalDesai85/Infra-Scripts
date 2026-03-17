#Requires -Version 5.0
# Script: Check local ClusSvc status and cluster name
# Exports result to C:\temp\

$serviceName = "ClusSvc"
$date = Get-Date -Format "MM-dd-yyyy_HH-mm-ss"
#write-host $date  

# Mention the ComputerName against which you want to check service status
$computer = $env:COMPUTERNAME
$server = $computer
# Create an empty array to store the results
$results = @()

# Check if the server is responding to ping or Test-NetConnection
$ping = Test-Connection -ComputerName $server -Count 1 -Quiet
$port445 = Test-NetConnection -ComputerName $server -Port 445 -InformationLevel Quiet
$port5985 = Test-NetConnection -ComputerName $server -Port 5985 -InformationLevel Quiet

if ($ping -or $port445 -or $port5985) {
    try {
        # Get the service status
        $service = Get-Service -ComputerName $server -Name $serviceName -ErrorAction Stop
        $status = $service.Status

        if ($status -eq 'Running') {
            $ClusterName = (Get-Cluster).Name
        }
        else {
            $ClusterName = (Get-ItemProperty -Path 'HKLM:\SYSTEM\ControlSet001\Services\ClusSvc\Parameters' -Name ClusterName -ErrorAction Stop).ClusterName
        }
    }
    catch [Microsoft.PowerShell.Commands.ServiceCommandException] {
        $status = "Not Found"
        $ClusterName = "Cluster role is not installed/Configured"
    }
    catch {
        $status = "Error"
        $ClusterName = "Unable to determine: $($_.Exception.Message)"
    }

    $result = [PSCustomObject]@{
        ServerName  = $server
        ServiceName = $serviceName
        Status      = $status
        ClusterName = $ClusterName
    }

    $result | Export-Csv -Path "$outputPath\ServiceStatus_$date.csv" -NoTypeInformation
    Write-Output "Service status has been exported to $outputPath"
