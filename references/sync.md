# Audio/Video Sync

Use this reference whenever a VoxCPM video has narration, subtitles, timed scene changes, or any risk of audio and visuals drifting apart.

## Non-Negotiable Rule

Build timing from the generated audio, not from a fixed template. Fixed scene durations are acceptable only after they have been reconciled with the actual narration length.

## Measure Narration

Run after VoxCPM creates the WAV file:

```powershell
cd D:\VoxCPM\VoxCPM-2.0.3\video-project\daily\YYYYMMDD
ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 .\narration\daily_YYYYMMDD.wav
```

Save this as `audioDuration`.

For multiple narration clips, measure each clip:

```powershell
Get-ChildItem .\narration\*.wav | ForEach-Object {
  $d = ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 $_.FullName
  "$($_.Name) $d"
}
```

## Build A Timing Plan

Create a timing plan before editing HTML:

```text
total = measured audio duration
intro = 5-8s
outro = 5-8s
news budget = total - intro - outro
news scene duration = news budget / story count
```

Adjust by story importance and script length:

- Short mention: 10-14s
- Normal news item: 14-20s
- Main story: 20-30s
- Outro: 5-8s unless the narration has a long closing

The sum of all scene durations must equal the audio duration within 0.2s.

## Sync HTML To The Plan

Set the same total duration in all relevant places:

```html
<html data-width="1920" data-height="1080" data-duration="87.42">
...
<div data-composition-id="root" data-width="1920" data-height="1080" data-start="0" data-duration="87.42">
...
<audio id="narration" data-start="0" data-duration="87.42" data-track-index="2" data-volume="1" src="narration/daily_YYYYMMDD.wav"></audio>
```

Scene schedule example:

```html
<div data-composition-id="daily-intro" data-composition-src="compositions/daily-intro.html" data-start="0" data-duration="7" data-track-index="1"></div>
<div data-composition-id="news-item-1" data-composition-src="compositions/news-item-1.html" data-start="7" data-duration="18.5" data-track-index="1"></div>
<div data-composition-id="news-item-2" data-composition-src="compositions/news-item-2.html" data-start="25.5" data-duration="17.5" data-track-index="1"></div>
<div data-composition-id="daily-outro" data-composition-src="compositions/daily-outro.html" data-start="79.42" data-duration="8" data-track-index="1"></div>
```

Avoid gaps and overlaps on the same visual track unless an intentional transition composition exists.

## Script-To-Scene Alignment

Write the narration script in scene blocks:

```text
[intro]
欢迎收看今日 AI HOT 日报。

[news-1]
第一条，...

[news-2]
第二条，...

[outro]
感谢收看，明日再见。
```

If possible, generate separate WAV clips per block. Separate clips make sync easier because each scene can use its own measured audio duration.

If using one full WAV, estimate per-scene duration from character count:

```text
sceneDuration = availableNewsBudget * sceneTextLength / totalNewsTextLength
```

Then manually nudge important scenes by 1-3 seconds based on content density.

## Visual Timing Rules

- Show the headline before or exactly when the related sentence starts.
- Keep summary text visible until that sentence finishes.
- Avoid cutting to the next story while the previous story is still being spoken.
- Use a transition only during natural pauses, never mid-sentence.
- Keep outro visible until narration ends.

## QA Commands

Measure rendered video:

```powershell
ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 daily_YYYYMMDD.mp4
```

Compare audio and video durations:

```powershell
$audio = [double](ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 .\narration\daily_YYYYMMDD.wav)
$video = [double](ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 .\daily_YYYYMMDD.mp4)
"audio=$audio video=$video diff=$([math]::Abs($audio-$video))"
```

Pass condition:

```text
abs(audio - video) <= 0.2 seconds
```

Extract spot-check frames near scene boundaries:

```powershell
ffmpeg -y -ss 6.8 -i daily_YYYYMMDD.mp4 -frames:v 1 -update 1 boundary_intro.png
ffmpeg -y -ss 25.4 -i daily_YYYYMMDD.mp4 -frames:v 1 -update 1 boundary_news2.png
```

Inspect frames and confirm the visible story matches the expected narration segment.

## Common Causes Of Desync

- Hardcoded 90s duration with a narration file that is not 90s.
- Scene durations copied from yesterday's project.
- Audio source points to an older WAV.
- Intro/outro animation duration changed without updating root duration.
- Multiple audio clips overlap on the same timeline.
- Rendered video duration is controlled by root duration, while audio duration is longer or shorter.
