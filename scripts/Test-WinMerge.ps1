[CmdletBinding()]
param([string]$WinMergeDirectory)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if (-not $WinMergeDirectory) { $WinMergeDirectory = Join-Path $root '.test-winmerge' }
$exe = Join-Path (Resolve-Path -LiteralPath $WinMergeDirectory).Path 'WinMergeU.exe'
function Compare-Markdown([string]$right, [bool]$usePlugin, [int]$expected) {
    $arguments = @('/noninteractive', '/noprefs', '/enableexitcode', '/s-', '/u', '/wl', '/wr', '/minimize')
    if ($usePlugin) { $arguments += @('/unpacker', 'MarkdownFormat') }
    $arguments += @(('"' + (Join-Path $root 'examples\left.md') + '"'), ('"' + (Join-Path $root "examples\$right.md") + '"'))
    $process = Start-Process -FilePath $exe -ArgumentList $arguments -WindowStyle Hidden -PassThru
    if (-not $process.WaitForExit(30000)) {
        Stop-Process -Id $process.Id
        throw 'WinMerge comparison timed out.'
    }
    $process.Refresh()
    if ($process.ExitCode -ne $expected) { throw "right=$right plugin=$usePlugin : expected $expected, got $($process.ExitCode)" }
    Write-Output "PASS right=$right plugin=$usePlugin exit=$expected"
}
Compare-Markdown 'right' $false 1
Compare-Markdown 'right' $true 0
Compare-Markdown 'changed' $true 1
