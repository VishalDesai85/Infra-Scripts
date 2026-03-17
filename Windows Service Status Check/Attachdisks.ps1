<#
.SYNOPSIS
    Attaches additional dynamic VHDX disks to existing Hyper-V VMs.

.DESCRIPTION
    Interactively prompts for:
      - VM names (comma-separated or from a text file)
      - Number of disks to attach per VM
      - Disk sizes — same for all VMs or custom per VM
    Creates dynamic VHDX files and attaches them to each specified VM.

.NOTES
    Author  : Dhanaji
    Version : 1.0
    Requires: Hyper-V PowerShell module, Run as Administrator
#>

#region --- VM Selection ---

Write-Host "`n=== Attach Dynamic Disks to Hyper-V VMs ===" -ForegroundColor Cyan

# List running VMs for reference
Write-Host "`nExisting VMs on this host:" -ForegroundColor Cyan
Get-VM | Select-Object Name, State | Format-Table -AutoSize

$vmInput = (Read-Host "Enter VM name(s) to attach disks to (comma-separated, e.g. Node1,Node2)").Trim().Trim('"').Trim("'")
$vmNames = $vmInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

# Validate each VM exists
$vmNames = $vmNames | Where-Object {
    if (Get-VM -Name $_ -ErrorAction SilentlyContinue) { $true }
    else { Write-Warning "VM '$_' not found on this host and will be skipped."; $false }
}

if ($vmNames.Count -eq 0) {
    Write-Error "No valid VMs found. Exiting."
    exit 1
}

Write-Host "`nVMs selected: $($vmNames -join ', ')" -ForegroundColor Green

#endregion

#region --- Disk Count ---

$diskCount = [int](Read-Host "`nHow many dynamic disks to attach to each VM? (e.g. 2)")
if ($diskCount -lt 1) {
    Write-Error "Disk count must be at least 1. Exiting."
    exit 1
}

#endregion

#region --- Disk Size Configuration ---

# Hashtable: $diskConfig[vmName] = @(sizeInBytes, sizeInBytes, ...)
$diskConfig = @{}

$sizeMode = (Read-Host "`nSet disk size(s) the same for all VMs, or differently per VM? Enter 'all' or 'per'").Trim().ToLower()

if ($sizeMode -eq 'all') {
    # Same sizes for every VM — ask once for each disk slot
    $sharedSizes = @()
    for ($d = 1; $d -le $diskCount; $d++) {
        $sizeGB = [int](Read-Host "  Enter size in GB for Disk $d (e.g. 100)")
        $sharedSizes += $sizeGB * 1GB
    }
    foreach ($vmName in $vmNames) {
        $diskConfig[$vmName] = $sharedSizes
    }
}
else {
    # Custom sizes per VM
    Write-Host "`nEnter disk sizes for each VM:" -ForegroundColor Cyan
    foreach ($vmName in $vmNames) {
        Write-Host "  VM: $vmName" -ForegroundColor Yellow
        $sizes = @()
        for ($d = 1; $d -le $diskCount; $d++) {
            $sizeGB = [int](Read-Host "    Disk $d size in GB (e.g. 100)")
            $sizes += $sizeGB * 1GB
        }
        $diskConfig[$vmName] = $sizes
    }
}

#endregion

#region --- HyperV Base Path ---

$hyperVBasePath = (Read-Host "`nEnter HyperV base path where VM folders reside (e.g. E:\HyperV)").Trim().Trim('"').Trim("'")
$hyperVBasePath = $hyperVBasePath.TrimEnd('\')

#endregion

#region --- Create and Attach Disks ---

Write-Host "`n--- Attaching Disks ---" -ForegroundColor Cyan

$results = @()

foreach ($vmName in $vmNames) {
    Write-Host "`nProcessing VM: $vmName" -ForegroundColor Yellow
    $sizes = $diskConfig[$vmName]

    # Disks go into <HyperVBasePath>\<vmName>\
    $vmDiskFolder = Join-Path -Path $hyperVBasePath -ChildPath $vmName
    if (-not (Test-Path -Path $vmDiskFolder)) {
        New-Item -Path $vmDiskFolder -ItemType Directory | Out-Null
        Write-Host "  Created folder: $vmDiskFolder" -ForegroundColor Yellow
    }

    for ($d = 0; $d -lt $diskCount; $d++) {
        $diskIndex = $d + 1
        $sizeBytes = $sizes[$d]
        $sizeGB = [math]::Round($sizeBytes / 1GB, 0)
        $vhdxPath = Join-Path -Path $vmDiskFolder -ChildPath "${vmName}_DataDisk${diskIndex}.vhdx"

        try {
            # Create dynamic VHDX
            New-VHD -Path $vhdxPath -SizeBytes $sizeBytes -Dynamic -ErrorAction Stop
            Write-Host "  [OK] Created: $vhdxPath ($sizeGB GB)" -ForegroundColor Green

            # Attach to VM
            Add-VMHardDiskDrive -VMName $vmName -Path $vhdxPath -ErrorAction Stop
            Write-Host "  [OK] Attached to VM: $vmName" -ForegroundColor Green

            $results += [PSCustomObject]@{
                VMName     = $vmName
                DiskNumber = $diskIndex
                SizeGB     = $sizeGB
                VHDXPath   = $vhdxPath
                Status     = "Success"
            }
        }
        catch {
            Write-Warning "  [FAILED] Disk $diskIndex for VM '$vmName': $_"
            $results += [PSCustomObject]@{
                VMName     = $vmName
                DiskNumber = $diskIndex
                SizeGB     = $sizeGB
                VHDXPath   = $vhdxPath
                Status     = "Failed: $_"
            }
        }
    }
}

#endregion

#region --- Summary ---

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

# Export results to CSV
$outputCsv = "C:\Temp\AttachDisks_Results.csv"
if (-not (Test-Path "C:\Temp")) { New-Item -Path "C:\Temp" -ItemType Directory | Out-Null }
$results | Export-Csv -Path $outputCsv -NoTypeInformation
Write-Host "Results exported to: $outputCsv" -ForegroundColor Green

#endregion
