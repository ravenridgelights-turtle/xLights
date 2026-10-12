param([ValidateSet('Master', 'LatestRelease')][string]$Source = 'Master')
. (Join-Path $PSScriptRoot 'Common.ps1')
Assert-TurtleDevelopmentBranch
Assert-TurtleCleanTree
Set-TurtleRemotes
Invoke-TurtleGit fetch upstream master --tags
$target = 'upstream/master'
if ($Source -eq 'LatestRelease') {
    $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/xLightsSequencer/xLights/releases/latest' -Headers @{ 'User-Agent' = 'xLights-Turtle-Dev' }
    $tag = [string]$release.tag_name
    if ($tag -notmatch '^[0-9][A-Za-z0-9._-]*$') { throw 'GitHub returned an unexpected release tag.' }
    $target = 'refs/tags/' + $tag
    Write-Host ('Latest official release: ' + $tag)
}
& git -C $script:TurtleRoot merge-base --is-ancestor $target HEAD
if ($LASTEXITCODE -eq 0) {
    Write-Host 'That official version is already included in your branch. Nothing needs merging.'
    return
}
if ($LASTEXITCODE -ne 1) { throw 'Could not compare the official version with your branch.' }
New-TurtleBackup 'before-official-update'
& git -C $script:TurtleRoot merge --no-edit $target
if ($LASTEXITCODE -ne 0) {
    $conflicts = @(& git -C $script:TurtleRoot diff --name-only --diff-filter=U)
    & git -C $script:TurtleRoot rev-parse -q --verify MERGE_HEAD *> $null
    if ($LASTEXITCODE -eq 0) { Invoke-TurtleGit merge --abort }
    throw ('Update stopped and the merge was aborted. Send me these conflicting files: ' + ($conflicts -join ', '))
}
Invoke-TurtleGit submodule sync --recursive
Invoke-TurtleGit submodule update --init --recursive --jobs 4
Write-Host 'Official updates have been merged locally. Build and test with 03-Build-and-Run.cmd.'
Write-Host 'After testing, save to YOUR fork with: git push origin turtle-dev'
