<#
    .SYNOPSIS
        Helper function to set a DHCP option value.

    .PARAMETER ApplyTo
        Specify where to set the DHCP option.

    .PARAMETER OptionId
        The option ID.

    .PARAMETER Value
        The option data value.

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

    .PARAMETER Ensure
        When set to 'Present', the option will be created.
        When set to 'Absent', the option will be removed.
#>
function Set-TargetResourceHelper
{
    [CmdletBinding()]
    [OutputType()]
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
        [System.String[]]
        $Value,

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
        $AddressFamily,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    # Checking if option needs to be configured for server, DHCP scope, Policy or reservedIP
    switch ($ApplyTo)
    {
        'Server'
        {
            $parameters = @{
                OptionId      = $OptionId
                VendorClass   = $VendorClass
                UserClass     = $UserClass
                AddressFamily = $AddressFamily
            }

            $currentConfiguration = Get-TargetResourceHelper -ApplyTo 'Server' @parameters

            # Testing for Ensure = Present
            if ($Ensure -eq 'Present')
            {
                $serverSettingValueMessage = $script:localizedData.ServerSettingValueMessage -f $OptionId, $VendorClass, $UserClass
                Write-Verbose $serverSettingValueMessage
                Set-DhcpServerv4OptionValue -OptionId $OptionId -Value $Value -VendorClass $VendorClass -UserClass $UserClass -Force
            }

            # Ensure = 'Absent'
            else
            {
                # If it exists and Ensure is 'Present' we should remove it
                if ($currentConfiguration.Ensure -eq 'Present')
                {
                    $serverRemoveValueMessage = $script:localizedData.ServerRemoveValueMessage -f $OptionId, $VendorClass, $UserClass
                    Write-Verbose $serverRemoveValueMessage
                    Remove-DhcpServerv4OptionValue -OptionId $OptionId -VendorClass $VendorClass -UserClass $UserClass
                }
            }
        }

        'Scope'
        {
            $parameters = @{
                ScopeId       = $ScopeId
                OptionId      = $OptionId
                VendorClass   = $VendorClass
                UserClass     = $UserClass
                AddressFamily = $AddressFamily
            }

            $currentConfiguration = Get-TargetResourceHelper -ApplyTo 'Scope' @parameters

            # Testing for Ensure = Present
            if ($Ensure -eq 'Present')
            {
                # If value should be present we just set it
                $scopeSettingValueMessage = $script:localizedData.ScopeSettingValueMessage -f $OptionId, $VendorClass, $UserClass, $ScopeId
                Write-Verbose $scopeSettingValueMessage
                Set-DhcpServerv4OptionValue -ScopeId $ScopeId -OptionId $OptionId -Value $Value -VendorClass $VendorClass -UserClass $UserClass -Force
            }
            # Ensure = 'Absent'
            else
            {
                # If it exists and Ensure is 'Present' we should remove it
                if ($currentConfiguration.Ensure -eq 'Present')
                {
                    $scopeRemoveValueMessage = $script:localizedData.ScopeRemoveValueMessage -f $OptionId, $VendorClass, $UserClass, $ScopeId
                    Write-Verbose $scopeRemoveValueMessage
                    Remove-DhcpServerv4OptionValue -ScopeId $ScopeId -OptionId $currentConfiguration.OptionId -VendorClass $VendorClass -UserClass $UserClass
                }
            }
        }

        'Policy'
        {
            # If $ScopeId exist
            if ($ScopeId)
            {
                $parameters = @{
                    PolicyName    = $PolicyName
                    ScopeId       = $ScopeId
                    OptionId      = $OptionId
                    VendorClass   = $VendorClass
                    UserClass     = $UserClass
                    AddressFamily = $AddressFamily
                }

                $currentConfiguration = Get-TargetResourceHelper -ApplyTo 'Policy' @parameters

                # Testing for Ensure = Present
                if ($Ensure -eq 'Present')
                {
                    # If value should be present we just set it
                    $policyWithScopeSettingValueMessage = $script:localizedData.PolicyWithScopeSettingValueMessage -f $OptionId, $VendorClass, $PolicyName, $ScopeId
                    Write-Verbose $policyWithScopeSettingValueMessage
                    Set-DhcpServerv4OptionValue -PolicyName $PolicyName -OptionId $OptionId -ScopeId $ScopeId -Value $Value -VendorClass $VendorClass -Force
                }

                # Ensure = 'Absent'
                else
                {
                    # If it exists and Ensure is 'Present' we should remove it
                    if ($currentConfiguration.Ensure -eq 'Present')
                    {
                        $policyWithScopeRemoveValueMessage = $script:localizedData.policyWithScopeRemoveValueMessage -f $OptionId, $VendorClass, $PolicyName, $ScopeId
                        Write-Verbose $policyWithScopeRemoveValueMessage
                        Remove-DhcpServerv4OptionValue -PolicyName $PolicyName -ScopeId $ScopeId -OptionId $OptionId -VendorClass $VendorClass
                    }
                }
            }
            # If $ScopeId is null
            else
            {
                $parameters = @{
                    PolicyName    = $PolicyName
                    OptionId      = $OptionId
                    VendorClass   = $VendorClass
                    UserClass     = $UserClass
                    AddressFamily = $AddressFamily
                }

                $currentConfiguration = Get-TargetResourceHelper -ApplyTo 'Policy' @parameters

                # Testing for Ensure = Present
                if ($Ensure -eq 'Present')
                {
                    # If value should be present we just set it
                    $policySettingValueMessage = $script:localizedData.PolicySettingValueMessage -f $OptionId, $VendorClass, $PolicyName
                    Write-Verbose $policySettingValueMessage
                    Set-DhcpServerv4OptionValue -PolicyName $PolicyName -OptionId $OptionId -Value $Value -VendorClass $VendorClass -Force
                }
                else
                {
                    # If it exists and Ensure is 'Present' we should remove it
                    if ($currentConfiguration.Ensure -eq 'Present')
                    {
                        $policyRemoveValueMessage = $script:localizedData.PolicyRemoveValueMessage -f $OptionId, $VendorClass, $PolicyName
                        Write-Verbose $policyRemoveValueMessage
                        Remove-DhcpServerv4OptionValue -PolicyName $PolicyName -OptionId $OptionId -VendorClass $VendorClass
                    }
                }
            }
        }

        'ReservedIP'
        {
            $parameters = @{
                ReservedIP    = $ReservedIP
                OptionId      = $OptionId
                VendorClass   = $VendorClass
                UserClass     = $UserClass
                AddressFamily = $AddressFamily
            }

            $currentConfiguration = Get-TargetResourceHelper -ApplyTo 'ReservedIP' @parameters

            # Testing for Ensure = Present
            if ($Ensure -eq 'Present')
            {
                # If value should be present we just set it
                $reservedIPSettingValueMessage = $script:localizedData.ReservedIPSettingValueMessage -f $OptionId, $VendorClass, $UserClass, $ReservedIP
                Write-Verbose $reservedIPSettingValueMessage
                Set-DhcpServerv4OptionValue -ReservedIP $ReservedIP -OptionId $OptionId -Value $Value -VendorClass $VendorClass -UserClass $UserClass -Force
            }

            # Ensure = 'Absent'
            else
            {
                # If it exists and Ensure is 'Present' we should remove it
                if ($currentConfiguration.Ensure -eq 'Present')
                {
                    $reservedIPRemoveValueMessage = $script:localizedData.ReservedIPRemoveValueMessage -f $OptionId, $VendorClass, $UserClass, $ReservedIP
                    Write-Verbose $reservedIPRemoveValueMessage
                    Remove-DhcpServerv4OptionValue -ReservedIP $ReservedIP -OptionId $OptionId -VendorClass $VendorClass -UserClass $UserClass
                }
            }
        }
    }
}
