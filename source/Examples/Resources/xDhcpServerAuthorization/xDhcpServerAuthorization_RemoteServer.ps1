<#
    .SYNOPSiS
       This example will authorize a remote DHCP server.
#>
configuration Example
{
    Import-DscResource -moduleName 'DhcpServerDsc'

    xDhcpServerAuthorization 'RemoteServerActivation'
    {
        IsSingleInstance = 'Yes'
        Ensure           = 'Present'
        DnsName          = 'ServerToAuthorize.contoso.com'
        IPAddress        = '192.168.0.1'
    }
}
