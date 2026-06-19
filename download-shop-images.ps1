# QSM Shop Image Downloader
# Run this script once to download all product images from B2Sign.
# They'll be saved to images\shop\ inside your Quality Website folder.

$folder = Split-Path -Parent $MyInvocation.MyCommand.Path
$outDir = Join-Path $folder "images\shop"

if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

$images = @(
    @{ id="vinyl-13oz";        url="https://qualitysignandmarquee.bs.run/image/thumb/240430/HrhLAGOx-s1000.jpg" },
    @{ id="vinyl-18oz";        url="https://qualitysignandmarquee.bs.run/image/thumb/240430/iQrOVCt4-s1000.jpg" },
    @{ id="mesh-banner";       url="https://qualitysignandmarquee.bs.run/image/thumb/240430/WvsHtoYW-s1000.jpg" },
    @{ id="fabric-9oz";        url="https://qualitysignandmarquee.bs.run/image/thumb/240228/s4X77Aea-s1000.jpg" },
    @{ id="tension-fabric";    url="https://qualitysignandmarquee.bs.run/image/thumb/240228/XWKEnh55-s1000.jpg" },
    @{ id="adv-flags";         url="https://qualitysignandmarquee.bs.run/image/thumb/240314/K0PPnkrc-s1000.jpg" },
    @{ id="retractable-stand"; url="https://qualitysignandmarquee.bs.run/image/thumb/240327/q6ZwMnsh-s1000.jpg" },
    @{ id="step-repeat";       url="https://qualitysignandmarquee.bs.run/image/thumb/240404/iYFM7ODc-s1000.jpg" },
    @{ id="a-frame";           url="https://qualitysignandmarquee.bs.run/image/thumb/240228/O8gZZ9tK-s1000.jpg" },
    @{ id="custom-tents";      url="https://qualitysignandmarquee.bs.run/image/thumb/250703/w1guOGMT-s1000.jpg" },
    @{ id="table-throws";      url="https://qualitysignandmarquee.bs.run/image/thumb/240228/slETs0ae-s1000.jpg" },
    @{ id="popup-displays";    url="https://qualitysignandmarquee.bs.run/image/thumb/240322/EUSNoLa3-s1000.jpg" },
    @{ id="seg-products";      url="https://qualitysignandmarquee.bs.run/image/thumb/240322/cfbv67nS-s1000.jpg" },
    @{ id="coroplast";         url="https://qualitysignandmarquee.bs.run/image/thumb/260519/eWxbxiSa-s1000.jpg" },
    @{ id="foam-board";        url="https://qualitysignandmarquee.bs.run/image/thumb/240228/lxjHrirW-s1000.jpg" },
    @{ id="aluminum-signs";    url="https://qualitysignandmarquee.bs.run/image/thumb/240228/rzwi0OFy-s1000.jpg" },
    @{ id="vehicle-magnets";   url="https://qualitysignandmarquee.bs.run/image/thumb/240228/Sk2xQQ9j-s1000.jpg" },
    @{ id="canvas-print";      url="https://qualitysignandmarquee.bs.run/image/thumb/240228/HSEyGxhC-s1000.jpg" },
    @{ id="dry-erase";         url="https://qualitysignandmarquee.bs.run/image/thumb/241119/itboM40s-s1000.jpg" }
)

$headers = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36"
    "Referer"    = "https://qualitysignandmarquee.bs.run/"
}

$ok = 0
$fail = 0

foreach ($img in $images) {
    $dest = Join-Path $outDir "$($img.id).jpg"
    try {
        Invoke-WebRequest -Uri $img.url -Headers $headers -OutFile $dest -TimeoutSec 20 -ErrorAction Stop
        $size = [math]::Round((Get-Item $dest).Length / 1KB)
        Write-Host "OK  $($img.id) ($($size)KB)" -ForegroundColor Green
        $ok++
    } catch {
        Write-Host "FAIL $($img.id): $_" -ForegroundColor Red
        $fail++
    }
}

Write-Host ""
Write-Host "Done: $ok downloaded, $fail failed." -ForegroundColor Cyan
Write-Host "Images saved to: $outDir"
Write-Host ""
Write-Host "Go back to Claude and say 'images are downloaded' to continue processing."
