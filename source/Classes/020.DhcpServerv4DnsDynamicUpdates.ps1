[DscResource()]
class DhcpServerv4DnsDynamicUpdates : ResourceBase
{
    [DscProperty(Key)]
    [Dhcpv4TargetScopeType]
    $TargetScope

    [DscProperty(Mandatory)]
    [Ensure]
    $Ensure = [Ensure]::Present

    [DscProperty()]
    [System.Nullable[System.Boolean]]
    $NameProtection

    [DscProperty()]
    [System.Nullable[System.Boolean]]
    $DeleteDnsRROnLeaseExpiry

    [DscProperty()]
    [DynamicUpdatesType]
    $DynamicUpdates

    [DscProperty()]
    [System.String]
    $IPAddress

    [DscProperty()]
    [System.Nullable[System.Boolean]]
    $UpdateDnsRRForOlderClients

    [DscProperty()]
    [System.String]
    $ScopeId

    [DscProperty()]
    [System.String]
    $PolicyName

    [DscProperty()]
    [System.Nullable[System.Boolean]]
    $DisableDnsPtrRRUpdate

    [DscProperty()]
    [System.String]
    $DnsSuffix

    [DscProperty(NotConfigurable)]
    [DhcpServerReason[]]
    $Reasons

    DhcpServerv4DnsDynamicUpdates () : base ($PSScriptRoot)
    {
        $this.FeatureOptionalEnums = $true
    }

    # Required DSC Methods, these call the method in the base class.
    [DhcpServerv4DnsDynamicUpdates] Get()
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
        $state = @{}
        $getParameters = @{}

        switch ($properties.TargetScope)
        {
            ServerPolicy
            {
                # Need to check the Policy exists
                $policy = Get-DhcpServerv4Policy -Name $this.PolicyName -ErrorAction SilentlyContinue

                if ($null -eq $policy)
                {
                    New-InvalidOperationException -Message ($this.localizedData.ServerPolicyDoesNotExist -f $this.PolicyName)
                }

                $getParameters.PolicyName = $this.PolicyName
                break
            }

            Scope
            {
                # Need to check the Scope exists
                $scope = Get-DhcpServerv4Scope -ScopeId $this.ScopeId -ErrorAction SilentlyContinue

                if ($null -eq $scope)
                {
                    New-InvalidOperationException -Message ($this.localizedData.ScopeDoesNotExist -f $this.ScopeId)
                }

                $getParameters.ScopeId = $this.ScopeId
                break
            }

            ScopePolicy
            {
                # Need to check the ScopePolicy exists
                $scope = Get-DhcpServerv4Scope -ScopeId $this.ScopeId -ErrorAction SilentlyContinue

                if ($null -eq $scope)
                {
                    New-InvalidOperationException -Message ($this.localizedData.ScopeDoesNotExist -f $this.ScopeId)
                }

                $policy = Get-DhcpServerv4Policy -Name $this.PolicyName -ScopeId $scope.ScopeId -ErrorAction SilentlyContinue

                if ($null -eq $policy)
                {
                    New-InvalidOperationException -Message ($this.localizedData.ScopePolicyDoesNotExist -f $this.ScopeId, $this.PolicyName)
                }

                $getParameters.ScopeId = $this.ScopeId
                $getParameters.PolicyName = $this.PolicyName
                break
            }

            Reservation
            {
                # Need to check the reservation exists
                $reservation = Get-DhcpServerv4Reservation -IPAddress $this.IPAddress -ErrorAction SilentlyContinue

                if ($null -eq $reservation)
                {
                    New-InvalidOperationException -Message ($this.localizedData.ReservationDoesNotExist -f $this.IPAddress)
                }

                $getParameters.IPAddress = $this.IPAddress
                break
            }
        }

        $getCurrentStateResult = Get-DhcpServerv4DnsSetting @getParameters

        if ($getCurrentStateResult)
        {
            $state = @{
                TargetScope                = [Dhcpv4TargetScopeType] $properties.TargetScope
                DeleteDnsRROnLeaseExpiry   = $getCurrentStateResult.DeleteDnsRROnLeaseExpiry
                DisableDnsPtrRRUpdate      = $getCurrentStateResult.DisableDnsPtrRRUpdate
                DnsSuffix                  = $getCurrentStateResult.DnsSuffix
                DynamicUpdates             = [DynamicUpdatesType] $getCurrentStateResult.DynamicUpdates
                NameProtection             = $getCurrentStateResult.NameProtection
                UpdateDnsRRForOlderClients = $getCurrentStateResult.UpdateDnsRRForOlderClients
            }

            switch ($properties.TargetScope)
            {
                ServerPolicy
                {
                    $state.PolicyName = $this.PolicyName
                    break
                }

                Scope
                {
                    $state.ScopeId = $this.ScopeId
                    break
                }

                Scope
                {
                    $state.ScopeId = $this.ScopeId
                    $state.PolicyName = $this.PolicyName
                    break
                }

                Reservation
                {
                    $state.IPAddress = $this.IPAddress
                    break
                }
            }
        }

        return $state
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
        $assertBoundParameterParameters = @{
            BoundParameterList = $properties
            RequiredParameter  = @(
                'DeleteDnsRROnLeaseExpiry'
                'DynamicUpdates'
                'NameProtection'
                'UpdateDnsRRForOlderClients'
                'DnsSuffix'
                'DisableDnsPtrRRUpdate'
            )
            RequiredBehavior   = 'Any'
        }

        Assert-BoundParameter @assertBoundParameterParameters

        # Scopes
        switch ($properties.TargetScope)
        {
            Server
            {
                $disallowedParameters = @(
                    'ScopeId'
                    'IPAddress'
                    'PolicyName'
                )

                $assertBoundParameterParameters = @{
                    BoundParameterList     = $properties
                    MutuallyExclusiveList1 = $disallowedParameters
                    MutuallyExclusiveList2 = $disallowedParameters
                }

                Assert-BoundParameter @assertBoundParameterParameters
                break
            }

            ServerPolicy
            {
                $assertBoundParameterParameters = @{
                    BoundParameterList = $properties
                    RequiredParameter  = @(
                        'PolicyName'
                    )
                }

                Assert-BoundParameter @assertBoundParameterParameters
                break
            }

            Scope
            {
                $assertBoundParameterParameters = @{
                    BoundParameterList = $properties
                    RequiredParameter  = @(
                        'ScopeId'
                    )
                }

                Assert-BoundParameter @assertBoundParameterParameters
                break
            }

            ScopePolicy
            {
                $assertBoundParameterParameters = @{
                    BoundParameterList = $properties
                    RequiredParameter  = @(
                        'ScopeId'
                        'PolicyName'
                    )
                }

                Assert-BoundParameter @assertBoundParameterParameters
                break
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
                break
            }

            default
            {
                # This should fail as TargetScope is not a valid value
                throw
            }
        }

        $ipStringsToValidate = @(
            @{
                ParameterName = 'IPAddress'
            }
            @{
                ParameterName = 'ScopeId'
            }
        )

        foreach ($ipString in $ipStringsToValidate)
        {
            if ($properties.ContainsKey($ipString.ParameterName))
            {
                $getValidIpAddressParams = @{
                    Address       = $properties.($ipString.ParameterName)
                    AddressFamily = 'IPv4'
                }

                Assert-IPAddress @getValidIpAddressParams
            }
        }
    }
}
