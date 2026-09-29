# Configures LOCAL isolation only: Flutter -> local API :5001 -> local Docker DB.
# Never copies Hostinger credentials into local env.

$ErrorActionPreference = "Stop"
$flutterRoot = Split-Path $PSScriptRoot -Parent
$backendRoot = "C:\NB\PropKart-Backend"

Copy-Item (Join-Path $flutterRoot "env\local.env.example") (Join-Path $flutterRoot "env\local.env") -Force
Copy-Item (Join-Path $flutterRoot "env\production.env.example") (Join-Path $flutterRoot "env\production.env") -Force
Copy-Item (Join-Path $backendRoot ".env.local.example") (Join-Path $backendRoot ".env.local") -Force

Set-Location $backendRoot
docker compose -f local/docker-compose.yml up -d
node local/apply-schema.mjs
node local/seed.mjs

Write-Host "Local stack configured."
Write-Host "  Flutter: flutter run --dart-define-from-file=env/local.env"
Write-Host "  API:     docker compose -f local/docker-compose.yml up -d  (port 5001)"
Write-Host "  Users:   LocalDev@2026 (local.tc1@propkart.local ACTIVE)"
