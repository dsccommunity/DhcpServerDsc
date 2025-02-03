[DscResource()]
class DhcpServerDnsDynamicUpdates : ResourceBase
{
    [DscProperty(Key)]
    [DhcpTargetScopeType]
    $TargetScope

    [DscProperty(Key)]
    [AddressFamilyType]
    $AddressFamily

    [DscProperty(Mandatory)]
    [Ensure]
    $Ensure

    # Common Properties
    #NameProtection Bool
    #DeleteDnsRROnLeaseExpiry Bool
    #DynamicUpdates String
    #IPAddress String/IPAddress

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
    [System.Nullable[System.Net.IPAddress]]
    $IPAddress

    # IPv4 Properties
    #UpdateDnsRRForOlderClients Bool
    #ScopeId String/IPAddress
    #PolicyName String
    #DisableDnsPtrRRUpdate Bool
    #DnsSuffix String

    [DscProperty()]
    [System.Nullable[System.Boolean]]
    $UpdateDnsRRForOlderClients

    [DscProperty()]
    [System.Nullable[System.Net.IPAddress]]
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

    # IPv6 properties
    #Prefix String/IPAddress

    [DscProperty()]
    [System.Nullable[System.Net.IPAddress]]
    $Prefix

    [DscProperty(NotConfigurable)]
    [DhcpServerReason[]]
    $Reasons

    DhcpServerDnsDynamicUpdates () : base ($PSScriptRoot)
    {
        $this.ExcludeDscProperties = @()

        $this.FeatureOptionalEnums = $true
    }

    # Required DSC Methods, these call the method in the base class.
    [DhcpServerDnsDynamicUpdates] Get()
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

        if ($properties.AddressFamily -eq [AddressFamilyType]::IPv4) {


            return
        }

        if ($properties.AddressFamily -eq [AddressFamilyType]::IPv6) {


            return
        }

        # Check IPv4 Properties
        <#
            Must supply one of
                DeleteDnsRROnLeaseExpiry
                DynamicUpdates
                NameProtection
                UpdateDnsRRForOlderClients
                DnsSuffix
                DisableDnsPtrRRUpdate

            Scopes
                Server
                    !ScopeId
                    !IPAddress
                    !PolicyName
                Scope
                    ScopeId
                Server Policy
                    PolicyName
                Scope Policy
                    ScopeId
                    PolicyName
                Reservation
                    IPAddress
                    !ScopeId
                    !PolicyName
        #>

        ##


        # Check IPv6 Properties
        <#
            Must supply one of
                DeleteDnsRROnLeaseExpiry
                DynamicUpdates
                NameProtection

            Scopes
                Server
                    !Prefix
                    !IPAddress
                Scope
                    Prefix
                Reservation
                    IPAddress

        #>

    }
}
