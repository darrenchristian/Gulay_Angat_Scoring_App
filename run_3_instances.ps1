# GulayAngat ScoreSync - Multi-Instance Launch Script
# Launches 3 testing windows side-by-side:
# Window 1: Admin
# Window 2: Judge 1
# Window 3: Judge 2

$exe = "build\windows\x64\runner\Debug\scoring_app.exe"

# Terminate any previously running instances
Get-Process -Name scoring_app -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 400

if (-not (Test-Path $exe)) {
    Write-Host "Executable not found. Building Windows debug app first..." -ForegroundColor Cyan
    flutter build windows --debug
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Starting Instance 1 (Admin)..." -ForegroundColor Green
Start-Process $exe -ArgumentList "--instance=1 --role=admin"
Start-Sleep -Milliseconds 800

Write-Host "Starting Instance 2 (Judge 1)..." -ForegroundColor Yellow
Start-Process $exe -ArgumentList "--instance=2 --role=judge"
Start-Sleep -Milliseconds 800

Write-Host "Starting Instance 3 (Judge 2)..." -ForegroundColor Magenta
Start-Process $exe -ArgumentList "--instance=3 --role=judge"

Write-Host "`nAll 3 instances launched successfully!" -ForegroundColor Green
Write-Host "- Instance 1 (Left): Admin view" -ForegroundColor Gray
Write-Host "- Instance 2 (Top-Right): Judge 1 view" -ForegroundColor Gray
Write-Host "- Instance 3 (Bottom-Right): Judge 2 view" -ForegroundColor Gray
