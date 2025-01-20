<#
    .SYNOPSiS
       This example will authorize the local DHCP server.
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

    xDhcpServerAuthorization 'LocalServerActivation'
    {
        IsSingleInstance = 'Yes'
        Ensure           = 'Present'
    }
}
