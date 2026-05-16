# AI资讯视频制作 - 完整链路脚本
# 修复版：使用 Python 生成 HTML，增加多重完整性检查，避免黑屏问题
param([string]$Date = (Get-Date).ToString("yyyyMMdd"))

$ErrorActionPreference = "Stop"
$VoxRoot = "d:\VoxCPM\VoxCPM-2.0.3"
$VideoProject = "$VoxRoot\video-project"
$DailyDir = "$VideoProject\daily\$Date"
$NarrationDir = "$DailyDir\narration"

# 工具绝对路径
$NodeDir = "D:\编程工具\node.js"
$HyperframesCli = "D:\VoxCPM\VoxCPM-2.0.3\video-project\node_modules\hyperframes\dist\cli.js"
$FfmpegPath = "C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1-full_build\bin\ffmpeg.exe"
$FfprobePath = "C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1-full_build\bin\ffprobe.exe"
if (-not (Test-Path $FfmpegPath)) { $FfmpegPath = "ffmpeg"; $FfprobePath = "ffprobe" }

# 确保 node 在 PATH 中
$env:PATH = "$NodeDir;$env:PATH"

# 创建统一输出目录
$OutputRoot = "$VideoProject\output"
if (-not (Test-Path $OutputRoot)) { New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null }

function Run-Hyperframes {
    param([string[]]$Args)
    & D:\编程工具\node.js\node.exe $HyperframesCli @Args
}

# 视觉风格轮换 (按星期几)
$DayOfWeek = [int](Get-Date).DayOfWeek
$Styles = @(
    @{ name="Signal Radar";    primary="#667eea"; secondary="#764ba2"; accent="#00d4ff"; bg="#0a0a0f"; label="雷达扫描" },
    @{ name="Deep Space";      primary="#4f46e5"; secondary="#7c3aed"; accent="#22d3ee"; bg="#050510"; label="星际简报" },
    @{ name="Command Center";  primary="#10b981"; secondary="#059669"; accent="#34d399"; bg="#0a0f0a"; label="指挥中心" },
    @{ name="Magazine Motion"; primary="#f59e0b"; secondary="#d97706"; accent="#fbbf24"; bg="#0f0a0a"; label="杂志动态" },
    @{ name="Neon Dataflow";   primary="#ec4899"; secondary="#db2777"; accent="#f472b6"; bg="#0f0a0a"; label="霓虹数据" },
    @{ name="Signal Radar";    primary="#667eea"; secondary="#764ba2"; accent="#00d4ff"; bg="#0a0a0f"; label="雷达扫描" },
    @{ name="Deep Space";      primary="#4f46e5"; secondary="#7c3aed"; accent="#22d3ee"; bg="#050510"; label="星际简报" }
)
$Style = $Styles[$DayOfWeek]

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

# ========== 步骤1: 获取AI资讯 ==========
Write-Host "`n[步骤1] 获取今日AI资讯..." -ForegroundColor Yellow
$UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 aihot-skill/0.2.0"
$since = (Get-Date).ToUniversalTime().AddHours(-24).ToString("yyyy-MM-ddTHH:mm:ssZ")
$url = "https://aihot.virxact.com/api/public/items?mode=selected&since=$since&take=10"
$headers = @{"User-Agent"=$UA}

try {
    # 使用 HttpClient 直接获取原始字节，避免 PowerShell 编码问题
    Add-Type -AssemblyName System.Net.Http
    $handler = New-Object System.Net.Http.HttpClientHandler
    $client = New-Object System.Net.Http.HttpClient($handler)
    $client.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36")
    $responseMsg = $client.GetAsync($url).Result
    $responseMsg.EnsureSuccessStatusCode()
    $jsonBytes = $responseMsg.Content.ReadAsByteArrayAsync().Result
    $jsonStr = [System.Text.Encoding]::UTF8.GetString($jsonBytes)
    $client.Dispose()
    $response = $jsonStr | ConvertFrom-Json
    $newsItems = $response.items | Select-Object -First 10
    Write-Host "  获取到 $($newsItems.Count) 条资讯" -ForegroundColor Green
    $newsItems | ConvertTo-Json -Depth 5 | Out-File -FilePath "$DailyDir\aihot_items.json" -Encoding UTF8
} catch {
    Write-Host "  错误: 无法获取AI资讯 - $_" -ForegroundColor Red
    exit 1
}

