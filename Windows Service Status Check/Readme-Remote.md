# ServiceStatus Check-Remotely
This script would be handy if you wish to run it from one of the member servers over the network 

This PowerShell script checks the Service status of Failover Cluster and exports the results to a CSV file.

# Define the service name you want to check
In our example, we are checking cluster service status


```powershell
$serviceName = "ClusSvc"
```

## Prerequisites

- PowerShell 5.1 or later
- Necessary permissions to run remote commands on the servers

## Usage

1. **Create a temp folder locally on the server on any drive of your choice**
     - Example: C:\temp
<br> This is the directory where the output would get exported 
     - Create a ServerList.txt file under c:\temp and enter server hostnames under serverlist.txt one in each line

2. **Run the Script:**
   - Open PowerShell with administrative privileges.
   - Execute the script.

```powershell
# Define the service name you want to check
$serviceName = "ClusSvc1"
$date = Get-Date -Format "MM-dd-yyyy_HH-mm-ss"
#write-host $date  

# Read the list of servers from a file
$servers = Get-Content -Path "C:\temp\ServerList.txt"

# Create an empty array to store the results
$results = @()

foreach ($server in $servers) {
    # Check if the server is responding to ping or Test-NetConnection
    $ping = Test-Connection -ComputerName $server -Count 1 -Quiet
    $port445 = Test-NetConnection -ComputerName $server -Port 445 -InformationLevel Quiet
    $port5985 = Test-NetConnection -ComputerName $server -Port 5985 -InformationLevel Quiet

    if ($ping -or $port445 -or $port5985) 
      {
        try {
            # Get the service status
            $service = Get-Service -ComputerName $server -Name $serviceName -ErrorAction Stop
            $status = $service.Status
            
            if($Status -eq 'Running')
             {
              $Clustername = (Invoke-command -ComputerName $server -ScriptBlock {(Get-cluster).name})
             }
            else
             {
              $Clustername =  (Get-ItemProperty -Path 'HKLM:\SYSTEM\ControlSet001\Services\ClusSvc\Parameters' -Name ClusterName).ClusterName
             }
           
        } 

    catch 
        
        {
            # If there's an error (e.g., service not found), set status to "Not Found"
             $status = "Not Found"
             $Clustername = "Cluster role is not installed/Configured"
        }
    
    } 
   
    else 
    
    {
        # If the server is not responding, set status to "Not Responding"
        $status = "Server Not Responding/Communicating"
        $Clustername = "As the Server is not responding/communicating Cluster Name cannot be fetched"
    }

    # Add the result to the array
    $results += [PSCustomObject]@{
        ServerName = $server
        ServiceName = $serviceName
        Status = $status
        Clustername = $Clustername
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path "C:\temp\ServiceStatus$date.csv" -NoTypeInformation

Write-Output "Service status has been exported to C:\temp\ location"
