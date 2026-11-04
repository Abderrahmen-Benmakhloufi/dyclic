# ==============================================================================
# Automated Export Script for LectureAide APKs
# ==============================================================================

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Démarrage de l'exportation des APKs LectureAide..." -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Bump build number in pubspec.yaml
$pubspecPath = Join-Path $ScriptDir "app\pubspec.yaml"
$content = Get-Content $pubspecPath -Raw
if ($content -match "version:\s*(\d+\.\d+\.\d+)\+(\d+)") {
    $ver = $matches[1]
    $buildNum = [int]$matches[2] + 1
    $newVersion = "$ver+$buildNum"
    $content = $content -replace "version:\s*\d+\.\d+\.\d+\+\d+", "version: $newVersion"
    Set-Content -Path $pubspecPath -Value $content -NoNewline
    Write-Host "Version incrémentée à : $newVersion" -ForegroundColor Green
} else {
    Write-Host "Impossible de lire la version dans pubspec.yaml" -ForegroundColor Yellow
}

# 2. Clean stale intermediate artifacts
Write-Host "Nettoyage des fichiers temporaires et du cache..." -ForegroundColor Yellow
Remove-Item -Recurse -Force "$ScriptDir\app\build\app\intermediates\flutter\release" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$ScriptDir\app\build\app\outputs\flutter-apk" -ErrorAction SilentlyContinue

# 3. Build APKs with split-per-abi
Write-Host "Compilation Flutter (split-per-abi)..." -ForegroundColor Yellow
Push-Location "$ScriptDir\app"
try {
    flutter build apk --split-per-abi
} finally {
    Pop-Location
}

# 4. Copy APKs to root
Write-Host "Copie des APKs vers la racine du projet..." -ForegroundColor Yellow
$outputs = "$ScriptDir\app\build\app\outputs\flutter-apk"

Copy-Item "$outputs\app-arm64-v8a-release.apk" "$ScriptDir\LectureAide-arm64-v8a.apk" -Force
Copy-Item "$outputs\app-armeabi-v7a-release.apk" "$ScriptDir\LectureAide-armeabi-v7a.apk" -Force
Copy-Item "$outputs\app-x86_64-release.apk" "$ScriptDir\LectureAide-x86_64.apk" -Force

# 5. Summary
Write-Host "EXPORTATION TERMINÉE AVEC SUCCÈS !" -ForegroundColor Green
Get-Item "$ScriptDir\LectureAide-*.apk" | Select-Object Name, @{Name="Taille (MB)"; Expression={[math]::Round($_.Length / 1MB, 2)}}, LastWriteTime | Format-Table -AutoSize
