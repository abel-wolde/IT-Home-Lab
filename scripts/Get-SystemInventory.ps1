<#
.SYNOPSIS
    Collects a system inventory (OS, hardware, disk, installed software).
.DESCRIPTION
    Runs against the local computer by default, or a remote computer with
    -ComputerName (requires WinRM). Exports to CSV or JSON. Read-only:
    it changes nothing on the target machine.
.EXAMPLE
    .\Get-SystemInventory.ps1 -OutputPath .\inventory.csv
.EXAMPLE
    .\Get-SystemInventory.ps1 -ComputerName CLIENT01 -Format Json -OutputPath .\client01.json
#>
[CmdletBinding()]
param(
    [string]$ComputerName = $env:COMPUTERNAME,

    [ValidateSet("Csv", "Json")]
    [string]$Format = "Csv",

    [string]$OutputPath
)

$os = Get-CimInstance Win32_OperatingSystem -ComputerName $ComputerName
$cpu = Get-CimInstance Win32_Processor -ComputerName $ComputerName |
    Select-Object -First 1
$memory = Get-CimInstance Win32_PhysicalMemory -ComputerName $ComputerName |
    Measure-Object -Property Capacity -Sum
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $ComputerName
$software = Get-CimInstance Win32_Product -ComputerName $ComputerName |
    Select-Object -ExpandProperty Name

$inventory = [PSCustomObject]@{
    ComputerName     = $ComputerName
    CollectedAt      = (Get-Date).ToString("o")
    OS               = $os.Caption
    OSVersion        = $os.Version
    LastBootUpTime   = $os.LastBootUpTime
    CPU              = $cpu.Name
    Cores            = $cpu.NumberOfCores
    MemoryGB         = [math]::Round($memory.Sum / 1GB, 2)
    Disks            = ($disks | ForEach-Object {
        "$($_.DeviceID) $([math]::Round($_.Size / 1GB, 1))GB total, $([math]::Round($_.FreeSpace / 1GB, 1))GB free"
    }) -join "; "
    InstalledSoftware = ($software -join "; ")
}

if (-not $OutputPath) {
    $ext = if ($Format -eq "Json") { "json" } else { "csv" }
    $OutputPath = ".\inventory-$ComputerName.$ext"
}

if ($Format -eq "Json") {
    $inventory | ConvertTo-Json -Depth 3 | Out-File -FilePath $OutputPath -Encoding utf8
}
else {
    $inventory | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
}

Write-Host "Inventory for $ComputerName written to $OutputPath"
$inventory | Format-List
