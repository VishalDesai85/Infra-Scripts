$Date = Get-Date -Format yyyy-MM-dd
$Cluster = Get-Cluster
$ReportPath = "C:\scripts\Checkpoint-Dashboard"
$File = Join-Path $ReportPath ("Checkpoint_Report_" + $Cluster + "_" + $Date + ".html")
Import-module -Name Failoverclusters, Hyper-V
New-Item -ItemType File $File -Force

Function fWriteHTML 
	{ 
	param($FileName) 
	$date = ( get-date ).ToString('yyyy/MM/dd') 
	Add-Content $FileName "<html>" 
	Add-Content $FileName "<head>" 
	Add-Content $FileName "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>" 
	Add-Content $FileName '<title>Checkpoint_Report</title>' 
	Add-Content $FileName '<STYLE TYPE="text/css">' 
	Add-Content $FileName  "<!--" 
	Add-Content $FileName  "td {" 
	Add-Content $FileName  "font-family: Tahoma;" 
	Add-Content $FileName  "font-size: 11px;" 
	Add-Content $FileName  "border-top: 2px solid #999999;" 
	Add-Content $FileName  "border-right: 2px solid #999999;" 
	Add-Content $FileName  "border-bottom: 2px solid #999999;" 
	Add-Content $FileName  "border-left: 2px solid #999999;" 
	Add-Content $FileName  "}" 
	Add-Content $FileName  "body {" 
    Add-Content $FileName  "margin-left: 5px;" 
	Add-Content $FileName  "margin-top: 5px;" 
	Add-Content $FileName  "margin-right: 5px;" 
	Add-Content $FileName  "margin-bottom: 5px;" 
	Add-Content $FileName  "" 
	Add-Content $FileName  "table {" 
	Add-Content $FileName  "border: thin solid #000000;" 
	Add-Content $FileName  "}" 
	Add-Content $FileName  "-->" 
	Add-Content $FileName  "</style>" 
	Add-Content $FileName "</head>" 
	Add-Content $FileName "<body>" 
	Add-Content $FileName  "<table width='100%'>" 
	Add-Content $FileName  "<tr bgcolor='#2F0B3A'>" 
	Add-Content $FileName  "<td colspan='30' height='20' align='center'>" 
	Add-Content $FileName  "<font face='tahoma' color='#FFFF00' size='4'><strong>Checkpoint_Report -  $date</strong></font>" 
	Add-Content $FileName  "</td>" 
	Add-Content $FileName  "</tr>" 
	Add-Content $FileName  "</table>" 
    }

    Function fWriteRole
	{
	Param ($FileName, $cname)
    Add-Content $FileName  "<table width='100%'>" 
	Add-Content $FileName  "<tr colspan='1' height='20' align='center' bgcolor='#000000'>" 
	Add-Content $FileName  "<td width = '100%' color='#000000' size='2' align=center><font color='#FFFC00'><strong>$cname</strong></font></td>" 
	Add-Content $FileName  "</tr>" 
	Add-Content $FileName  "</table>" 
    	}

Function fWriteTable 
	{ 
	Param($FileName) 
	Add-Content $FileName  "<table width='100%'>"
 	Add-Content $FileName "<tr bgcolor=#BE81F7>" 
	Add-Content $FileName "<td width='10%' align=center>VM</td>"
    Add-Content $FileName "<td width='6%' align=center>FirstSnapShotDate</td>"
    Add-Content $FileName "<td width='6%' align=center>LastSnapShotDate</td>"
    Add-Content $FileName "<td width='6%' align=center>SnapShotCount</td>"
	Add-Content $FileName "</tr>"
	}

Function fWriteNode
	{
	Param ($FileName, $nodeName)
    Add-Content $FileName  "<table width='100%'>" 
	Add-Content $FileName  "<tr height='20' bgcolor='#000000'>" 
	Add-Content $FileName  "<td width = '64%' size='3' align=center><font color='White'><strong>$nodeName</strong></Font></td>" 
	Add-Content $FileName  "</tr>"
	Add-Content $FileName  "</table>"
   	}

Function fWriteVMInfo
	{ 
	Param($FileName, $vmname, $FSSDate, $LSSDate, $SSCount)
	Add-Content $FileName "<tr bgcolor=#FFFFFF>"
	Add-Content $FileName "<td width='10%' align=center>$vmname</td>" 
	Add-Content $FileName "<td width='6%' align=center>$FSSDate</td>"
    Add-Content $FileName "<td width='6%' align=center>$LSSDate</td>"
    Add-Content $FileName "<td width='6%' align=center>$SSCount</td>"
	Add-Content $FileName "</tr>"
    }

