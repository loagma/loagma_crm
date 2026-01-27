# Fix Prisma Generate Script
# Run this script as Administrator if the regular command fails

Write-Host "Attempting to fix Prisma generation issue..." -ForegroundColor Yellow

# Navigate to backend directory
Set-Location $PSScriptRoot

# Stop any Node.js processes that might be locking files
Write-Host "Checking for Node.js processes..." -ForegroundColor Yellow
$nodeProcesses = Get-Process -Name node -ErrorAction SilentlyContinue
if ($nodeProcesses) {
    Write-Host "Found $($nodeProcesses.Count) Node.js process(es). Stopping them..." -ForegroundColor Yellow
    $nodeProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# Remove existing Prisma client
if (Test-Path "node_modules\.prisma") {
    Write-Host "Removing existing .prisma folder..." -ForegroundColor Yellow
    Remove-Item -Path "node_modules\.prisma" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

# Also try to remove the specific DLL file if it exists
$dllPath = "node_modules\.prisma\client\query_engine-windows.dll.node"
if (Test-Path $dllPath) {
    Write-Host "Removing locked DLL file..." -ForegroundColor Yellow
    Remove-Item -Path $dllPath -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

# Wait a moment for file handles to release
Start-Sleep -Seconds 2

# Try to generate
Write-Host "Generating Prisma client..." -ForegroundColor Yellow
npx prisma generate

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Prisma client generated successfully!" -ForegroundColor Green
} else {
    Write-Host "❌ Generation failed. Try the following:" -ForegroundColor Red
    Write-Host "1. Close all file explorer windows showing node_modules folder" -ForegroundColor Yellow
    Write-Host "2. Close your IDE/editor (VS Code, etc.)" -ForegroundColor Yellow
    Write-Host "3. Run PowerShell as Administrator and run this script again" -ForegroundColor Yellow
    Write-Host "4. Temporarily exclude node_modules\.prisma from Windows Defender" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor Yellow
    Write-Host "To run as Administrator:" -ForegroundColor Cyan
    Write-Host "  Right-click PowerShell -> Run as Administrator" -ForegroundColor Cyan
    Write-Host "  Then run: cd D:\loagma_crm\backend" -ForegroundColor Cyan
    Write-Host "  Then run: .\fix-prisma-generate.ps1" -ForegroundColor Cyan
}
