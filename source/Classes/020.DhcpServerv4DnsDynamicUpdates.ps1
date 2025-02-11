<#
    .SYNOPSIS
        The `DhcpServerv4DnsDynamicUpdates` DSC resource is used to create, modify or remove
        IPv4 DnsDynamicUpdates on a Dhcp Server, ServerPolicy, Scope, ScopePolicy or Reservation.

    .DESCRIPTION
        This resource is used to create, edit or remove DnsDynamicUpdate settings on DhcpServers.

    .PARAMETER TargetScope
        The target scope type of the operation.

    .PARAMETER Ensure
        Specifies whether the configuration should exist.

    .PARAMETER NameProtection
        Specifies whether Name Protection is enabled.

    .PARAMETER DeleteDnsRROnLeaseExpiry
        Whether the setting to discard A and PTR records when a lease is deleted.

    .PARAMETER DynamicUpdates
        The dynamic update mode, this can be Always, Never or OnClientRequest.

    .PARAMETER DisableDnsPtrRRUpdate


    .PARAMETER UpdateDnsRRForOlderClients


    .PARAMETER IPAddress
        The IpAddress to target. This is only applicable to Reservation TargetScope.

    .PARAMETER ScopeId
        The scope Id to target. This is only applicable to Scope and ScopePolicy TargetScope.

    .PARAMETER PolicyName
        The name of the policy to target. This is only applicable to ServerPolicy and ScopePolicy TargetScope.

    .PARAMETER DnsSuffix
        The DNS Suffix to register DHCP clients to. This is only applicable to ServerPolicy and ScopePolicy TargetScope.

    .PARAMETER Reasons
        Returns the reason a property is not in desired state.
#>

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

        #TODO: Make this stop outputting 'loading module'
        $SavedVerbosePreference = $global:VerbosePreference
        $SavedOutputPreference = $global:OutputPreference
        $global:VerbosePreference = $global:OutputPreference = 'SilentlyContinue'
        $null = Import-Module 'DhcpServer'
        $global:VerbosePreference = $SavedVerbosePreference
        $global:OutputPreference = $SavedOutputPreference

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

                ScopePolicy
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
        $setParams = @{}

        switch ($this.TargetScope)
        {
            ServerPolicy
            {
                $setParams.PolicyName = $this.PolicyName
                break
            }

            Scope
            {
                $setParams.ScopeId = $this.ScopeId
                break
            }

            ScopePolicy
            {
                $setParams.ScopeId = $this.ScopeId
                $setParams.PolicyName = $this.PolicyName
                break
            }

            Reservation
            {
                $setParams.IPAddress = $this.IPAddress
                break
            }
        }

        Set-DhcpServerv4DnsSetting @setParams @properties
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
                    'DnsSuffix'
                )

                $assertBoundParameterParameters = @{
                    BoundParameterList     = $properties
                    MutuallyExclusiveList1 = 'TargetScope'
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

                $disallowedParameters = @(
                    'DnsSuffix'
                )

                $assertBoundParameterParameters = @{
                    BoundParameterList     = $properties
                    MutuallyExclusiveList1 = 'TargetScope'
                    MutuallyExclusiveList2 = $disallowedParameters
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

                $disallowedParameters = @(
                    'DnsSuffix'
                    'NameProtection'
                )

                $assertBoundParameterParameters = @{
                    BoundParameterList     = $properties
                    MutuallyExclusiveList1 = 'TargetScope'
                    MutuallyExclusiveList2 = $disallowedParameters
                }

                Assert-BoundParameter @assertBoundParameterParameters
                break
            }
        }

        foreach ($ipString in @('IPAddress', 'ScopeId'))
        {
            if ($properties.ContainsKey($ipString))
            {
                $getValidIpAddressParams = @{
                    Address       = $properties.$ipString
                    AddressFamily = 'IPv4'
                }

                Assert-IPAddress @getValidIpAddressParams
            }
        }
    }
}