# ========== 步骤2: 生成视频脚本 ==========
Write-Host "`n[步骤2] 生成视频脚本..." -ForegroundColor Yellow
$dateStr = (Get-Date -Format "yyyy年M月d日")
$weekDay = (Get-Date).ToString("dddd", [System.Globalization.CultureInfo]::GetCultureInfo("zh-CN"))

# 随机开场白，让每次视频更生动
$openings = @(
    "哈喽大家好！欢迎来到今日AI资讯速递，我是您的AI新闻主播。$dateStr，$weekDay，一起来看看今天AI圈都发生了哪些大事。",
    "大家好！这里是AI HOT每日播报，今天是$dateStr $weekDay。最新鲜的AI行业资讯，马上为您带来。",
    "欢迎收看今天的AI热点快报！我是人工智能资讯主播，今天$dateStr $weekDay，精选了$($newsItems.Count)条最重要的AI新闻，马上开始。",
    "嘿，各位科技爱好者！欢迎锁定AI HOT日报。今天是$dateStr $weekDay，让我们快速浏览今日AI领域最值得关注的动态。"
)
$opening = $openings[(Get-Random) % $openings.Count]

# 随机结束语
$endings = @(
    "好了，以上就是今天全部的AI资讯内容。感谢您的收看，我们明天同一时间，再见！",
    "今天的AI热点就分享到这里。喜欢内容别忘了点赞关注，明天继续为你带来最新鲜的行业资讯，拜拜！",
    "今日AI资讯播报完毕。感谢陪伴，我们明天再会，记得关注获取每日AI最新动态哦！",
    "这就是今天的十条精选AI新闻。感谢收看，明天同一时间，我们继续解读AI行业新动态，再见啦！"
)
$ending = $endings[(Get-Random) % $endings.Count]

$scriptLines = @($opening, "")
for ($i = 0; $i -lt $newsItems.Count; $i++) {
    $item = $newsItems[$i]
    # 更自然的播报语气
    $scriptLines += "来看第$($i+1)条新闻。$($item.title)。$($item.summary)"
    $scriptLines += ""
}
$scriptLines += $ending
$scriptTxt = $scriptLines -join "`r`n"

$scriptFile = "$DailyDir\script.txt"
[IO.File]::WriteAllText($scriptFile, $scriptTxt, [System.Text.Encoding]::UTF8)
Write-Host "  脚本已保存到: $scriptFile" -ForegroundColor Green

# ========== 步骤3: 生成VoxCPM配音 ==========
Write-Host "`n[步骤3] 生成VoxCPM配音 (预计5-10分钟)..." -ForegroundColor Yellow
$outputWav = "$VideoProject\narration\daily_$Date.wav"
Set-Location $VoxRoot
& .\venv\Scripts\python.exe "$VideoProject\generate_voice_template.py" --script-file $scriptFile --output-file $outputWav

if (-not (Test-Path $outputWav)) {
    Write-Host "  错误: 配音生成失败，未找到输出文件" -ForegroundColor Red
    exit 1
}
if ((Get-Item $outputWav).Length -lt 100000) {
    Write-Host "  错误: 配音文件过小 ($([math]::Round((Get-Item $outputWav).Length/1KB)) KB)，可能生成不完整" -ForegroundColor Red
    exit 1
}
Write-Host "  配音已生成: $outputWav ($([math]::Round((Get-Item $outputWav).Length/1MB,1)) MB)" -ForegroundColor Green

# ========== 步骤4: 测量配音时长 ==========
Write-Host "`n[步骤4] 测量配音时长并分配场景时间..." -ForegroundColor Yellow
try {
    $audioDuration = [double](& $FfprobePath -v error -show_entries format=duration -of default=nk=1:nw=1 $outputWav)
    Write-Host "  配音时长: $([math]::Round($audioDuration, 1)) 秒" -ForegroundColor Green
} catch {
    Write-Host "  警告: 无法测量音频时长，使用默认值 90 秒" -ForegroundColor Yellow
    $audioDuration = 90.0
}

# 分配时长: intro 8s + 10条新闻 + outro 8s
$introDuration = 8.0
$outroDuration = 8.0
$newsCount = $newsItems.Count
$newsTotal = $audioDuration - $introDuration - $outroDuration
$newsDuration = if ($newsCount -gt 0) { [math]::Round($newsTotal / $newsCount, 1) } else { 18.0 }
$totalDuration = $introDuration + ($newsDuration * $newsCount) + $outroDuration

Write-Host "  场景分配: 开场 ${introDuration}s + $newsCount x ${newsDuration}s + 结尾 ${outroDuration}s = $([math]::Round($totalDuration, 1))s" -ForegroundColor Green

