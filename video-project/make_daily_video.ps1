# AI资讯视频制作 - 完整链路脚本
# 修复版：使用 Python 生成 HTML，增加多重完整性检查，避免黑屏问题
param([string]$Date = (Get-Date).ToString("yyyyMMdd"))

$ErrorActionPreference = "Stop"
try {
    $RunDate = [datetime]::ParseExact($Date, "yyyyMMdd", [System.Globalization.CultureInfo]::InvariantCulture)
} catch {
    Write-Host "  错误: Date 参数必须是 yyyyMMdd 格式，例如 20260517。当前值: $Date" -ForegroundColor Red
    exit 1
}

$VoxRoot = "d:\VoxCPM\VoxCPM-2.0.3"
$VideoProject = "$VoxRoot\video-project"
$DailyDir = "$VideoProject\daily\$Date"
$NarrationDir = "$DailyDir\narration"
$InstallRoot = Split-Path -Parent $VoxRoot

# 工具绝对路径
$PackagedNodeExe = Join-Path $InstallRoot "tools\node.js\node.exe"
$LegacyNodeExe = "D:\编程工具\node.js\node.exe"
if (Test-Path $PackagedNodeExe) {
    $NodeExe = $PackagedNodeExe
} elseif (Test-Path $LegacyNodeExe) {
    $NodeExe = $LegacyNodeExe
} else {
    $NodeExe = "node"
}
$NodeDir = Split-Path -Parent $NodeExe

$HyperframesCli = Join-Path $VideoProject "node_modules\hyperframes\dist\cli.js"

$PackagedFfmpegBin = Join-Path $InstallRoot "tools\ffmpeg-8.1-full_build\bin"
$PackagedFfmpeg = Join-Path $PackagedFfmpegBin "ffmpeg.exe"
$PackagedFfprobe = Join-Path $PackagedFfmpegBin "ffprobe.exe"
$LegacyFfmpeg = "C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1-full_build\bin\ffmpeg.exe"
$LegacyFfprobe = "C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1-full_build\bin\ffprobe.exe"
if (Test-Path $PackagedFfmpeg) {
    $FfmpegPath = $PackagedFfmpeg
    $FfprobePath = $PackagedFfprobe
} elseif (Test-Path $LegacyFfmpeg) {
    $FfmpegPath = $LegacyFfmpeg
    $FfprobePath = $LegacyFfprobe
} else {
    $FfmpegPath = "ffmpeg"
    $FfprobePath = "ffprobe"
}

$PackagedPlaywrightBrowsers = Join-Path $InstallRoot "tools\ms-playwright"
if (Test-Path $PackagedPlaywrightBrowsers) {
    $env:PLAYWRIGHT_BROWSERS_PATH = $PackagedPlaywrightBrowsers
}

# 确保 node 在 PATH 中
if ($NodeDir) { $env:PATH = "$NodeDir;$env:PATH" }
if (Test-Path $PackagedFfmpegBin) { $env:PATH = "$PackagedFfmpegBin;$env:PATH" }

# 创建统一输出目录
$OutputRoot = "$VideoProject\output"
if (-not (Test-Path $OutputRoot)) { New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null }
$QaScript = "$VideoProject\qa_video.ps1"

function Run-Hyperframes {
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$CliArgs
    )
    if (-not $CliArgs -or $CliArgs.Count -eq 0) {
        throw "HyperFrames command missing"
    }
    $previousErrorActionPreference = $ErrorActionPreference
    $exitCode = 0
    try {
        # HyperFrames writes compiler warnings to stderr; they should be logged, not treated as terminating PowerShell errors.
        $ErrorActionPreference = "Continue"
        & $NodeExe $HyperframesCli @CliArgs 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($exitCode -ne 0) {
        throw "HyperFrames command failed: $($CliArgs -join ' ')"
    }
}

