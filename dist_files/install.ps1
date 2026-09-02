# MECCHA CHAMELEON - Low-Frequency Yell Taunt : installer
# Windows PowerShell 5.1 compatible. No admin rights needed.
# Purely additive: writes three new zzz_ChameleonYell_P.* files and never
# modifies or overwrites a stock game file.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $root 'find_game.ps1')

Write-Host ''
Write-Host '  MECCHA CHAMELEON - Low-Frequency Yell Taunt' -ForegroundColor Cyan
Write-Host '  ===========================================' -ForegroundColor Cyan
Write-Host ''

$paks = Find-Game
if (-not $paks) { $paks = Read-GamePathFromUser }
if (-not $paks) { Write-Host '  Cancelled.'; return }

Write-Host '  Game found: ' -NoNewline
Write-Host $paks -ForegroundColor Green
Write-Host ''

$variants = @(
    @{ Key = '1'; Name = 'A_male_scream';  Label = 'Male scream      - 95.7% of energy below 750 Hz' },
    @{ Key = '2'; Name = 'B_hey_call';     Label = 'Man calling out  - 91.8% below 750 Hz' },
    @{ Key = '3'; Name = 'C_wilhelm';      Label = 'Wilhelm scream   - 88.2% below 750 Hz' },
    @{ Key = '4'; Name = 'D_death_scream'; Label = 'Death scream     - 86.1% below 750 Hz' }
)

Write-Host '  Choose a yell (the previews folder lets you hear them first):'
foreach ($v in $variants) { Write-Host ('    [{0}] {1}' -f $v.Key, $v.Label) }
Write-Host '    [R] Remove the mod'
Write-Host ''
$choice = Read-Host '  Choice'

if ($choice -match '^\s*[Rr]') {
    & (Join-Path $root 'uninstall.ps1')
    return
}

$sel = $variants | Where-Object { $_.Key -eq $choice.Trim() }
if (-not $sel) { Write-Host '  Not a valid choice.' -ForegroundColor Red; return }

$srcDir = Join-Path $root ('mods\' + $sel.Name)
if (-not (Test-Path $srcDir)) { Write-Host "  Missing folder: $srcDir" -ForegroundColor Red; return }
$files = @(Get-ChildItem $srcDir -File)
if ($files.Count -eq 0) { Write-Host "  No files in $srcDir" -ForegroundColor Red; return }

# Pre-flight: refuse if the game holds any target file open, so a locked file
# can never leave a half-swapped set behind.
$locked = @()
foreach ($f in $files) {
    $t = Join-Path $paks $f.Name
    if (Test-Path $t) {
        try {
            $fs = [System.IO.File]::Open($t, 'Open', 'Write', 'None')
            $fs.Close()
        } catch { $locked += $f.Name }
    }
}
if ($locked.Count -gt 0) {
    Write-Host ''
    Write-Host ('  Cannot install - file(s) in use: ' + ($locked -join ', ')) -ForegroundColor Red
    Write-Host '  MECCHA CHAMELEON is still running. Quit the game completely,'
    Write-Host '  then run this installer again.'
    Write-Host '  Nothing was changed.' -ForegroundColor Yellow
    return
}

foreach ($f in $files) { Copy-Item $f.FullName (Join-Path $paks $f.Name) -Force }

$bad = @()
foreach ($f in $files) {
    $a = (Get-FileHash $f.FullName -Algorithm SHA256).Hash
    $b = (Get-FileHash (Join-Path $paks $f.Name) -Algorithm SHA256).Hash
    if ($a -ne $b) { $bad += $f.Name }
}

Write-Host ''
if ($bad.Count -gt 0) {
    Write-Host ('  VERIFY FAILED: ' + ($bad -join ', ')) -ForegroundColor Red
    Write-Host '  Try again with the game closed.'
} else {
    Write-Host ("  Installed '{0}' - all {1} files verified." -f $sel.Name, $files.Count) -ForegroundColor Green
    Write-Host '  Launch the game and use your taunt. Run UNINSTALL.bat to revert.'
}
