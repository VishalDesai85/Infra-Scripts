# Define the service name you want to check
$serviceName = "ClusSvc"
$date = Get-Date -Format "MM-dd-yyyy_HH-mm-ss"
#write-host $date  

# Read the list of servers from a file
$servers = Get-Content -Path "C:\temp\ServerList.txt"

# Create an empty array to store the results
$results = @()

foreach ($server in $servers) {
    # Check if the server is responding to ping or Test-NetConnection
    $ping = Test-Connection -ComputerName $server -Count 1 -Quiet
    $port445 = (Test-NetConnection -ComputerName $server -Port 445  -InformationLevel Quiet -WarningAction SilentlyContinue).TcpTestSucceeded
    $port5985 = (Test-NetConnection -ComputerName $server -Port 5985 -InformationLevel Quiet -WarningAction SilentlyContinue).TcpTestSucceeded

    if ($ping -or $port445 -or $port5985) {
        try {
            # Get the service status
            $service = Get-Service -ComputerName $server -Name $serviceName -ErrorAction Stop
            $status = $service.status
            
            if ($status -eq 'Running') {
                $Clustername = (Invoke-Command -ComputerName $server -ScriptBlock { (Get-Cluster).Name })

                # Fetch cluster roles (cluster groups) running on this cluster
                try {
                    $roleObjects = Invoke-Command -ComputerName $server -ScriptBlock {
                        Get-ClusterGroup | Select-Object -Property Name, State
                    }
                    if ($roleObjects) {
                        $ClusterRoles = ($roleObjects | ForEach-Object { "$($_.Name) [$($_.State)]" }) -join '; '
                    }
                    else {
                        $ClusterRoles = "No role is running on the server"
                    }
                }
                catch {
                    $ClusterRoles = "Unable to retrieve cluster roles: $_"
                }
            }
            else {
                $Clustername = Invoke-Command -ComputerName $server -ScriptBlock {
                    (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\ClusSvc\Parameters' -Name ClusterName).ClusterName
                }
                $ClusterRoles = "N/A - ClusSvc is not Running"
            }
        }
        catch {
            # If there's an error (e.g., service not found, Cannot find path, etc), set status to "Not Found"
            $status = "Not Found"
            $Clustername = "Cluster service is not installed/Configured"
            $ClusterRoles = "N/A - Cluster role is not Configured"
        }
     
        
    }
    else {
        # If the server is not responding, set status to "Not Responding"
        $status = "Server Not Responding/Communicating"
        $Clustername = "As the Server is not responding/communicating Cluster Name cannot be fetched"
        $ClusterRoles = "N/A - Server is not responding/communicating"
    }
    # Add the result to the array
    $results += [PSCustomObject]@{
        ServerName   = $server
        ServiceName  = $serviceName
        Status       = $status
        ClusterName  = $Clustername
        ClusterRoles = $ClusterRoles
    }
}


# Export the results to a CSV file
$results | Export-Csv -Path "C:\temp\ServiceStatus$date.csv" -NoTypeInformation

Write-Output "Service status has been exported to C:\temp\ location"