function Run-VideoQa {
    param(
        [Parameter(Mandatory=$true)][string]$VideoFile,
        [Parameter(Mandatory=$true)][string]$AudioFile
    )
    if (-not (Test-Path $QaScript)) {
        throw "QA script not found: $QaScript"
    }
    $previousErrorActionPreference = $ErrorActionPreference
    $exitCode = 0
    try {
        $ErrorActionPreference = "Continue"
        & powershell -NoProfile -ExecutionPolicy Bypass -File $QaScript `
            -VideoFile $VideoFile `
            -AudioFile $AudioFile `
            -MaxDurationDeltaSeconds 0.2 `
            -MaxBlackSeconds 1.0 `
            -MaxBlackRatio 0.02 2>&1 |
            Tee-Object -FilePath ([System.IO.Path]::ChangeExtension($VideoFile, ".qa.log"))
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($exitCode -ne 0) {
        throw "Video QA failed: $VideoFile"
    }
}

function Invoke-AiHotJson {
    param(
        [Parameter(Mandatory=$true)][System.Net.Http.HttpClient]$Client,
        [Parameter(Mandatory=$true)][string]$Url
    )

    $responseMsg = $Client.GetAsync($Url).GetAwaiter().GetResult()
    if (-not $responseMsg) { throw "AI HOT API 没有返回 HTTP 响应: $Url" }
    [void]$responseMsg.EnsureSuccessStatusCode()
    if (-not $responseMsg.Content) { throw "AI HOT API 响应没有 Content: $Url" }

    $jsonBytes = $responseMsg.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
    if (-not $jsonBytes -or $jsonBytes.Length -eq 0) { throw "AI HOT API 返回空内容: $Url" }
    $jsonStr = [System.Text.Encoding]::UTF8.GetString($jsonBytes)
    if ([string]::IsNullOrWhiteSpace($jsonStr)) { throw "AI HOT API 返回空 JSON 字符串: $Url" }

    $json = $jsonStr | ConvertFrom-Json
    if (-not $json) { throw "AI HOT JSON 解析结果为空: $Url" }
    return $json
}

function Convert-AiHotDailyArchiveToItems {
    param([Parameter(Mandatory=$true)]$DailyArchive)

    $items = @()
    if (-not ($DailyArchive.PSObject.Properties.Name -contains "sections")) {
        return @()
    }

    $archivePublishedAt = $DailyArchive.generatedAt
    if (-not $archivePublishedAt) { $archivePublishedAt = $DailyArchive.windowEnd }

    foreach ($section in @($DailyArchive.sections)) {
        if (-not $section) { continue }
        $sectionLabel = [string]$section.label
        if ([string]::IsNullOrWhiteSpace($sectionLabel)) { $sectionLabel = "AI HOT" }

        foreach ($rawItem in @($section.items)) {
            if (-not $rawItem -or [string]::IsNullOrWhiteSpace([string]$rawItem.title)) { continue }

            $sourceName = [string]$rawItem.sourceName
            if ([string]::IsNullOrWhiteSpace($sourceName)) { $sourceName = $sectionLabel }

            $items += [PSCustomObject]@{
                title = [string]$rawItem.title
                summary = [string]$rawItem.summary
                source = $sourceName
                url = [string]$rawItem.sourceUrl
                publishedAt = [string]$archivePublishedAt
                category = $sectionLabel
            }
        }
    }

    return @($items)
}

function Split-VoiceText {
    param(
        [Parameter(Mandatory=$true)][string]$Text,
        [int]$MaxChars = 160
    )
    $cleanText = $Text.Trim()
    if ($cleanText.Length -le $MaxChars) {
        return @($cleanText)
    }

    $parts = @()
    $current = ""
    $sentences = [System.Text.RegularExpressions.Regex]::Split($cleanText, "(?<=[。！？!?；;])")
    foreach ($sentence in $sentences) {
        $piece = $sentence.Trim()
        if ([string]::IsNullOrWhiteSpace($piece)) { continue }

        if (($current.Length + $piece.Length) -le $MaxChars) {
            $current = "$current$piece"
            continue
        }

        if (-not [string]::IsNullOrWhiteSpace($current)) {
            $parts += $current
            $current = ""
        }

        while ($piece.Length -gt $MaxChars) {
            $parts += $piece.Substring(0, $MaxChars)
            $piece = $piece.Substring($MaxChars)
        }
        $current = $piece
    }

    if (-not [string]::IsNullOrWhiteSpace($current)) {
        $parts += $current
    }
    return $parts
}

# 视觉风格轮换 (按 Date 参数的星期几)
$DayOfWeek = [int]$RunDate.DayOfWeek
$Styles = @(
    @{ name="Signal Radar";    primary="#667eea"; secondary="#764ba2"; accent="#00d4ff"; bg="#0a0a0f"; label="雷达扫描" },
    @{ name="Deep Space";      primary="#4f46e5"; secondary="#7c3aed"; accent="#22d3ee"; bg="#050510"; label="星际简报" },
    @{ name="Command Center";  primary="#10b981"; secondary="#059669"; accent="#34d399"; bg="#0a0f0a"; label="指挥中心" },
    @{ name="Magazine Motion"; primary="#f59e0b"; secondary="#d97706"; accent="#fbbf24"; bg="#0f0a0a"; label="杂志动态" },
    @{ name="Neon Dataflow";   primary="#ec4899"; secondary="#db2777"; accent="#f472b6"; bg="#0f0a0a"; label="霓虹数据" },
    @{ name="Signal Radar";    primary="#667eea"; secondary="#764ba2"; accent="#00d4ff"; bg="#0a0a0f"; label="雷达扫描" },
    @{ name="Deep Space";      primary="#4f46e5"; secondary="#7c3aed"; accent="#22d3ee"; bg="#050510"; label="星际简报" }
)
$StyleIndex = $DayOfWeek % $Styles.Count
$Style = $Styles[$StyleIndex]
if (-not $Style) {
    Write-Host "  错误: 无法获取视觉样式 (DayOfWeek=$DayOfWeek, Index=$StyleIndex)" -ForegroundColor Red
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AI资讯视频自动生成 日期: $Date" -ForegroundColor Cyan
Write-Host "  视觉风格: $($Style.name) ($($Style.label))" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 创建目录
if (-not (Test-Path $DailyDir)) { New-Item -ItemType Directory -Force -Path $DailyDir | Out-Null }
if (-not (Test-Path $NarrationDir)) { New-Item -ItemType Directory -Force -Path $NarrationDir | Out-Null }
# 清理旧 composition 文件
if (Test-Path "$DailyDir\compositions") { Remove-Item "$DailyDir\compositions\*" -Force -ErrorAction SilentlyContinue }
else { New-Item -ItemType Directory -Force -Path "$DailyDir\compositions" | Out-Null }
$staleArtifacts = @(
    "$DailyDir\daily_$Date.mp4",
    "$DailyDir\daily_${Date}_draft.mp4",
    "$DailyDir\daily_${Date}_vertical.mp4",
    "$DailyDir\narration\daily_$Date.wav",
    "$VideoProject\narration\daily_$Date.wav",
    "$OutputRoot\daily_$Date.mp4",
    "$OutputRoot\daily_${Date}_draft.mp4",
    "$OutputRoot\daily_${Date}_vertical.mp4"
)
foreach ($artifact in $staleArtifacts) {
    Remove-Item -LiteralPath $artifact -Force -ErrorAction SilentlyContinue
}

# ========== 步骤1: 获取AI资讯 ==========
Write-Host "`n[步骤1] 获取 $Date AI资讯..." -ForegroundColor Yellow
$UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 aihot-skill/0.2.0"
$targetDay = $RunDate.ToString("yyyy-MM-dd")
$archiveUrl = "https://aihot.virxact.com/api/public/daily/$targetDay"

$handler = $null
$client = $null
try {
    $today = (Get-Date).Date
    if ($RunDate.Date -gt $today) {
        throw "Date 不能是未来日期。当前日期: $($today.ToString('yyyyMMdd'))，请求日期: $Date"
    }

    # 使用 HttpClient 直接获取原始字节，避免 PowerShell 编码问题
    Add-Type -AssemblyName System.Net.Http
    $handler = New-Object System.Net.Http.HttpClientHandler
    if (-not $handler) { throw "无法创建 HttpClientHandler" }
    $client = New-Object System.Net.Http.HttpClient($handler)
    if (-not $client) { throw "无法创建 HttpClient" }
    [void]$client.DefaultRequestHeaders.TryAddWithoutValidation("User-Agent", $UA)

    $newsItems = @()
    $archiveError = $null
    try {
        Write-Host "  优先读取日报归档: $archiveUrl" -ForegroundColor DarkGray
        $dailyArchive = Invoke-AiHotJson -Client $client -Url $archiveUrl
        $newsItems = @(Convert-AiHotDailyArchiveToItems -DailyArchive $dailyArchive | Select-Object -First 10)
    } catch {
        $archiveError = $_
        Write-Host "  日报归档读取失败: $archiveError" -ForegroundColor Yellow
    }

    if ($newsItems.Count -eq 0 -and $RunDate.Date -eq $today) {
        $since = $RunDate.Date.AddDays(-1).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $url = "https://aihot.virxact.com/api/public/items?mode=selected&since=$since&take=10"
        Write-Host "  今日归档为空，改用实时精选接口: $url" -ForegroundColor Yellow
        $response = Invoke-AiHotJson -Client $client -Url $url
        if (-not ($response.PSObject.Properties.Name -contains "items")) {
            throw "AI HOT JSON 缺少 items 字段"
        }
        $newsItems = @($response.items | Where-Object { $_ -and $_.title } | Select-Object -First 10)
    }

    if ($newsItems.Count -eq 0) {
        if ($archiveError) {
            throw "AI HOT $Date 日报归档为空或不可用；为避免日期错配，非今日日期不会回退到最近资讯接口。归档错误: $archiveError"
        }
        throw "AI HOT $Date 日报归档为空，无法生成日报"
    }
    Write-Host "  获取到 $($newsItems.Count) 条资讯" -ForegroundColor Green
    $newsItems | ConvertTo-Json -Depth 5 | Out-File -FilePath "$DailyDir\aihot_items.json" -Encoding UTF8
} catch {
    Write-Host "  错误: 无法获取AI资讯 - $_" -ForegroundColor Red
    exit 1
} finally {
    if ($client) { $client.Dispose() }
    if ($handler) { $handler.Dispose() }
}

# ========== 步骤2: 生成视频脚本 ==========
Write-Host "`n[步骤2] 生成视频脚本..." -ForegroundColor Yellow
$zhCn = [System.Globalization.CultureInfo]::GetCultureInfo("zh-CN")
$dateStr = $RunDate.ToString("yyyy年M月d日", $zhCn)
$weekDay = $RunDate.ToString("dddd", $zhCn)

# 随机开场白，让每次视频更生动
$openings = @(
    "哈喽大家好！欢迎来到今日AI资讯速递，我是您的AI新闻主播。$dateStr，$weekDay，一起来看看今天AI圈都发生了哪些大事。",
    "大家好！这里是AI HOT每日播报，今天是$dateStr $weekDay。最新鲜的AI行业资讯，马上为您带来。",
    "欢迎收看今天的AI热点快报！我是人工智能资讯主播，今天$dateStr $weekDay，精选了$($newsItems.Count)条最重要的AI新闻，马上开始。",
    "嘿，各位科技爱好者！欢迎锁定AI HOT日报。今天是$dateStr $weekDay，让我们快速浏览今日AI领域最值得关注的动态。"
)
$opening = $openings[(Get-Random -Minimum 0 -Maximum $openings.Count)]

# 随机结束语
$endings = @(
    "好了，以上就是今天全部的AI资讯内容。感谢您的收看，我们明天同一时间，再见！",
    "今天的AI热点就分享到这里。喜欢内容别忘了点赞关注，明天继续为你带来最新鲜的行业资讯，拜拜！",
    "今日AI资讯播报完毕。感谢陪伴，我们明天再会，记得关注获取每日AI最新动态哦！",
    "这就是今天的十条精选AI新闻。感谢收看，明天同一时间，我们继续解读AI行业新动态，再见啦！"
)
$ending = $endings[(Get-Random -Minimum 0 -Maximum $endings.Count)]

$scriptBlocks = @()
$scriptBlocks += [PSCustomObject]@{
    id = "intro"
    type = "intro"
    title = "开场"
    text = $opening
}

$scriptLines = @($opening, "")
for ($i = 0; $i -lt $newsItems.Count; $i++) {
    $item = $newsItems[$i]
    # 更自然的播报语气
    $blockText = "来看第$($i+1)条新闻。$($item.title)。$($item.summary)"
    $scriptBlocks += [PSCustomObject]@{
        id = "news-$($i+1)"
        type = "news"
        title = [string]$item.title
        text = $blockText
    }
    $scriptLines += $blockText
    $scriptLines += ""
}
$scriptBlocks += [PSCustomObject]@{
    id = "outro"
    type = "outro"
    title = "结尾"
    text = $ending
}
$scriptLines += $ending
$scriptTxt = $scriptLines -join "`r`n"

$scriptFile = "$DailyDir\script.txt"
[IO.File]::WriteAllText($scriptFile, $scriptTxt, [System.Text.Encoding]::UTF8)
Write-Host "  脚本已保存到: $scriptFile" -ForegroundColor Green

$voiceBlocks = @()
foreach ($block in $scriptBlocks) {
    $parts = @(Split-VoiceText -Text ([string]$block.text) -MaxChars 160)
    for ($partIndex = 0; $partIndex -lt $parts.Count; $partIndex++) {
        $partId = if ($parts.Count -eq 1) { [string]$block.id } else { "$($block.id)-part-$($partIndex + 1)" }
        $voiceBlocks += [PSCustomObject]@{
            id = $partId
            scene_id = [string]$block.id
            type = [string]$block.type
            title = [string]$block.title
            text = [string]$parts[$partIndex]
        }
    }
}
$scriptBlocks = $voiceBlocks

$segmentScriptDir = "$DailyDir\script_segments"
if (Test-Path $segmentScriptDir) { Remove-Item "$segmentScriptDir\*" -Force -ErrorAction SilentlyContinue }
else { New-Item -ItemType Directory -Force -Path $segmentScriptDir | Out-Null }
foreach ($block in $scriptBlocks) {
    [IO.File]::WriteAllText((Join-Path $segmentScriptDir "$($block.id).txt"), [string]$block.text, [System.Text.Encoding]::UTF8)
}
$segmentsManifest = "$DailyDir\voice_segments.json"
$scriptBlocks | ConvertTo-Json -Depth 5 | Out-File -FilePath $segmentsManifest -Encoding UTF8
Write-Host "  已拆分为 $($scriptBlocks.Count) 段配音脚本，每段单独生成后再拼接" -ForegroundColor Green

# ========== 步骤3: 自动截图新闻证据图片 ==========
Write-Host "`n[步骤3] 使用Playwright自动截图新闻原文..." -ForegroundColor Yellow
& $VoxRoot\venv\Scripts\python.exe "$VideoProject\screenshot_news.py" $DailyDir "$DailyDir\aihot_items.json"
if ($LASTEXITCODE -ne 0) {
    Write-Host "  警告: 部分截图失败，但继续制作视频" -ForegroundColor Yellow
}
Write-Host "  截图流程完成" -ForegroundColor Green

# ========== 步骤4: 分段生成VoxCPM配音 ==========
Write-Host "`n[步骤4] 分段生成VoxCPM配音并拼接 (预计5-10分钟)..." -ForegroundColor Yellow
$outputWav = "$NarrationDir\daily_$Date.wav"
$legacyOutputWav = "$VideoProject\narration\daily_$Date.wav"
$segmentAudioDir = "$NarrationDir\segments"
if (Test-Path $segmentAudioDir) { Remove-Item "$segmentAudioDir\*" -Force -ErrorAction SilentlyContinue }
else { New-Item -ItemType Directory -Force -Path $segmentAudioDir | Out-Null }

try {
    $os = Get-CimInstance Win32_OperatingSystem
    $freeVirtualGb = [math]::Round($os.FreeVirtualMemory / 1MB, 1)
    if ($freeVirtualGb -lt 18) {
        throw "当前可用虚拟内存约 ${freeVirtualGb}GB，低于 VoxCPM 的安全阈值。请先关闭浏览器/视频工具，或把 Windows 页面文件提高到 32GB 以上后再运行。"
    }
} catch {
    if ($_.Exception.Message -like "*虚拟内存约*") {
        Write-Host "  错误: $_" -ForegroundColor Red
        exit 1
    }
    Write-Host "  警告: 无法读取虚拟内存状态，继续尝试生成配音" -ForegroundColor Yellow
}

Set-Location $VoxRoot
$voiceLog = "$DailyDir\voice_generation.log"
$previousErrorActionPreference = $ErrorActionPreference
$voiceExitCode = 0
try {
    $ErrorActionPreference = "Continue"
    & .\venv\Scripts\python.exe "$VideoProject\generate_voice_template.py" --segments-json $segmentsManifest --output-dir $segmentAudioDir 2>&1 |
        Tee-Object -FilePath $voiceLog
    $voiceExitCode = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $previousErrorActionPreference
}
if ($voiceExitCode -ne 0) {
    $voiceLogText = ""
    if (Test-Path $voiceLog) {
        $voiceLogText = Get-Content -LiteralPath $voiceLog -Raw -ErrorAction SilentlyContinue
    }
    if ($voiceLogText -match "1455|页面文件|paging file|page file") {
        Write-Host "  错误: VoxCPM 模型加载失败，检测到 Windows 1455/页面文件不足。" -ForegroundColor Red
        Write-Host "  处理办法: 关闭浏览器/视频软件后重试；或把 Windows 虚拟内存/页面文件调到 32GB 以上并重启。" -ForegroundColor Red
        Write-Host "  详细日志: $voiceLog" -ForegroundColor Yellow
    }
    Write-Host "  错误: 分段配音生成失败，退出码 $voiceExitCode" -ForegroundColor Red
    exit 1
}

$segmentResultPath = Join-Path $segmentAudioDir "segments_result.json"
$segmentResultsById = @{}
if (Test-Path $segmentResultPath) {
    $segmentResults = @(Get-Content -LiteralPath $segmentResultPath -Raw -Encoding UTF8 | ConvertFrom-Json)
    foreach ($result in $segmentResults) {
        if ($result.id -and $result.path) {
            $segmentResultsById[[string]$result.id] = [string]$result.path
        }
    }
}

$segmentAudioFiles = @()
foreach ($block in $scriptBlocks) {
    $segmentWav = if ($segmentResultsById.ContainsKey([string]$block.id)) {
        $segmentResultsById[[string]$block.id]
    } else {
        Join-Path $segmentAudioDir "$($block.id).wav"
    }
    if (-not (Test-Path $segmentWav)) {
        Write-Host "  错误: 分段配音缺失: $segmentWav" -ForegroundColor Red
        exit 1
    }
    if ((Get-Item $segmentWav).Length -lt 10000) {
        Write-Host "  错误: 分段配音文件过小: $segmentWav" -ForegroundColor Red
        exit 1
    }
    $segmentAudioFiles += $segmentWav
}

$concatList = Join-Path $segmentAudioDir "concat_audio.txt"
$concatLines = @()
foreach ($file in $segmentAudioFiles) {
    $safePath = ([string]$file).Replace("\", "/").Replace("'", "'\''")
    $concatLines += "file '$safePath'"
}
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllLines($concatList, $concatLines, $utf8NoBom)

& $FfmpegPath -hide_banner -loglevel error -y -f concat -safe 0 -i $concatList -acodec pcm_s16le $outputWav
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $outputWav)) {
    Write-Host "  错误: ffmpeg 拼接配音失败" -ForegroundColor Red
    exit 1
}
if ((Get-Item $outputWav).Length -lt 100000) {
    Write-Host "  错误: 拼接后的配音文件过小 ($([math]::Round((Get-Item $outputWav).Length/1KB)) KB)，可能生成不完整" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path "$VideoProject\narration")) { New-Item -ItemType Directory -Force -Path "$VideoProject\narration" | Out-Null }
