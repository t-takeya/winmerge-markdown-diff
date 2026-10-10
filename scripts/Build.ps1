[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$release = Join-Path $root 'dist\winmerge-markdown-diff'
$prettier = Join-Path $root 'node_modules\prettier'
if (-not (Test-Path -LiteralPath $prettier)) { throw 'Run npm ci before building.' }
New-Item -ItemType Directory -Force -Path "$release\Commands\MarkdownFormat\src", "$release\Commands\MarkdownFormat\node_modules", "$release\plugin" | Out-Null
Copy-Item -LiteralPath "$root\src\format.mjs" -Destination "$release\Commands\MarkdownFormat\src" -Force
Copy-Item -LiteralPath $prettier -Destination "$release\Commands\MarkdownFormat\node_modules" -Recurse -Force
Copy-Item -LiteralPath "$root\plugin\MarkdownFormat.xml" -Destination "$release\plugin" -Force
Copy-Item -LiteralPath "$root\scripts\Install.ps1", "$root\README.md", "$root\LICENSE" -Destination $release -Force
Copy-Item -LiteralPath "$root\examples" -Destination $release -Recurse -Force
Compress-Archive -Path "$release\*" -DestinationPath "$root\dist\winmerge-markdown-diff-1.0.0.zip" -Force
Write-Output "Built: $root\dist\winmerge-markdown-diff-1.0.0.zip"
