$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$toolsRoot = Join-Path $projectRoot '.tools'
$flutterRoot = Join-Path $toolsRoot 'flutter'
$flutterBin = Join-Path $flutterRoot 'bin'
$flutterCmd = Join-Path $flutterBin 'flutter.bat'
$defaultAndroidSdkRoot = Join-Path $toolsRoot 'android-sdk'
$userAndroidSdkRoot = [Environment]::GetEnvironmentVariable('ANDROID_HOME', 'User')
$androidSdkRoot = $env:ANDROID_HOME

if ([string]::IsNullOrWhiteSpace($androidSdkRoot)) {
  $androidSdkRoot = $userAndroidSdkRoot
}

if ([string]::IsNullOrWhiteSpace($androidSdkRoot) -or -not (Test-Path $androidSdkRoot)) {
  if (Test-Path $defaultAndroidSdkRoot) {
    $androidSdkRoot = $defaultAndroidSdkRoot
  } else {
    $androidSdkRoot = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
  }
}

if (-not (Test-Path $flutterCmd)) {
  Write-Host "Flutter SDK not found at $flutterRoot" -ForegroundColor Red
  Write-Host "Expected executable: $flutterCmd"
  Write-Host "Run '.\\.codex\\scripts\\install-flutter-sdk.ps1' to install it into the project."
  exit 1
}

$env:FLUTTER_ROOT = $flutterRoot
if (-not $env:PUB_CACHE) {
  $env:PUB_CACHE = Join-Path $env:LOCALAPPDATA 'Pub\Cache'
}

$pathParts = @()
if ($env:Path) {
  $pathParts = $env:Path -split ';'
}

if ($pathParts -notcontains $flutterBin) {
  $env:Path = "$flutterBin;$env:Path"
}

if (Test-Path $androidSdkRoot) {
  $env:ANDROID_HOME = $androidSdkRoot
  $env:ANDROID_SDK_ROOT = $androidSdkRoot

  $androidPathEntries = @(
    (Join-Path $androidSdkRoot 'platform-tools'),
    (Join-Path $androidSdkRoot 'cmdline-tools\latest\bin'),
    (Join-Path $androidSdkRoot 'emulator')
  )

  foreach ($entry in $androidPathEntries) {
    if ((Test-Path $entry) -and ($pathParts -notcontains $entry)) {
      $env:Path = "$entry;$env:Path"
      $pathParts = $env:Path -split ';'
    }
  }
}

Write-Host "Flutter environment ready" -ForegroundColor Green
Write-Host "Project tools: $toolsRoot"
Write-Host "SDK: $flutterRoot"
& $flutterCmd --version

$pubspecPath = Join-Path (Get-Location) 'pubspec.yaml'
if (Test-Path $pubspecPath) {
  Write-Host "Flutter project detected: $pubspecPath"
} else {
  Write-Host "No pubspec.yaml found in $(Get-Location)."
}

Write-Host "Run 'flutter doctor -v' to validate Android/desktop toolchains."