Copy-Item -LiteralPath $outputWav -Destination $legacyOutputWav -Force
Write-Host "  配音已生成: $outputWav ($([math]::Round((Get-Item $outputWav).Length/1MB,1)) MB)" -ForegroundColor Green

# ========== 步骤5: 测量配音时长 ==========
Write-Host "`n[步骤5] 测量分段时长并生成场景时间轴..." -ForegroundColor Yellow
try {
    $audioDurationText = (& $FfprobePath -v error -show_entries format=duration -of default=nk=1:nw=1 $outputWav | Select-Object -First 1)
    $audioDuration = [double]::Parse(([string]$audioDurationText).Trim(), [System.Globalization.CultureInfo]::InvariantCulture)
    Write-Host "  拼接配音时长: $([math]::Round($audioDuration, 1)) 秒" -ForegroundColor Green
} catch {
    Write-Host "  错误: 无法测量拼接配音时长 - $_" -ForegroundColor Red
    exit 1
}

$timingSegments = @()
$currentStart = 0.0
for ($idx = 0; $idx -lt $scriptBlocks.Count; $idx++) {
    $block = $scriptBlocks[$idx]
    $segmentFile = $segmentAudioFiles[$idx]
    try {
        $segmentDurationText = (& $FfprobePath -v error -show_entries format=duration -of default=nk=1:nw=1 $segmentFile | Select-Object -First 1)
        $segmentDuration = [double]::Parse(([string]$segmentDurationText).Trim(), [System.Globalization.CultureInfo]::InvariantCulture)
    } catch {
        Write-Host "  错误: 无法测量分段配音时长: $segmentFile" -ForegroundColor Red
        exit 1
    }
    $timingSegments += [PSCustomObject]@{
        id = [string]$block.id
        scene_id = if ($block.PSObject.Properties.Name -contains "scene_id") { [string]$block.scene_id } else { [string]$block.id }
        type = [string]$block.type
        title = [string]$block.title
        start = [math]::Round($currentStart, 3)
        duration = [math]::Round($segmentDuration, 3)
        audio = [string]$segmentFile
    }
    $currentStart += $segmentDuration
}

