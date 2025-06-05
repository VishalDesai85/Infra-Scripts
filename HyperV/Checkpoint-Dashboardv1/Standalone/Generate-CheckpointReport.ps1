$Date = Get-Date -Format yyyy-MM-dd
$HostName = $env:COMPUTERNAME
$ReportPath = "C:\scripts\Checkpoint-Dashboard"
$File = Join-Path $ReportPath ("Checkpoint_Report_" + $HostName + "_" + $Date + ".html")

if (!(Test-Path $ReportPath)) {
    New-Item -ItemType Directory -Path $ReportPath -Force
}

Import-Module Hyper-V
New-Item -ItemType File -Path $File -Force

function fWriteHTML {
    param($FileName)
    $date = (Get-Date).ToString('yyyy/MM/dd')
    Add-Content $FileName "<html><head><meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>"
    Add-Content $FileName "<title>Checkpoint_Report</title><style type='text/css'>"
    Add-Content $FileName "td { font-family: Tahoma; font-size: 11px; border: 2px solid #999999; }"
    Add-Content $FileName "body { margin: 5px; } table { border: thin solid #000000; }</style></head><body>"
    Add-Content $FileName "<table width='100%'><tr bgcolor='#2F0B3A'><td colspan='30' height='20' align='center'>"
    Add-Content $FileName "<font face='tahoma' color='#FFFF00' size='4'><strong>Checkpoint_Report - $date</strong></font>"
    Add-Content $FileName "</td></tr></table>"
}

function fWriteTable {
    param($FileName)
    Add-Content $FileName "<table width='100%'><tr bgcolor=#BE81F7>"
    Add-Content $FileName "<td align=center>VM</td><td align=center>FirstSnapShotDate</td><td align=center>LastSnapShotDate</td><td align=center>SnapShotCount</td></tr>"
}

function fWriteVMInfo {
    param($FileName, $vmname, $FSSDate, $LSSDate, $SSCount)
    Add-Content $FileName "<tr bgcolor=#FFFFFF><td align=center>$vmname</td><td align=center>$FSSDate</td><td align=center>$LSSDate</td><td align=center>$SSCount</td></tr>"
}

fWriteHTML $File
fWriteTable $File

$VMList = Get-VM
foreach ($vm in $VMList) {
    Write-Host "Processing VM - $($vm.Name)" -ForegroundColor Green
    if ($vm.ParentSnapshotId) {
        $snapshots = Get-VMSnapshot -VMName $vm.Name
        $FSSDate = ($snapshots | Sort-Object CreationTime | Select-Object -First 1).CreationTime.ToShortDateString()
        $LSSDate = ($snapshots | Sort-Object CreationTime | Select-Object -Last 1).CreationTime.ToShortDateString()
        $SSCount = ($snapshots | Measure-Object).Count
    } else {
        $FSSDate = "NA"; $LSSDate = "NA"; $SSCount = "NA"
    }
    fWriteVMInfo $File $vm.Name $FSSDate $LSSDate $SSCount
}

Add-Content $File "</table></body></html>"

Send-MailMessage -To "wintel@yourdomain.com" `
    -Cc "lead@yourdomain.com", "manager@yourdomain.com" `
    -From "$env:COMPUTERNAME@yourdomain.com" `
    -Body (Get-Content $File | Out-String) `
    -Attachments $File `
    -SmtpServer "10.10.50.150" `
    -Subject "HyperV CheckPoint Dashboard $env:COMPUTERNAME" `
    -BodyAsHtml
