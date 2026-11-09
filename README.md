# IT Home Lab

A documented, reproducible home lab for learning Windows system administration:
Active Directory, a ticket workflow, and PowerShell automation.

**Status: lab guide + working scripts.** This is a setup guide and a set of
scripts I wrote and tested where I could. It does **not** claim a lab is
currently running, and it contains no fake servers, users, or metrics.
To actually run the lab you need a hypervisor and a Windows Server
evaluation ISO (see Setup below).

## What is in here

| Path | What it is |
|---|---|
| `docs/ad-setup.md` | Step-by-step Active Directory domain controller setup (Windows Server) and a Samba AD alternative on Linux |
| `docs/network-diagram.md` | Lab network layout (text diagram) |
| `docs/ticketing-workflow.md` | How tickets flow from report to resolution |
| `scripts/New-LabUser.ps1` | Create an AD user, set a temp password, add to a group (supports `-WhatIf` dry run) |
| `scripts/Get-SystemInventory.ps1` | Collect OS / CPU / RAM / disk / installed software, export CSV or JSON |
| `scripts/Test-PatchStatus.ps1` | Check installed updates and pending-reboot status |
| `ticketing/tickets.py` | Small SQLite ticket tracker (CLI: create, list, close) |
| `ticketing/README.md` | Ticket tracker usage |
| `tests/test_tickets.py` | Tests for the ticket tracker |

## Lab layout

- **DC01** — Windows Server, domain controller, DNS, DHCP (`lab.local`)
- **CLIENT01** — Windows 11 VM, domain-joined, for testing logons and Group Policy
- **ADMIN** — your host machine, running the PowerShell scripts with RSAT

See `docs/network-diagram.md` for addresses.

## Setup (summary)

1. Install a hypervisor (Hyper-V, VMware Workstation Player, or VirtualBox).
2. Download the Windows Server 2022/2025 evaluation ISO from Microsoft.
3. Create DC01 (2 vCPU, 4 GB RAM, 60 GB disk), install the AD DS role,
   promote it to a domain controller for `lab.local` — full steps in
   `docs/ad-setup.md`.
4. Create CLIENT01, join it to `lab.local`.
5. On your admin machine, install RSAT (ActiveDirectory module), then run
   the scripts in `scripts/` — start with `-WhatIf`.

No Samba alternative? `docs/ad-setup.md` also covers a Samba AD DC on
Ubuntu as a lower-cost option.

## Ticketing

Two options, both documented in `docs/ticketing-workflow.md`:

1. **Local tracker** — `ticketing/tickets.py`, SQLite-backed, no server needed.
   `python3 ticketing/tickets.py new --title "Wi-Fi drops in lab" --reporter abel`
2. **GitHub Issues workflow** — labels + templates for a shared lab, documented
   in the same file.

## PowerShell scripts

All scripts require Windows PowerShell 5.1+ (or PowerShell 7 with the
WindowsCompatibility module for the AD cmdlets). `New-LabUser.ps1` requires
the ActiveDirectory module (RSAT). They were written and reviewed on Linux,
where PowerShell is not installed, so **run them with `-WhatIf` first on a
real Windows machine** before letting them make changes.

```powershell
# Dry run first — shows what would happen, changes nothing
.\scripts\New-LabUser.ps1 -FirstName "Test" -LastName "User" -Username "tuser" -WhatIf

# Real run
.\scripts\New-LabUser.ps1 -FirstName "Test" -LastName "User" -Username "tuser" -Group "Lab Users"

# Inventory of the local machine, to CSV
.\scripts\Get-SystemInventory.ps1 -OutputPath .\inventory.csv

# Patch / reboot status
.\scripts\Test-PatchStatus.ps1
```

## Tests

```bash
cd it-home-lab
python3 -m pytest tests/ -q
```

## Author

Abel Wolde — https://github.com/abel-wolde
