param(
    [string] $RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Push-Location $RepoRoot
try {
    Write-Host "[RUN] python -m unittest tests/test_project_contracts.py" -ForegroundColor Cyan
    python -m unittest tests/test_project_contracts.py
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    Write-Host "[RUN] tools/test-public-boundary.ps1" -ForegroundColor Cyan
    & (Join-Path $RepoRoot 'tools/test-public-boundary.ps1') -RepoRoot $RepoRoot
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}
