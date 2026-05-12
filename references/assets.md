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

## External Inspiration: react-bits

[react-bits](https://github.com/DavidHDev/react-bits) is a large collection of animated React components (90+ components). While these are React-based and cannot be used directly in HyperFrames, they serve as excellent **visual inspiration** for:

- **Background effects**: Aurora, particles, gradients, mesh gradients
- **Text animations**: Split text, scramble, typewriter, reveal effects
- **UI animations**: Card entrances, stagger effects, hover states
- **3D effects**: Rotating elements, perspective transforms, depth layers

### How to use react-bits as inspiration

1. **Browse** [reactbits.dev](https://reactbits.dev/) for visual ideas
2. **Extract** the core animation concept (timing, easing, visual pattern)
3. **Recreate** using GSAP `fromTo()` or Anime.js in HyperFrames HTML
4. **Simplify** for video: remove interactivity, fix random values, ensure determinism

### Example: Aurora Background

react-bits has an Aurora component with flowing gradient waves. To recreate in HyperFrames:

```html
<!-- Simplified Aurora-inspired background -->
<div class="aurora-bg">
  <div class="wave wave-1"></div>
  <div class="wave wave-2"></div>
  <div class="wave wave-3"></div>
</div>
<style>
  .aurora-bg { position: absolute; inset: 0; overflow: hidden; }
  .wave {
    position: absolute;
    width: 200%;
    height: 200%;
    border-radius: 40%;
    opacity: 0.3;
  }
  .wave-1 { background: radial-gradient(circle, #667eea 0%, transparent 70%); top: -50%; left: -50%; }
  .wave-2 { background: radial-gradient(circle, #764ba2 0%, transparent 70%); top: -30%; left: -30%; }
  .wave-3 { background: radial-gradient(circle, #00d4ff 0%, transparent 70%); top: -40%; left: -40%; }
</style>
<script>
  const tl = gsap.timeline({ paused: true });
  tl.to(".wave-1", { rotation: 360, duration: 20, ease: "none" })
    .to(".wave-2", { rotation: -360, duration: 25, ease: "none" }, 0)
    .to(".wave-3", { rotation: 180, duration: 30, ease: "none" }, 0);
  window.__timelines["aurora-bg"] = tl;
</script>
```

### Key adaptation rules

- **No React**: Convert all React components to plain HTML + CSS + GSAP/Anime.js
- **No interactivity**: Remove mouse, scroll, click handlers
- **Deterministic**: Replace random values with fixed seeds or pre-calculated values
- **Seekable**: Ensure animations work correctly when seeked to any point in time
- **Performance**: Keep particle counts and DOM elements reasonable for video rendering

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
