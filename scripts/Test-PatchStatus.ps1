<#
.SYNOPSIS
    Reports patch status: installed updates, pending reboot, last update time.
.DESCRIPTION
    Read-only. Lists the most recent installed hotfixes, checks the
    pending-reboot registry keys, and reports when Windows Update last
    ran. Run on DC01 / CLIENT01 during lab maintenance windows.
.EXAMPLE
    .\Test-PatchStatus.ps1
#>
[CmdletBinding()]
param(
    [string]$ComputerName = $env:COMPUTERNAME,

    [int]$HotfixCount = 10
)

$hotfixes = Get-HotFix -ComputerName $ComputerName |
    Sort-Object InstalledOn -Descending |
    Select-Object -First $HotfixCount HotFixID, Description, InstalledOn

# Pending reboot: Component Based Servicing key or pending file renames
$pendingReboot = $false
$reasons = @()

$rebootKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
)
foreach ($key in $rebootKeys) {
    if (Test-Path $key) { $pendingReboot = $true; $reasons += "Registry key present: $key" }
}
$pendingRename = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction SilentlyContinue
if ($pendingRename.PendingFileRenameOperations) {
    $pendingReboot = $true; $reasons += "Pending file rename operations exist"
}

$lastUpdate = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install" -ErrorAction SilentlyContinue

[PSCustomObject]@{
    ComputerName   = $ComputerName
    CheckedAt      = (Get-Date).ToString("o")
    PendingReboot  = $pendingReboot
    RebootReasons  = ($reasons -join "; ")
    LastUpdateTime = $lastUpdate.LastSuccessTime
    RecentHotfixes = ($hotfixes | ForEach-Object { "$($_.HotFixID) ($($_.InstalledOn))" }) -join ", "
} | Format-List

Write-Host "`nMost recent hotfixes:"
$hotfixes | Format-Table -AutoSize
