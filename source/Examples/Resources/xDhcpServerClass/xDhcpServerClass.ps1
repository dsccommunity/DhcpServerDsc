<#
    .SYNOPSiS
       This example creates a new DHCP Server class.
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

    xDhcpServerClass 'VendorClass'
    {
        ensure        = 'Present'
        Name          = 'VendorClass'
        Type          = 'Vendor'
        AsciiData     = 'sampledata'
        AddressFamily = 'IPv4'
        Description   = 'Vendor Class Description'
    }
}
