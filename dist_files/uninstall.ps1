# Removes the mod. Deletes only the files this mod added; stock game files
# are never touched, so this fully reverts you to the original whistle.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $root 'find_game.ps1')

Write-Host ''
$paks = Find-Game
if (-not $paks) { $paks = Read-GamePathFromUser }
if (-not $paks) { Write-Host '  Cancelled.'; return }

$found = @(Get-ChildItem $paks -Filter 'zzz_ChameleonYell_P.*' -File -ErrorAction SilentlyContinue)
if ($found.Count -eq 0) { Write-Host '  Mod is not installed - nothing to do.'; return }

$removed = 0
$locked = @()
foreach ($f in $found) {
    try { Remove-Item $f.FullName -Force; $removed++ }
    catch { $locked += $f.Name }
}

if ($locked.Count -gt 0) {
    Write-Host ('  In use: ' + ($locked -join ', ')) -ForegroundColor Red
    Write-Host '  Quit MECCHA CHAMELEON completely, then run this again.'
    if ($removed -gt 0) {
        Write-Host "  ($removed file(s) were removed; re-run to finish.)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Mod removed ($removed files). Back to the stock whistle." -ForegroundColor Green
}
