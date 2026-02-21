# Add Related Notes to the cataclysmic flood file
$folder = 'D:\Obsidian\Main\10 - Clippings'
$file = Get-ChildItem $folder | Where-Object { $_.Name -match "cataclysmic" } | Select-Object -First 1
if ($file) {
    $content = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    # Append Related Notes at end if not already present
    if ($content -notmatch 'Related Notes') {
        $addition = "`n---`n## Related Notes`n- [[MOC - Science & Nature]]`n"
        $content = $content.TrimEnd() + "`n" + $addition
        Set-Content -LiteralPath $file.FullName -Value $content -Encoding UTF8 -NoNewline
        Write-Host "Added Related Notes to: $($file.Name)"
    } else {
        Write-Host "Related Notes already present"
    }
} else {
    Write-Host "File not found"
}
