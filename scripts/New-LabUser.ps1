<#
.SYNOPSIS
    Creates a user in the lab Active Directory domain.
.DESCRIPTION
    Creates an AD user in OU=Lab Users,DC=lab,DC=local, sets a temporary
    password that must be changed at first logon, and adds the user to a
    group. Supports -WhatIf for a dry run. Requires the ActiveDirectory
    module (RSAT) and domain admin rights in the lab.
.EXAMPLE
    .\New-LabUser.ps1 -FirstName "Test" -LastName "User" -Username "tuser" -WhatIf
.EXAMPLE
    .\New-LabUser.ps1 -FirstName "Test" -LastName "User" -Username "tuser" -Group "Lab Users"
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$FirstName,

    [Parameter(Mandatory = $true)]
    [string]$LastName,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z][a-z0-9._-]{2,19}$')]
    [string]$Username,

    [string]$Group = "Lab Users",

    [string]$OrganizationalUnit = "OU=Lab Users,DC=lab,DC=local",

    [string]$Domain = "lab.local"
)

Import-Module ActiveDirectory -ErrorAction Stop

$upn = "$Username@$Domain"
$displayName = "$FirstName $LastName"

if (Get-ADUser -Filter "SamAccountName -eq '$Username'" -ErrorAction SilentlyContinue) {
    Write-Error "A user named '$Username' already exists in $Domain."
    exit 1
}

if ($PSCmdlet.ShouldProcess($upn, "Create AD user '$displayName'")) {
    $tempPassword = Read-Host -Prompt "Temporary password for $Username" -AsSecureString

    New-ADUser -Name $displayName `
        -GivenName $FirstName `
        -Surname $LastName `
        -SamAccountName $Username `
        -UserPrincipalName $upn `
        -Path $OrganizationalUnit `
        -AccountPassword $tempPassword `
        -Enabled $true `
        -ChangePasswordAtLogon $true `
        -PasswordNeverExpires $false

    if (Get-ADGroup -Filter "Name -eq '$Group'" -ErrorAction SilentlyContinue) {
        Add-ADGroupMember -Identity $Group -Members $Username
        Write-Host "Added $Username to group '$Group'."
    }
    else {
        Write-Warning "Group '$Group' does not exist; user created without group membership."
    }

    Write-Host "Created user $displayName ($upn). They must change their password at first logon."
}
