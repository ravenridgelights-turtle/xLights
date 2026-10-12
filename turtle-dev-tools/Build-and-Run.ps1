param(
    [ValidateSet('Debug', 'Release')][string]$Configuration = 'Debug',
    [switch]$NoRun,
    [string]$ShowDirectory = (Join-Path $env:LOCALAPPDATA 'xLights-Turtle\TestShow')
)
. (Join-Path $PSScriptRoot 'Common.ps1')
Assert-TurtleRepository
$visualStudio = Get-TurtleVisualStudio
Assert-TurtleVulkan
$null = Initialize-TurtleIspc
Invoke-TurtleGit submodule sync --recursive
Invoke-TurtleGit submodule update --init --recursive --jobs 4
$msbuild = Join-Path $visualStudio 'MSBuild\Current\Bin\MSBuild.exe'
if (-not (Test-Path $msbuild)) { throw 'MSBuild.exe was not found in Visual Studio 2026.' }
$solution = Join-Path $script:TurtleRoot 'xLights\xLights.sln'
$jobs = [Math]::Max(1, [Math]::Min(4, [Environment]::ProcessorCount))
Write-Host ('Building xLights ' + $Configuration + ' x64. The first build downloads dependencies and may take a while.')
& $msbuild $solution /restore ('/m:' + $jobs) ('/p:Configuration=' + $Configuration) /p:Platform=x64
if ($LASTEXITCODE -ne 0) { throw 'The build failed. Send me the first error from the build window.' }
$executable = Join-Path $script:TurtleRoot ('xLights\x64\' + $Configuration + '\xLights.exe')
if (-not (Test-Path $executable)) { throw ('Build finished, but xLights.exe was not found at ' + $executable) }
Write-Host ('Built: ' + $executable)
if (-not $NoRun) {
    New-Item -ItemType Directory -Force -Path $ShowDirectory | Out-Null
    Write-Host ('Opening your development build with test show: ' + $ShowDirectory)
    Start-Process -FilePath $executable -WorkingDirectory (Split-Path -Parent $executable) -ArgumentList ('-s "' + $ShowDirectory + '"')
}
