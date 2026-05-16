# 自动化任务执行前环境预检 + 磁盘清理脚本
param(
    [string]$DailyDir = "d:\VoxCPM\VoxCPM-2.0.3\video-project\daily",
    [long]$MinFreeGB = 5,
    [long]$MinFreeDGB = 10,
    [int]$KeepDays = 7
)

$hasError = $false
$hasWarning = $false

function Write-Check {
    param($status, $message)
    if ($status -eq "OK") {
        Write-Host "  [OK] $message" -ForegroundColor Green
    } elseif ($status -eq "WARN") {
        Write-Host "  [WARN] $message" -ForegroundColor Yellow
        $script:hasWarning = $true
    } elseif ($status -eq "FAIL") {
        Write-Host "  [FAIL] $message" -ForegroundColor Red
        $script:hasError = $true
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  每日任务执行前环境预检" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. 磁盘空间检查
Write-Host ""
Write-Host "[检查1/7] 磁盘空间..." -ForegroundColor Yellow
$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match "^[A-Z]:\\$" }
foreach ($drive in $drives) {
    $freeGB = [math]::Round($drive.Free / 1GB, 1)
    $totalGB = [math]::Round(($drive.Free + $drive.Used) / 1GB, 1)
    $pct = [math]::Round(($drive.Free / ($drive.Free + $drive.Used)) * 100, 1)
    $label = $drive.Name + ":"
    if ($label -eq "C:") {
        if ($freeGB -lt $MinFreeGB) {
            Write-Check "FAIL" "$label 仅剩 ${freeGB}GB / ${totalGB}GB (${pct}% 可用)，低于阈值 ${MinFreeGB}GB"
        } else {
            Write-Check "OK" "$label ${freeGB}GB / ${totalGB}GB (${pct}% 可用)"
        }
    } elseif ($label -eq "D:") {
        if ($freeGB -lt $MinFreeDGB) {
            Write-Check "WARN" "$label 仅剩 ${freeGB}GB / ${totalGB}GB (${pct}% 可用)，低于阈值 ${MinFreeDGB}GB"
        } else {
            Write-Check "OK" "$label ${freeGB}GB / ${totalGB}GB (${pct}% 可用)"
        }
    }
}

# 2. 自动清理旧视频文件
Write-Host ""
Write-Host "[检查2/7] 旧视频文件清理..." -ForegroundColor Yellow
if (Test-Path $DailyDir) {
    $cutoff = (Get-Date).AddDays(-$KeepDays).ToString("yyyyMMdd")
    $folders = Get-ChildItem -Path $DailyDir -Directory | Where-Object {
        $_.Name -match "^\d{8}$" -and $_.Name -lt $cutoff
    }
    $cleanedSize = 0
    foreach ($folder in $folders) {
        $files = Get-ChildItem -Path $folder.FullName -Filter "*.mp4" -Recurse -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            $cleanedSize += $f.Length
            Remove-Item -Path $f.FullName -Force
        }
        $logs = Get-ChildItem -Path $folder.FullName -Filter "*.log" -Recurse -ErrorAction SilentlyContinue
        foreach ($f in $logs) {
            $cleanedSize += $f.Length
            Remove-Item -Path $f.FullName -Force
        }
    }
    if ($cleanedSize -gt 0) {
        $mb = [math]::Round($cleanedSize / 1MB, 1)
        Write-Check "OK" "已清理 ${mb}MB 旧文件"
    } else {
        Write-Check "OK" "无需清理旧文件"
    }
} else {
    Write-Check "WARN" "daily 目录不存在: $DailyDir"
}

# 3. 检查 HyperFrames 环境
Write-Host ""
Write-Host "[检查3/7] HyperFrames 环境..." -ForegroundColor Yellow
$npxCheck = "D:\编程工具\node.js\npx.cmd"
if (Test-Path $npxCheck) {
    Write-Check "OK" "npx 可用"
} else {
    Write-Check "FAIL" "npx 不可用"
}

# 4. 检查 FFmpeg
Write-Host ""
Write-Host "[检查4/7] FFmpeg 环境..." -ForegroundColor Yellow
$ffmpegCheck = "C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1-full_build\bin\ffmpeg.exe"
$ffprobeCheck = "C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1-full_build\bin\ffprobe.exe"
if ((Test-Path $ffmpegCheck) -and (Test-Path $ffprobeCheck)) {
    Write-Check "OK" "ffmpeg 和 ffprobe 可用"
} else {
    Write-Check "WARN" "ffmpeg 或 ffprobe 可能不在 PATH 中"
}

# 5. 检查 VoxCPM 配音环境
Write-Host ""
Write-Host "[检查5/7] VoxCPM 配音环境..." -ForegroundColor Yellow
$voxPy = "d:\VoxCPM\VoxCPM-2.0.3\venv\Scripts\python.exe"
$voxGen = "d:\VoxCPM\VoxCPM-2.0.3\video-project\generate_voice_template.py"
if (Test-Path $voxPy) {
    Write-Check "OK" "VoxCPM Python 可用"
} else {
    Write-Check "FAIL" "VoxCPM Python 不存在"
}
if (Test-Path $voxGen) {
    Write-Check "OK" "配音生成脚本存在"
} else {
    Write-Check "FAIL" "配音生成脚本不存在"
}

# 6. 检查 MediaPublishPlatform
Write-Host ""
Write-Host "[检查6/7] MediaPublishPlatform 发布服务..." -ForegroundColor Yellow
try {
    $mppCheck = Invoke-RestMethod -Uri "http://127.0.0.1:5409/getValidAccounts" -Method GET -TimeoutSec 5
    $validCount = ($mppCheck.data | Where-Object { $_[4] -eq 1 }).Count
    Write-Check "OK" "MPP 后端运行中，有效账号: $validCount 个"
} catch {
    Write-Check "WARN" "MPP 后端未运行或无法连接 127.0.0.1:5409"
}

# 7. 检查 GPU
Write-Host ""
Write-Host "[检查7/7] GPU 状态..." -ForegroundColor Yellow
try {
    $gpu = nvidia-smi --query-gpu=name,memory.free --format=csv,noheader 2>$null
    if ($gpu) {
        Write-Check "OK" "GPU 可用: $gpu"
    } else {
        Write-Check "WARN" "nvidia-smi 不可用"
    }
} catch {
    Write-Check "WARN" "无法检测 GPU 状态"
}

# 总结
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($hasError) {
    Write-Host "  预检结果: 存在致命问题，任务中止！" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Cyan
    exit 1
} elseif ($hasWarning) {
    Write-Host "  预检结果: 有警告，但继续执行" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "  预检结果: 全部通过，开始执行任务" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    exit 0
}
