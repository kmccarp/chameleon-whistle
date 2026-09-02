# Locates the MECCHA CHAMELEON Paks folder. Dot-sourced by install/uninstall.
# Windows PowerShell 5.1 compatible.

function Find-Game {
    $roots = New-Object System.Collections.Generic.List[string]

    # 1. Steam's own install path, from the registry
    $steam = $null
    foreach ($k in @('HKCU:\Software\Valve\Steam',
                     'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam',
                     'HKLM:\SOFTWARE\Valve\Steam')) {
        try {
            $p = Get-ItemProperty -Path $k -ErrorAction Stop
            if ($p.SteamPath) { $steam = $p.SteamPath }
            elseif ($p.InstallPath) { $steam = $p.InstallPath }
            if ($steam) { break }
        } catch {}
    }

    if ($steam) {
        $steam = $steam -replace '/', '\'
        $roots.Add($steam)
        # 2. every additional Steam library listed in libraryfolders.vdf
        $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
        if (Test-Path $vdf) {
            $text = Get-Content $vdf -Raw
            foreach ($m in [regex]::Matches($text, '"path"\s*"([^"]+)"')) {
                $roots.Add(($m.Groups[1].Value -replace '\\\\', '\'))
            }
        }
    }

    # 3. common fallback locations on every ready drive
    foreach ($d in [System.IO.DriveInfo]::GetDrives()) {
        if ($d.IsReady) {
            $roots.Add((Join-Path $d.Name 'Program Files (x86)\Steam'))
            $roots.Add((Join-Path $d.Name 'Program Files\Steam'))
            $roots.Add((Join-Path $d.Name 'SteamLibrary'))
            $roots.Add((Join-Path $d.Name 'Games\Steam'))
        }
    }

    foreach ($r in $roots) {
        try {
            $c = Join-Path $r 'steamapps\common\MECCHA CHAMELEON\Chameleon\Content\Paks'
            if (Test-Path $c) { return $c }
        } catch {}
    }
    return $null
}

function Read-GamePathFromUser {
    Write-Host '  Could not find MECCHA CHAMELEON automatically.' -ForegroundColor Yellow
    Write-Host '  Paste the full path to the game folder - the one containing'
    Write-Host '  PenguinHotel.exe - or press Enter to cancel.'
    $manual = Read-Host '  Path'
    if ([string]::IsNullOrWhiteSpace($manual)) { return $null }
    $manual = $manual.Trim().Trim('"')
    $try = Join-Path $manual 'Chameleon\Content\Paks'
    if (Test-Path $try) { return $try }
    if (Test-Path $manual) { return $manual }
    Write-Host "  Not found: $manual" -ForegroundColor Red
    return $null
}
