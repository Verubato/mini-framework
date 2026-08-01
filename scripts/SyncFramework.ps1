<#
.SYNOPSIS
Copies this repo's src\MiniFramework into every addon that embeds it.

.DESCRIPTION
Each addon vendors a snapshot of the framework at src\Libs\MiniFramework. This script
overwrites those snapshots from src\MiniFramework in this repo, so one edit here
propagates everywhere with a single command.

Targets are discovered by looking for an existing src\Libs\MiniFramework folder in every
sibling repo of this one. Use -Include to seed an addon that hasn't been migrated yet.

The copy is exact: files deleted from the source are deleted from each addon too, so a
renamed framework file never leaves a stale orphan behind that the toc still loads.

.PARAMETER Include
Only sync these repo folder names. Also forces creation in addons that don't embed it yet.

.PARAMETER Exclude
Skip these repo folder names.

.PARAMETER ReposRoot
Folder holding the addon repos. Defaults to this repo's parent.

.PARAMETER WhatIf
Report what would change without writing anything.

.EXAMPLE
.\SyncFramework.ps1 -WhatIf

.EXAMPLE
.\SyncFramework.ps1 -Include MiniFader, MiniHider
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string[]] $Include,
    [string[]] $Exclude,
    [string] $ReposRoot
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$source = Join-Path $repoRoot "src\MiniFramework"

if (-not (Test-Path -LiteralPath $source)) {
    throw "Source not found: $source"
}

if (-not $ReposRoot) {
    $ReposRoot = Split-Path $repoRoot -Parent
}

if (-not (Test-Path -LiteralPath $ReposRoot)) {
    throw "Repos root not found: $ReposRoot"
}

# Version stamp, so the summary says what everyone is being moved to.
$namespace = Get-Content -LiteralPath (Join-Path $source "Namespace.lua") -Raw
$version = if ($namespace -match 'local VERSION = "([^"]+)"') { $Matches[1] } else { "unknown" }

Write-Host ("MiniFramework {0}" -f $version)
Write-Host ("Source:  {0}" -f $source)
Write-Host ("Repos:   {0}" -f $ReposRoot)
Write-Host ""

$candidates = @(
    Get-ChildItem -LiteralPath $ReposRoot -Directory |
        Where-Object { $_.FullName -ne $repoRoot } |
        Where-Object {
            (Test-Path -LiteralPath (Join-Path $_.FullName "src\Libs\MiniFramework")) -or
            ($Include -contains $_.Name)
        }
)

if ($Include) {
    foreach ($name in $Include) {
        if (-not ($candidates | Where-Object Name -eq $name)) {
            throw "Repo not found: $name"
        }
    }

    $candidates = @($candidates | Where-Object { $Include -contains $_.Name })
}

if ($Exclude) {
    $candidates = @($candidates | Where-Object { $Exclude -notcontains $_.Name })
}

if ($candidates.Count -eq 0) {
    Write-Warning "No addons embed MiniFramework yet. Use -Include to seed one."
    return
}

# Relative paths of everything the source provides, for both copying and orphan detection.
$sourceFiles = @(
    Get-ChildItem -LiteralPath $source -Recurse -File |
        ForEach-Object { $_.FullName.Substring($source.Length).TrimStart("\") }
)

$changedRepos = 0
$totalWritten = 0
$totalRemoved = 0

foreach ($repo in $candidates) {
    $target = Join-Path $repo.FullName "src\Libs\MiniFramework"
    $written = @()
    $removed = @()

    foreach ($relative in $sourceFiles) {
        $from = Join-Path $source $relative
        $to = Join-Path $target $relative

        $identical = (Test-Path -LiteralPath $to) -and
            ((Get-FileHash -LiteralPath $from).Hash -eq (Get-FileHash -LiteralPath $to).Hash)

        if ($identical) {
            continue
        }

        $written += $relative

        if ($PSCmdlet.ShouldProcess($to, "Copy")) {
            $parent = Split-Path $to -Parent

            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }

            Copy-Item -LiteralPath $from -Destination $to -Force
        }
    }

    # Anything in the target that the source no longer has.
    if (Test-Path -LiteralPath $target) {
        $targetFiles = @(
            Get-ChildItem -LiteralPath $target -Recurse -File |
                ForEach-Object { $_.FullName.Substring($target.Length).TrimStart("\") }
        )

        foreach ($relative in $targetFiles) {
            if ($sourceFiles -contains $relative) {
                continue
            }

            $removed += $relative

            if ($PSCmdlet.ShouldProcess((Join-Path $target $relative), "Remove")) {
                Remove-Item -LiteralPath (Join-Path $target $relative) -Force
            }
        }
    }

    if ($written.Count -eq 0 -and $removed.Count -eq 0) {
        Write-Host ("  {0,-24} up to date" -f $repo.Name) -ForegroundColor DarkGray
        continue
    }

    $changedRepos++
    $totalWritten += $written.Count
    $totalRemoved += $removed.Count

    Write-Host ("  {0,-24} {1} updated, {2} removed" -f $repo.Name, $written.Count, $removed.Count) -ForegroundColor Green

    foreach ($relative in $written) {
        Write-Verbose ("    + {0}" -f $relative)
    }

    foreach ($relative in $removed) {
        Write-Host ("    - {0}" -f $relative) -ForegroundColor Yellow
    }

    # A missing toc entry means the copy is inert - worth saying out loud.
    $toc = @(Get-ChildItem -LiteralPath (Join-Path $repo.FullName "src") -Filter *.toc -File) | Select-Object -First 1

    if ($toc -and -not (Select-String -LiteralPath $toc.FullName -Pattern "MiniFramework\.xml" -Quiet)) {
        Write-Warning ("{0}: {1} does not reference Libs\MiniFramework\MiniFramework.xml" -f $repo.Name, $toc.Name)
    }
}

Write-Host ""
Write-Host ("{0}/{1} repos changed, {2} files written, {3} removed" -f
    $changedRepos, $candidates.Count, $totalWritten, $totalRemoved)
