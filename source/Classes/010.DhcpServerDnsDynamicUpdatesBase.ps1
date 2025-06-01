<#
    .SYNOPSIS
        A class with DSC properties that are used in multiple child classes.

    .DESCRIPTION
        A class with DSC properties that are used in multiple child classes.

    .PARAMETER Reasons
        Returns the reason a property is not in desired state.
#>

class DhcpServerDnsDynamicUpdatesBase : ResourceBase
{
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

    [DscProperty(NotConfigurable)]
    [DhcpServerReason[]]
    $Reasons

    DhcpServerDnsDynamicUpdatesBase () : base ($PSScriptRoot)
    {
        $this.FeatureOptionalEnums = $true
    }
}
