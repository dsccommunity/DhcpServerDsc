<#
    .SYNOPSiS
       This example reservs an IP address within a DHCP server.
#>
configuration Example
{
    Import-DscResource -ModuleName 'PSDscResources' -ModuleVersion '2.12.0.0'
    Import-DscResource -moduleName 'DhcpServerDsc'

    WindowsFeature 'DHCP'
    {
        Name   = 'DHCP'
        Ensure = 'Present'
    }

    xDhcpServerReservation 'PullServerIP'
    {
        Ensure           = 'Present'
        ScopeID          = '192.168.1.0'
        ClientMACAddress = '00155D8A54A1'
        IPAddress        = '192.168.1.2'
        Name             = 'DSCPullServer'
        AddressFamily    = 'IPv4'
    }
}