$body = "<h4><br /> Wintel team, <br /><br /> Please Run through the checkpoints that are presently running and please have them deleted if they are over three days. Before any patching activity or any checkpoint request, mention it to client that the snapshot would be deleted in three days time proactively to avoid performance issues.<br /> <br /> 
For VMs which are over 1 TB in size, please delete them in 24 hours time. Put the disclaimer to client before taking the patching or before taking checkpoint if the request comes from client. <br /> Thank you.<br /></h4>"
Function fCreateReport
    {
    
    Param($Name, $Type)
    If ($Type -match "cluster")
        {
        Write-Host ("Collecting Information from cluster"+$Name) -ForegroundColor Yellow -BackgroundColor Blue
        fWriteRole $File ("Cluster - "+$Name+$body)
        $Nodes = Get-Cluster $Name | Get-clusterNode | where {$_.state -eq "Up"}
        $nodecount = $Nodes.length
        $hostInfo = Get-Cluster $Name | Get-ClusterNode | Select Name, @{Label="VM"; Expression={[int]""}}
        For ($a=0; $a -lt $nodecount; $a++)
        {
        Write-Host ("Processing VM on Host"+$Nodes.Name[$a]) -ForegroundColor Yellow -BackgroundColor Blue
        $VMlist = Get-VM -ComputerName $Nodes.Name[$a]
        $VMCount = $hostInfo[$a].VM = $VMlist.count
        If ($VMCount -ge "1")
            {
            fWriteNode $File $Nodes.Name[$a]
            fWriteTable $File
            For ($b=0; $b -lt $VMCount; $b++)
            {
            
				$vmName = $VMlist[$b].Name
				Write-Host ("Processing VM - "+$vmName) -ForegroundColor Green
				$vmInfo = Get-VM -VMName $vmName -ComputerName $Nodes[$a].Name

                If ($vmInfo.ParentSnapShotID)
                {
                $FSSDate = ((get-vmsnapshot -VMname $vmInfo.Name -computername $Nodes.Name[$a]).creationtime | Sort-Object | Select-Object -First 1).ToshortDateString()
                $LSSDate = ((get-VMSnapshot -VMName $vmInfo.Name -ComputerName $Nodes.Name[$a]).CreationTime | Sort-Object | Select-Object -Last 1).ToShortDateString()
                $SSCount = ((Get-VMSnapShot -VMName $vmInfo.Name -ComputerName $Nodes.Name[$a]) | Measure).Count
                }
                Else
                {
                $FSSDate = "NA"
                $LSSDate = "NA"
                $SSCount = "NA"
                }
            fWriteVMInfo $File $vmInfo.Name $FSSDate $LSSDate $SSCount
            Write-Host "Finished Processing VM - " $vmInfo.Name -ForegroundColor Yellow -BackgroundColor DarkGreen
            }
            Write-Host "Finished Processing VMs On Hyper-V Cluster Node - "$Nodes.Name[$a] -ForegroundColor White -BackgroundColor Blue
            }
        Else
            {
            Write-Host "No VM found on Hyper-V server - " $Nodes.Name[$a] -ForegroundColor Black -BackgroundColor DarkRed
            }
        }
        Write-Host "Finished Processing Cluster $Name" -ForegroundColor Black -BackgroundColor Cyan
        }
    }
fWriteHTML $File

If (Get-Cluster)
    {
    Write-Host "Checking Server for Hyper-V role" -ForegroundColor Black -BackgroundColor Cyan
    $Liste = (Get-Cluster).Name
    fCreateReport $Liste "Cluster"
    }
ElseIf (Get-Cluster)
    {
    Write-Host "Please run the script from a Hyper-V Cluster node" -ForegroundColor Black -BackgroundColor Red
    Write-Host "()()()EXITING SCRIPT()()()" -ForegroundColor Yellow -BackgroundColor Red
    }


Send-MailMessage -To winadminmlx@icicbankltd.com -Cc kumar.saurabh1@ext.icicibank.com, arvind.kawale@ext.icicibank.com -From write-host $env:COMPUTERNAME@icicibankltd.com -Body (Get-Content "$File" |Out-String) -Attachments "$File" -SmtpServer 10.151.56.38 -Subject "HyperV CheckPoint Dashboard $env:COMPUTERNAME" -BodyAsHtml