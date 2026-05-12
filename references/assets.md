# Cool Visual Assets

Use this reference when a VoxCPM/AI HOT video needs stronger visual treatment, motion graphics, or reusable Anime.js effects.

Visual assets must support the timing plan. Do not add an effect that delays a headline, hides a story while its narration is playing, or extends a scene beyond the measured audio budget. Read `sync.md` first when narration exists.

## Local Asset Library

Anime.js examples live at:

```text
D:\VoxCPM\anime-master\examples\
```

Also inspect:

```text
D:\VoxCPM\anime-master\VIDEO_ASSETS_GUIDE.md
```

Preview examples locally:

```powershell
cd D:\VoxCPM\anime-master
npm install
npm run dev
```

## Recommended Assets By Scene

| Scene need | Local example | Why it works |
| --- | --- | --- |
| Tech/cosmic opening | `timeline-50K-stars` | Dense starfield, high-tech atmosphere |
| Warm particle ambience | `additive-fireflies` | Glowing particles, easy to recolor |
| Abstract AI background | `additive-creature` | Organic computational motion |
| Brand/logo reveal | `svg-line-drawing` | Draws paths cleanly for logo or icons |
| Advanced logo reference | `animejs-v4-logo-animation` | Complex but useful as motion reference |
| Headline reveal | `text/split-effects` | Split text animation for big titles |
| Hacker/AI text reveal | `text/scramble` | Scramble-to-readable effect |
| News typing reveal | `irregular-playback-typewriter` | Typewriter cadence for quotes or headlines |
| Data/report graphic | `svg-graph` | Animated charts and paths |
| Card stack entrance | `stagger` | Reliable staggered feature/news cards |
| Grid reveal | `advanced-grid-staggering` | Strong for AI model/product grids |
| Depth transition | `layered-css-transforms` | 3D layered scene movement |
| Seamless transition texture | `timeline-seamless-loop` | Looping visual bed between scenes |
| Outro flock/free motion | `timeline-refresh-starlings` | Organic ending motion |
| Code/technical demo | `auto-layout/code` | Good for model/API announcements |
| Card UI demo | `auto-layout/cards` | Useful for product feature cards |
| System/space metaphor | `auto-layout/planets` | Orbit/system visual metaphor |

Avoid examples that require live interaction: `animatable-follow-cursor`, `draggable-*`, `onscroll-*`, and `clock-playback-controls`.

## HyperFrames Adaptation Pattern

Convert Anime.js examples into render-safe, seekable animation:

```html
<script src="https://cdn.jsdelivr.net/npm/animejs@4.0.2/lib/anime.iife.min.js"></script>
<script>
  window.__hfAnime = window.__hfAnime || [];

  const anim = anime({
    targets: ".particle",
    translateX: [0, 120],
    translateY: [0, -60],
    opacity: [0, 1],
    duration: 2000,
    easing: "easeInOutQuad",
    autoplay: false
  });

  window.__hfAnime.push(anim);
</script>
```

Rules:

- Keep `autoplay: false`.
- Register every animation on `window.__hfAnime`.
- Avoid `anime.random()` in render-critical timelines unless values are generated once from a deterministic seed.
- Avoid wall-clock loops and user input.
- Keep infinite loops finite or attach them to the HyperFrames-controlled timeline.
- Prefer CSS/GSAP `fromTo()` for core text and card entrances; use Anime.js for ornament, particles, line drawing, or special effects.

## Color Retheming

Use the default VoxCPM/AI HOT palette:

```css
#0a0a0f
#111118
#667eea
#764ba2
#00d4ff
#ffffff
rgba(255,255,255,0.76)
```

For `additive-fireflies`, replace warm colors with:

```js
const colors = ["#667eea", "#764ba2", "#00d4ff"];
```

For SVG line drawing, set strokes to:

```html
stroke="#667eea"
```

or use a gradient from `#667eea` to `#00d4ff`.

## Practical Recipes

Before choosing a recipe, check `variation.md` and pick a route that differs from the previous output.

### Cinematic Daily Intro

Use:

- `timeline-50K-stars` as a subtle background.
- Large title `AI HOT 日报`.
- Date badge above title.
- `fromTo()` title entrance and slow background movement.

Keep the starfield behind text at low opacity so compression does not bury the title.

### News Card With Energy

Use:

- Static text composition for reliability.
- Left accent line.
- Large number (`01`, `02`, etc.).
- `fromTo()` entrance for number, title, summary, source.
- Optional `additive-fireflies` or radial glow in the background.

Avoid variable-driven repeated sub-compositions unless the render has been verified.

### Data/Model Launch Story

Use:

- `svg-graph` for animated metric lines.
- `auto-layout/code` for code/model-card moments.
- `advanced-grid-staggering` for model capability grids.

Keep data labels at least 18px and body text 28px+ for 1080p video.

### Outro

Use:

- `timeline-refresh-starlings` or a slow radial glow.
- Centered “感谢收看 / 明日再见”.
- Brand/source line at bottom.

Avoid fading all foreground elements out before the final frame unless intentionally ending on black.
