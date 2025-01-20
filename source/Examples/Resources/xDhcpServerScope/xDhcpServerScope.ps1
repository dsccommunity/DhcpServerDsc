<#
    .SYNOPSiS
       This example creates a new DHCP Server scope, or if the scope already exist
       it changes an existing scope.
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

    xDhcpServerScope 'Scope'
    {
        Ensure        = 'Present'
        ScopeId       = '192.168.1.0'
        IPStartRange  = '192.168.1.1'
        IPEndRange    = '192.168.1.254'
        Name          = 'ContosoScope'
        SubnetMask    = '255.255.255.0'
        LeaseDuration = ((New-TimeSpan -Hours 8).ToString())
        State         = 'Active'
        AddressFamily = 'IPv4'
    }
}