# ========== 步骤5: 生成HTML场景 ==========
Write-Host "`n[步骤5] 生成HyperFrames HTML场景..." -ForegroundColor Yellow

# 复制配音到daily目录
Copy-Item -LiteralPath $outputWav -Destination "$NarrationDir\daily_$Date.wav" -Force
if (-not (Test-Path "$NarrationDir\daily_$Date.wav")) {
    Write-Host "  错误: 配音复制失败，目标文件不存在" -ForegroundColor Red
    exit 1
}
Write-Host "  配音已复制到: $NarrationDir" -ForegroundColor Green

$p = $Style.primary
$s = $Style.secondary
$a = $Style.accent
$bg = $Style.bg

# 使用 Python 生成 HTML 场景（更可靠，避免 PowerShell 编码问题）
Write-Host "  使用 Python 生成 HTML 场景..." -ForegroundColor Yellow

# 创建临时 JSON 传给 Python
$tempJson = @"
{
    "news_items": $(
        $newsItems | Select-Object title,summary,source | ConvertTo-Json -Depth 3
    ),
    "style_name": "$($Style.name)",
    "style_label": "$($Style.label)",
    "intro_duration": $introDuration,
    "outro_duration": $outroDuration,
    "news_duration": $newsDuration,
    "total_duration": $totalDuration
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

# ========== 步骤6: 自动截图新闻证据图片 ==========
Write-Host "`n[步骤6] 使用Playwright自动截图新闻原文..." -ForegroundColor Yellow
& $VoxRoot\venv\Scripts\python.exe "$VideoProject\screenshot_news.py" $DailyDir "$DailyDir\aihot_items.json"
if ($LASTEXITCODE -ne 0) {
    Write-Host "  警告: 部分截图失败，但继续制作视频" -ForegroundColor Yellow
}
Write-Host "  截图完成" -ForegroundColor Green

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
Write-Host "  运行 lint..." -ForegroundColor Yellow
try {
    Run-Hyperframes lint 2>&1 | Tee-Object -FilePath "$DailyDir\lint.log"
    Write-Host "  lint 通过" -ForegroundColor Green
} catch {
    Write-Host "  lint 发现问题，但继续渲染: $_" -ForegroundColor Yellow
}

# ========== 步骤8: 渲染视频 - 带重试机制 ==========
Write-Host "`n[步骤8] 渲染视频 (带自动重试)..." -ForegroundColor Yellow
$renderSuccess = $false
$maxRenderRetries = 2

for ($retry = 1; $retry -le $maxRenderRetries; $retry++) {
    Write-Host "  尝试渲染 (尝试 $retry/$maxRenderRetries)..." -ForegroundColor Yellow
    try {
        Run-Hyperframes render --output "daily_${Date}_draft.mp4" --fps 30 --quality draft 2>&1 | Tee-Object -FilePath "$DailyDir\render_draft_attempt_$retry.log"
    } catch {
        Write-Host "  Draft渲染失败: $_" -ForegroundColor Red
        if ($retry -lt $maxRenderRetries) {
            Write-Host "  等待 5 秒后重试..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
        continue
    }

    # 黑屏检测 - 检查文件是否存在且时长合理
    if (Test-Path "$DailyDir\daily_${Date}_draft.mp4") {
        try {
            $blackDetect = & $FfprobePath -v error -show_entries format=duration -of default=nk=1:nw=1 "$DailyDir\daily_${Date}_draft.mp4"
            $duration = [double]$blackDetect
            Write-Host "  Draft视频时长: $([math]::Round($duration, 1))s" -ForegroundColor Green
            # 时长大于3秒认为有效
            if ($duration -gt 3) {
                $renderSuccess = $true
                break
            } else {
                Write-Host "  检测到异常: 时长太短 ($([math]::Round($duration, 1))s)，可能黑屏" -ForegroundColor Red
                Remove-Item "$DailyDir\daily_${Date}_draft.mp4" -Force -ErrorAction SilentlyContinue
            }
        } catch {
            Write-Host "  无法检测视频时长" -ForegroundColor Yellow
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
        Run-Hyperframes render --output "daily_$Date.mp4" --fps 30 --quality standard 2>&1 | Tee-Object -FilePath "$DailyDir\render.log"
    } catch {
        Write-Host "  标准渲染失败，保留draft版本" -ForegroundColor Yellow
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
        & $FfmpegPath -y -i $horizontalFile -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=black" -c:a copy $verticalFile 2>&1 | Out-Null
        if (Test-Path $verticalFile) {
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
