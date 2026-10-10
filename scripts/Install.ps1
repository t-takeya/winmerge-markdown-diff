[CmdletBinding()]
param(
    [string]$WinMergeDirectory = "$env:ProgramFiles\WinMerge",
    [string]$NodeExecutable,
    [switch]$Automatic
)
$ErrorActionPreference = 'Stop'
# This file is distributed in the root of the release ZIP.
$release = $PSScriptRoot
if (-not (Test-Path -LiteralPath (Join-Path $release 'Commands\MarkdownFormat\src\format.mjs'))) {
    throw 'Run Install.ps1 from the extracted release ZIP (npm run build creates it).'
}
$target = (Resolve-Path -LiteralPath $WinMergeDirectory).Path
if (-not (Test-Path -LiteralPath (Join-Path $target 'WinMergeU.exe'))) {
    throw 'WinMergeU.exe was not found in WinMergeDirectory.'
}
if (-not $NodeExecutable) { $NodeExecutable = (Get-Command node.exe -ErrorAction Stop).Source }
$NodeExecutable = (Resolve-Path -LiteralPath $NodeExecutable).Path
$nodeVersion = & $NodeExecutable --version
if ($LASTEXITCODE -ne 0 -or $nodeVersion -notmatch '^v(\d+)\.' -or [int]$Matches[1] -lt 22) {
    throw 'Node.js 22 or later is required.'
}
$pluginsDirectory = Join-Path $target 'MergePlugins'
$commandsDirectory = Join-Path $target 'Commands'
New-Item -ItemType Directory -Force -Path $pluginsDirectory, $commandsDirectory | Out-Null
$xmlPath = Join-Path $pluginsDirectory 'Plugins.xml'
$document = New-Object System.Xml.XmlDocument
$document.PreserveWhitespace = $true
if (Test-Path -LiteralPath $xmlPath) {
    $document.Load($xmlPath)
} else {
    $document.LoadXml('<?xml version="1.0" encoding="utf-8"?><plugins></plugins>')
}
if ($document.DocumentElement.Name -ne 'plugins') { throw 'Unexpected Plugins.xml format.' }
$definition = New-Object System.Xml.XmlDocument
$definition.Load((Join-Path $release 'plugin\MarkdownFormat.xml'))
$plugin = $document.ImportNode($definition.SelectSingleNode('/plugins/plugin'), $true)
$plugin.SelectSingleNode('unpack-file/command').InnerText = $plugin.SelectSingleNode('unpack-file/command').InnerText.Replace('__NODE_EXE__', $NodeExecutable)
$plugin.SelectSingleNode('is-automatic').SetAttribute('value', $Automatic.IsPresent.ToString().ToLowerInvariant())
foreach ($old in @($document.SelectNodes('/plugins/plugin[@name="MarkdownFormat"]'))) {
    [void]$old.ParentNode.RemoveChild($old)
}
[void]$document.DocumentElement.AppendChild($plugin)
# Keep other plugin definitions, and back up the complete previous XML.
if (Test-Path -LiteralPath $xmlPath) {
    $backup = $xmlPath + '.backup-' + [Guid]::NewGuid().ToString('N')
    Copy-Item -LiteralPath $xmlPath -Destination $backup
}
Copy-Item -LiteralPath (Join-Path $release 'Commands\MarkdownFormat') -Destination $commandsDirectory -Recurse -Force
$document.Save($xmlPath)
Write-Output "Installed MarkdownFormat in $target. Restart WinMerge."
