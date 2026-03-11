[CmdletBinding()]
param(
    [string]$AvdName = "wave_api35",
    [string]$PackageName = "com.wave.messenger",
    [string]$SystemImage = "system-images;android-35;default;x86_64",
    [string]$NdkVersion = "28.2.13676358",
    [string]$CMakeVersion = "3.22.1",
    [switch]$NoWatch,
    [int]$MaxWatchBuilds = 0,
    [int]$PollIntervalMs = 1200,
    [int]$QuietPeriodMs = 1500
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$FlutterRoot = Join-Path $RepoRoot "wave_flutter"
$AndroidRoot = Join-Path $FlutterRoot "android"
$LocalPropertiesPath = Join-Path $AndroidRoot "local.properties"
$LogsRoot = Join-Path $RepoRoot "logs"
$ArtifactsRoot = Join-Path $RepoRoot "artifacts"
$ApkExportsRoot = Join-Path $ArtifactsRoot "apk"
$EmulatorLog = Join-Path $LogsRoot "mobile-emulator.log"
$EmulatorErrLog = Join-Path $LogsRoot "mobile-emulator.err.log"
$ServerBaseUrl = "http://45.12.70.75:3000"

$WatchRootCandidates = @(
    (Join-Path $FlutterRoot "lib"),
    (Join-Path $FlutterRoot "android"),
    (Join-Path $FlutterRoot "assets")
)
$WatchFileCandidates = @(
    (Join-Path $FlutterRoot "pubspec.yaml"),
    (Join-Path $FlutterRoot "pubspec.lock"),
    (Join-Path $FlutterRoot "analysis_options.yaml")
)
$WatchExcludedRegex = [regex]'\\(build|\.dart_tool|\.gradle|captures|logs|\.git)\\'

function Write-Step {
    param([string]$Message)
    Write-Host "[INFO] $Message"
}

function Write-WarnMessage {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Invoke-CheckedProcess {
    param(
        [string]$FilePath,
        [string[]]$Arguments = @(),
        [string]$WorkingDirectory,
        [string]$ErrorMessage
    )

    $previousLocation = $null
    if ($WorkingDirectory) {
        $previousLocation = Get-Location
        Push-Location $WorkingDirectory
    }

    try {
        & $FilePath @Arguments | Out-Host
        $exitCode = $LASTEXITCODE
    } finally {
        if ($null -ne $previousLocation) {
            Pop-Location
        }
    }

    if ($exitCode -ne 0) {
        if (-not $ErrorMessage) {
            $ErrorMessage = "Command failed: $FilePath $($Arguments -join ' ')"
        }
        throw "$ErrorMessage (exit code: $exitCode)"
    }
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

function Clear-AvdQuickBootArtifacts {
    param([string]$AvdName)

    $avdPath = Join-Path $env:USERPROFILE ".android\avd\$AvdName.avd"
    if (-not (Test-Path -LiteralPath $avdPath)) {
        return
    }

    $snapshotPath = Join-Path $avdPath "snapshots\default_boot"
    if (Test-Path -LiteralPath $snapshotPath) {
        Write-Step "Removing stale quickboot snapshot for '$AvdName'"
        try {
            Remove-Item -LiteralPath $snapshotPath -Recurse -Force
        } catch {
            Write-WarnMessage "Quickboot snapshot is busy and will be reused for the current emulator session."
        }
    }
}

function Ensure-Emulator {
    param(
        [string]$Adb,
        [string]$EmulatorPath,
        [string]$AvdName
    )

    $existing = Get-EmulatorSerial -Adb $Adb
    if ($null -eq $existing) {
        Clear-AvdQuickBootArtifacts -AvdName $AvdName
        $drive = Get-PSDrive C
        if ($drive.Free -lt 1.5GB) {
            $freeGb = [math]::Round($drive.Free / 1GB, 2)
            throw "Need at least 1.5 GB free on C: to start the emulator. Current free space: $freeGb GB."
        }

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
        [string]$AndroidPath,
        [string]$ApkPath
    )

    $buildStartedAtUtc = (Get-Date).ToUniversalTime()

    Write-Step "Running flutter pub get"
    Invoke-CheckedProcess `
        -FilePath $FlutterCmd `
        -Arguments @("pub", "get") `
        -WorkingDirectory $FlutterPath `
        -ErrorMessage "flutter pub get failed"

    Write-Step "Building debug APK"
    if (Test-Path -LiteralPath $ApkPath) {
        Remove-Item -LiteralPath $ApkPath -Force
    }
    Invoke-CheckedProcess `
        -FilePath $Gradlew `
        -Arguments @(
            "--no-daemon",
            "-Dkotlin.compiler.execution.strategy=in-process",
            "-Dkotlin.incremental=false",
            "app:assembleDebug",
            "--stacktrace"
        ) `
        -WorkingDirectory $AndroidPath `
        -ErrorMessage "Gradle debug build failed"

    Assert-File -Path $ApkPath
    $apkFile = Get-Item -LiteralPath $ApkPath
    if ($apkFile.LastWriteTimeUtc -lt $buildStartedAtUtc) {
        throw "APK was not refreshed during the current build: $ApkPath"
    }

    Write-Step "Fresh APK created at $($apkFile.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))"
}

function Install-And-LaunchApk {
    param(
        [string]$Adb,
        [string]$Serial,
        [string]$ApkPath,
        [string]$PackageName
    )

    Write-Step "Installing APK on $Serial"
    Invoke-CheckedProcess `
        -FilePath $Adb `
        -Arguments @("-s", $Serial, "install", "-r", $ApkPath) `
        -ErrorMessage "APK installation failed"

    Write-Step "Launching $PackageName"
    Invoke-CheckedProcess `
        -FilePath $Adb `
        -Arguments @("-s", $Serial, "shell", "am", "start", "-S", "-W", "-n", "$PackageName/.MainActivity") `
        -ErrorMessage "App launch failed"
}

function Export-Apk {
    param([string]$SourcePath)

    Assert-File -Path $SourcePath
    New-Item -ItemType Directory -Force -Path $ApkExportsRoot | Out-Null

    $latestPath = Join-Path $ApkExportsRoot "WaveMessenger-latest.apk"
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $archivePath = Join-Path $ApkExportsRoot "WaveMessenger-$timestamp.apk"

    Copy-Item -LiteralPath $SourcePath -Destination $latestPath -Force
    Copy-Item -LiteralPath $SourcePath -Destination $archivePath -Force

    return @{
        LatestPath = $latestPath
        ArchivePath = $archivePath
    }
}

function Test-WatchableFile {
    param([System.IO.FileInfo]$File)

    if ($File.Name -eq "GeneratedPluginRegistrant.java") {
        return $false
    }

    return -not $WatchExcludedRegex.IsMatch($File.FullName)
}

function Get-WatchEntries {
    $entries = [System.Collections.Generic.List[string]]::new()

    foreach ($root in $WatchRootCandidates) {
        if (-not (Test-Path -LiteralPath $root)) {
            continue
        }

        foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File -Force) {
            if (-not (Test-WatchableFile -File $file)) {
                continue
            }
            $entries.Add(("{0}|{1}|{2}" -f $file.FullName, $file.LastWriteTimeUtc.Ticks, $file.Length))
        }
    }

    foreach ($filePath in $WatchFileCandidates) {
        if (-not (Test-Path -LiteralPath $filePath)) {
            continue
        }

        $file = Get-Item -LiteralPath $filePath -Force
        $entries.Add(("{0}|{1}|{2}" -f $file.FullName, $file.LastWriteTimeUtc.Ticks, $file.Length))
    }

    return $entries | Sort-Object
}

function New-WatchSnapshot {
    $entries = @(Get-WatchEntries)
    $content = $entries -join "`n"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $sha.ComputeHash($bytes)
        $hash = [System.BitConverter]::ToString($hashBytes).Replace("-", "")
    } finally {
        $sha.Dispose()
    }

    return @{
        Entries = $entries
        Hash = $hash
    }
}

function Get-ChangedPaths {
    param(
        [string[]]$PreviousEntries,
        [string[]]$CurrentEntries
    )

    $changes = Compare-Object -ReferenceObject $PreviousEntries -DifferenceObject $CurrentEntries |
        Select-Object -ExpandProperty InputObject

    $paths = [System.Collections.Generic.List[string]]::new()
    foreach ($change in $changes) {
        $path = ($change -split '\|', 2)[0]
        if ($paths.Contains($path)) {
            continue
        }
        $paths.Add($path)
        if ($paths.Count -ge 5) {
            break
        }
    }

    return $paths
}

function Format-ChangedPaths {
    param([string[]]$Paths)

    if ($Paths.Count -eq 0) {
        return ""
    }

    $labels = foreach ($path in $Paths) {
        if ($path.StartsWith($FlutterRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            $path.Substring($FlutterRoot.Length).TrimStart('\')
        } else {
            Split-Path -Leaf $path
        }
    }

    return ($labels -join ", ")
}

function Invoke-BuildAndDeploy {
    param(
        [string]$FlutterCmd,
        [string]$FlutterPath,
        [string]$Gradlew,
        [string]$AndroidPath,
        [string]$Adb,
        [string]$EmulatorPath,
        [string]$AvdName,
        [string]$ApkPath,
        [string]$PackageName
    )

    Build-Apk `
        -FlutterCmd $FlutterCmd `
        -FlutterPath $FlutterPath `
        -Gradlew $Gradlew `
        -AndroidPath $AndroidPath `
        -ApkPath $ApkPath
    Assert-File -Path $ApkPath
    $exportedApk = Export-Apk -SourcePath $ApkPath
    $serial = Ensure-Emulator -Adb $Adb -EmulatorPath $EmulatorPath -AvdName $AvdName
    Install-And-LaunchApk -Adb $Adb -Serial $serial -ApkPath $ApkPath -PackageName $PackageName
    return @{
        Serial = $serial
        LatestApkPath = $exportedApk.LatestPath
        ArchiveApkPath = $exportedApk.ArchivePath
    }
}

function Wait-ForNextStableChange {
    param(
        [hashtable]$LastSnapshot,
        [int]$PollIntervalMs,
        [int]$QuietPeriodMs
    )

    do {
        Start-Sleep -Milliseconds $PollIntervalMs
        $currentSnapshot = New-WatchSnapshot
    } while ($currentSnapshot.Hash -eq $LastSnapshot.Hash)

    Write-Step "Detected source changes. Waiting for file writes to settle..."

    do {
        $candidateSnapshot = $currentSnapshot
        Start-Sleep -Milliseconds $QuietPeriodMs
        $currentSnapshot = New-WatchSnapshot
    } while ($currentSnapshot.Hash -ne $candidateSnapshot.Hash)

    return @{
        Snapshot = $currentSnapshot
        ChangedPaths = @(Get-ChangedPaths -PreviousEntries $LastSnapshot.Entries -CurrentEntries $currentSnapshot.Entries)
    }
}

New-Item -ItemType Directory -Force -Path $LogsRoot | Out-Null
New-Item -ItemType Directory -Force -Path $ApkExportsRoot | Out-Null

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
$buildResult = Invoke-BuildAndDeploy `
    -FlutterCmd $FlutterCmd `
    -FlutterPath $FlutterRoot `
    -Gradlew $Gradlew `
    -AndroidPath $AndroidRoot `
    -Adb $Adb `
    -EmulatorPath $Emulator `
    -AvdName $AvdName `
    -ApkPath $ApkPath `
    -PackageName $PackageName
$serial = $buildResult.Serial

Write-Step "Server: $ServerBaseUrl"
Write-Step "APK: $ApkPath"
Write-Step "APK (latest copy): $($buildResult.LatestApkPath)"
Write-Step "APK (archive copy): $($buildResult.ArchiveApkPath)"
Write-Step "Device: $serial"

if ($NoWatch) {
    return
}

Write-Step "Watch mode is active. Edit files in wave_flutter and the app will rebuild automatically."
Write-Step "Press Ctrl+C to stop the auto builder."

$snapshot = New-WatchSnapshot
$completedWatchBuilds = 0

while ($true) {
    $change = Wait-ForNextStableChange -LastSnapshot $snapshot -PollIntervalMs $PollIntervalMs -QuietPeriodMs $QuietPeriodMs
    $snapshot = $change.Snapshot

    $changedLabel = Format-ChangedPaths -Paths $change.ChangedPaths
    if ($changedLabel) {
        Write-Step "Changed: $changedLabel"
    }

    try {
        $buildResult = Invoke-BuildAndDeploy `
            -FlutterCmd $FlutterCmd `
            -FlutterPath $FlutterRoot `
            -Gradlew $Gradlew `
            -AndroidPath $AndroidRoot `
            -Adb $Adb `
            -EmulatorPath $Emulator `
            -AvdName $AvdName `
            -ApkPath $ApkPath `
            -PackageName $PackageName
        $serial = $buildResult.Serial
        $completedWatchBuilds += 1
        Write-Step "Auto rebuild completed at $((Get-Date).ToString('HH:mm:ss')) on $serial"
        Write-Step "Latest APK copy: $($buildResult.LatestApkPath)"
        if ($MaxWatchBuilds -gt 0 -and $completedWatchBuilds -ge $MaxWatchBuilds) {
            Write-Step "Reached MaxWatchBuilds=$MaxWatchBuilds. Exiting watch mode."
            return
        }
    } catch {
        Write-WarnMessage "Auto rebuild failed: $($_.Exception.Message)"
    } finally {
        $snapshot = New-WatchSnapshot
    }
}
