<#
    .SYNOPSIS
        Creates a terminating error record and throws it.

    .PARAMETER ErrorId
        The error ID.

    .PARAMETER ErrorMessage
        The error message.

    .PARAMETER ErrorCategory
        The error category.
#>

function New-TerminatingError
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ErrorId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ErrorMessage,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory
    )

    $exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception, $ErrorId, $ErrorCategory, $null
    throw $errorRecord
}
