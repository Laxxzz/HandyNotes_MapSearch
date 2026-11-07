# Publishes the current build to every public channel as ONE action: a GitHub
# release on the public releases repo, then CurseForge, Wago Addons and
# WoWInterface with the same zip, and last the patch notes in Discord #releases.
#
# The logic is shared by every addon: Publish-WowAddon.ps1 in the wow-addon skill's
# scripts directory (its header documents all behaviour and parameters). What is
# specific to MapSearch lives in dev/publish.json next to this file: the public
# releases repo, the zip checks and the words public patch notes may never contain.
#
# Run from the primary checkout at the published master commit; it publishes, so only
# with the user's go-ahead. Parameters pass straight through: -Repo -Notes -Only
# -CurseId -WagoId -WowiId -Replace -Unlanded -DryRun. WOW_PUBLISHER_SCRIPT, when set,
# names another copy of the shared script (an unlanded change to it, under test).

[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Repo,
    [string]$Notes,
    [ValidateSet("github", "wago", "curse", "wowi", "discord")]
    [string[]]$Only,
    [string]$CurseId,
    [string]$WagoId,
    [string]$WowiId,
    [switch]$Replace,
    [switch]$Unlanded,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ref = (Get-Item "$HOME\.claude\skills\wow-addon").Target | Split-Path | Split-Path
$shared = if ($env:WOW_PUBLISHER_SCRIPT) { $env:WOW_PUBLISHER_SCRIPT } else { Join-Path $ref "scripts\Publish-WowAddon.ps1" }
if (-not (Test-Path -LiteralPath $shared)) { throw "shared publisher not found: $shared" }

$forward = @{ Source = (Split-Path -Parent $PSScriptRoot) }
foreach ($key in $PSBoundParameters.Keys) { $forward[$key] = $PSBoundParameters[$key] }
& $shared @forward