$segmentSum = ($timingSegments | Measure-Object -Property duration -Sum).Sum
$delta = $audioDuration - $segmentSum
if ([math]::Abs($delta) -gt 0.005 -and $timingSegments.Count -gt 0) {
    $lastIndex = $timingSegments.Count - 1
    $timingSegments[$lastIndex].duration = [math]::Round($timingSegments[$lastIndex].duration + $delta, 3)
}

$newsCount = $newsItems.Count
$introDuration = [double](($timingSegments | Where-Object { $_.scene_id -eq "intro" } | Measure-Object -Property duration -Sum).Sum)
$outroDuration = [double](($timingSegments | Where-Object { $_.scene_id -eq "outro" } | Measure-Object -Property duration -Sum).Sum)
$newsSceneDurations = @()
for ($i = 1; $i -le $newsCount; $i++) {
    $sceneId = "news-$i"
    $sceneDurationSum = ($timingSegments | Where-Object { $_.scene_id -eq $sceneId } | Measure-Object -Property duration -Sum).Sum
    if ($null -ne $sceneDurationSum) {
        $newsSceneDurations += [double]$sceneDurationSum
    }
}
$newsDuration = if ($newsSceneDurations.Count -gt 0) { [double](($newsSceneDurations | Measure-Object -Average).Average) } else { 0.0 }
$totalDuration = [math]::Round(($timingSegments | Measure-Object -Property duration -Sum).Sum, 3)

