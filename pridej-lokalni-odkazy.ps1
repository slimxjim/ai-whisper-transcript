# pridej-lokalni-odkazy.ps1
# Pro každý Drive/YouTube odkaz v HTML přidá odkaz na lokální video soubor.
# Mapování "klíč (ID z URL) -> vzor názvu souboru" je v mapovani-videa.json.
# Vzor se porovnává s názvem souboru bez diakritiky, malými písmeny.
#
# Použití:
#   .\pridej-lokalni-odkazy.ps1                      # výchozí soubory vedle skriptu
#   .\pridej-lokalni-odkazy.ps1 -HtmlPath "C:\jiný\plan.html" -Root "D:\videa"
#
# Skript je idempotentní – při opakovaném spuštění nejdřív odstraní
# dříve vložené lokální odkoazy a pak je znovu přidá.

param(
  [string]$HtmlPath = "$PSScriptRoot\plan-studia.html",
  [string]$Root     = "C:\HOME\DATA\Rekvalifikační kurz",
  [string]$MapPath  = "$PSScriptRoot\mapovani-videa.json"
)

$ErrorActionPreference = 'Stop'

function ConvertTo-Normalized([string]$s) {
  $d = $s.Normalize([Text.NormalizationForm]::FormD)
  $sb = New-Object Text.StringBuilder
  foreach ($ch in $d.ToCharArray()) {
    if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne 'NonSpacingMark') {
      [void]$sb.Append($ch)
    }
  }
  ($sb.ToString().ToLower() -replace '[^a-z0-9]+', ' ').Trim() -replace '\s+', ' '
}

# 1) Načti mapování
$map = Get-Content $MapPath -Raw -Encoding UTF8 | ConvertFrom-Json
$patterns = @{}
foreach ($p in $map.PSObject.Properties) {
  if ($p.Value) { $patterns[$p.Name] = [string]$p.Value }
}

# 2) Projdi videosoubory a postav index normalizovaných názvů
$exts = '.mp4', '.mkv', '.webm', '.avi', '.mov', '.mpg', '.mpeg'
$files = Get-ChildItem $Root -Recurse -File -ErrorAction SilentlyContinue |
         Where-Object { $exts -contains $_.Extension.ToLower() }

$index = @{}
foreach ($f in $files) {
  $norm = ConvertTo-Normalized $f.BaseName
  if (-not $index.ContainsKey($norm)) { $index[$norm] = $f }
  else { $index[$norm] = @($index[$norm]) + $f }   # duplicitní názvy
}

function Find-LocalFile([string]$pattern) {
  $rx = '(?<![a-z0-9])' + [regex]::Escape((ConvertTo-Normalized $pattern)) + '(?![a-z0-9])'
  $hits = @()
  foreach ($k in $index.Keys) {
    if ($k -match $rx) {
      $v = $index[$k]
      if ($v -is [array]) { $hits += $v } else { $hits += $v }
    }
  }
  if ($hits.Count -eq 0) { return $null }
  # stejný název souboru na více místech (kopie) není nejednoznačnost – vezmi první
  $names = $hits | ForEach-Object { $_.Name } | Sort-Object -Unique
  if ($names.Count -gt 1) {
    Write-Warning "Vzor '$pattern' odpovídá $($hits.Count) různým souborům – přeskočeno."
    return $null
  }
  return ($hits | Sort-Object FullName)[0]
}

