# Start the Twenty frontend hot-reload dev server (Vite) on http://localhost:3001
#
# Prereq: the backend stack must be running first:
#     cd twenty; docker compose up -d
# The dev server talks to that backend at http://localhost:3000
# (configured in packages/twenty-front/.env -> REACT_APP_SERVER_BASE_URL).
#
# Edit any file under packages/twenty-front/src and the browser updates in ~1s,
# no Docker rebuild. (Rebuild the image only to deploy: cd twenty; docker compose build; docker compose up -d)

$ErrorActionPreference = "Stop"

# Yarn 4 / nx live here (corepack installed to a writable dir, no admin needed)
$env:Path = "C:\Users\tayyab\corepack-bin;" + $env:Path

Set-Location "$PSScriptRoot\packages\twenty-front"
Write-Host "Starting Vite dev server on http://localhost:3001 ..." -ForegroundColor Cyan
npx vite --port 3001 --host
