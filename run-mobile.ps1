[CmdletBinding()]
param(
    [string]$AvdName = "wave_api35",
    [string]$PackageName = "com.wave.messenger",
    [string]$SystemImage = "system-images;android-35;default;x86_64",
    [string]$NdkVersion = "28.2.13676358",
    [string]$CMakeVersion = "3.22.1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$FlutterRoot = Join-Path $RepoRoot "wave_flutter"
$AndroidRoot = Join-Path $FlutterRoot "android"
$LocalPropertiesPath = Join-Path $AndroidRoot "local.properties"
$LogsRoot = Join-Path $RepoRoot "logs"
$EmulatorLog = Join-Path $LogsRoot "mobile-emulator.log"
$EmulatorErrLog = Join-Path $LogsRoot "mobile-emulator.err.log"
$ServerBaseUrl = "http://45.12.70.75:3000"

function Write-Step {
    param([string]$Message)
    Write-Host "[INFO] $Message"
}

function Write-WarnMessage {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Get-LocalProperty {
    param(
        [string]$Path,
        [string]$Key
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing local.properties: $Path"
    }

    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match "^\s*${Key}\s*=(.*)$") {
            return ($Matches[1].Trim() -replace "\\\\", "\")
        }
    }

    throw "Property '$Key' was not found in $Path"
}

function Assert-File {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required file was not found: $Path"
    }
}

function Install-SdkPackage {
    param(
        [string]$SdkManager,
        [string]$PackageId
    )

    Write-Step "Installing Android package '$PackageId'"
    'y', 'y', 'y', 'y', 'y' | & $SdkManager $PackageId | Out-Host
}

function Ensure-SdkPackageByPath {
    param(
        [string]$SdkManager,
        [string]$CheckPath,
        [string]$PackageId
    )

    if (Test-Path -LiteralPath $CheckPath) {
        return
    }

    Install-SdkPackage -SdkManager $SdkManager -PackageId $PackageId
}

function Set-AvdConfigValues {
    param(
        [string]$ConfigPath,
        [hashtable]$Values
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    if (Test-Path -LiteralPath $ConfigPath) {
        foreach ($line in Get-Content -LiteralPath $ConfigPath) {
            $lines.Add($line)
        }
    }

    foreach ($key in $Values.Keys) {
        $newLine = "$key=$($Values[$key])"
        $updated = $false
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match ("^" + [regex]::Escape($key) + "=")) {
                $lines[$i] = $newLine
                $updated = $true
                break
            }
        }
        if (-not $updated) {
            $lines.Add($newLine)
        }
    }

    Set-Content -LiteralPath $ConfigPath -Value $lines -Encoding ASCII
}

function Ensure-Avd {
    param(
        [string]$AvdManager,
        [string]$AvdName,
        [string]$SystemImage
    )

    $avdList = & $AvdManager list avd | Out-String
    if ($avdList -notmatch "(?m)^\s*Name:\s*$([regex]::Escape($AvdName))\s*$") {
        Write-Step "Creating AVD '$AvdName'"
        'no' | & $AvdManager create avd -n $AvdName -k $SystemImage -d "pixel_7" | Out-Host
    }

    $configPath = Join-Path $env:USERPROFILE ".android\avd\$AvdName.avd\config.ini"
    Assert-File -Path $configPath

    Set-AvdConfigValues -ConfigPath $configPath -Values @{
        "avd.id" = $AvdName
        "avd.name" = $AvdName
        "disk.dataPartition.size" = "512M"
        "hw.sdCard" = "no"
        "sdcard.size" = "32 MB"
    }
}

function Get-EmulatorSerial {
    param([string]$Adb)

    $lines = & $Adb devices
    foreach ($line in $lines) {
        if ($line -match "^(emulator-\d+)\s+(\w+)$") {
            return @{
                Serial = $Matches[1]
                State = $Matches[2]
            }
        }
    }

    return $null
}

