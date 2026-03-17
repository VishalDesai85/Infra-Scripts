#Requires -Version 5.0
# Script: Check local ClusSvc status and cluster name
# Exports result to C:\temp\

$serviceName = "ClusSvc"
$date = Get-Date -Format "MM-dd-yyyy_HH-mm-ss"
$server = $env:COMPUTERNAME
$outputPath = "C:\temp"

# Ensure output directory exists
if (-not (Test-Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory | Out-Null
}

try {
    $service = Get-Service -Name $serviceName -ErrorAction Stop
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

$result | Format-Table -AutoSize

$result | Export-Csv -Path "$outputPath\ServiceStatus_$date.csv" -NoTypeInformation
Write-Output "Service status has been exported to $outputPath"
