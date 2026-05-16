---
name: voxcpm-video-maker
description: >
  This skill should be used when the user asks to make, repair, debug, render, or automate
  VoxCPM/AI HOT news videos in D:\VoxCPM, especially requests such as "zuo shipin",
  "AI news video", "VoxCPM voiceover", "HyperFrames render", "black screen video",
  "audio video out of sync", "yin hua bu tong bu", "cool visual assets",
  "Anime.js effects", "avoid repetitive videos", "product promo short video",
  "9:16 vertical video", "partner/channel promo", "competitor research", "web assets",
  or "debug a generated MP4".
  It covers AI HOT news collection, VoxCPM narration generation, HyperFrames composition
  authoring, required web research, competitor scans, web image/video material sourcing,
  Anime.js visual asset integration, premium art direction, audio/video sync,
  visual variation, local rendering, QA, and black-screen debugging.
---

# VoxCPM Video Maker

Create, repair, and render AI news videos with AI HOT content, VoxCPM voice generation, HyperFrames HTML compositions, and optional Anime.js visual assets.

## Local Map

Use these paths as the canonical local environment:

| Resource | Path |
| --- | --- |
| VoxCPM root | `D:\VoxCPM\VoxCPM-2.0.3\` |
| HyperFrames video project | `D:\VoxCPM\VoxCPM-2.0.3\video-project\` |
| Daily video folders | `D:\VoxCPM\VoxCPM-2.0.3\video-project\daily\YYYYMMDD\` |
| Narration output | `D:\VoxCPM\VoxCPM-2.0.3\video-project\narration\` |
| Anime.js asset library | `D:\VoxCPM\anime-master\examples\` |
| Anime.js asset guide | `D:\VoxCPM\anime-master\VIDEO_ASSETS_GUIDE.md` |
| One-click script | `D:\VoxCPM\VoxCPM-2.0.3\video-project\make_daily_video.ps1` |

## Core Workflow

### For Daily AI HOT News Videos (Fully Automated)

When the user asks for "today's AI news video", "make daily AI HOT", "generate today's video", or similar:

1. **Directly run the fully automated one-click script**:
   ```powershell
   cd D:\VoxCPM\VoxCPM-2.0.3\video-project
   .\make_daily_video.ps1
   ```
2. The script handles **everything end-to-end**:
   - Fetches 10 AI HOT news items automatically
   - Writes a natural narration script with random openings/closings
   - Generates VoxCPM narration locally
   - Measures audio duration and allocates scene timing
   - Generates HTML compositions (AI dynamic layout if `ai_config.json` is configured, else fallback to template)
   - Playwright automatically captures screenshots for all news with retry
   - Runs HyperFrames lint and validation
   - Renders video with automatic retry and black screen detection
   - Copies final MP4 to unified output folder `D:\VoxCPM\VoxCPM-2.0.3\video-project\output\`
   - Generates vertical 9:16 version if horizontal succeeds
3. After script completes, report the output location and confirm success.
4. Do **NOT** manually repeat steps that the script already automates.

### For Custom Product/Promo Videos (Manual)

1. Run real web research for the product/news/topic, competitors, and usable visual references.
2. Save a source log with URLs, dates, claims, and asset candidates.
3. Fetch AI HOT items when the video contains AI news.
4. Select the strongest claims or product selling points.
5. Write a short narration script with scene blocks.
6. Generate VoxCPM narration locally.
7. Measure narration duration and create a timing plan before writing scene HTML.
8. Build a visual direction using `references/art-direction.md`.
9. Pick a visual concept that differs from recent outputs.
10. Build or update a HyperFrames project under `daily\YYYYMMDD` or a product-specific folder.
11. Add scenes and approved web/local/Anime.js assets.
12. Run `npx hyperframes lint`, `validate`, and `inspect`.
13. Render a draft MP4, test sync/black frames/sample frames, then render standard/high quality.
14. Run an aesthetic review on extracted frames; revise if the video looks cheap, generic, or PPT-like.

## Mandatory Web Research

For every new video, perform real network research before writing the script or selecting visuals. Read `references/web-research.md` for the required process. Do not rely only on memory.

Use web research for:

- official product facts and screenshots
- competitor feature scans
- market/category language
- partner, reseller, channel, or business-opportunity positioning
- visual references from official sites, product pages, app stores, docs, press pages, and reputable reviews
- royalty-free or permission-safe image/video candidates

Create this file in the project folder:

```text
source-log.md
```

Include:

```text
Research date:
Product official sources:
Competitor sources:
Claim -> source URL:
Visual asset candidates:
Assets used:
Assets rejected:
```

**Exception for Daily AI HOT News:** The `make_daily_video.ps1` script already fetches AI HOT items and captures screenshots automatically. You don't need to manually create a source log for fully automated daily news.

If network access fails, state that research could not be completed and stop before making competitive claims.

## Product Promo / Partner Shorts

For product, feature-introduction, launch, website, channel, reseller, or business-opportunity shorts, read `references/product-short.md`.

Default product short requirements:

- Use actual web research for product and competitors.
- Make the video 9:16 unless the user asks otherwise.
- Aim for about 55-70 seconds.
- Use a premium launch-film direction: Apple keynote clarity, Google I/O energy, Bloomberg-style data visualization.
- Avoid PPT-like slide decks, cheap templates, generic stock backgrounds, and repetitive card-only layouts.
- Show product function, proof, competitor contrast, and the business opportunity when relevant.
- End with a clear CTA for the intended audience: buyer, user, partner, channel, reseller, or website lead.

For AI HOT data, use:

```powershell
$UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 aihot-skill/0.2.0"
$since = (Get-Date).ToUniversalTime().AddHours(-24).ToString("yyyy-MM-ddTHH:mm:ssZ")
$url = "https://aihot.virxact.com/api/public/items?mode=selected&since=$since&take=10"
$headers = @{"User-Agent"=$UA}
$response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
$response.items | Select-Object title, source, publishedAt, url, summary | ConvertTo-Json -Depth 3
```

## Project Structure

Prefer this stable structure for daily videos:

```text
video-project\daily\YYYYMMDD\
  index.html
  script.txt
  narration\
    daily_YYYYMMDD.wav
  compositions\
    daily-intro.html
    news-item-1.html
    news-item-2.html
    news-item-3.html
    news-item-4.html
    daily-outro.html
