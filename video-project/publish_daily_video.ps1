# Daily video publish controller.
# Publishes only QA-passed videos to valid MediaPublishPlatform accounts.
param(
    [string]$Date = (Get-Date).ToString("yyyyMMdd"),
    [string]$DailyDir = "D:\VoxCPM\VoxCPM-2.0.3\video-project\daily\$Date",
    [string]$MppUrl = "http://127.0.0.1:5409",
    [string[]]$Platforms = @(),
    [int]$DelaySeconds = 120
)

$ErrorActionPreference = "Continue"
$results = @()
$VideoProject = "D:\VoxCPM\VoxCPM-2.0.3\video-project"
$QaScript = "$VideoProject\qa_video.ps1"
$AudioFile = "$DailyDir\narration\daily_$Date.wav"

function Test-VideoQa {
    param([string]$VideoFile)
    if (-not (Test-Path $QaScript)) { throw "QA script not found: $QaScript" }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $QaScript -VideoFile $VideoFile -AudioFile $AudioFile 2>&1 |
        Tee-Object -FilePath ([System.IO.Path]::ChangeExtension($VideoFile, ".prepublish.qa.log"))
    return ($LASTEXITCODE -eq 0)
}

function Write-Result {
    param([string]$Platform, [string]$Status, [string]$Detail)
    $color = if ($Status -eq "SUCCESS") { "Green" } elseif ($Status -eq "SKIP") { "Yellow" } else { "Red" }
    Write-Host "  [$Status] $Platform - $Detail" -ForegroundColor $color
    $script:results += [PSCustomObject]@{ Platform = $Platform; Status = $Status; Detail = $Detail }
}

function Resolve-MppAccountFile {
    param($Account)
    if ($Account -is [array] -and $Account.Count -ge 3) {
        return [string]$Account[2]
    }
    if ($Account.PSObject.Properties.Name -contains "filePath") {
        return [string]$Account.filePath
    }
    return [string]$Account
}

function Normalize-PublishTags {
    param([object]$Tags)
    $rawItems = @()
    if ($Tags -is [array]) {
        $rawItems = $Tags
    } else {
        $rawItems = ([string]$Tags) -split "[,，\s]+"
    }

    $clean = @()
    foreach ($item in $rawItems) {
        $tag = ([string]$item).Trim().TrimStart("#").Trim()
        $tag = ($tag -replace "[^\p{L}\p{Nd}_\u4e00-\u9fff]", "")
        if ($tag -and -not ($clean -contains $tag)) {
            $clean += $tag
        }
    }
    return @($clean | Select-Object -First 5)
}

function Convert-TagsForMpp {
    param([object]$Tags)
    return (Normalize-PublishTags $Tags) -join ","
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Daily video publish controller" -ForegroundColor Cyan
Write-Host "  Date: $Date" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$horizontalFile = "$DailyDir\daily_$Date.mp4"
$verticalFile = "$DailyDir\daily_${Date}_vertical.mp4"

if (-not (Test-Path $horizontalFile)) {
    Write-Host "ERROR: horizontal video not found: $horizontalFile" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $AudioFile)) {
    Write-Host "ERROR: narration audio not found: $AudioFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-VideoQa $horizontalFile)) {
    Write-Host "ERROR: horizontal pre-publish QA failed: $horizontalFile" -ForegroundColor Red
    exit 1
}
Write-Host "Horizontal video: $horizontalFile" -ForegroundColor Green

if (Test-Path $verticalFile) {
    if (-not (Test-VideoQa $verticalFile)) {
        Write-Host "ERROR: vertical pre-publish QA failed: $verticalFile" -ForegroundColor Red
        exit 1
    }
    Write-Host "Vertical video: $verticalFile" -ForegroundColor Green
} else {
    Write-Host "Vertical video not found; horizontal file will be used for every platform." -ForegroundColor Yellow
}

Write-Host "`nFetching valid accounts..." -ForegroundColor Yellow
try {
    $mppCheck = Invoke-RestMethod -Uri "$MppUrl/getValidAccounts" -Method GET -TimeoutSec 10
    $allAccounts = $mppCheck.data
    $validAccounts = @($allAccounts | Where-Object { $_[4] -eq 1 })
    $invalidAccounts = @($allAccounts | Where-Object { $_[4] -eq 0 })
    Write-Host "  Valid accounts: $($validAccounts.Count)" -ForegroundColor Green
    if ($invalidAccounts.Count -gt 0) {
        Write-Host "  Invalid accounts skipped: $($invalidAccounts.Count)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: cannot connect to MPP backend ($MppUrl): $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$platformMap = @{
    1 = @{ name = "xiaohongshu"; label = "xiaohongshu"; format = "vertical" }
    2 = @{ name = "tencent"; label = "tencent"; format = "horizontal" }
    3 = @{ name = "douyin"; label = "douyin"; format = "vertical" }
    4 = @{ name = "kuaishou"; label = "kuaishou"; format = "vertical" }
    5 = @{ name = "tiktok"; label = "TikTok"; format = "vertical" }
    6 = @{ name = "instagram"; label = "Instagram"; format = "vertical" }
    7 = @{ name = "facebook"; label = "Facebook"; format = "horizontal" }
    8 = @{ name = "bilibili"; label = "bilibili"; format = "horizontal" }
    9 = @{ name = "baijiahao"; label = "baijiahao"; format = "horizontal" }
}

$requestedPlatforms = @($Platforms | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ })

Write-Host "`nGenerating title, description, and tags..." -ForegroundColor Yellow
$aihotFile = "$DailyDir\aihot_items.json"
$title = ""
$text = ""
$tags = @()

