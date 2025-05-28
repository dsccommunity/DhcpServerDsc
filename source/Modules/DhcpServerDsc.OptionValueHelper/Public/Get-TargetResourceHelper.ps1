<#
    .SYNOPSIS
        Helper function to get a DHCP option value.

    .PARAMETER ApplyTo
        Specify where to get the DHCP option from.

    .PARAMETER OptionId
        The option ID.

    .PARAMETER VendorClass
        The option vendor class. Use an empty string for standard class.

    .PARAMETER UserClass
        The option user class.

    .PARAMETER ScopeId
        If used, the option scope ID.

    .PARAMETER PolicyName
        If used, the option policy name.

    .PARAMETER ReservedIP
        If used, the option reserved IP.

    .PARAMETER AddressFamily
        The option definition address family (IPv4 or IPv6). Currently only the IPv4 is supported.
#>
function Get-TargetResourceHelper
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Server', 'Scope', 'Policy', 'ReservedIP')]
        [System.String]
        $ApplyTo,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.UInt32]
        $OptionId,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $VendorClass,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $UserClass,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $ScopeId,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $PolicyName,

        [Parameter()]
        [AllowNull()]
        [System.Net.IPAddress]
        $ReservedIP,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily
    )

    #region Input Validation

    # Check for DhcpServer module/role.
    Assert-Module -ModuleName 'DHCPServer'

    #endregion Input Validation

    # Checking if option needs to be configured for server, DHCP scope, Policy or reservedIP
    switch ($ApplyTo)
    {
        'Server'
        {
            # Getting the dhcp server option Value
            $serverGettingValueMessage = $script:localizedData.ServerGettingValueMessage -f $OptionId, $VendorClass, $UserClass
            Write-Verbose $serverGettingValueMessage

            $parameters = @{
                OptionId    = $OptionId
                VendorClass = $VendorClass
                userClass   = $UserClass
            }

            $currentConfiguration = Get-DhcpServerv4OptionValue @parameters -ErrorAction 'SilentlyContinue'
        }

        'Scope'
        {
            # Getting the dhcp server option Value
            $scopeGettingValueMessage = $script:localizedData.ScopeGettingValueMessage -f $OptionId, $VendorClass, $UserClass, $ScopeId
            Write-Verbose $scopeGettingValueMessage

            $parameters = @{
                OptionId    = $OptionId
                ScopeId     = $ScopeId
                VendorClass = $VendorClass
                UserClass   = $UserClass
            }

            $currentConfiguration = Get-DhcpServerv4OptionValue @parameters -ErrorAction 'SilentlyContinue'
        }

        'Policy'
        {
            # Getting the dhcp policy option Value
            $policyGettingValueMessage = $script:localizedData.PolicyGettingValueMessage -f $OptionId, $VendorClass, $ScopeId, $PolicyName
            Write-Verbose $policyGettingValueMessage

            # Policy can exist on server or scope level, so we need to address both cases
            if ($ScopeId)
            {
                $parameters = @{
                    PolicyName  = $PolicyName
                    OptionId    = $OptionId
                    VendorClass = $VendorClass
                    ScopeId     = $ScopeId
                }

                $currentConfiguration = Get-DhcpServerv4OptionValue @parameters -ErrorAction 'SilentlyContinue'
            }
            else
            {
                $parameters = @{
                    PolicyName  = $PolicyName
                    OptionId    = $OptionId
                    VendorClass = $VendorClass
                }

                $currentConfiguration = Get-DhcpServerv4OptionValue @parameters -ErrorAction 'SilentlyContinue'
            }
        }

        'ReservedIP'
        {
            # Getting the dhcp reserved IP option Value
            $reservedIPGettingValueMessage = $script:localizedData.ReservedIPGettingValueMessage -f $OptionId, $VendorClass, $PolicyName, $ReservedIP
            Write-Verbose $reservedIPGettingValueMessage

            $parameters = @{
                ReservedIP  = $ReservedIP
                OptionId    = $OptionId
                VendorClass = $VendorClass
                UserClass   = $UserClass
            }

            $currentConfiguration = Get-DhcpServerv4OptionValue @parameters -ErrorAction 'SilentlyContinue'
        }
    }

    # Testing for null
    if ($currentConfiguration)
    {
        $hashTable = @{
            ApplyTo       = $ApplyTo
            OptionId      = $currentConfiguration.OptionID
            Value         = $currentConfiguration.Value
            VendorClass   = $currentConfiguration.VendorClass
            UserClass     = $currentConfiguration.UserClass
            ScopeId       = $currentConfiguration.ScopeId
            PolicyName    = $currentConfiguration.PolicyName
            ReservedIP    = $currentConfiguration.ReservedIP
            AddressFamily = $AddressFamily
            Ensure        = 'Present'
        }
    }
    else
    {
        $hashTable = @{
            ApplyTo       = $null
            OptionId      = $null
            Value         = $null
            VendorClass   = $null
            UserClass     = $null
            ScopeId       = $null
            PolicyName    = $null
            ReservedIP    = $null
            AddressFamily = $null
            Ensure        = 'Absent'
        }
    }

    $hashTable
}
