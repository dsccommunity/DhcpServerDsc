<#
    .SYNOPSiS
       This example creates two new DHCP Server option definitions.
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

    xDhcpServerOptionDefinition 'DHCPServerOptionDefinition1'
    {
        Ensure        = 'Present'
        Name          = 'Cisco AP c1700 Provisioning'
        OptionID      = '200'
        Type          = 'IPv4Address'
        AddressFamily = 'IPv4'
        VendorClass   = 'Cisco AP c1700'
        Description   = 'Sample description'
    }

    xDhcpServerOptionDefinition 'DHCPServerOptionDefinition2'
    {
        Ensure        = 'Present'
        Name          = 'sample name'
        OptionID      = '200'
        Type          = 'IPv4Address'
        AddressFamily = 'IPv4'
        VendorClass   = ''  #default option class
        Description   = 'Sample description'
    }

    xDhcpServerOptionDefinition 'DHCPServerOptionDefinition3'
    {
        Ensure        = 'Present'
        Name          = 'PXEClient'
        OptionID      = '060'
        Type          = 'String'
        AddressFamily = 'IPv4'
        VendorClass   = ''  #default option class
        Description   = 'Sample description'
        DefaultValue  = 'PXEClient'
    }
}
