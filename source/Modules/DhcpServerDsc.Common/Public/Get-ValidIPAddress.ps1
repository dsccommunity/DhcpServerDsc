# Internal function to translate a string to valid IPAddress format
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
