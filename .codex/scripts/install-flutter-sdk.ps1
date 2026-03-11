$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$toolsRoot = Join-Path $projectRoot '.tools'
$downloadsRoot = Join-Path $toolsRoot 'downloads\flutter'
$flutterRoot = Join-Path $toolsRoot 'flutter'
$flutterBin = Join-Path $flutterRoot 'bin'
$legacyFlutterRoot = Join-Path $env:USERPROFILE 'develop\flutter'
$legacyFlutterBin = Join-Path $legacyFlutterRoot 'bin'

New-Item -ItemType Directory -Force -Path $toolsRoot | Out-Null
New-Item -ItemType Directory -Force -Path $downloadsRoot | Out-Null

if ((Test-Path $legacyFlutterRoot) -and -not (Test-Path $flutterRoot)) {
  Move-Item -Path $legacyFlutterRoot -Destination $flutterRoot
}

if (-not (Test-Path (Join-Path $flutterRoot 'bin\flutter.bat'))) {
  $release = Invoke-RestMethod -Uri 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json'
  $current = $release.releases | Where-Object { $_.hash -eq $release.current_release.stable } | Select-Object -First 1
  $zipPath = Join-Path $downloadsRoot ([IO.Path]::GetFileName($current.archive))
  $downloadUrl = "https://storage.googleapis.com/flutter_infra_release/releases/$($current.archive)"

  Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

  $actualHash = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($actualHash -ne $current.sha256.ToLowerInvariant()) {
    throw "SHA256 mismatch. Expected $($current.sha256), got $actualHash"
  }

  if (Test-Path $flutterRoot) {
    Remove-Item $flutterRoot -Recurse -Force
  }

  Expand-Archive -Path $zipPath -DestinationPath $toolsRoot -Force
}

$pathEntries = @()
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath) {
  $pathEntries = $userPath -split ';'
}

$pathEntries = $pathEntries | Where-Object { $_ -and ($_ -ne $legacyFlutterBin) -and ($_ -ne $flutterBin) }
$pathEntries = ,$flutterBin + $pathEntries

[Environment]::SetEnvironmentVariable('FLUTTER_ROOT', $flutterRoot, 'User')
[Environment]::SetEnvironmentVariable('Path', ($pathEntries -join ';'), 'User')

$env:FLUTTER_ROOT = $flutterRoot
$env:Path = "$flutterBin;$env:Path"

Write-Host "Flutter SDK ready at $flutterRoot"
