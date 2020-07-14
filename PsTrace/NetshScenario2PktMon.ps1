[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Scenario = 'internetclient_dbg',

    [Parameter()]
    [int]
    $FileSize = 2048,

    [Parameter()]
    [string]
    $OutPath = '$Env:SystemDrive\NetTrace-PktMon-' + $Scenario + '.etl'
)

$ScenarioString = netsh.exe trace show scenario $Scenario
$PktMonCmd = "PktMon.exe start -c -t ```n"
$PktMonProvider = ''

foreach ($line in $ScenarioString)
{
    if ($line.IndexOf(':') -ne -1)
    {
        $Item = $line.SubString(0, $line.IndexOf(':'))
    }
    else
    {
        $Item = ''
    }
    switch ($Item)
    {
        "Provider"
        {
            $PktMonCmd += $PktMonProvider
            $PktMonProvider = '    -p '
        }
        "Provider Guid"
        { 
            $PktMonProvider += '"' + $line.Substring($line.IndexOf('{')) + '" '
        }
        "Default Level"
        {
            if ($line.IndexOf('(') -eq -1)
            {
                $PktMonProvider += '-l ' + $line.Substring($line.LastIndexOf(' ') + 1) + ' '
            }
            else
            {
                $PktMonProvider += '-l ' + $line.Substring($line.LastIndexOf(' ') - 1, 1) + ' '
            }
        }
        "Default Keywords"
        {
            if ($line.IndexOf('(') -eq -1)
            {
                $defaultKey = $line.Substring($line.IndexOf('0x'))
                if ($defaultKey -eq '0x0')
                {
                    $PktMonProvider += "-k 0xFFFFFFFFFFFFFFFF ```n"
                }
                else
                {
                    $PktMonProvider += '-k ' + $defaultKey + " ```n"
                }
            }
            else
            {
                $PktMonProvider += '-k ' + $line.Substring($line.IndexOf('0x'), $line.IndexOf('(') - $line.IndexOf('0x') - 1) + " ```n"
            }
        }
        Default
        {}
    }
}

$PktMonCmd += $PktMonProvider
$PktMonCmd += '    -f ' + $OutPath + ' -s ' + $FileSize

$PktMonCmd | Tee-Object -FilePath $PSScriptRoot\PktMon_Scenario_$Scenario.ps1