function ConvertTo-FileUri([string]$path) {
  $segments = $path -replace '\\', '/' -split '/'
  $enc = ($segments | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/'
  $enc = $enc -replace '^([A-Za-z])%3A', '$1:'   # zpátky dvojtečku za písmenem disku
  return 'file:///' + $enc
}

# 3) Načti HTML a odstraň dříve vložené prvky (lokální odkoazy i ikony)
$enc = New-Object Text.UTF8Encoding($false)
$html = [IO.File]::ReadAllText($HtmlPath, $enc)
$html = [regex]::Replace($html, '<span class="local-wrap"[^>]*>.*?</span>', '', 'Singleline')
$html = [regex]::Replace($html, '<img class="link-icon"[^>]*>', '')

# 4) Procházej kotvy a vkládej ikony a lokální odkazy
$added = 0; $icons = 0; $unmapped = @(); $nomatch = @()
$sb = New-Object Text.StringBuilder
$pos = 0
$anchorRx = [regex]'<a\b[^>]*href="([^"]+)"[^>]*>.*?</a>'

function Get-FaviconDomain([string]$href) {
  foreach ($d in 'drive.google.com', 'youtube.com', 'youtu.be', 'meet.google.com') {
    if ($href.Contains($d)) { return $d }
  }
  return $null
}

$emojiMap = @{
  '.mp4'='🎬'; '.mkv'='🎬'; '.webm'='🎬'; '.avi'='🎬'; '.mov'='🎬'; '.mpg'='🎬'; '.mpeg'='🎬'
  '.mp3'='🎵'; '.wav'='🎵'; '.flac'='🎵'
  '.jpg'='🖼️'; '.jpeg'='🖼️'; '.png'='🖼️'; '.gif'='🖼️'
  '.pdf'='📄'
}
function Get-FileEmoji([string]$path) {
  $e = [IO.Path]::GetExtension($path).ToLower()
  if ($emojiMap.ContainsKey($e)) { return $emojiMap[$e] }
  return '📄'
}

foreach ($m in $anchorRx.Matches($html)) {
  $href = $m.Groups[1].Value
  $domain = Get-FaviconDomain $href

  # lokální soubor: jen pro drive/youtube odkazy s mapováním
  $localInject = ''
  if ($href -match 'drive\.google\.com/file/d/|youtube\.com/watch|youtu\.be/') {
    $key = $null
    foreach ($k in $patterns.Keys) { if ($href.Contains($k)) { $key = $k; break } }
    if ($key) {
      $file = Find-LocalFile $patterns[$key]
      if ($file) {
        $uri  = ConvertTo-FileUri $file.FullName
        $name = [System.Net.WebUtility]::HtmlEncode($file.Name)
        $emoji = Get-FileEmoji $file.FullName
        $localInject = ' <span class="local-wrap">· <a class="local-file" href="' + $uri + '" title="Otevřít lokální soubor"><span class="fi">' + $emoji + '</span> ' + $name + '</a></span>'
        $added++
      } else {
        $nomatch += "$key -> $($patterns[$key])"
      }
    } else {
      $unmapped += $href
    }
  }

  $favImg = ''
  if ($domain) {
    $favImg = '<img class="link-icon" src="https://www.google.com/s2/favicons?domain=' + $domain + '&sz=32" alt="" width="16" height="16">'
    $icons++
  }

  if (-not $favImg -and -not $localInject) { continue }

  # přestav kotvu: ikona hned za otevírací tag, lokální odkaz za </a>
  $val = $m.Value
  $openEnd = $val.IndexOf('>') + 1
  $openTag = $val.Substring(0, $openEnd)
  $inner = $val.Substring($openEnd, $val.Length - $openEnd - 4)   # bez '</a>'
  $newA = $openTag + $favImg + $inner + '</a>' + $localInject

  [void]$sb.Append($html.Substring($pos, $m.Index - $pos))
  [void]$sb.Append($newA)
  $pos = $m.Index + $m.Length
}

[void]$sb.Append($html.Substring($pos))
[IO.File]::WriteAllText($HtmlPath, $sb.ToString(), $enc)

Write-Host "`nHotovo: $icons ikon, $added lokálních odkazů v $HtmlPath"
if ($unmapped.Count) { Write-Host "`nBez mapování (přidejte do mapovani-videa.json):"; $unmapped | ForEach-Object { Write-Host "  $_" } }
if ($nomatch.Count)  { Write-Host "`nMapováno, ale soubor nenalezen:"; $nomatch  | ForEach-Object { Write-Host "  $_" } }
