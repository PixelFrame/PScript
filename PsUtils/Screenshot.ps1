function CaptureScreen
{
    param (
        [string]$OutputFile
    )

    if ([string]::IsNullOrEmpty($OutputFile))
    {
        $Now = Get-Date -Format "yyyyMMddHHmmssfff"
        $OutputFile = "sc-$Now.png"
    }

    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms

    $screenWidth = [System.Windows.Forms.SystemInformation]::VirtualScreen.Width
    $screenHeight = [System.Windows.Forms.SystemInformation]::VirtualScreen.Height
    $bitmap = New-Object System.Drawing.Bitmap $screenWidth, $screenHeight
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen(0, 0, 0, 0, $bitmap.Size)

    $bitmap.Save($OutputFile, [System.Drawing.Imaging.ImageFormat]::Png)

    $graphics.Dispose()
    $bitmap.Dispose()

    return $OutputFile
}

CaptureScreen -OutputFile "E:\Temp\screenshot.png"