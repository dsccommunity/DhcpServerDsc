<#
    .SYNOPSIS
        Writes the property message to the verbose stream.

    .PARAMETER Parameters
        The parameters to write.

    .PARAMETER KeysToSkip
        The keys to skip.

    .PARAMETER MessageTemplate
        The message template to use.
#>

function Write-PropertyMessage
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Parameters,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $KeysToSkip,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MessageTemplate
    )

    foreach ($key in $parameters.keys)
    {
        if ($keysToSkip -notcontains $key)
        {
            $msg = $MessageTemplate -f $key, $parameters[$key]
            Write-Verbose -Message $msg
        }
    }
}
