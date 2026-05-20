param(
    [Parameter(Mandatory=$true)][string]$VideoFile,
    [string]$AudioFile = "",
    [double]$MaxDurationDeltaSeconds = 2.0,
    [double]$MaxBlackSeconds = 2.0,
    [double]$MaxBlackRatio = 0.05
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$InstallRoot = Split-Path -Parent $ProjectRoot
$PackagedFfmpeg = Join-Path $InstallRoot "tools\ffmpeg-8.1-full_build\bin\ffmpeg.exe"
$PackagedFfprobe = Join-Path $InstallRoot "tools\ffmpeg-8.1-full_build\bin\ffprobe.exe"
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

function Get-MediaDuration {
    param([string]$Path)
    $raw = & $FfprobePath -v error -show_entries format=duration -of default=nk=1:nw=1 $Path
    if ($LASTEXITCODE -ne 0) { throw "ffprobe failed: $Path" }
    return [double]$raw
}

function Get-BlackDuration {
    param([string]$Path)
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & $FfmpegPath -hide_banner -i $Path -vf "blackdetect=d=0.5:pic_th=0.98" -an -f null - 2>&1 | Out-String
    $ErrorActionPreference = $previousPreference
    if ($LASTEXITCODE -ne 0) { throw "ffmpeg blackdetect failed: $Path`n$output" }
    $total = 0.0
    foreach ($match in [regex]::Matches($output, "black_duration:([0-9.]+)")) {
        $total += [double]$match.Groups[1].Value
    }
    return [PSCustomObject]@{ Duration = $total; Output = $output }
}

if (-not (Test-Path $VideoFile)) { throw "Video not found: $VideoFile" }
$videoItem = Get-Item $VideoFile
if ($videoItem.Length -lt 1000000) { throw "Video file too small: $([math]::Round($videoItem.Length / 1KB, 1)) KB" }

$videoDuration = Get-MediaDuration $VideoFile
if ($videoDuration -lt 3) { throw "Video duration abnormal: $videoDuration seconds" }

if ($AudioFile) {
    if (-not (Test-Path $AudioFile)) { throw "Audio not found: $AudioFile" }
    $audioItem = Get-Item $AudioFile
    if ($audioItem.Length -lt 100000) { throw "Audio file too small: $([math]::Round($audioItem.Length / 1KB, 1)) KB" }
    $audioDuration = Get-MediaDuration $AudioFile
    $durationDelta = [math]::Abs($videoDuration - $audioDuration)
    if ($durationDelta -gt $MaxDurationDeltaSeconds) {
        throw "Audio/video duration mismatch: video $([math]::Round($videoDuration, 3))s, audio $([math]::Round($audioDuration, 3))s, delta $([math]::Round($durationDelta, 3))s"
    }
    if ($videoItem.LastWriteTime -lt $audioItem.LastWriteTime) {
        throw "Video is older than audio: video $($videoItem.LastWriteTime), audio $($audioItem.LastWriteTime)"
    }
}

$black = Get-BlackDuration $VideoFile
$blackLimit = [math]::Max($MaxBlackSeconds, $videoDuration * $MaxBlackRatio)
if ($black.Duration -gt $blackLimit) {
    $black.Output | Out-File -FilePath ([System.IO.Path]::ChangeExtension($VideoFile, ".blackdetect.log")) -Encoding UTF8
    throw "Black-screen check failed: black $([math]::Round($black.Duration, 3))s, limit $([math]::Round($blackLimit, 3))s"
}

[PSCustomObject]@{
    Status = "PASS"
    VideoFile = $VideoFile
    VideoDuration = [math]::Round($videoDuration, 3)
    VideoSizeMB = [math]::Round($videoItem.Length / 1MB, 2)
    VideoLastWriteTime = $videoItem.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    AudioFile = $AudioFile
    BlackDuration = [math]::Round($black.Duration, 3)
} | ConvertTo-Json -Depth 3
