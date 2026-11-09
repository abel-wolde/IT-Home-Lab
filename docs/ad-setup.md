# Active Directory setup — Windows Server (primary) and Samba (alternative)

## Option A — Windows Server domain controller (recommended for learning AD)

### Prerequisites

- Hypervisor: Hyper-V, VMware Workstation Player, or VirtualBox
- Windows Server 2022 or 2025 **evaluation** ISO (180-day trial, free from
  Microsoft's Evaluation Center)
- DC01 VM: 2 vCPU, 4 GB RAM, 60 GB disk, one NAT/host-only network adapter
- A static IP for DC01, e.g. `192.168.56.10`, gateway `192.168.56.1`,
  DNS pointing at itself (`127.0.0.1`)

### Steps

1. Install Windows Server (Desktop Experience) on DC01. Set the static IP.
2. Rename the computer:
   ```powershell
   Rename-Computer -NewName "DC01" -Restart
   ```
3. Install the AD DS role:
   ```powershell
   Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
   ```
4. Promote to a domain controller for a new forest, domain `lab.local`:
   ```powershell
   Install-ADDSForest -DomainName "lab.local" -DomainNetbiosName "LAB" `
       -SafeModeAdministratorPassword (Read-Host -AsSecureString "DSRM password") `
       -InstallDns -Force
   ```
   The server restarts. Log back in as `LAB\Administrator`.
5. Install DHCP (optional, for the lab network) and authorize it:
   ```powershell
   Install-WindowsFeature DHCP -IncludeManagementTools
   Add-DhcpServerInDC -DnsName "dc01.lab.local" -IPAddress 192.168.56.10
   Add-DhcpServerv4Scope -Name "Lab LAN" -StartRange 192.168.56.100 `
       -EndRange 192.168.56.200 -SubnetMask 255.255.255.0
   Set-DhcpServerv4OptionValue -DnsServer 192.168.56.10 -Router 192.168.56.1
   ```
6. Create an OU structure and a couple of test users:
   ```powershell
   New-ADOrganizationalUnit -Name "Lab Users" -Path "DC=lab,DC=local"
   New-ADOrganizationalUnit -Name "Lab Computers" -Path "DC=lab,DC=local"
   ```
   Then use `scripts/New-LabUser.ps1` to create users in `OU=Lab Users,DC=lab,DC=local`.
7. Join CLIENT01 (Windows 11 VM) to the domain: Settings > System > About >
   Domain or workgroup > Change, enter `lab.local`, log in as `LAB\Administrator`.

### Group Policy starter

Create one GPO linked to `OU=Lab Computers` that sets a lab wallpaper and
disables the guest account. Keep GPOs small and named by purpose, e.g.
`LAB-Computers-Baseline`. Test every GPO on CLIENT01 before linking it wider.

## Option B — Samba AD DC on Ubuntu (lower cost, no Windows Server licence)

Useful if you only have one Linux host. It provides a real AD DC (Kerberos,
LDAP, DNS) that Windows clients can join, but Group Policy editing is
limited and some Windows-only features are missing.

```bash
sudo apt update && sudo apt install -y samba smbclient winbind krb5-user
sudo samba-tool domain provision --realm=LAB.LOCAL --domain=LAB \
    --server-role=dc --dns-backend=SAMBA_INTERNAL \
    --adminpass='<strong-password>'
sudo systemctl enable --now samba-ad-dc
samba-tool user create tuser --given-name=Test --surname=User
```

Verify with `samba-tool domain info 127.0.0.1` and by joining CLIENT01 to
`lab.local` with the Samba admin credentials.

## What I actually did

I wrote this guide and the scripts from Microsoft's and Samba's published
documentation. I have **not** yet built the DC01 VM — the steps above are
the plan, not a record of a running lab. When I build it, I will record the
real host, dates, and any deviations here.
