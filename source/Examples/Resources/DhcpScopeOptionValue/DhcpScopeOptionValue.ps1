<#
    .SYNOPSiS
        This example shows how to substitute the xDhcpServerOption resource, setting the gateway (option 3), DNS Servers (option 6) and domain name (Option 15).
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

    # Setting scope gateway
    DhcpScopeOptionValue 'ScopeOptionGateway'
    {
        OptionId      = 3
        Value         = '1.1.1.1'
        ScopeId       = '1.1.1.0'
        VendorClass   = ''
        UserClass     = ''
        AddressFamily = 'IPv4'
    }

    # Setting scope DNS servers
    DhcpScopeOptionValue 'ScopeOptionDNS'
    {
        OptionId      = 6
        Value         = @('1.1.1.1', '2.2.2.2')
        ScopeId       = '1.1.1.0'
        VendorClass   = ''
        UserClass     = ''
        AddressFamily = 'IPv4'
    }

    # Setting scope DNS domain name
    DhcpScopeOptionValue 'ScopeOptionDNSDomainName'
    {
        OptionId      = 15
        Value         = 'contoso.com'
        ScopeId       = '1.1.1.0'
        VendorClass   = ''
        UserClass     = ''
        AddressFamily = 'IPv4'
    }
}
