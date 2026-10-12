$ErrorActionPreference = 'Stop'
$script:TurtleRepository = 'ravenridgelights-turtle/xLights'
$script:TurtleRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:TurtleTools = Join-Path $env:LOCALAPPDATA 'xLights-Turtle\Tools'

function Invoke-TurtleGit {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$GitArguments)
    & git -C $script:TurtleRoot @GitArguments
    if ($LASTEXITCODE -ne 0) {
        throw ('Git failed: git ' + ($GitArguments -join ' '))
    }
}

function Assert-TurtleRepository {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Install Git for Windows, then reopen this window.'
    }
    $originUrl = [string](Invoke-TurtleGit config --get remote.origin.url)
    $allowed = @(
        'https://github.com/ravenridgelights-turtle/xLights',
        'https://github.com/ravenridgelights-turtle/xLights.git',
        'git@github.com:ravenridgelights-turtle/xLights.git',
        'ssh://git@github.com/ravenridgelights-turtle/xLights.git'
    )
    if ($allowed -notcontains $originUrl.TrimEnd('/')) {
        throw 'This helper only works inside your personal ravenridgelights-turtle/xLights clone. It refuses the official repository.'
    }
}

function Assert-TurtleDevelopmentBranch {
    Assert-TurtleRepository
    $branch = [string](Invoke-TurtleGit branch --show-current)
    if ($branch.Trim() -ne 'turtle-dev') {
        throw 'Switch to turtle-dev before using this helper: git switch turtle-dev'
    }
}

function Assert-TurtleCleanTree {
    $changes = @(Invoke-TurtleGit status --porcelain)
    if ($changes.Count -gt 0) {
        throw 'You have local changes. Commit them or save them with Git before updating; this helper will not erase them.'
    }
    foreach ($state in @('MERGE_HEAD', 'CHERRY_PICK_HEAD', 'REVERT_HEAD', 'rebase-merge', 'rebase-apply')) {
        $statePath = [string](Invoke-TurtleGit rev-parse --git-path $state)
        if (-not [IO.Path]::IsPathRooted($statePath)) {
            $statePath = Join-Path $script:TurtleRoot $statePath
        }
        if (Test-Path $statePath) {
            throw 'Finish or abort the Git operation already in progress before updating.'
        }
    }
}

function Set-TurtleRemotes {
    Assert-TurtleRepository
    $remotes = @(Invoke-TurtleGit remote)
    if ($remotes -contains 'upstream') {
        Invoke-TurtleGit remote set-url upstream https://github.com/xLightsSequencer/xLights.git
    } else {
        Invoke-TurtleGit remote add upstream https://github.com/xLightsSequencer/xLights.git
    }
    Invoke-TurtleGit config --replace-all remote.upstream.pushurl https://upstream-read-only.invalid/xLights.git
    Invoke-TurtleGit config remote.pushDefault origin
    Invoke-TurtleGit config branch.turtle-dev.remote origin
    Invoke-TurtleGit config branch.turtle-dev.merge refs/heads/turtle-dev
    Invoke-TurtleGit config branch.turtle-dev.pushRemote origin
    Invoke-TurtleGit config pull.ff only
    Invoke-TurtleGit config fetch.prune true
}

function New-TurtleBackup {
    param([string]$Reason)
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff')
    $name = 'backup/turtle-' + $Reason + '-' + $stamp
    Invoke-TurtleGit branch $name HEAD
    Write-Host ('Saved local backup: ' + $name)
}

function Initialize-TurtleIspc {
    $existing = Get-Command ispc.exe -ErrorAction SilentlyContinue
    if ($existing) { return (Split-Path -Parent $existing.Source) }
    $version = '1.31.0'
    $folder = Join-Path $script:TurtleTools ('ispc-' + $version)
    $executable = @(Get-ChildItem -Path $folder -Filter ispc.exe -Recurse -ErrorAction SilentlyContinue)
    if ($executable.Count -eq 0) {
        New-Item -ItemType Directory -Force -Path $folder | Out-Null
        $zip = Join-Path $script:TurtleTools ('ispc-' + $version + '.zip')
        Write-Host ('Downloading ISPC ' + $version + ' from its official GitHub release...')
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -UseBasicParsing -Uri ('https://github.com/ispc/ispc/releases/download/v' + $version + '/ispc-v' + $version + '-windows.zip') -OutFile $zip
        Expand-Archive -Path $zip -DestinationPath $folder -Force
        Remove-Item $zip
        $executable = @(Get-ChildItem -Path $folder -Filter ispc.exe -Recurse)
    }
    if ($executable.Count -ne 1) { throw 'Could not find ispc.exe in the ISPC download.' }
    $binPath = Split-Path -Parent $executable[0].FullName
    $env:PATH = $binPath + ';' + $env:PATH
    return $binPath
}

function Get-TurtleVisualStudio {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path $vswhere)) {
        throw 'Install Visual Studio 2026 Community with the Desktop development with C++ workload.'
    }
    $installations = & $vswhere -latest -version '[18.0,19.0)' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($LASTEXITCODE -ne 0 -or -not $installations) {
        throw 'Visual Studio 2026 C++ tools were not found. Current xLights uses v145; install the Desktop development with C++ workload in Visual Studio 2026.'
    }
    return ([string]$installations).Trim()
}

function Assert-TurtleVulkan {
    if (-not $env:VULKAN_SDK -or -not (Test-Path (Join-Path $env:VULKAN_SDK 'Bin\glslc.exe'))) {
        throw 'Install the Vulkan SDK from https://vulkan.lunarg.com/sdk/home#windows, then reopen this window.'
    }
}
