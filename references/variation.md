# Visual Variation System

Use this reference when making a new AI HOT/VoxCPM video so the result does not look like a clone of prior outputs.

For premium videos, read `art-direction.md` first. Variation is not enough by itself; the video also needs strong composition, hierarchy, and visual references.

## Principle

Keep the brand recognizable, but vary the visual grammar. Reuse the workflow, not the same composition.

## Choose One Route Per Video

Select a route before writing HTML. Let the news content drive the choice.

### Signal Radar

Use for breaking industry news, policy, funding, market movement.

- Background: radar rings, scanning lines, map/grid texture.
- Palette: dark graphite, cyan, electric blue, small red/orange alert accents.
- Layout: left-side story stack or center radar with callouts.
- Motion: sweep, ping, reveal-on-scan.
- Assets: `svg-graph`, `timeline-seamless-loop`, custom CSS radial rings.

### Deep Space Briefing

Use for model launches, research, future-looking stories.

- Background: starfield, depth layers, slow parallax.
- Palette: deep black, violet, indigo, cool white.
- Layout: large cinematic title, floating story panels.
- Motion: slow camera drift, star streaks, soft glows.
- Assets: `timeline-50K-stars`, `additive-fireflies`, `layered-css-transforms`.

### Command Center

Use for security, developer tools, infrastructure, npm/package incidents.

- Background: terminal grid, status panels, code blocks.
- Palette: near black, green/cyan, amber warning.
- Layout: dashboard, split panels, source ticker.
- Motion: typing, line scans, status changes.
- Assets: `auto-layout/code`, `svg-graph`, `text/scramble`.

### Magazine Motion

Use for general daily recaps and broad summaries.

- Background: restrained texture, editorial blocks, clean whitespace-on-dark.
- Palette: black, off-white, one accent per issue.
- Layout: large typography, quote cards, story index.
- Motion: editorial slides, mask reveals, gentle card movement.
- Assets: `text/split-effects`, `stagger`, `auto-layout/cards`.

### Neon Dataflow

Use for AI product updates, APIs, model ecosystems, workflow automation.

- Background: flowing paths, particles, network lines.
- Palette: black, cyan, purple, occasional magenta.
- Layout: diagonal paths or nodes connecting story cards.
- Motion: particles along paths, graph draws, node pulses.
- Assets: `svg-line-drawing`, `additive-creature`, `advanced-grid-staggering`.

## Variation Checklist

Before rendering, confirm at least three changes from the previous video:

- Different intro composition.
- Different news-card layout.
- Different background asset.
- Different transition language.
- Different accent palette.
- Different type scale or title placement.
- Different story rhythm.
- Different outro design.

If fewer than three changed, revise before rendering.

## Avoid These Repetition Traps

- Same centered title intro every day.
- Same left accent line and number for every story.
- Same dark purple/cyan gradient in every scene.
- Same “感谢收看 / 明日再见” outro framing every time.
- Same 8s intro + 18s per story + 10s outro regardless of audio.
- Same animation offsets copied into every composition.

## Story-Driven Layout Choices

Map story type to layout:

| Story type | Preferred layout |
| --- | --- |
| Model release | capability grid, model card, benchmark strip |
| Funding/company | timeline, profile card, market signal |
| Security incident | command center alert, dependency map |
| Research paper | abstract diagram, layered concept cards |
| Product launch | interface-like cards, feature carousel |
| Opinion/quote | editorial quote layout, kinetic typography |

## Asset Rotation

Rotate assets across issues:

```text
Issue A: timeline-50K-stars + stagger + svg-line-drawing
Issue B: command center CSS grid + text/scramble + svg-graph
Issue C: additive-fireflies + auto-layout/cards + layered-css-transforms
Issue D: advanced-grid-staggering + additive-creature + kinetic type
```

Use one hero asset and one supporting asset per video. Too many asset systems make the video incoherent.

## Controlled Randomness

Use deterministic variation based on date or issue id:

```js
function mulberry32(seed) {
  return function() {
    let t = seed += 0x6D2B79F5;
    t = Math.imul(t ^ t >>> 15, t | 1);
    t ^= t + Math.imul(t ^ t >>> 7, t | 61);
    return ((t ^ t >>> 14) >>> 0) / 4294967296;
  };
}

const seed = 20260513;
const rand = mulberry32(seed);
```

Use seeded values for particle positions, small rotations, card offsets, or background node locations. Do not use `Math.random()` directly in render-critical code.

## Required Design Note

For each generated video, create or update a short note in the project folder:

```text
visual-direction.md
```

Include:

```text
Route: Command Center
Why: npm/security/tooling story leads the issue.
Hero asset: auto-layout/code
Supporting asset: svg-graph
Timing basis: narration duration 87.42s
Changed from last video: intro layout, palette, story cards, outro
```

This gives future agents a memory of what has already been used.
