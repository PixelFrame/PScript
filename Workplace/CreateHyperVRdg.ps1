param(
  [Parameter()] [string] $RdgName,
  [Parameter()] [string] $VMHost,
  [Parameter()] [Microsoft.HyperV.PowerShell.VirtualMachine[]] $VMs
)
function CreateServerNode
{
  param(
    [Parameter()] [Microsoft.HyperV.PowerShell.VirtualMachine] $VM
  )
  $newNode = $Script:EleServer.Clone()
  $newNode.properties.displayName = $VM.Name
  $newNode.properties.vmId = $VM.Id.ToString()
  return $newNode
}

$BaseXml = @"
<?xml version=`"1.0`" encoding=`"utf-8`"?>
<RDCMan programVersion=`"2.90`" schemaVersion=`"3`">
  <file>
    <credentialsProfiles />
    <properties>
      <expanded>True</expanded>
      <name>$RdgName</name>
    </properties>
    <group>
      <properties>
        <expanded>False</expanded>
        <name>Default</name>
      </properties>
      <server>
        <properties>
          <displayName>displayname</displayName>
          <connectionType>VirtualMachineConsoleConnect</connectionType>
          <vmId>vmId</vmId>
          <name>$VMHost</name>
        </properties>
      </server>
    </group>
  </file>
  <connected />
  <favorites />
  <recentlyUsed />
</RDCMan>
"@

$XmlDoc = New-Object System.Xml.XmlDocument
$XmlDoc.LoadXml($BaseXml)
$Script:EleServer = $XmlDoc.RDCMan.file.group.server
$XmlDoc.RDCMan.file.group.RemoveChild($Script:EleServer) | Out-Null

foreach ($VM in $VMs)
{
  $srvNode = CreateServerNode $VM
  $XmlDoc.RDCMan.file.group.AppendChild($srvNode) | Out-Null
}

$XmlDoc.Save("$PSScriptRoot\$RdgName.rdg")