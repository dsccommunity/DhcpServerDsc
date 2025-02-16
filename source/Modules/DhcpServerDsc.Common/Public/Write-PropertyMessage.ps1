# Internal function to write verbose messages for collection of properties
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
