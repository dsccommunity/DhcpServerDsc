<#
    .SYNOPSIS
        Validates a string to ensure it is a valid TimeSpan.

    .PARAMETER TsString
        The string to validate.

    .PARAMETER ParameterName
        The name of the parameter for error purposes.

    .OUTPUTS
        [System.TimeSpan] object.
#>

function Get-ValidTimeSpan
{
    [CmdletBinding()]
    [OutputType([System.TimeSpan])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TsString,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ParameterName
    )

    [System.TimeSpan] $timeSpan = New-TimeSpan

    $result = [System.TimeSpan]::TryParse($TsString, [ref] $timeSpan)

    if (-not $result)
    {
        $errorMsg = $($script:localizedData.InvalidTimeSpanFormat) -f $ParameterName

        New-TerminatingError -ErrorId 'NotValidTimeSpan' -ErrorMessage $errorMsg -ErrorCategory InvalidType
    }

    return $timeSpan
}
