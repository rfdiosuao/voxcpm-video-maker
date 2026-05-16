# 每日视频发布控制脚本
# 功能: 只发布到有效账号平台、错峰发布、基于内容生成标题
param(
    [string]$Date = (Get-Date).ToString("yyyyMMdd"),
    [string]$DailyDir = "d:\VoxCPM\VoxCPM-2.0.3\video-project\daily\$Date",
    [string]$MppUrl = "http://127.0.0.1:5409",
    [int]$DelaySeconds = 120  # 平台间发布间隔(秒)
)

$ErrorActionPreference = "Continue"
$results = @()

function Write-Result($platform, $status, $detail) {
    $color = if ($status -eq "成功") { "Green" } elseif ($status -eq "跳过") { "Yellow" } else { "Red" }
    Write-Host "  [$status] $platform - $detail" -ForegroundColor $color
    $script:results += [PSCustomObject]@{ Platform = $platform; Status = $status; Detail = $detail }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  每日视频发布控制" -ForegroundColor Cyan
Write-Host "  日期: $Date" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. 检查视频文件
$horizontalFile = "$DailyDir\daily_$Date.mp4"
$verticalFile = "$DailyDir\daily_${Date}_vertical.mp4"
if (-not (Test-Path $horizontalFile)) {
    Write-Host "错误: 横屏视频不存在: $horizontalFile" -ForegroundColor Red
    exit 1
}
Write-Host "横屏视频: $horizontalFile" -ForegroundColor Green
if (Test-Path $verticalFile) {
    Write-Host "竖屏视频: $verticalFile" -ForegroundColor Green
} else {
    Write-Host "竖屏视频不存在,将使用横屏视频发布到所有平台" -ForegroundColor Yellow
}

# 2. 获取有效账号
Write-Host "`n获取有效账号..." -ForegroundColor Yellow
try {
    $mppCheck = Invoke-RestMethod -Uri "$MppUrl/getValidAccounts" -Method GET -TimeoutSec 10
    $allAccounts = $mppCheck.data
    $validAccounts = $allAccounts | Where-Object { $_[4] -eq 1 }
    $invalidAccounts = $allAccounts | Where-Object { $_[4] -eq 0 }
    Write-Host "  有效账号: $($validAccounts.Count) 个" -ForegroundColor Green
    if ($invalidAccounts.Count -gt 0) {
        Write-Host "  失效账号: $($invalidAccounts.Count) 个 (已跳过)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "错误: 无法连接 MPP 后端 ($MppUrl)" -ForegroundColor Red
    exit 1
}

# 平台类型映射
$platformMap = @{
    1 = @{ name = "xiaohongshu"; label = "小红书"; format = "vertical" }
    2 = @{ name = "tencent";     label = "视频号";  format = "horizontal" }
    3 = @{ name = "douyin";      label = "抖音";    format = "vertical" }
    4 = @{ name = "kuaishou";    label = "快手";    format = "vertical" }
    5 = @{ name = "tiktok";      label = "TikTok";  format = "vertical" }
    6 = @{ name = "instagram";   label = "Instagram"; format = "vertical" }
    7 = @{ name = "facebook";    label = "Facebook";  format = "horizontal" }
    8 = @{ name = "bilibili";    label = "B站";     format = "horizontal" }
    9 = @{ name = "baijiahao";   label = "百家号";  format = "horizontal" }
}

# 3. 读取 AI HOT 数据生成标题/简介/话题
Write-Host "`n生成标题/简介/话题..." -ForegroundColor Yellow
$aihotFile = "$DailyDir\aihot_items.json"
$title = ""
$text = ""
$tags = ""
if (Test-Path $aihotFile) {
    try {
        $items = Get-Content $aihotFile -Encoding UTF8 | ConvertFrom-Json
        $titles = $items | ForEach-Object { $_.title } | Select-Object -First 3
        $sources = ($items | ForEach-Object { $_.source } | Select-Object -Unique) -join ","
        
        # 标题生成
        $templates = @(
            "AI圈今天炸了!OpenAI/Anthropic/Google全有大动作",
            "今日AI热点速递:$($titles[0])",
            "X天获万星!这个AI工具火了",
            "大厂都在用的秘密武器,终于开源了",
            "AI圈炸了!OpenAI刚刚发布了..."
        )
        $title = $templates[(Get-Random -Maximum $templates.Count)]
        if ($title -like "*OpenAI*" -and -not ($sources -like "*OpenAI*")) {
            $title = "今日AI热点速递:$($titles[0])"
        }
        
        # 简介生成
        $text = "今日AI热点速递:`n"
        $text += ($items | ForEach-Object { "- $($_.title)" } | Select-Object -First 4) -join "`n"
        $text += "`n`n你怎么看?评论区聊聊"
        
        # 话题生成
        $topicKeywords = @("AI日报","人工智能","大模型","科技热点","OpenAI","AIGC")
        $tags = ($topicKeywords | Get-Random -Count 4) -join ","
        
        Write-Host "  标题: $title" -ForegroundColor Green
        Write-Host "  话题: $tags" -ForegroundColor Green
    } catch {
        Write-Host "  读取AI HOT数据失败,使用默认标题" -ForegroundColor Yellow
    }
}

if (-not $title) {
    $title = "AI HOT 每日精选日报 $Date"
    $text = "今日AI行业重要资讯精选,真实证据,深度解读"
    $tags = "AI日报,人工智能,科技热点"
}

# 4. 逐个平台发布(错峰)
Write-Host "`n开始发布(平台间间隔 ${DelaySeconds} 秒)..." -ForegroundColor Yellow
foreach ($account in $validAccounts) {
    $typeId = $account[1]
    $platformInfo = $platformMap[$typeId]
    if (-not $platformInfo) {
        Write-Result "未知平台($typeId)" "跳过" "未识别的平台类型"
        continue
    }
    
    $platformName = $platformInfo.name
    $platformLabel = $platformInfo.label
    $format = $platformInfo.format
    
    # 选择视频文件
    $videoFile = if ($format -eq "vertical" -and (Test-Path $verticalFile)) { $verticalFile } else { $horizontalFile }
    
    Write-Host "`n[$platformLabel] 准备发布..." -ForegroundColor Cyan
    Write-Host "  文件: $videoFile" -ForegroundColor Gray
    
    # 构建发布参数
    $body = @{
        type = $typeId
        accountList = @($account[3])
        fileList = @($videoFile)
        title = $title
        text = $text
        tags = $tags
    } | ConvertTo-Json -Depth 3
    
    try {
        $response = Invoke-RestMethod -Uri "$MppUrl/postVideo" -Method POST -ContentType "application/json" -Body $body -TimeoutSec 60
        if ($response -and $response.code -eq 200) {
            Write-Result $platformLabel "成功" $response.message
        } else {
            Write-Result $platformLabel "失败" ($response.message -as [string])
        }
    } catch {
        Write-Result $platformLabel "失败" $_.Exception.Message
    }
    
    # 错峰等待
    Start-Sleep -Seconds $DelaySeconds
}

# 5. 汇总结果
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  发布汇总" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$successCount = ($results | Where-Object { $_.Status -eq "成功" }).Count
$failCount = ($results | Where-Object { $_.Status -eq "失败" }).Count
$skipCount = ($results | Where-Object { $_.Status -eq "跳过" }).Count
Write-Host "  成功: $successCount 个平台" -ForegroundColor Green
Write-Host "  失败: $failCount 个平台" -ForegroundColor Red
Write-Host "  跳过: $skipCount 个平台" -ForegroundColor Yellow

# 保存结果日志
$results | ConvertTo-Json -Depth 3 | Out-File -FilePath "$DailyDir\publish_result.json" -Encoding UTF8
Write-Host "  结果已保存: $DailyDir\publish_result.json" -ForegroundColor Gray

if ($failCount -gt 0) {
    exit 1
} else {
    exit 0
}
