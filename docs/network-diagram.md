# Lab network diagram

```
                    ┌──────────────────────┐
                    │  Host machine (ADMIN) │
                    │  PowerShell + RSAT    │
                    │  192.168.56.1 (host)  │
                    └──────────┬───────────┘
                               │  host-only network 192.168.56.0/24
              ┌────────────────┴────────────────┐
              │                                 │
   ┌────────────────────┐            ┌────────────────────┐
   │ DC01               │            │ CLIENT01           │
   │ Windows Server     │            │ Windows 11         │
   │ AD DS, DNS, DHCP   │            │ domain-joined      │
   │ 192.168.56.10      │            │ 192.168.56.101     │
   │ lab.local          │            │ (DHCP)             │
   └────────────────────┘            └────────────────────┘
```

- **Network:** host-only `192.168.56.0/24` — lab VMs can talk to each other
  and the host, but have no route to the internet unless you add NAT.
  Keep it isolated: lab AD should never touch a production network.
- **DNS:** DC01 is the DNS server for the lab (`192.168.56.10`).
  Clients must use it as their DNS server or domain logon fails.
- **DHCP:** DC01 hands out `192.168.56.100–200`.
- **Admin access:** RDP/WinRM to DC01 and CLIENT01 from the host only.
