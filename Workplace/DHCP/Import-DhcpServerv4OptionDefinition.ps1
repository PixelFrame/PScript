[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path = 'C:\DhcpVendorClassAndOption'
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
        $Options = [string] (Get-Content -Path $File) | ConvertFrom-Json -ErrorAction SilentlyContinue # Convert to string type as bug of ConvertFrom-Json on Windows Server 2012
        $LocalOptions = Get-DhcpServerv4OptionDefinition -VendorClass $Options[0].VendorClass
        "Processing Vendor Class " + $Options[0].VendorClass
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
        "Process Completed Class " + $Options[0].VendorClass
        ""
    }
}