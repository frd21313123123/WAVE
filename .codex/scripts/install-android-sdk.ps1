$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$toolsRoot = Join-Path $projectRoot '.tools'
$downloadRoot = Join-Path $toolsRoot 'downloads\android-sdk'
$legacySdkRoot = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$secondaryLegacySdkRoot = 'D:\Android\Sdk'
$sdkRoot = Join-Path $toolsRoot 'android-sdk'
$cmdlineRoot = Join-Path $sdkRoot 'cmdline-tools'
$latestRoot = Join-Path $cmdlineRoot 'latest'
$sdkManager = Join-Path $latestRoot 'bin\sdkmanager.bat'
$zipUrl = 'https://dl.google.com/android/repository/commandlinetools-win-14742923_latest.zip'
$expectedSha1 = '16b3f45ddb3d85ea6bbe6a1c0b47146daf0db450'
$legacyPathEntries = @(
  (Join-Path $legacySdkRoot 'platform-tools'),
  (Join-Path $legacySdkRoot 'cmdline-tools\latest\bin'),
  (Join-Path $secondaryLegacySdkRoot 'platform-tools'),
  (Join-Path $secondaryLegacySdkRoot 'cmdline-tools\latest\bin')
)

New-Item -ItemType Directory -Force -Path $toolsRoot | Out-Null
New-Item -ItemType Directory -Force -Path $downloadRoot | Out-Null

foreach ($candidateRoot in @($secondaryLegacySdkRoot, $legacySdkRoot)) {
  if ((Test-Path $candidateRoot) -and ($candidateRoot -ne $sdkRoot) -and -not (Test-Path $sdkRoot)) {
    New-Item -ItemType Directory -Force -Path (Split-Path $sdkRoot -Parent) | Out-Null
    Move-Item -Path $candidateRoot -Destination $sdkRoot
    break
  }
}

if (-not (Test-Path $sdkManager)) {
  $zipPath = Join-Path $downloadRoot 'commandlinetools-win-14742923_latest.zip'
  $extractRoot = Join-Path $downloadRoot 'cmdline-tools'

  if (Test-Path $extractRoot) {
    Remove-Item $extractRoot -Recurse -Force
  }

  New-Item -ItemType Directory -Force -Path $cmdlineRoot | Out-Null
  Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath

  $actualSha1 = (Get-FileHash -Path $zipPath -Algorithm SHA1).Hash.ToLowerInvariant()
  if ($actualSha1 -ne $expectedSha1) {
    throw "SHA1 mismatch. Expected $expectedSha1, got $actualSha1"
  }

  Expand-Archive -Path $zipPath -DestinationPath $extractRoot -Force

  if (Test-Path $latestRoot) {
    Remove-Item $latestRoot -Recurse -Force
  }

  New-Item -ItemType Directory -Force -Path $latestRoot | Out-Null
  Move-Item -Path (Join-Path $extractRoot 'cmdline-tools\*') -Destination $latestRoot -Force
}

$pathEntries = @()
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath) {
  $pathEntries = $userPath -split ';'
}

$wantedEntries = @(
  (Join-Path $sdkRoot 'platform-tools'),
  (Join-Path $latestRoot 'bin')
)

foreach ($entry in $wantedEntries) {
  $pathEntries = $pathEntries | Where-Object { $_ -and ($_ -ne $entry) -and ($_ -notin $legacyPathEntries) }
  if ($pathEntries -notcontains $entry) {
    $pathEntries = ,$entry + $pathEntries
  }
}

[Environment]::SetEnvironmentVariable('ANDROID_HOME', $sdkRoot, 'User')
[Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', $sdkRoot, 'User')
[Environment]::SetEnvironmentVariable('Path', ($pathEntries -join ';'), 'User')

$env:ANDROID_HOME = $sdkRoot
$env:ANDROID_SDK_ROOT = $sdkRoot
$env:Path = "$($wantedEntries -join ';');$env:Path"

Write-Host "Installing Android SDK packages into $sdkRoot"
& $sdkManager --sdk_root=$sdkRoot 'platform-tools' 'platforms;android-36' 'build-tools;36.0.0'

$licenseInput = @('y','y','y','y','y','y','y','y','y','y') -join [Environment]::NewLine
$licenseInput | & $sdkManager --sdk_root=$sdkRoot --licenses | Out-Null

$adbPath = Join-Path $sdkRoot 'platform-tools\adb.exe'
if (-not (Test-Path $adbPath)) {
  $platformToolsZip = Join-Path $downloadRoot 'platform-tools-latest-windows.zip'
  $platformToolsExtractRoot = Join-Path $downloadRoot 'platform-tools'
  $platformToolsUrl = 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip'
  $platformToolsTarget = Join-Path $sdkRoot 'platform-tools'

  if (Test-Path $platformToolsExtractRoot) {
    Remove-Item $platformToolsExtractRoot -Recurse -Force
  }

  Invoke-WebRequest -Uri $platformToolsUrl -OutFile $platformToolsZip
  Expand-Archive -Path $platformToolsZip -DestinationPath $platformToolsExtractRoot -Force

  if (Test-Path $platformToolsTarget) {
    Remove-Item $platformToolsTarget -Recurse -Force
  }

  Move-Item -Path (Join-Path $platformToolsExtractRoot 'platform-tools') -Destination $platformToolsTarget -Force
}

Write-Host "Android SDK ready at $sdkRoot"
