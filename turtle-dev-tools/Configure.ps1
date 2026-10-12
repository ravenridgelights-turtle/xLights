. (Join-Path $PSScriptRoot 'Common.ps1')
Assert-TurtleDevelopmentBranch
Set-TurtleRemotes
Invoke-TurtleGit submodule sync --recursive
Invoke-TurtleGit submodule update --init --recursive --jobs 4

$binPath = Initialize-TurtleIspc
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (($userPath -split ';') -notcontains $binPath) {
    $updatedPath = if ([string]::IsNullOrWhiteSpace($userPath)) { $binPath } else { $userPath.TrimEnd(';') + ';' + $binPath }
    [Environment]::SetEnvironmentVariable('Path', $updatedPath, 'User')
}

& git -C $script:TurtleRoot config user.name *> $null
if ($LASTEXITCODE -ne 0) { Invoke-TurtleGit config user.name ravenridgelights-turtle }
& git -C $script:TurtleRoot config user.email *> $null
if ($LASTEXITCODE -ne 0) { Invoke-TurtleGit config user.email 54298835+ravenridgelights-turtle@users.noreply.github.com }

Write-Host ''
Write-Host 'Configured: your GitHub fork receives pushes; official xLights only supplies downloads.'
Write-Host 'Development branch: turtle-dev. ISPC is ready. Reopen Visual Studio if it was already running.'
$visualStudio = Get-TurtleVisualStudio
Assert-TurtleVulkan
Write-Host ('Visual Studio: ' + $visualStudio)
Write-Host 'Ready. Double-click 03-Build-and-Run.cmd.'
