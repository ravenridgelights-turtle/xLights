. (Join-Path $PSScriptRoot 'Common.ps1')
Assert-TurtleDevelopmentBranch
Assert-TurtleCleanTree
Set-TurtleRemotes
Invoke-TurtleGit fetch origin turtle-dev
$localSha = [string](Invoke-TurtleGit rev-parse HEAD)
$remoteSha = [string](Invoke-TurtleGit rev-parse origin/turtle-dev)
if ($localSha -ne $remoteSha) {
    & git -C $script:TurtleRoot merge-base --is-ancestor HEAD origin/turtle-dev
    if ($LASTEXITCODE -ne 0) {
        throw 'Your PC has commits not included on GitHub. Send me git status and git log -5 --oneline so we can combine them without losing work.'
    }
    New-TurtleBackup 'before-pull'
    Invoke-TurtleGit merge --ff-only origin/turtle-dev
}
Invoke-TurtleGit submodule sync --recursive
Invoke-TurtleGit submodule update --init --recursive --jobs 4
Write-Host 'Your PC now has the latest changes from your personal turtle-dev branch.'
Write-Host 'Double-click 03-Build-and-Run.cmd to compile and test them.'
