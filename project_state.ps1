# project_state.ps1 - vygeneruje PROJEKT-STAV.md:
# metadata PC + strom .gitignored souboru s velikostmi + co co vytvari.
# Spusteni:  powershell -File project_state.ps1
$ErrorActionPreference = 'SilentlyContinue'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
$outFile = Join-Path $root 'PROJEKT-STAV.md'

function Format-Size([double]$bytes) {
    foreach ($u in 'B','KB','MB','GB','TB') {
        if ($bytes -lt 1024 -or $u -eq 'TB') {
            if ($u -eq 'B') { return "$([int]$bytes) B" }
            return ('{0:N1} {1}' -f $bytes, $u)
        }
        $bytes /= 1024
    }
}

function Get-DirSize([string]$path) {
    $sum = (Get-ChildItem -LiteralPath $path -Recurse -File -Force |
            Measure-Object Length -Sum).Sum
    if ($null -eq $sum) { return 0 }
    return [double]$sum
}

# ---------- metadata PC ----------
$os  = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$gpu = Get-CimInstance Win32_VideoController | ForEach-Object { $_.Name }
$ramGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)

# ---------- nastroje ----------
$tools = @()
foreach ($t in 'python','py','git','ffmpeg','winget') {
    $c = Get-Command $t -ErrorAction SilentlyContinue
    if ($c) { $tools += "| ``$t`` | ``$($c.Source)`` |" }
}
$venvPy = Join-Path $root '.venv\Scripts\python.exe'
$venvState = if (Test-Path $venvPy) { 'existuje' } else { 'chybi' }

# ---------- gitignored obsah ----------
$ignored = @(git -c core.quotepath=false ls-files --others --ignored --exclude-standard)
$tops = $ignored | ForEach-Object { ($_ -split '/')[0] } | Sort-Object -Unique

# co v projektu co vytvari (mapovani, doplnovat dle potreby)
$notes = @{
    '.venv'        = 'vytvari install_wizard.bat -> setup_env.py (pip install -r requirements.txt + CUDA DLL)'
    '.whisper'     = 'cache Whisper modelu; stahne setup_env.py, prepise se HF_HOME v prepis.py'
    '__pycache__'  = 'vznika automaticky pri behu pythonu'
    'prepis'       = 'testovaci videa - nejde o instalaci, jen data'
    'nul'          = 'omylem vznikly soubor (Windows), smazat'
    'sync.ffs_db'  = 'osobni data / sync, do instalace nepatri'
}
$logNote = 'logy a docasne vysledky prepis_batch.py (*.log, *.docasny.txt) - vznikaji za behu'

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('# PROJEKT-STAV - co projekt potrebuje')
$lines.Add('')
$lines.Add('> Vygenerovano: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm'))
$lines.Add('> Skriptem ``project_state.ps1`` - po kazde instalaci/zmene staci spustit znovu.')
$lines.Add('')
$lines.Add('## Metadata pocitace')
$lines.Add('')
$lines.Add('| Polozka | Hodnota |')
$lines.Add('|---|---|')
$lines.Add("| Pocitac | ``$env:COMPUTERNAME`` |")
$lines.Add("| Uzivatel | ``$env:USERDOMAIN\$env:USERNAME`` |")
$lines.Add("| OS | $($os.Caption) $($os.Version) (build $($os.BuildNumber)) |")
$lines.Add("| CPU | $($cpu.Name.Trim()) |")
$lines.Add("| RAM | $ramGB GB |")
$lines.Add("| GPU | $($gpu -join ', ') |")
$lines.Add('')
$lines.Add('## Nastroje')
$lines.Add('')
$lines.Add('| Nastroj | Cesta |')
$lines.Add('|---|---|')
if ($tools.Count) { $lines.AddRange($tools) } else { $lines.Add('| (nic) | |') }
$lines.Add("| ``.venv`` python | ``$venvPy`` ($venvState) |")
$lines.Add('')
$lines.Add('## Gitignored obsah (co instalace musi vytvorit / co se prenasi)')
$lines.Add('')

foreach ($top in $tops) {
    $items = @($ignored | Where-Object { $_ -eq $top -or $_ -like "$top/*" })
    $full = Join-Path $root ($top -replace '/', '\')
    $isDir = Test-Path -LiteralPath $full -PathType Container
    $size = if ($isDir) { Get-DirSize $full } else { (Get-Item -LiteralPath $full).Length }
    $count = $items.Count
    $lines.Add("### ``$top`` - $(Format-Size $size), $count souboru")
    $note = $notes[$top]
    if (-not $note -and ($top -like '*.log' -or $top -like '*.docasny.txt')) { $note = $logNote }
    if ($note) { $lines.Add(''); $lines.Add("> $note"); $lines.Add('') }

    # podstrom: jen pro mensi adresare, u obrich staci souhrn
    if ($isDir -and $count -le 400) {
        Get-ChildItem -LiteralPath $full -Force | ForEach-Object {
            $csize = if ($_.PSIsContainer) { Get-DirSize $_.FullName } else { $_.Length }
            $cname = $_.Name + $(if ($_.PSIsContainer) { '/' } else { '' })
            $lines.Add("- ``$cname`` - $(Format-Size $csize)")
        }
    } elseif ($isDir) {
        $lines.Add('- ... (vetsi objem - souhrn vyse)')
    }
    $lines.Add('')
}

$lines.Add('## PATH')
$lines.Add('')
$lines.Add('<details><summary>Aktualni PATH</summary>')
$lines.Add('')
foreach ($p in ($env:PATH -split ';' | Where-Object { $_ })) {
    $lines.Add("- ``$p``")
}
$lines.Add('')
$lines.Add('</details>')
$lines.Add('')

$lines -join "`n" | Out-File -FilePath $outFile -Encoding utf8
Write-Host "Vygenerovano: $outFile"