$audioTimingPath = "$DailyDir\audio_timing.json"
[PSCustomObject]@{
    date = $Date
    total_duration = $totalDuration
    segments = $timingSegments
} | ConvertTo-Json -Depth 5 | Out-File -FilePath $audioTimingPath -Encoding UTF8

Write-Host "  场景分配: 开场 $([math]::Round($introDuration,3))s + $newsCount 条新闻按真实配音时长 + 结尾 $([math]::Round($outroDuration,3))s = $([math]::Round($totalDuration,3))s" -ForegroundColor Green

# ========== 步骤6: 生成HTML场景 ==========
Write-Host "`n[步骤6] 生成HyperFrames HTML场景..." -ForegroundColor Yellow

# 配音已在 daily 目录中，供 index.html 引用
if (-not (Test-Path "$NarrationDir\daily_$Date.wav")) {
    Write-Host "  错误: 配音文件不存在，无法生成视频" -ForegroundColor Red
    exit 1
}
Write-Host "  配音已就绪: $NarrationDir" -ForegroundColor Green

$p = $Style.primary
$s = $Style.secondary
$a = $Style.accent
$bg = $Style.bg

# 使用 Python 生成 HTML 场景（更可靠，避免 PowerShell 编码问题）
Write-Host "  使用 Python 生成 HTML 场景..." -ForegroundColor Yellow