```

Use one static composition file per news card when reliability matters. Avoid reusing the same `data-composition-id` for multiple instances of a variable-driven sub-composition unless the current HyperFrames behavior has been verified in that project.

## Audio/Video Sync

Treat audio/video sync as a release blocker. Read `references/sync.md` before creating or repairing a full video with narration.

Core rules:

- Measure the generated narration with `ffprobe` before deciding `data-duration`.
- Make total root duration match the narration duration within 0.2s.
- Allocate scene durations from the script structure and audio length, not from a fixed template.
- Keep scene text visible while the matching sentence is spoken.
- Never use a fixed 90s project duration unless the narration is actually 90s.
- After render, compare output audio duration and video duration with `ffprobe`.

Quick duration command:

```powershell
ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 .\narration\daily_YYYYMMDD.wav
```

Use the measured value in:

- `<html data-duration="...">` if present.
- Root `<div data-composition-id="root" ... data-duration="...">`.
- Narration `<audio ... data-duration="...">`.
- The final scene end time.

## Visual Variation

Do not generate a same-looking video every day. Read `references/variation.md` when creating a new video, especially daily/news videos.

Every new video must choose a visual route before authoring:

| Route | Good for | Asset direction |
| --- | --- | --- |
| Signal Radar | breaking AI industry news | radial scans, rings, grid, cyan accents |
| Deep Space Briefing | model launches/research | starfield, parallax, slow cosmic motion |
| Command Center | security/business/product updates | terminal blocks, data panels, dashboards |
| Magazine Motion | broad daily recap | editorial typography, clean cards, large quotes |
| Neon Dataflow | technical/tooling stories | lines, particles, graphs, flowing paths |

Vary at least three dimensions per video:

- layout system
- background asset
- transition style
- accent palette
- typography scale
- motion rhythm
- story structure

Do not reuse the same `daily-intro` + identical news-card layout + identical outro for consecutive videos unless the user explicitly asks for a fixed template.

## Art Direction Gate

Treat aesthetics as a release blocker. Read `references/art-direction.md` before building product promos, 9:16 shorts, website videos, or any video where the user asks for premium quality.

Before writing HTML, create:

```text
visual-direction.md
moodboard-notes.md
keyframes-plan.md
```

Every video must define:

- one clear art-direction route
- 3-5 external visual references found through web research
- typography system
- layout grid
- motion language
- color palette
- forbidden looks
- hero frames for intro, middle, and CTA

Reject outputs that look like:

- a dark PPT deck with animated cards
- generic neon tech template
- random stock background behind text
- dense unreadable dashboard
- low-contrast gray text on black
- repeated centered title + bullet list scenes

## Composition Rules

Write each composition as a full HTML document:

```html
<!DOCTYPE html>
<html data-width="1920" data-height="1080">
<head>
  <meta charset="UTF-8">
</head>
<body>
  <div data-composition-id="news-item-1" data-width="1920" data-height="1080">
    ...
  </div>
  <script src="https://cdn.jsdelivr.net/npm/gsap@3.12.5/dist/gsap.min.js"></script>
  <script>
    window.__timelines = window.__timelines || {};
    const tl = gsap.timeline({ paused: true });
    window.__timelines["news-item-1"] = tl;
  </script>