function Ensure-Emulator {
    param(
        [string]$Adb,
        [string]$EmulatorPath,
        [string]$AvdName
    )

    $drive = Get-PSDrive C
    if ($drive.Free -lt 1.5GB) {
        $freeGb = [math]::Round($drive.Free / 1GB, 2)
        throw "Need at least 1.5 GB free on C: to start the emulator. Current free space: $freeGb GB."
    }

    $existing = Get-EmulatorSerial -Adb $Adb
    if ($null -eq $existing) {
        Write-Step "Starting Android emulator '$AvdName'"
        Start-Process -FilePath $EmulatorPath `
            -ArgumentList "-avd $AvdName -no-snapshot -no-boot-anim -gpu swiftshader_indirect -no-audio" `
            -RedirectStandardOutput $EmulatorLog `
            -RedirectStandardError $EmulatorErrLog | Out-Null
    } else {
        Write-Step "Reusing running emulator $($existing.Serial)"
    }

    $deadline = (Get-Date).AddMinutes(6)
    do {
        Start-Sleep -Seconds 5
        $current = Get-EmulatorSerial -Adb $Adb
        if ($null -ne $current -and $current.State -eq "device") {
            break
        }
    } while ((Get-Date) -lt $deadline)

    if ($null -eq $current -or $current.State -ne "device") {
        if (Test-Path -LiteralPath $EmulatorLog) {
            Get-Content -LiteralPath $EmulatorLog -Tail 120 | Out-Host
        }
        throw "Android emulator did not become ready in time."
    }

    do {
        Start-Sleep -Seconds 5
        $bootCompleted = (& $Adb -s $current.Serial shell getprop sys.boot_completed 2>$null).Trim()
    } while ((Get-Date) -lt $deadline -and $bootCompleted -ne "1")

    if ($bootCompleted -ne "1") {
        throw "Android emulator boot did not finish in time."
    }

    return $current.Serial
}

function Build-Apk {
    param(
        [string]$FlutterCmd,
        [string]$FlutterPath,
        [string]$Gradlew,
        [string]$AndroidPath
    )

    Write-Step "Running flutter pub get"
    & $FlutterCmd pub get | Out-Host

    Write-Step "Building debug APK"
    Push-Location $AndroidPath
    try {
        & $Gradlew app:assembleDebug --stacktrace | Out-Host
    } finally {
        Pop-Location
    }
}

function Install-And-LaunchApk {
    param(
        [string]$Adb,
        [string]$Serial,
        [string]$ApkPath,
        [string]$PackageName
    )

    Write-Step "Installing APK on $Serial"
    & $Adb -s $Serial install -r $ApkPath | Out-Host

    Write-Step "Launching $PackageName"
    & $Adb -s $Serial shell monkey -p $PackageName -c android.intent.category.LAUNCHER 1 | Out-Host
}

New-Item -ItemType Directory -Force -Path $LogsRoot | Out-Null

$SdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { Get-LocalProperty -Path $LocalPropertiesPath -Key "sdk.dir" }
$FlutterSdk = if ($env:FLUTTER_ROOT) { $env:FLUTTER_ROOT } else { Get-LocalProperty -Path $LocalPropertiesPath -Key "flutter.sdk" }

$FlutterCmd = Join-Path $FlutterSdk "bin\flutter.bat"
$Adb = Join-Path $SdkRoot "platform-tools\adb.exe"
$Emulator = Join-Path $SdkRoot "emulator\emulator.exe"
$SdkManager = Join-Path $SdkRoot "cmdline-tools\latest\bin\sdkmanager.bat"
$AvdManager = Join-Path $SdkRoot "cmdline-tools\latest\bin\avdmanager.bat"
$Gradlew = Join-Path $AndroidRoot "gradlew.bat"
$ApkPath = Join-Path $AndroidRoot "build\app\outputs\flutter-apk\app-debug.apk"

Assert-File -Path $FlutterCmd
Assert-File -Path $Adb
Assert-File -Path $SdkManager
Assert-File -Path $AvdManager
Assert-File -Path $Gradlew

Ensure-SdkPackageByPath -SdkManager $SdkManager -CheckPath $Emulator -PackageId "emulator"
Ensure-SdkPackageByPath -SdkManager $SdkManager -CheckPath (Join-Path $SdkRoot "system-images\android-35\default\x86_64\source.properties") -PackageId $SystemImage
Ensure-SdkPackageByPath -SdkManager $SdkManager -CheckPath (Join-Path $SdkRoot "ndk\$NdkVersion\source.properties") -PackageId "ndk;$NdkVersion"
Ensure-SdkPackageByPath -SdkManager $SdkManager -CheckPath (Join-Path $SdkRoot "cmake\$CMakeVersion\bin\cmake.exe") -PackageId "cmake;$CMakeVersion"

Ensure-Avd -AvdManager $AvdManager -AvdName $AvdName -SystemImage $SystemImage
Build-Apk -FlutterCmd $FlutterCmd -FlutterPath $FlutterRoot -Gradlew $Gradlew -AndroidPath $AndroidRoot

Assert-File -Path $ApkPath

$serial = Ensure-Emulator -Adb $Adb -EmulatorPath $Emulator -AvdName $AvdName
Install-And-LaunchApk -Adb $Adb -Serial $serial -ApkPath $ApkPath -PackageName $PackageName

Write-Step "Server: $ServerBaseUrl"
Write-Step "APK: $ApkPath"
Write-Step "Device: $serial"