# 创建临时 JSON 传给 Python
$newsItemsJson = $newsItems | Select-Object title,summary,source | ConvertTo-Json -Depth 3
$segmentsJson = $timingSegments | Select-Object id,scene_id,type,title,start,duration | ConvertTo-Json -Depth 5
$tempJson = @"
{
    "news_items": $newsItemsJson,
    "style_name": "$($Style.name)",
    "style_label": "$($Style.label)",
    "intro_duration": $introDuration,
    "outro_duration": $outroDuration,
    "news_duration": $newsDuration,
    "total_duration": $totalDuration,
    "segments": $segmentsJson
}
"@
$tempJsonFile = "$DailyDir\temp_generate_config.json"
$tempJson | Out-File -FilePath $tempJsonFile -Encoding UTF8

# 调用 Python 生成
& $VoxRoot\venv\Scripts\python.exe "$VideoProject\generate_html.py" $DailyDir $Date $p $s $a $bg $tempJsonFile
if ($LASTEXITCODE -ne 0) {
    Write-Host "  错误: Python HTML生成失败，退出码 $LASTEXITCODE" -ForegroundColor Red
    exit 1
}

# 删除临时文件
if (Test-Path $tempJsonFile) {
    Remove-Item $tempJsonFile -Force
}

# ========== 完整性检查：确保所有HTML文件都生成成功 ==========
Write-Host "`n[检查] 验证HTML文件完整性..." -ForegroundColor Yellow
$expectedFiles = @(
    "$DailyDir\compositions\daily-intro.html",
    "$DailyDir\compositions\daily-outro.html",
    "$DailyDir\index.html"
)
for ($i = 1; $i -le $newsItems.Count; $i++) {
    $expectedFiles += "$DailyDir\compositions\news-item-$i.html"
}
$missingFiles = @()
foreach ($file in $expectedFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}
if ($missingFiles.Count -gt 0) {
    Write-Host "  错误: 以下HTML文件生成失败 ($($missingFiles.Count) 个缺失):" -ForegroundColor Red
    foreach ($f in $missingFiles) {
        Write-Host "    - $f" -ForegroundColor Red
    }
    Write-Host "  终止流水线，请检查问题后重试" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] 所有 $($expectedFiles.Count) 个HTML文件检查通过" -ForegroundColor Green

