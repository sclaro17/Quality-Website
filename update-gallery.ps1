# =====================================================================
#  Quality Sign & Marquee - Update Gallery
#  Scans the images\ category folders and rewrites the photo gallery
#  in index.html. Existing photos and their captions are kept exactly;
#  any new photos you dropped in are added automatically.
#
#  You do NOT need to edit this file. Just double-click "Update Gallery.bat".
# =====================================================================

$ErrorActionPreference = 'Stop'
$root  = Split-Path -Parent $MyInvocation.MyCommand.Path
$index = Join-Path $root 'index.html'

Write-Host ''
Write-Host '  Quality Sign & Marquee - Update Gallery' -ForegroundColor Yellow
Write-Host '  ----------------------------------------'

if (-not (Test-Path -LiteralPath $index)) {
  Write-Host "  ERROR: Could not find index.html next to this tool." -ForegroundColor Red
  return
}

$cats = [ordered]@{
  'marquees'        = 'Marquee'
  'in-theatre'      = 'In-Theatre'
  'custom-displays' = 'Custom Display'
  'conventions'     = 'Convention'
  'fulfillment'     = 'Fulfillment'
}
$headers = @{
  'marquees'='Marquees'; 'in-theatre'='In-Theatre Displays'
  'custom-displays'='Custom Displays'; 'conventions'='Conventions'; 'fulfillment'='Fulfillment'
}
$exts = @('.jpg','.jpeg','.png','.webp','.gif')
$acr  = @('amc','cmx','na','qsm','imax','xd','rpx','3d','4dx','iset','nailba','wb','usa','ny','la')

function Tidy([string]$file) {
  $b = [IO.Path]::GetFileNameWithoutExtension($file)
  $b = $b -replace '[_-]',' '
  $b = ($b -replace '\s+',' ').Trim()
  $words = $b -split ' '
  $out = foreach ($w in $words) {
    if ($w.Length -eq 0) { continue }
    if ($acr -contains $w.ToLower()) { $w.ToUpper() }
    else { $w.Substring(0,1).ToUpper() + $w.Substring(1).ToLower() }
  }
  ($out -join ' ')
}
function HtmlEsc([string]$s) {
  ($s -replace '&','&amp;') -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;'
}

$template = @'
      <div class="gallery-item" data-category="@@CAT@@" tabindex="0" role="button" aria-label="@@CAP@@">
        <img src="images/@@CAT@@/@@SRC@@" loading="lazy"
             alt="@@CAP@@"
             onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
        <div class="gallery-placeholder" style="display:none">
          <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="m21 15-5-5L5 21"/></svg>
          @@LABEL@@
        </div>
        <div class="gallery-overlay"><span class="gallery-caption">@@CAP@@</span></div>
      </div>
'@
$template = $template -replace "`r",''

$text = [IO.File]::ReadAllText($index)

$m = [regex]::Match($text, '(?s)(<!--GALLERY-AUTO-START[^>]*-->)(.*?)(<!--GALLERY-AUTO-END-->)')
if (-not $m.Success) {
  Write-Host "  ERROR: gallery markers not found in index.html. No changes made." -ForegroundColor Red
  return
}
$region = $m.Groups[2].Value

$existing = @{}
$order = [ordered]@{}
foreach ($c in $cats.Keys) { $order[$c] = New-Object System.Collections.ArrayList }

$itemRx = [regex]::new('(?s)<div class="gallery-item".*?</div>\s*</div>')
foreach ($it in $itemRx.Matches($region)) {
  $block = $it.Value
  $sm = [regex]::Match($block, 'src="images/([^"]+)"')
  $cm = [regex]::Match($block, 'data-category="([^"]+)"')
  if (-not $sm.Success -or -not $cm.Success) { continue }
  $cat = $cm.Groups[1].Value
  $key = [uri]::UnescapeDataString($sm.Groups[1].Value)
  $existing[$key] = '      ' + ($block.Trim() -replace "`r",'')
  if ($order.Contains($cat)) { [void]$order[$cat].Add($key) }
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.Append("`n")
$added = 0
foreach ($cat in $cats.Keys) {
  [void]$sb.Append("      <!-- $($headers[$cat]) -->`n")
  $folder = Join-Path $root ("images\" + $cat)
  $files = @()
  if (Test-Path -LiteralPath $folder) {
    $files = Get-ChildItem -LiteralPath $folder -File |
             Where-Object { $exts -contains $_.Extension.ToLower() } |
             Select-Object -ExpandProperty Name
  }
  $used = @{}
  foreach ($key in $order[$cat]) {
    $fn = ($key -split '/')[-1]
    if ($files -contains $fn) {
      [void]$sb.Append($existing[$key] + "`n")
      $used[$fn] = $true
    }
  }
  foreach ($fn in ($files | Sort-Object)) {
    if ($used.ContainsKey($fn)) { continue }
    $cap = HtmlEsc (Tidy $fn)
    $src = [uri]::EscapeDataString($fn)
    $block = $template.Replace('@@CAT@@',$cat).Replace('@@SRC@@',$src).Replace('@@LABEL@@',$cats[$cat]).Replace('@@CAP@@',$cap)
    [void]$sb.Append($block + "`n")
    $added++
    Write-Host ("  + added: {0}  ->  {1}" -f $fn, (Tidy $fn)) -ForegroundColor Green
  }
  [void]$sb.Append("`n")
}
[void]$sb.Append('      ')
$newRegion = $sb.ToString()

if (($newRegion -replace "`r",'') -eq ($region -replace "`r",'')) {
  Write-Host "  No new photos found. Gallery already up to date." -ForegroundColor Cyan
  return
}

[IO.File]::Copy($index, "$index.bak", $true)
$newText = $text.Substring(0, $m.Groups[2].Index) + $newRegion + $text.Substring($m.Groups[2].Index + $m.Groups[2].Length)
$utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($index, $newText, $utf8)

Write-Host ''
Write-Host ("  Done. Added {0} new photo(s)." -f $added) -ForegroundColor Yellow
Write-Host "  A backup of the previous index.html was saved as index.html.bak"
Write-Host ''
Write-Host "  NEXT: open GitHub Desktop, then Commit to main, then Push origin."
Write-Host ''
