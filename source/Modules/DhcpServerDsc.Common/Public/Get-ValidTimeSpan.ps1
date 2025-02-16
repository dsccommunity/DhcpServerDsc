# Internal function to translate a string to valid TimeSpan format
function Get-ValidTimeSpan
{
    [CmdletBinding()]
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
