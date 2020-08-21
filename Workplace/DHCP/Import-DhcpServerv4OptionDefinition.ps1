[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path = 'C:\DhcpClassOption'
)

$OptionFiles = Get-ChildItem -Path $Path\Options*.json

if ($null -eq $OptionFiles)
{
    "No Option Files Found!"
    Exit
}
else
{
    foreach ($File in $OptionFiles)
    {
        $Options = [string] (Get-Content -Path $File) | ConvertFrom-Json
        $LocalOptions = Get-DhcpServerv4OptionDefinition -VendorClass $Options[0].VendorClass
        foreach ($Option in $Options)
        {
            if ($LocalOptions.OptionId -notcontains $Option.OptionId)
            {
                if ($Option.MultiValued -eq 'False')
                {
                    Add-DhcpServerv4OptionDefinition -OptionId $Option.OptionId -Type $Option.Type `
                        -Name $Option.Name -Description $Option.Description `
                        -VendorClass $Option.VendorClass
                    "Added Option " + $Option.OptionId
                }
                else
                {
                    Add-DhcpServerv4OptionDefinition -OptionId $Option.OptionId -Type $Option.Type `
                        -Name $Option.Name -Description $Option.Description `
                        -VendorClass $Option.VendorClass -MultiValued
                    "Added Option " + $Option.OptionId
                }
            }
            else
            {
                "Skipped Option " + $Option.OptionId
            }
        }
    }
}