# ========== 步骤7: Lint检查 ==========
Write-Host "`n[步骤7] 运行HyperFrames检查..." -ForegroundColor Yellow
Set-Location $DailyDir
Write-Host "  运行 lint / inspect..." -ForegroundColor Yellow
try {
    $lintArgs = @("lint")
    $inspectArgs = @("inspect")
    Run-Hyperframes @lintArgs 2>&1 | Tee-Object -FilePath "$DailyDir\lint.log"
    Run-Hyperframes @inspectArgs 2>&1 | Tee-Object -FilePath "$DailyDir\inspect.log"
    Write-Host "  HyperFrames检查通过" -ForegroundColor Green
} catch {
    Write-Host "  HyperFrames检查失败，终止渲染: $_" -ForegroundColor Red
    exit 1
}

# ========== 步骤8: 渲染视频 - 带重试机制 ==========
Write-Host "`n[步骤8] 渲染视频 (带自动重试)..." -ForegroundColor Yellow
$renderSuccess = $false
$maxRenderRetries = 2

for ($retry = 1; $retry -le $maxRenderRetries; $retry++) {
    Write-Host "  尝试渲染 (尝试 $retry/$maxRenderRetries)..." -ForegroundColor Yellow
    try {
        $renderDraftArgs = @("render", "-o", "daily_${Date}_draft.mp4", "-f", "30", "-q", "draft")
        Run-Hyperframes @renderDraftArgs 2>&1 | Tee-Object -FilePath "$DailyDir\render_draft_attempt_$retry.log"
    } catch {
        Write-Host "  Draft渲染失败: $_" -ForegroundColor Red
        if ($retry -lt $maxRenderRetries) {
            Write-Host "  等待 5 秒后重试..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
        continue
    }

    # QA检测 - 时长同步 + 黑屏检测
    if (Test-Path "$DailyDir\daily_${Date}_draft.mp4") {
        try {
            Run-VideoQa "$DailyDir\daily_${Date}_draft.mp4" "$NarrationDir\daily_$Date.wav"
            Write-Host "  Draft视频QA通过" -ForegroundColor Green
            $renderSuccess = $true
            break
        } catch {
            Write-Host "  Draft视频QA失败: $_" -ForegroundColor Red
            Remove-Item "$DailyDir\daily_${Date}_draft.mp4" -Force -ErrorAction SilentlyContinue
        }
    }

    if (-not $renderSuccess -and $retry -lt $maxRenderRetries) {
        Write-Host "  等待 5 秒后重试..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    }
}

if ($renderSuccess) {
    Write-Host "  Draft渲染成功，进行标准质量渲染..." -ForegroundColor Green
    try {
        $renderStandardArgs = @("render", "-o", "daily_$Date.mp4", "-f", "30", "-q", "standard")
        Run-Hyperframes @renderStandardArgs 2>&1 | Tee-Object -FilePath "$DailyDir\render.log"
        Run-VideoQa "$DailyDir\daily_$Date.mp4" "$NarrationDir\daily_$Date.wav"
        Write-Host "  标准视频QA通过" -ForegroundColor Green
    } catch {
        Write-Host "  标准渲染或QA失败，保留draft版本: $_" -ForegroundColor Yellow
        Remove-Item "$DailyDir\daily_$Date.mp4" -Force -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "  所有渲染尝试都失败了" -ForegroundColor Red
    exit 1
}

# ========== 步骤9: 生成竖屏版 ==========
Write-Host "`n[步骤9] 生成竖屏版(9:16)..." -ForegroundColor Yellow
$horizontalFile = "$DailyDir\daily_$Date.mp4"
$verticalFile = "$DailyDir\daily_${Date}_vertical.mp4"
if (Test-Path $horizontalFile) {
    try {
        # 使用FFmpeg将横屏转为竖屏: 居中裁剪+缩放,保持原始比例
        $previousErrorActionPreference = $ErrorActionPreference
        $ffmpegExitCode = 0
        try {
            $ErrorActionPreference = "Continue"
            & $FfmpegPath -y -i $horizontalFile -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=black" -c:a copy $verticalFile 2>&1 | Out-Null
            $ffmpegExitCode = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }
        if ($ffmpegExitCode -ne 0) {
            throw "ffmpeg 竖屏转码失败，退出码 $ffmpegExitCode"
        }
        if (Test-Path $verticalFile) {
            Run-VideoQa $verticalFile "$NarrationDir\daily_$Date.wav"
            Write-Host "  竖屏版已生成: $verticalFile" -ForegroundColor Green
        } else {
            Write-Host "  竖屏版生成失败" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  竖屏版生成异常: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  横屏版不存在,跳过竖屏生成" -ForegroundColor Yellow
}

# ========== 完成 ==========
$outputFile = "$DailyDir\daily_$Date.mp4"
$verticalFile = "$DailyDir\daily_${Date}_vertical.mp4"
if (Test-Path $outputFile) {
    Run-VideoQa $outputFile "$NarrationDir\daily_$Date.wav"
    # 复制到统一输出目录
    Copy-Item $outputFile -Destination "$OutputRoot\daily_$Date.mp4" -Force
    if (Test-Path $verticalFile) {
        Copy-Item $verticalFile -Destination "$OutputRoot\daily_${Date}_vertical.mp4" -Force
    }

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  视频制作完成！" -ForegroundColor Green
    Write-Host "  项目目录: $outputFile" -ForegroundColor Green
    Write-Host "  统一输出: $OutputRoot\daily_$Date.mp4" -ForegroundColor Green
    if (Test-Path $verticalFile) {
        Write-Host "  竖屏输出: $OutputRoot\daily_${Date}_vertical.mp4" -ForegroundColor Green
    }
    Write-Host "========================================" -ForegroundColor Cyan
    exit 0
} elseif (Test-Path "$DailyDir\daily_${Date}_draft.mp4") {
    # 复制draft到统一输出目录
    Copy-Item "$DailyDir\daily_${Date}_draft.mp4" -Destination "$OutputRoot\daily_${Date}_draft.mp4" -Force

    Write-Host "`n========================================" -ForegroundColor Yellow
    Write-Host "  仅Draft版本可用" -ForegroundColor Yellow
    Write-Host "  项目目录: $DailyDir\daily_${Date}_draft.mp4" -ForegroundColor Yellow
    Write-Host "  统一输出: $OutputRoot\daily_${Date}_draft.mp4" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n========================================" -ForegroundColor Red
    Write-Host "  视频渲染失败！" -ForegroundColor Red
    Write-Host "  请查看 render.log" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    exit 1
}
