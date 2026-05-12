# Black-Screen Debugging Playbook

Use this reference when a VoxCPM/HyperFrames render is black, nearly black, missing text, or only shows tiny leftover elements.

## First Principle

Do not guess. Use three evidence streams:

1. HyperFrames validation: lint, validate, inspect.
2. Rendered-video black-frame detection with FFmpeg.
3. Actual screenshots extracted from the MP4.

## Commands

Run from the daily project directory:

```powershell
cd D:\VoxCPM\VoxCPM-2.0.3\video-project\daily\YYYYMMDD
npx hyperframes lint --json
npx hyperframes validate --json
npx hyperframes inspect --json
```

Render a fast draft:

```powershell
npx hyperframes render --output daily_YYYYMMDD_debug.mp4 --fps 30 --quality draft
```

Detect black frames:

```powershell
ffmpeg -hide_banner -i daily_YYYYMMDD_debug.mp4 -vf blackdetect=d=0.5:pic_th=0.98 -an -f null -
```

Extract sample frames:

```powershell
ffmpeg -y -ss 5 -i daily_YYYYMMDD_debug.mp4 -frames:v 1 -update 1 sample_5s.png
ffmpeg -y -ss 45 -i daily_YYYYMMDD_debug.mp4 -frames:v 1 -update 1 sample_45s.png
ffmpeg -y -ss 85 -i daily_YYYYMMDD_debug.mp4 -frames:v 1 -update 1 sample_85s.png
```

## Diagnosis Order

### 1. Media 404

Check `validate --json` for messages like:

```text
404 loading narration/daily_YYYYMMDD.wav
```

Fix by keeping media inside the project folder:

```text
daily\YYYYMMDD\narration\daily_YYYYMMDD.wav
```

Use this in `index.html`:

```html
<audio id="narration" data-start="0" data-duration="90" data-track-index="2" data-volume="1" src="narration/daily_YYYYMMDD.wav"></audio>
```

Do not rely on `../../narration/...`; HyperFrames serves from the project root and may block or rewrite parent-directory paths.

### 2. Malformed HTML Or JSON

Search for broken attributes and tags:

```powershell
rg -n "data-variable-values|</span>|</div>|<template|__timelines|getVariables|data-composition-id|data-composition-src" .
```

Common breakages:

- Missing closing quote inside `data-variable-values`.
- Raw JSON containing unescaped quotes.
- Garbled closing tags such as `AI HOT 精选/span>`.
- Bad generated Chinese text caused by encoding corruption.

Prefer static composition files when generated JSON is brittle:

```text
compositions\news-item-1.html
compositions\news-item-2.html
compositions\news-item-3.html
compositions\news-item-4.html
```

### 3. Composition Identity Mismatch

Every loaded composition must have a consistent identity:

```html
<!-- index.html host -->
<div data-composition-id="news-item-3"
     data-composition-src="compositions/news-item-3.html"
     data-start="44"
     data-duration="18"
     data-track-index="1"></div>
```

```html
<!-- child root -->
<div data-composition-id="news-item-3" data-width="1920" data-height="1080">
```

```js
window.__timelines["news-item-3"] = tl;
```

If the host id, child root id, and timeline key disagree, scenes may not render or animate correctly.

### 4. `<template>` In The Wrong Place

Standalone composition files should be full HTML documents. Do not use:

```html
<template id="daily-intro-template">
```

Use:

```html
<!DOCTYPE html>
<html data-width="1920" data-height="1080">
```

### 5. Fragile `gsap.from()` In Sub-Compositions

When a sub-composition is loaded through `data-composition-src`, replace core entrances with `fromTo()`. This makes seeked render frames deterministic.

Fragile:

```js
tl.from(".news-title", { x: 40, opacity: 0, duration: 0.8 }, 0.5);
```

Stable:

```js
tl.fromTo(".news-title", { x: 40, opacity: 0 }, { x: 0, opacity: 1, duration: 0.8, ease: "power3.out" }, 0.5);
```

### 6. Timeline Registration

Check every composition:

```js
window.__timelines = window.__timelines || {};
const tl = gsap.timeline({ paused: true });
window.__timelines["composition-id"] = tl;
```

The timeline key must equal the root `data-composition-id`.

### 7. CDN Or Script Failure

If `gsap` or `anime` fails to load, timeline construction fails. HyperFrames usually inlines CDN scripts during compile, but offline or blocked networks can still break preview. Consider local copies if failures repeat.

## Proven Repair From `daily\20260512`

Symptoms:

- Rendered `daily_20260512.mp4` was black from about 2.12s to 80.32s.
- Mid-video screenshot showed only a small “AI HOT 精选” tag.
- `validate` reported `404 loading narration/daily_20260512.wav`.

Root causes:

- `data-variable-values` JSON for the first news item had a broken quote.
- Multiple news scenes reused `data-composition-id="news-item"`.
- Audio referenced `../../narration/daily_20260512.wav`, outside the daily project root.
- Some child HTML had broken closing tags.
- `gsap.from()` in loaded sub-compositions made seeked frame state unreliable.

Repair:

1. Copy narration into `daily\20260512\narration\daily_20260512.wav`.
2. Change audio source to `src="narration/daily_20260512.wav"`.
3. Replace variable-driven repeated `news-item.html` with static:
   - `news-item-1.html`
   - `news-item-2.html`
   - `news-item-3.html`
   - `news-item-4.html`
4. Make each host id, child root id, and timeline key match.
5. Replace entrance tweens with `fromTo()`.
6. Run `lint`, `validate`, `inspect`.
7. Render draft and run `blackdetect`.
8. Render standard output.

Success criteria:

- `npx hyperframes lint --json` has `errorCount: 0`.
- `npx hyperframes validate --json` has no errors and no contrast failures.
- `npx hyperframes inspect --json` has `ok: true`.
- `ffmpeg blackdetect` prints no long `black_start` / `black_end` segments.
- Sample frames at intro, middle, and outro visibly contain expected text and background.
