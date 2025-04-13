<#
    .SYNOPSIS
        Function to assert if values of ScopeId/SubnetMask/IPStartRange/IPEndRange make sense.

    .DESCRIPTION
        Internal function used to assert if value of following parameters are correct:
        - ScopeID
        - SubnetMask
        - IPStartRange
        - IPEndRange

        It validates them against simple rules:
        - Has to be correct (IPv4) address
        - Anything but SubnetMask has to follow the rule that:
        (TokenFromParameter) -band (TokenFromSubnetMask) = (TokenFromScopeId)
        - IPStartRange has to be before IPEndRange
        Implementation for IPv4.

    .PARAMETER ScopeId
        String version of ScopeId.

    .PARAMETER SubnetMask
        String version of SubnetMask.

    .PARAMETER IPStartRange
        String version of StartRange.

    .PARAMETER IPEndRange
        String version of EndRange.

    .PARAMETER AddressFamily
        AddressFamily that IPs should validate against.

    .EXAMPLE
        Assert-ScopeParameter -ScopeId 192.168.1.0 -SubnetMask 255.255.255.0 -IPStartRange 192.168.1.1 -IPEndRange 192.168.1.254 -AddressFamily IPv4
        Validates all parameters against rules and returns nothing (all parameters are correct).

    .EXAMPLE
        Assert-ScopeParameter -ScopeId 192.168.1.0 -SubnetMask 255.255.240.0 -IPStartRange 192.168.1.1 -IPEndRange 192.168.1.254 -AddressFamily IPv4
        Returns error informing that using specified SubnetMask with specified ScopeId is incorrect:
        Value of byte 3 in ScopeId (1) is not valid. Binary AND with byte 3 in SubnetMask (240) should be equal to byte 3 in ScopeId (1).
#>

function Assert-ScopeParameter
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ScopeId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SubnetMask,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPStartRange,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPEndRange,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily
    )

    # Convert the Subnet Mask to be a valid IPAddress
    $netMask = Get-ValidIPAddress -IpString $SubnetMask -AddressFamily $AddressFamily -ParameterName SubnetMask

    # Convert the ScopeID to be a valid IPAddress
    $scope = Get-ValidIPAddress -IpString $ScopeId -AddressFamily $AddressFamily -ParameterName ScopeId

    # Convert the Start Range to be a valid IPAddress
    $startRange = Get-ValidIPAddress -IpString $IPStartRange -AddressFamily $AddressFamily -ParameterName IPStartRange

    # Convert the End Range to be a valid IPAddress
    $endRange = Get-ValidIPAddress -IpString $IPEndRange -AddressFamily $AddressFamily -ParameterName IPEndRange

    # Check to ensure startRange is smaller than endRange
    if ($endRange.Address -lt $startRange.Address)
    {
        $errorMsg = $script:localizedData.InvalidStartAndEndRangeMessage -f $IPStartRange, $IPEndRange
        New-TerminatingError -ErrorId RangeNotCorrect -ErrorMessage $errorMsg -ErrorCategory InvalidArgument
    }

    $addressBytes = @{
        ScopeId      = $scope.GetAddressBytes()
        SubnetMask   = $netMask.GetAddressBytes()
        IPStartRange = $startRange.GetAddressBytes()
        IPEndRange   = $endRange.GetAddressBytes()
    }

    foreach ($parameter in $addressBytes.Keys.Where{ $_ -ne 'SubnetMask' })
    {
        foreach ($ipTokenIndex in 0..3)
        {
            $parameterByte = $addressBytes[$parameter][$ipTokenIndex]
            $subnetMaskByte = $addressBytes['SubnetMask'][$ipTokenIndex]
            $scopeIdByte = $addressBytes['ScopeId'][$ipTokenIndex]
            if (($parameterByte -band $subnetMaskByte) -ne $scopeIdByte)
            {
                $errorMsg = $($script:localizedData.InvalidScopeIdSubnetMask) -f ($ipTokenIndex + 1), $parameter, $parameterByte, $subnetMaskByte, $scopeIdByte

                New-TerminatingError -ErrorId ScopeIdOrMaskIncorrect -ErrorMessage $errorMsg -ErrorCategory InvalidArgument
            }
        }
    }
}
