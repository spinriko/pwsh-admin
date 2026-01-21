$source = "C:\code\pwsh-admin"
$target = "$env:USERPROFILE\OneDrive\Documents\PowerShell\Modules\pwsh-admin"

Write-Host "Deploying pwsh-admin module..." -ForegroundColor Cyan

# Remove old module folder if it exists
if (Test-Path $target) {
    Write-Host "Removing existing module at $target" -ForegroundColor Yellow
    Remove-Item -Path $target -Recurse -Force
}

# Recreate module folder
New-Item -ItemType Directory -Path $target -Force | Out-Null

# Copy fresh module files
Copy-Item -Path "$source\*" -Destination $target -Recurse -Force

Write-Host "Deployment complete." -ForegroundColor Green
