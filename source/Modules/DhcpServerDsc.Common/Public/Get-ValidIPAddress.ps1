<#
    .SYNOPSIS
        Function to convert an IP address from a string to a [System.Net.IPAddress] type.

    .DESCRIPTION
        Function to try and convert a IPv4 or IPv6 string to a [System.Net.IPAddress] type.

    .PARAMETER IpString
        IpString to convert.

    .PARAMETER AddressFamily
        The AddressFamily of the IpString.

    .PARAMETER ParameterName
        The ParameterName of the IpString for error purposes.

    .OUTPUTS
        [System.Net.IPAddress] object.
#>

function Get-ValidIPAddress
{
    [CmdletBinding()]
    [OutputType([System.Net.IPAddress])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $IpString,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ParameterName
    )

    if ($AddressFamily -eq 'IPv4')
    {
        $ipAddressFamily = 'InterNetwork'
    }
    else
    {
        $ipAddressFamily = 'InterNetworkV6'
    }

    [System.Net.IPAddress] $ipAddress = $null

    $result = [System.Net.IPAddress]::TryParse($IpString, [ref] $ipAddress)

    if (-not $result)
    {
        $errorMsg = $($script:localizedData.InvalidIPAddressFormat) -f $ParameterName

        New-TerminatingError -ErrorId 'NotValidIPAddress' -ErrorMessage $errorMsg -ErrorCategory InvalidType
    }

    if ($ipAddress.AddressFamily -ne $ipAddressFamily)
    {
        $errorMsg = $($script:localizedData.InvalidIPAddressFamily) -f $ipAddress, $AddressFamily

        New-TerminatingError -ErrorId 'InvalidIPAddressFamily' -ErrorMessage $errorMsg -ErrorCategory SyntaxError
    }

    return $ipAddress
}
