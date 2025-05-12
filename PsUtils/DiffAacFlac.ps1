$AAC = Get-ChildItem -Recurse -Filter *.m4a -Path X:\Music\AAC | Select-Object @(
    @{Name = "FullPath"; Expression = { $_.FullName } }
    @{Name = "RelativeName"; Expression = { [System.IO.Path]::GetRelativePath('X:\Music\AAC', $_.Directory) + '\' + $_.BaseName } }
)
$Flac = Get-ChildItem -Recurse -Filter *.flac -Path X:\Music\Lossless | Select-Object @(
    @{Name = "FullPath"; Expression = { $_.FullName } }
    @{Name = "RelativeName"; Expression = { [System.IO.Path]::GetRelativePath('X:\Music\Lossless', $_.Directory) + '\' + $_.BaseName } }
)
Compare-Object $AAC $Flac -Property RelativeName -PassThru