# 每日AI日报视频制作与发布 - 主控脚本
# 功能: 预检 -> 启动MPP -> 制作视频 -> 发布 -> 汇总
param(
    [string]$Date = (Get-Date).ToString("yyyyMMdd"),
    [int]$VideoTimeoutMinutes = 30,    # 视频制作超时(分钟)
    [int]$PublishTimeoutMinutes = 20,   # 发布超时(分钟)
    [string]$LockFile = "d:\VoxCPM\VoxCPM-2.0.3\video-project\.pipeline.lock"
)

$ErrorActionPreference = "Continue"
$VideoProject = "d:\VoxCPM\VoxCPM-2.0.3\video-project"
$DailyDir = "$VideoProject\daily\$Date"
$LogFile = "$VideoProject\pipeline_$Date.log"

function Write-Log($level, $message) {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$timestamp] [$level] $message"
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
    $colorMap = @{ "INFO" = "White"; "OK" = "Green"; "WARN" = "Yellow"; "ERROR" = "Red" }
    Write-Host $line -ForegroundColor ($colorMap[$level] -as [System.ConsoleColor])
}

# ========== 防重复执行 ==========
Write-Log "INFO" "========== 每日流水线启动 =========="
Write-Log "INFO" "日期: $Date"

if (Test-Path $LockFile) {
    $lockAge = (Get-Date) - (Get-Item $LockFile).LastWriteTime
    if ($lockAge.TotalHours -lt 2) {
        Write-Log "WARN" "检测到锁文件(创建于 $([math]::Round($lockAge.TotalMinutes,1)) 分钟前)，可能已有实例在运行，退出"
        exit 0
    } else {
        Write-Log "WARN" "锁文件已过期($([math]::Round($lockAge.TotalHours,1)) 小时)，强制继续"
        Remove-Item $LockFile -Force
    }
}

# 创建锁文件
"running" | Out-File -FilePath $LockFile -Force
Write-Log "INFO" "锁文件已创建: $LockFile"

try {
    # ========== 步骤1: 环境预检 ==========
    Write-Log "INFO" "[步骤1] 环境预检..."
    & "$VideoProject\pre_flight_check.ps1"
    if ($LASTEXITCODE -eq 1) {
        Write-Log "ERROR" "预检发现致命问题，中止任务"
        exit 1
    }
    Write-Log "OK" "预检通过"

    # ========== 步骤2: 启动 MediaPublishPlatform ==========
    Write-Log "INFO" "[步骤2] 确保 MediaPublishPlatform 运行..."
    try {
        $mppCheck = Invoke-RestMethod -Uri "http://127.0.0.1:5409/getValidAccounts" -Method GET -TimeoutSec 5
        Write-Log "OK" "MPP 后端已在运行"
    } catch {
        Write-Log "WARN" "MPP 后端未运行，尝试启动..."
        Start-Process -FilePath "C:\Users\Administrator\AppData\Local\Programs\Python\Python311\python.exe" `
            -ArgumentList "D:\VoxCPM\MediaPublishPlatform\MediaPublishPlatform\sau_backend\sau_backend.py" `
            -WindowStyle Hidden
        Start-Sleep -Seconds 10
        try {
            $mppCheck = Invoke-RestMethod -Uri "http://127.0.0.1:5409/getValidAccounts" -Method GET -TimeoutSec 5
            Write-Log "OK" "MPP 后端已启动"
        } catch {
            Write-Log "WARN" "MPP 后端启动失败或仍未就绪，发布步骤将跳过"
        }
    }

    # ========== 步骤3: 制作视频(带超时) ==========
    Write-Log "INFO" "[步骤3] 制作视频 (超时: ${VideoTimeoutMinutes}分钟)..."
    $videoJob = Start-Job -ScriptBlock {
        param($scriptPath, $date)
        & $scriptPath -Date $date
    } -ArgumentList "$VideoProject\make_daily_video.ps1", $Date

    $videoJob | Wait-Job -Timeout ($VideoTimeoutMinutes * 60) | Out-Null
    if ($videoJob.State -eq "Running") {
        Write-Log "ERROR" "视频制作超时($VideoTimeoutMinutes 分钟)，强制终止"
        Stop-Job $videoJob
        Remove-Job $videoJob
        exit 1
    }

    $videoResult = Receive-Job $videoJob
    Remove-Job $videoJob
    Write-Log "INFO" "视频制作输出:`n$videoResult"

    $horizontalFile = "$DailyDir\daily_$Date.mp4"
    if (-not (Test-Path $horizontalFile)) {
        Write-Log "ERROR" "视频制作失败，未找到输出文件: $horizontalFile"
        exit 1
    }
    Write-Log "OK" "视频制作完成: $horizontalFile"

    # ========== 步骤4: 发布视频(带超时) ==========
    Write-Log "INFO" "[步骤4] 发布视频 (超时: ${PublishTimeoutMinutes}分钟)..."
    try {
        $mppCheck = Invoke-RestMethod -Uri "http://127.0.0.1:5409/getValidAccounts" -Method GET -TimeoutSec 5
        $publishJob = Start-Job -ScriptBlock {
            param($scriptPath, $date)
            & $scriptPath -Date $date
        } -ArgumentList "$VideoProject\publish_daily_video.ps1", $Date

        $publishJob | Wait-Job -Timeout ($PublishTimeoutMinutes * 60) | Out-Null
        if ($publishJob.State -eq "Running") {
            Write-Log "WARN" "发布超时($PublishTimeoutMinutes 分钟)，强制终止"
            Stop-Job $publishJob
            Remove-Job $publishJob
        } else {
            $publishResult = Receive-Job $publishJob
            Remove-Job $publishJob
            Write-Log "INFO" "发布输出:`n$publishResult"
        }
    } catch {
        Write-Log "WARN" "发布步骤跳过: $_"
    }

    # ========== 步骤5: 汇总 ==========
    Write-Log "INFO" "[步骤5] 任务汇总..."
    $files = Get-ChildItem -Path $DailyDir -Filter "*.mp4" | Select-Object Name, @{N="SizeMB";E={[math]::Round($_.Length/1MB,1)}}
    foreach ($f in $files) {
        Write-Log "OK" "产出文件: $($f.Name) ($($f.SizeMB) MB)"
    }

    if (Test-Path "$DailyDir\publish_result.json") {
        $pubResult = Get-Content "$DailyDir\publish_result.json" | ConvertFrom-Json
        $success = ($pubResult | Where-Object { $_.Status -eq "成功" }).Count
        $fail = ($pubResult | Where-Object { $_.Status -eq "失败" }).Count
        Write-Log "OK" "发布结果: $success 成功, $fail 失败"
    }

    Write-Log "INFO" "========== 流水线完成 =========="
    exit 0

} catch {
    Write-Log "ERROR" "流水线异常: $_"
    exit 1
} finally {
    # 清理锁文件
    if (Test-Path $LockFile) {
        Remove-Item $LockFile -Force
        Write-Log "INFO" "锁文件已清理"
    }
}
