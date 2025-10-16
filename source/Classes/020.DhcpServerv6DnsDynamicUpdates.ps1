<#
    .SYNOPSIS
        The `DhcpServerv6DnsDynamicUpdates` DSC resource is used to create, modify or remove
        IPv6 DnsDynamicUpdates on a Dhcp Server, ServerPolicy, Scope, ScopePolicy or Reservation.

    .DESCRIPTION
        This resource is used to create, edit or remove DnsDynamicUpdate settings on DhcpServers.

    .PARAMETER TargetScope
        The target scope type of the operation.

    .PARAMETER Ensure
        Specifies whether the configuration should exist.

    .PARAMETER NameProtection


    .PARAMETER DeleteDnsRROnLeaseExpiry


    .PARAMETER DynamicUpdates


    .PARAMETER IPAddress


    .PARAMETER Prefix

    .PARAMETER Reasons
        Returns the reason a property is not in desired state.
#>

[DscResource()]
class DhcpServerv6DnsDynamicUpdates : DhcpServerDnsDynamicUpdatesBase
{
    [DscProperty(Key)]
    [Dhcpv6TargetScopeType]
    $TargetScope

    [DscProperty()]
    [System.String]
    $Prefix

    DhcpServerv6DnsDynamicUpdates () : base ()
    {
        $this.ExcludeDscProperties = @()
    }

    # Required DSC Methods, these call the method in the base class.
    [DhcpServerv6DnsDynamicUpdates] Get()
    {
        # Call the base method to return the properties.
        return ([ResourceBase] $this).Get()
    }

    [void] Set()
    {
        # Call the base method to enforce the properties.
        ([ResourceBase] $this).Set()
    }

    [System.Boolean] Test()
    {
        # Call the base method to test all of the properties that should be enforced.
        return ([ResourceBase] $this).Test()
    }

    # Base method Get() call this method to get the current state as a Hashtable.
    [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        return @{}
    }

    <#
        Base method Set() call this method with the properties that should be
        enforced and that are not in desired state.
    #>
    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
    }

    <#
        Base method Assert() call this method with the properties that was assigned
        a value.
    #>
    hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
    {
        Assert-Module -ModuleName 'DHCPServer'

        # Test at least one of the following exists
        $mustHaveOne = @(
            'DeleteDnsRROnLeaseExpiry'
            'DynamicUpdates'
            'NameProtection'
        )

        $optionalProperties = $properties.Keys.Where({ $_ -in $mustHaveOne })

        if (-not $optionalProperties)
        {
            $errorMessage = $this.localizedData.SpecificParametersOneMustBeSet -f ($mustHaveOne -join ''', ''')

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $errorMessage,
                    'DS6DDU0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    'Required optional parameters'
                )
            )
        }

        # Scopes
        switch ($properties.TargetScope)
        {
            Server
            {
                $disallowedParameters = @(
                    'Prefix'
                    'IPAddress'
                )

                $assertBoundParameterParameters = @{
                    BoundParameterList     = $properties
                    MutuallyExclusiveList1 = $disallowedParameters
                    MutuallyExclusiveList2 = $disallowedParameters
                }

                Assert-BoundParameter @assertBoundParameterParameters
            }

            Scope
            {
                $assertBoundParameterParameters = @{
                    BoundParameterList = $properties
                    RequiredParameter  = @(
                        'Prefix'
                    )
                }

                Assert-BoundParameter @assertBoundParameterParameters
            }

            Reservation
            {
                $assertBoundParameterParameters = @{
                    BoundParameterList = $properties
                    RequiredParameter  = @(
                        'IPAddress'
                    )
                }

                Assert-BoundParameter @assertBoundParameterParameters
            }
        }
    }
}