if (Test-Path $aihotFile) {
    try {
        $items = Get-Content $aihotFile -Encoding UTF8 | ConvertFrom-Json
        $titles = @($items | ForEach-Object { $_.title } | Select-Object -First 4)
        $sources = ($items | ForEach-Object { $_.source } | Select-Object -Unique) -join ","

        $title = if ($titles.Count -gt 0) {
            "AI HOT Daily: $($titles[0])"
        } else {
            "AI HOT Daily Brief $Date"
        }
        if ($title.Length -gt 50) {
            $title = $title.Substring(0, 47) + "..."
        }

        $text = "AI HOT daily brief:`n"
        $text += ($titles | ForEach-Object { "- $_" }) -join "`n"
        $text += "`n`nSources: AI HOT aggregation and original-page screenshots. For industry reference only."

        $candidateTags = @("AINews", "AI", "LLM", "TechNews", "AIGC")
        if ($sources -like "*OpenAI*" -or ($titles -join " ") -like "*OpenAI*") { $candidateTags += "OpenAI" }
        if (($titles -join " ") -like "*Google*") { $candidateTags += "GoogleAI" }
        if (($titles -join " ") -like "*Claude*" -or $sources -like "*Claude*") { $candidateTags += "Claude" }
        $tags = Normalize-PublishTags $candidateTags

        Write-Host "  Title: $title" -ForegroundColor Green
        Write-Host "  Tags: $((Normalize-PublishTags $tags) -join ',')" -ForegroundColor Green
    } catch {
        Write-Host "  Failed to read AI HOT data; using fallback metadata: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

if (-not $title) {
    $title = "AI HOT Daily Brief $Date"
    $text = "Daily AI industry brief with source-backed items."
    $tags = Normalize-PublishTags @("AINews", "AI", "TechNews")
}

Write-Host "`nPublishing with ${DelaySeconds}s delay between platforms..." -ForegroundColor Yellow
foreach ($account in $validAccounts) {
    $typeId = [int]$account[1]
    $platformInfo = $platformMap[$typeId]
    if (-not $platformInfo) {
        Write-Result "unknown($typeId)" "SKIP" "unrecognized platform type"
        continue
    }

    $platformName = $platformInfo.name
    $platformLabel = $platformInfo.label
    if ($requestedPlatforms.Count -gt 0 -and -not ($requestedPlatforms -contains $platformName) -and -not ($requestedPlatforms -contains $platformLabel.ToLowerInvariant())) {
        Write-Result $platformLabel "SKIP" "not requested"
        continue
    }

    $videoFile = if ($platformInfo.format -eq "vertical" -and (Test-Path $verticalFile)) { $verticalFile } else { $horizontalFile }
    if (-not (Test-VideoQa $videoFile)) {
        Write-Result $platformLabel "FAIL" "pre-publish QA failed: $videoFile"
        continue
    }

    $accountFile = Resolve-MppAccountFile $account
    if (-not $accountFile.EndsWith(".json")) {
        Write-Result $platformLabel "FAIL" "invalid account file returned by MPP: $accountFile"
        continue
    }

    Write-Host "`n[$platformLabel] Preparing publish..." -ForegroundColor Cyan
    Write-Host "  File: $videoFile" -ForegroundColor Gray
    Write-Host "  Account file: $accountFile" -ForegroundColor Gray

    $bodyObject = @{
        type = $typeId
        accountList = @($accountFile)
        fileType = 2
        fileList = @($videoFile)
        title = $title
        text = $text
        tags = Convert-TagsForMpp $tags
        location = 1
        enableTimer = 0
        videosPerDay = 1
        dailyTimes = @()
        startDays = 0
    }
    $body = $bodyObject | ConvertTo-Json -Depth 6

    try {
        $logPath = Join-Path $DailyDir ("publish_{0}_{1}.log" -f $platformName, (Get-Date).ToString("yyyyMMdd_HHmmss"))
        "REQUEST:`n$body`n" | Out-File -LiteralPath $logPath -Encoding UTF8
        $response = Invoke-RestMethod -Uri "$MppUrl/postVideo" -Method POST -ContentType "application/json; charset=utf-8" -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 300
        "RESPONSE:`n$($response | ConvertTo-Json -Depth 10)" | Add-Content -LiteralPath $logPath -Encoding UTF8
        if ($response -and $response.code -eq 200) {
            Write-Result $platformLabel "SUCCESS" $response.msg
        } else {
            Write-Result $platformLabel "FAIL" ($response.msg -as [string])
        }
    } catch {
        Write-Result $platformLabel "FAIL" $_.Exception.Message
    }

    if ($DelaySeconds -gt 0) {
        Start-Sleep -Seconds $DelaySeconds
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Publish summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$successCount = @($results | Where-Object { $_.Status -eq "SUCCESS" }).Count
$failCount = @($results | Where-Object { $_.Status -eq "FAIL" }).Count
$skipCount = @($results | Where-Object { $_.Status -eq "SKIP" }).Count
Write-Host "  Success: $successCount" -ForegroundColor Green
Write-Host "  Failed: $failCount" -ForegroundColor Red
Write-Host "  Skipped: $skipCount" -ForegroundColor Yellow

$results | ConvertTo-Json -Depth 3 | Out-File -FilePath "$DailyDir\publish_result.json" -Encoding UTF8
Write-Host "  Result saved: $DailyDir\publish_result.json" -ForegroundColor Gray

if ($failCount -gt 0) {
    exit 1
}
exit 0
