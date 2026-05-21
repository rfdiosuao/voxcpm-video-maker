# Daily AI video pipeline controller.
# Flow: preflight -> ensure MPP -> generate video -> QA -> optional publish -> summary.
param(
    [string]$Date = (Get-Date).ToString("yyyyMMdd"),
    [int]$VideoTimeoutMinutes = 60,
    [int]$PublishTimeoutMinutes = 30,
    [string[]]$PublishPlatforms = @(),
    [switch]$NoPublish,
    [string]$LockFile = "D:\VoxCPM\VoxCPM-2.0.3\video-project\.pipeline.lock"
)

$ErrorActionPreference = "Continue"
$VideoProject = "D:\VoxCPM\VoxCPM-2.0.3\video-project"
$DailyDir = "$VideoProject\daily\$Date"
$LogFile = "$VideoProject\pipeline_$Date.log"
$QaScript = "$VideoProject\qa_video.ps1"
$AudioFile = "$DailyDir\narration\daily_$Date.wav"
$MakeScript = "$VideoProject\make_daily_video.ps1"
$PublishScript = "$VideoProject\publish_daily_video.ps1"
$EnsureMppScript = "D:\VoxCPM\MediaPublishPlatform\MediaPublishPlatform\ensure_backend_running.ps1"

function Write-Log {
    param([string]$Level, [string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
    $colorMap = @{ INFO = "White"; OK = "Green"; WARN = "Yellow"; ERROR = "Red" }
    Write-Host $line -ForegroundColor ($colorMap[$Level] -as [System.ConsoleColor])
}

function Invoke-JobWithTimeout {
    param(
        [scriptblock]$ScriptBlock,
        [object[]]$ArgumentList,
        [int]$TimeoutSeconds,
        [string]$Name
    )
    $job = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
    $job | Wait-Job -Timeout $TimeoutSeconds | Out-Null
    if ($job.State -eq "Running") {
        Stop-Job $job
        Remove-Job $job
        throw "$Name timed out after $TimeoutSeconds seconds"
    }
    $output = Receive-Job $job
    $state = $job.State
    Remove-Job $job
    if ($state -ne "Completed") {
        throw "$Name failed with job state: $state"
    }
    return $output
}

Write-Log "INFO" "========== Daily pipeline started =========="
Write-Log "INFO" "Date: $Date"
$pipelineStartedAt = Get-Date

if (Test-Path $LockFile) {
    $lockAge = (Get-Date) - (Get-Item $LockFile).LastWriteTime
    if ($lockAge.TotalHours -lt 2) {
        Write-Log "WARN" "Existing lock is recent ($([math]::Round($lockAge.TotalMinutes,1)) minutes); another run may be active."
        exit 0
    }
    Write-Log "WARN" "Existing lock is stale ($([math]::Round($lockAge.TotalHours,1)) hours); replacing it."
    Remove-Item -LiteralPath $LockFile -Force
}

"running" | Out-File -FilePath $LockFile -Force -Encoding UTF8
Write-Log "INFO" "Lock created: $LockFile"

try {
    Write-Log "INFO" "[1] Preflight..."
    & "$VideoProject\pre_flight_check.ps1"
    if ($LASTEXITCODE -eq 1) {
        throw "Preflight found fatal issues"
    }
    Write-Log "OK" "Preflight passed"

    Write-Log "INFO" "[2] Ensuring MediaPublishPlatform backend..."
    if (Test-Path $EnsureMppScript) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $EnsureMppScript
    } else {
        Write-Log "WARN" "MPP ensure script not found: $EnsureMppScript"
    }
    try {
        Invoke-RestMethod -Uri "http://127.0.0.1:5409/getValidAccounts" -Method GET -TimeoutSec 20 | Out-Null
        Write-Log "OK" "MPP backend reachable"
    } catch {
        if (-not $NoPublish) {
            Write-Log "WARN" "MPP backend unreachable; publish step will be skipped: $($_.Exception.Message)"
        }
    }

    Write-Log "INFO" "[3] Generating video..."
    $videoOutput = Invoke-JobWithTimeout -Name "video generation" -TimeoutSeconds ($VideoTimeoutMinutes * 60) -ScriptBlock {
        param($ScriptPath, $RunDate)
        & powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -Date $RunDate
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    } -ArgumentList @($MakeScript, $Date)
    Write-Log "INFO" "Video generation output:`n$videoOutput"

    $horizontalFile = "$DailyDir\daily_$Date.mp4"
    $verticalFile = "$DailyDir\daily_${Date}_vertical.mp4"
    if (-not (Test-Path $horizontalFile)) {
        throw "Horizontal output not found: $horizontalFile"
    }
    $horizontalItem = Get-Item -LiteralPath $horizontalFile
    if ($horizontalItem.LastWriteTime -lt $pipelineStartedAt) {
        throw "Horizontal output is older than this pipeline run: $horizontalFile"
    }
    if (-not (Test-Path $AudioFile)) {
        throw "Narration output not found: $AudioFile"
    }
    $audioItem = Get-Item -LiteralPath $AudioFile
    if ($audioItem.LastWriteTime -lt $pipelineStartedAt) {
        throw "Narration output is older than this pipeline run: $AudioFile"
    }

    Write-Log "INFO" "[4] Final QA..."
    & powershell -NoProfile -ExecutionPolicy Bypass -File $QaScript -VideoFile $horizontalFile -AudioFile $AudioFile 2>&1 |
        Tee-Object -FilePath ([System.IO.Path]::ChangeExtension($horizontalFile, ".pipeline.qa.log"))
    if ($LASTEXITCODE -ne 0) {
        throw "Horizontal video QA failed: $horizontalFile"
    }
    if (Test-Path $verticalFile) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $QaScript -VideoFile $verticalFile -AudioFile $AudioFile 2>&1 |
            Tee-Object -FilePath ([System.IO.Path]::ChangeExtension($verticalFile, ".pipeline.qa.log"))
        if ($LASTEXITCODE -ne 0) {
            throw "Vertical video QA failed: $verticalFile"
        }
    }
    Write-Log "OK" "QA passed"

    if ($NoPublish) {
        Write-Log "INFO" "[5] Publish skipped by -NoPublish"
    } else {
        Write-Log "INFO" "[5] Publishing..."
        try {
            Invoke-RestMethod -Uri "http://127.0.0.1:5409/getValidAccounts" -Method GET -TimeoutSec 20 | Out-Null
            $publishArgs = @($PublishScript, $Date, $PublishPlatforms)
            $publishOutput = Invoke-JobWithTimeout -Name "publish" -TimeoutSeconds ($PublishTimeoutMinutes * 60) -ScriptBlock {
                param($ScriptPath, $RunDate, $Platforms)
                $args = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $ScriptPath, "-Date", $RunDate, "-DelaySeconds", "120")
                if ($Platforms -and $Platforms.Count -gt 0) {
                    $args += "-Platforms"
                    $args += $Platforms
                }
                & powershell @args
                if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
            } -ArgumentList $publishArgs
            Write-Log "INFO" "Publish output:`n$publishOutput"
        } catch {
            Write-Log "WARN" "Publish skipped or failed: $($_.Exception.Message)"
        }
    }

    Write-Log "INFO" "[6] Summary..."
    $files = Get-ChildItem -Path $DailyDir -Filter "*.mp4" -ErrorAction SilentlyContinue |
        Select-Object Name, @{N="SizeMB";E={[math]::Round($_.Length / 1MB, 1)}}
    foreach ($file in $files) {
        Write-Log "OK" "Output: $($file.Name) ($($file.SizeMB) MB)"
    }

    if (Test-Path "$DailyDir\publish_result.json") {
        $publishResult = Get-Content "$DailyDir\publish_result.json" -Encoding UTF8 | ConvertFrom-Json
        $success = @($publishResult | Where-Object { $_.Status -eq "SUCCESS" }).Count
        $fail = @($publishResult | Where-Object { $_.Status -eq "FAIL" }).Count
        $skip = @($publishResult | Where-Object { $_.Status -eq "SKIP" }).Count
        Write-Log "OK" "Publish result: $success success, $fail failed, $skip skipped"
    }

    Write-Log "INFO" "========== Daily pipeline completed =========="
    exit 0
} catch {
    Write-Log "ERROR" "Pipeline failed: $($_.Exception.Message)"
    exit 1
} finally {
    if (Test-Path $LockFile) {
        Remove-Item -LiteralPath $LockFile -Force
        Write-Log "INFO" "Lock removed"
    }
}
