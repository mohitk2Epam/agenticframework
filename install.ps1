<#
.SYNOPSIS
SF AI Dev Framework - Install Script for PowerShell 7
Copies .claude/ directory into target SFDX project.
#>

param(
    [string]$TargetDir = '.'
)

Set-StrictMode -Version Latest

$ResolvedTarget = Resolve-Path -Path $TargetDir -ErrorAction Stop
if ($ResolvedTarget -is [string]) {
    $TargetDir = $ResolvedTarget
}
else {
    $TargetDir = $ResolvedTarget.ProviderPath
}

if (-not (Test-Path -Path $TargetDir -PathType Container)) {
    Write-Error "Error: Target directory '$TargetDir' does not exist."
    exit 1
}

if (-not (Test-Path -Path (Join-Path $TargetDir 'sfdx-project.json'))) {
    Write-Warning "Warning: No sfdx-project.json found in '$TargetDir'."
    $response = Read-Host 'Are you sure this is an SFDX project? (y/n)'
    if ($response -ne 'y') {
        Write-Host 'Aborted.'
        exit 1
    }
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceRoot = Join-Path $ScriptDir '.claude'
$TargetRoot = Join-Path $TargetDir '.claude'

if (-not (Test-Path -Path $SourceRoot -PathType Container)) {
    Write-Error "Error: Source framework directory '$SourceRoot' does not exist."
    exit 1
}

if (Test-Path -Path $TargetRoot -PathType Container) {
    Write-Warning "Warning: .claude/ already exists in '$TargetDir'."
    Write-Warning 'This will merge framework files into existing .claude/ directory.'
    Write-Warning 'Existing files will NOT be overwritten. Continue? (y/n)'
    $response = Read-Host
    if ($response -ne 'y') {
        Write-Host 'Aborted.'
        exit 1
    }
}

function Copy-DirectoryNoOverwrite {
    param(
        [Parameter(Mandatory)] [string]$Source,
        [Parameter(Mandatory)] [string]$Destination
    )

    if (-not (Test-Path -Path $Source -PathType Container)) {
        return
    }

    $items = Get-ChildItem -Path $Source -Recurse -Force
    foreach ($item in $items) {
        $relativePath = $item.FullName.Substring($Source.Length).TrimStart('\','/')
        $destPath = Join-Path $Destination $relativePath

        if ($item.PSIsContainer) {
            if (-not (Test-Path -Path $destPath)) {
                New-Item -Path $destPath -ItemType Directory -Force | Out-Null
            }
        }
        else {
            if (-not (Test-Path -Path $destPath)) {
                $destDir = Split-Path -Parent $destPath
                if (-not (Test-Path -Path $destDir)) {
                    New-Item -Path $destDir -ItemType Directory -Force | Out-Null
                }
                Copy-Item -Path $item.FullName -Destination $destPath -Force
            }
        }
    }
}

New-Item -Path $TargetRoot -ItemType Directory -Force | Out-Null

Copy-DirectoryNoOverwrite -Source (Join-Path $SourceRoot 'skills') -Destination (Join-Path $TargetRoot 'skills')
Copy-DirectoryNoOverwrite -Source (Join-Path $SourceRoot 'agents') -Destination (Join-Path $TargetRoot 'agents')
Copy-DirectoryNoOverwrite -Source (Join-Path $SourceRoot 'workflows') -Destination (Join-Path $TargetRoot 'workflows')

New-Item -Path (Join-Path $TargetRoot 'context') -ItemType Directory -Force | Out-Null

$claudeSource = Join-Path $SourceRoot 'CLAUDE.md'
$claudeTarget = Join-Path $TargetRoot 'CLAUDE.md'
if (-not (Test-Path -Path $claudeTarget)) {
    Copy-Item -Path $claudeSource -Destination $claudeTarget -Force
    Write-Host 'Created .claude/CLAUDE.md'
}
else {
    Write-Host 'Skipped .claude/CLAUDE.md (already exists)'
}

$registrySource = Join-Path $SourceRoot 'skills-registry.json'
$registryTarget = Join-Path $TargetRoot 'skills-registry.json'
if (-not (Test-Path -Path $registryTarget)) {
    Copy-Item -Path $registrySource -Destination $registryTarget -Force
    Write-Host 'Created .claude/skills-registry.json'
}
else {
    Write-Host 'Skipped .claude/skills-registry.json (already exists)'
}

Write-Host ''
Write-Host "SF AI Dev Framework installed to: $TargetRoot"
Write-Host ''
Write-Host 'Next steps:'
Write-Host '  1. Run AIInitFramework to populate .claude/context/'
Write-Host '  2. Open project in Claude Code (CLAUDE.md loads automatically)'
Write-Host '  3. For Cursor: copy .claude/CLAUDE.md content to .cursorrules'
