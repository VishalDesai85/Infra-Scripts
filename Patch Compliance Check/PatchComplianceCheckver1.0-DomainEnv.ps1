#################################################
#Approch for Domain Joined servers
#Ensure to create a folder under C:\temp or any path of your choice and update computer names under computers.txt file. Only hostnames one in each line will do.
#Example:
#node01-2019
#node02-2019
#node03-2019

#Also, enter the latest Security Update patch IDs in the script below line #17, #18, #19 and #20 if applicable before you run it to get exact compliance checks done
################################################

#defining $date for display of current date and time and while exporting the csv at the end of the script
$date = Get-Date -Format "MM-dd-yyyy_HH-mm-ss"
write-host $date  


#Enter the latest Security Patches and OOB patches against which you wish check do patch compliance check
$2016OS = ""
$2019OS = ""
$2022OS = ""
$OOB = ""

$list = Get-content C:\temp\computers.txt
 
foreach($svr in $list)
{

$connection = Test-NetConnection -ComputerName $svr -Port 445
if ((test-Connection -ComputerName $svr -Count 2 -Quiet) -or ($connection.TcpTestSucceeded)) 
{
 
    $hostname = (get-WmiObject -ComputerName $svr win32_computersystem).Name
    $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $svr
    $osEdition = $os.Caption
    $osversion = (Get-WmiObject -Computername $svr Win32_OperatingSystem).version
    $lastBootUpTime = $os.ConvertToDateTime($os.LastBootUpTime)
    $formattedlastBootTime = $lastBootUpTime.ToString("MM/dd/yyyy HH:mm:ss tt")
    #$lastbootup = [Management.ManagementDateTimeConverter]::ToDateTime($lastBootUpTime).ToString("dd/MM/yyyy")
    $hotfixeid = (Get-WmiObject -Class Win32_QuickFixEngineering -ComputerName $svr | Select-Object HotFixID | Sort-Object InstalledOn -Descending | Select-Object -First 1).hotfixid
    $installedon = (Get-WmiObject -Class Win32_QuickFixEngineering -ComputerName $svr | Select-Object InstalledOn | Sort-Object InstalledOn -Descending | Select-Object -First 1).Installedon
    $hotfixes = Get-WmiObject -Class Win32_QuickFixEngineering -ComputerName $svr
    $hotfixCount = $hotfixes.Count
    
    #considering n-1 month difference to state patch compliance status.
    
    $currentDate = Get-Date 
    $monthsDifference = (($currentDate.Year - $installedOn.Year) * 12) + $currentDate.Month - $installedOn.Month

    if ($monthsDifference -gt 1) 
      {
        $PatchCompliance = "Non-Compliant"
      } 
        else 
      {
            
    # Check if months difference is not greater than month then check if the latest Security patch is installed
    if ($hotfixeid -eq $2016OS -or $hotfixeid -eq $2019OS -or $hotfixeid -eq $2022OS -or $hotfixeid -eq $OOB) 
      {
            $PatchCompliance = "Compliant"
      } 
            else 
      {
            $PatchCompliance = "Non-Compliant, ensure you have latest Security Patch intalled"
      }
      

      #$PatchCompliance = "Compliant"
    }
 
#write-host $hostname
#write-host $osEdition
#write-host $osversion
#write-host $formattedlastBootTime
#write-host $hotfixeid
#write-host $installedon
#write-host $hotfixCount
if (test-Connection -ComputerName $svr -Count 2 -Quiet)
  {
    Write-host $svr is pinging -ForegroundColor Green
    $ping = $svr + " " + "is online"
  }

  else 

  {
    Write-host $svr is not pinging -ForegroundColor Red
    $ping = $svr + " " + "is not pinging. ICMP must be disabled as SMB access is working fine"
 
   }

}

else
 {
 $hostname = $svr
 $osEdition = "NA"
 $osversion = "NA"
 $formattedlastBootTime = "NA"
 $hotfixeid = "NA"
 $installedon = "NA"
 $hotfixCount = "NA"
 $ping = $svr + "is not pinging nor responding to connections over 445. The server is either poweredoff state OR not part of domain and both ICMP and 445 must be restricted"
 $PatchCompliance = "NA"
}


$outputs = @()
 
#Add newly created object to the array
 
for ($i=1;$i -le 1;$i++)
{
    $output = New-Object System.Object
    $output | Add-Member -MemberType NoteProperty -Name Hostname $hostname
    $output | Add-Member -MemberType NoteProperty -Name OSEdition $osEdition
    $output | Add-Member -MemberType NoteProperty -Name OSversion $osversion  
    $output | Add-Member -MemberType NoteProperty -Name LastbootTime $formattedlastBootTime
    $output | Add-Member -MemberType NoteProperty -Name Hotfixid $hotfixeid
    $output | Add-Member -MemberType NoteProperty -Name InstalledOn $installedon
    $output | Add-Member -MemberType NoteProperty -Name HotfixCount $hotfixCount
    $output | Add-Member -MemberType NoteProperty -Name Serverstatus $ping
    $output | Add-Member -MemberType NoteProperty -Name PatchComplaince $PatchCompliance
    
    $outputs += $output
    Start-Sleep -Seconds 1
}
 
#Finally, use Export-Csv to export the data to a csv file
$outputs | Export-Csv  -NoTypeInformation -Append "C:\temp\Logs$date.csv"
}

