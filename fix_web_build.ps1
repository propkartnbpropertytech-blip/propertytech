# fix_web_build.ps1
# Run this script if you run build_runner and experience JS integer literal compilation errors when running on web.

$filePath = "lib/core/storage/isar_collections.g.dart"

if (Test-Path $filePath) {
    Write-Host "🔧 Fixing JS integer literals in $filePath..." -ForegroundColor Cyan

    (Get-Content $filePath) -replace '1318305215323522509', '1318305215323522560' `
      -replace '3268401673993471357', '3268401673993471488' `
      -replace '8271700807818507403', '8271700807818507264' `
      -replace '7980756281068083239', '7980756281068083200' `
      -replace '4721984852078906678', '4721984852078906368' `
      -replace '435823299237027808', '435823299237027840' `
      -replace '886259216879823833', '886259216879823872' `
      -replace '4502856345066684593', '4502856345066684416' `
      -replace '8922081633273292290', '8922081633273292800' `
      -replace '7985840613772203549', '7985840613772204032' `
      -replace '5416242803166401319', '5416242803166401536' | Set-Content $filePath

    Write-Host "✅ Successfully resolved float representation issues!" -ForegroundColor Green
} else {
    Write-Warning "Could not find $filePath. Run build_runner first."
}
