Add-Type -AssemblyName System.Net.Http

$apiKey  = "3VjgeLyjhaQU5Lj5cMWCCo5PDD72"
$shopDir = "C:\Users\steph\Claude\Projects\Quality Website\images\shop"

$images = Get-ChildItem -Path $shopDir -Filter "*.jpg" |
          Where-Object { $_.Name -ne "test-preview.jpg" } |
          Sort-Object Name

$total = $images.Count
$i = 0

Write-Host "Clipdrop Remove Text — $total images`n"

foreach ($img in $images) {
    $i++
    Write-Host "[$i/$total] $($img.Name) ..." -NoNewline

    try {
        $client = New-Object System.Net.Http.HttpClient
        $client.DefaultRequestHeaders.Add("x-api-key", $apiKey)

        $content  = New-Object System.Net.Http.MultipartFormDataContent
        $fileBytes = [System.IO.File]::ReadAllBytes($img.FullName)
        $filePart  = New-Object System.Net.Http.ByteArrayContent($fileBytes)
        $filePart.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("image/jpeg")
        $content.Add($filePart, "image_file", $img.Name)

        $response = $client.PostAsync("https://clipdrop-api.co/remove-text/v1", $content).Result

        if ($response.IsSuccessStatusCode) {
            $resultBytes = $response.Content.ReadAsByteArrayAsync().Result
            [System.IO.File]::WriteAllBytes($img.FullName, $resultBytes)
            Write-Host " OK"
        } else {
            $err = $response.Content.ReadAsStringAsync().Result
            Write-Host " FAILED ($($response.StatusCode)) — $err"
        }

        $client.Dispose()
    } catch {
        Write-Host " ERROR: $_"
    }
}

Write-Host "`nAll done! Press Enter to close."
Read-Host
