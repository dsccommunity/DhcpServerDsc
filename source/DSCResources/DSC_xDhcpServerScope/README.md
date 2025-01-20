# Description

The xDhcpServerScope DSC resource manages IP address scopes. An IP-address
scope is a consecutive range of possible IP addresses that the DHCP server
can lease to clients on a subnet.

**LeaseDuration**: This should be specified in the following format: `Days.Hours:Minutes:Seconds`
  - For example, '`02.00:00:00`' is 2 days and '`08:00:00`' is 8 hours.

## Requirements

- Target machine must be running Windows Server 2012 R2 or later.
- Target machine must be running at minimum Windows PowerShell 5.0.
