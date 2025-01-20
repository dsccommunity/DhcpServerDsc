<#
    .SYNOPSiS
       This example sets an option ID 8 (cookie servers) on a server level.
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

    DhcpServerOptionValue 'ServerOptionValue_ID-008'
    {
        OptionId      = 8
        Value         = '1.1.1.1'
        VendorClass   = ''
        UserClass     = ''
        AddressFamily = 'IPv4'
        Ensure        = 'Present'
    }
}