</body>
</html>
```

Follow these hard rules:

- Do not wrap standalone composition content in `<template>`.
- Make every root `data-composition-id` match its `window.__timelines[...]` key.
- Keep every GSAP timeline `paused: true`.
- Prefer `tl.fromTo()` over `tl.from()` inside sub-compositions loaded by `data-composition-src`; seeked rendering is more deterministic.
- Do not use `repeat: -1`; calculate finite repeats if looping is necessary.
- Keep assets inside the current project folder or a subfolder. HyperFrames will not reliably serve `../../` paths.
- Put narration for a daily project under `daily\YYYYMMDD\narration\`.

## Visual Style

Default to a dark AI news style:

```css
:root {
  --bg-primary: #0a0a0f;
  --bg-secondary: #111118;
  --accent-1: #667eea;
  --accent-2: #764ba2;
  --accent-3: #00d4ff;
  --text-primary: #ffffff;
  --text-secondary: rgba(255,255,255,0.76);
}
```

Use large, readable video typography:

| Element | 1920x1080 size |
| --- | --- |
| Main title | 80-120px |
| Scene heading | 48-72px |
| Body summary | 28-34px |
| Source/category | 16-22px |

## Anime.js And Cool Assets

When the user asks for more visual impact, read `references/assets.md`. It maps local Anime.js examples to video use cases and explains how to adapt them to HyperFrames.

Quick picks:

| Need | Asset |
| --- | --- |
| Tech/cosmic intro | `timeline-50K-stars` |
| Particle atmosphere | `additive-fireflies` |
| Logo drawing | `svg-line-drawing` |
| Feature/card entrance | `stagger` or `advanced-grid-staggering` |
| Depth transition | `layered-css-transforms` |
| Data animation | `svg-graph` |
| Typewriter/news reveal | `irregular-playback-typewriter` |

When adapting Anime.js:

- Set `autoplay: false`.
- Register animations in `window.__hfAnime`.
- Avoid mouse, scroll, drag, or playback-control demos for rendered video.
- Replace random or wall-clock behavior with deterministic values.

## Rendering And QA

Run these checks before handing off:

```powershell
cd D:\VoxCPM\VoxCPM-2.0.3\video-project\daily\YYYYMMDD
npx hyperframes lint
npx hyperframes validate
npx hyperframes inspect
npx hyperframes render --output daily_YYYYMMDD_draft.mp4 --fps 30 --quality draft
ffmpeg -hide_banner -i daily_YYYYMMDD_draft.mp4 -vf blackdetect=d=0.5:pic_th=0.98 -an -f null -
ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 daily_YYYYMMDD_draft.mp4
npx hyperframes render --output daily_YYYYMMDD.mp4 --fps 30 --quality standard
```

Extract sample frames when debugging:

```powershell
ffmpeg -y -ss 5 -i daily_YYYYMMDD.mp4 -frames:v 1 -update 1 sample_5s.png
ffmpeg -y -ss 45 -i daily_YYYYMMDD.mp4 -frames:v 1 -update 1 sample_45s.png
ffmpeg -y -ss 85 -i daily_YYYYMMDD.mp4 -frames:v 1 -update 1 sample_85s.png
```

## Black-Screen Debugging

When a rendered video is black or nearly black, read `references/black-screen-debug.md` and follow it exactly. The proven order is:

1. Run `npx hyperframes lint --json`, `validate --json`, and `inspect --json`.
2. Check all media 404s, especially audio outside the project folder.
3. Search for malformed HTML: broken quotes, broken JSON in `data-variable-values`, broken closing tags.
4. Check composition identity: host `data-composition-id`, child root `data-composition-id`, and `window.__timelines[...]`.
5. Replace fragile `from()` tweens in sub-compositions with `fromTo()`.
6. Render a draft and run `ffmpeg blackdetect`.
7. Extract sample frames at intro, middle, and outro.

Recent proven fix: the `20260512` daily video was black because of malformed `data-variable-values`, reused `news-item` IDs, `../../narration` media 404, broken text/closing tags, and seek-unstable `from()` animation. The reliable repair was to create unique static `news-item-1.html` to `news-item-4.html`, copy narration into `daily\20260512\narration\`, use local `src="narration/daily_20260512.wav"`, and switch scene entrances to `fromTo()`.

## Local Automation

Use the one-click script when the user wants the whole workflow:

```powershell
cd D:\VoxCPM\VoxCPM-2.0.3\video-project
.\make_daily_video.ps1
```

Ensure the script copies generated narration into the daily project folder before rendering:

```powershell
$dailyNarrationDir = "$dailyDir\narration"
if (-not (Test-Path $dailyNarrationDir)) {
    New-Item -ItemType Directory -Force -Path $dailyNarrationDir | Out-Null
}
Copy-Item -LiteralPath $outputWav -Destination "$dailyNarrationDir\daily_$Date.wav" -Force
```

## Reference Files

- `references/assets.md` - Cool Anime.js and HyperFrames visual asset patterns.
- `references/art-direction.md` - Premium visual direction, moodboard, composition, and aesthetic QA.
- `references/web-research.md` - Required real web research, competitor scan, and source logging.
- `references/product-short.md` - 9:16 product promo, feature-introduction, partner, and channel short-video workflow.
- `references/sync.md` - Audio/video timing, scene allocation, and sync QA.
- `references/variation.md` - Non-repetitive visual direction and variation system.
- `references/black-screen-debug.md` - Reproducible black-screen diagnosis and repair workflow.
