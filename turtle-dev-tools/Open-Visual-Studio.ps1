. (Join-Path $PSScriptRoot 'Common.ps1')
Assert-TurtleDevelopmentBranch
$visualStudio = Get-TurtleVisualStudio
Assert-TurtleVulkan
$null = Initialize-TurtleIspc
$devenv = Join-Path $visualStudio 'Common7\IDE\devenv.exe'
$solution = Join-Path $script:TurtleRoot 'xLights\xLights.sln'
Start-Process -FilePath $devenv -WorkingDirectory $script:TurtleRoot -ArgumentList ('"' + $solution + '"')
Write-Host 'Choose Debug and x64; right-click the xLights project and choose Set as Startup Project.'
$testShow = Join-Path $env:LOCALAPPDATA 'xLights-Turtle\TestShow'
Write-Host ('For a separate test show, set Debugging > Command Arguments to -s "' + $testShow + '".')
