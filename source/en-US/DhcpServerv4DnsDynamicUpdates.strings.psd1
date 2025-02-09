<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource DhcpServerDnsDynamicUpdates module. This file should only contain
        localized strings for private functions, public command, and
        classes (that are not a DSC resource).
#>

ConvertFrom-StringData @'
    ## Strings overrides for the ResourceBase's default strings.
    # None

    ## Strings directly used by the derived class DhcpServerv4DnsDynamicUpdates.
    SpecificParametersOneMustBeSet = At least one of the parameters '{0}' must be specified. (DS4DDU0001)
    ServerPolicyDoesNotExist = The Server Policy '{0}' does not exist. (DS4DDU0001)
    ScopeDoesNotExist = The Scope '{0}' does not exist. (DS4DDU0002)
    ScopePolicyDoesNotExist = The Scope Policy '{0}', '{1}' does not exist. (DS4DDU0003)
    ReservationDoesNotExist = The Reservation '{0}' does not exist. (DS4DDU0004)
'@
