# Premium Art Direction

Use this reference whenever video quality matters. The goal is to prevent ugly, generic, PPT-like outputs by forcing visual research, composition planning, and aesthetic QA before delivery.

## Core Principle

Do not start from a template. Start from a visual thesis.

Good video design has:

- a recognizable point of view
- strong first frame
- consistent typography
- intentional empty space
- clear foreground/background hierarchy
- motion that reveals meaning
- real or well-designed product visuals
- rhythm matched to narration

Bad video design usually has:

- too many small cards
- equal-weight text everywhere
- generic gradients
- random particles
- cheap glow effects
- centered text on every scene
- no product object or concrete visual
- motion that only decorates

## Required Pre-Design Files

Create these in the project folder before writing `index.html`:

```text
visual-direction.md
moodboard-notes.md
keyframes-plan.md
```

### `visual-direction.md`

```markdown
# Visual Direction

Route:
Audience:
Platform:
Primary emotion:
Visual thesis:
Palette:
Typography:
Layout grid:
Motion language:
Hero asset:
Supporting assets:
Forbidden looks:
```

### `moodboard-notes.md`

Use real web research. Include links to visual references:

```markdown
# Moodboard Notes

Reference 1:
- URL:
- What to borrow:
- What not to copy:

Reference 2:
- URL:
- What to borrow:
- What not to copy:
```

For premium tech/product films, look at:

- Apple product/keynote pages and event films.
- Google I/O opening graphics.
- Bloomberg data visualization clips/pages.
- Stripe/Linear/Notion/Arc style product pages.
- High-quality app launch films and SaaS motion pages.

Do not copy assets or footage unless rights are clear. Borrow composition, pacing, hierarchy, and motion logic.

### `keyframes-plan.md`

Plan still frames before animation:

```markdown
# Keyframes Plan

00:00 Hook frame:
- Foreground:
- Background:
- Main text:
- Motion:

00:12 Product reveal:
- Foreground:
- Background:
- Main text:
- Motion:

00:35 Comparison/data:
- Foreground:
- Background:
- Main text:
- Motion:

00:55 CTA:
- Foreground:
- Background:
- Main text:
- Motion:
```

## Composition Standards

### 9:16 Vertical

Use `1080x1920`. Compose for mobile first:

- Keep main text inside a central safe area.
- Use top/bottom regions intentionally: hook top, product center, CTA bottom.
- Avoid tiny tables; convert comparisons into 2-4 large proof cells.
- Use large focal objects, not many small cards.
- Leave space for platform UI overlays when appropriate.

Suggested safe area:

```css
.safe {
  position: absolute;
  inset: 120px 72px 160px;
}
```

### 16:9 Landscape

Use `1920x1080`. Compose like a launch film or editorial data story:

- Strong horizontal rhythm.
- One hero object or data form per frame.
- Avoid full-screen centered text for every scene.

## Typography Rules

Use no more than two font families. Prefer one strong sans family with weight contrast.

For 9:16:

| Role | Size |
| --- | --- |
| Hero title | 88-136px |
| Scene claim | 56-88px |
| Body/explainer | 32-44px |
| Source/micro label | 20-28px |

Rules:

- Never use negative letter spacing.
- Avoid more than 18 Chinese characters on one line for hero text.
- Break long claims into semantic lines.
- Make one element dominant; do not make all text the same size.
- Use source labels small but readable.

## Color And Depth

Avoid one-note dark purple/cyan gradients unless the brand demands it.

Build palettes like this:

```text
Base: near black / off white
Accent A: product/brand color
Accent B: data contrast color
Signal: warning/success color used sparingly
```

Depth hierarchy:

1. Background texture or field.
2. Mid-layer data lines / product halo / UI frame.
3. Foreground claim or product object.
4. Tiny source/proof labels.

If everything glows, nothing is premium. Use glow only to mark interaction, energy, or product focus.

## Motion Direction

Motion should reveal hierarchy:

- Camera push for product reveal.
- Scan/wipe for data discovery.
- Mask reveal for premium typography.
- Count-up or path draw for proof.
- Snap/lock motion for technical confidence.
- Slow parallax for depth.

Avoid:

- random floating cards
- endless bounce easing
- all elements entering from the same direction
- fast motion on every object
- unrelated particle loops covering text

Use three rhythm levels:

```text
Hook: fast, sharp, high contrast
Proof: measured, data-led, stable
CTA: slower, confident, spacious
```

## Premium Product Promo Recipe

For a product-focused promo:

1. Start with a macro product object, real UI, category symbol, or abstract system visual, not a bullet list.
2. Show the problem state as a system, workflow, or data visualization.
3. Reveal the product as the organizing layer that resolves the problem.
4. Convert features into visual modules: input, action, proof, outcome, and next step.
5. Use competitor/category comparison as a sourced matrix or animated capability map.
6. End with the requested business frame: purchase, signup, demo, channel, partner, reseller, or lead capture.

Visual route:

```text
Apple clarity: large product object, few words
Google I/O energy: abstract system motion
Bloomberg proof: data labels, comparison cells, source notes
```

## Aesthetic QA

After rendering a draft, extract frames:

```powershell
ffmpeg -y -ss 2 -i draft.mp4 -frames:v 1 -update 1 qa_02.png
ffmpeg -y -ss 12 -i draft.mp4 -frames:v 1 -update 1 qa_12.png
ffmpeg -y -ss 30 -i draft.mp4 -frames:v 1 -update 1 qa_30.png
ffmpeg -y -ss 55 -i draft.mp4 -frames:v 1 -update 1 qa_55.png
```

Review every frame:

| Question | Pass condition |
| --- | --- |
| Is there one clear focal point? | Viewer knows where to look within 1 second |
| Does it look like a real designed frame? | Not like a slide template |
| Is the product/category visible? | Product object, UI, or category visual is present |
| Is text readable on mobile? | Main claim readable at phone size |
| Is hierarchy clear? | Title, proof, source labels have distinct weights |
| Is motion meaningful? | Motion reveals product/proof, not just decoration |
| Is it different from previous videos? | At least 3 visual dimensions changed |

If any frame fails, revise before final render.

## Common Fixes For Ugly Drafts

- Too many cards: replace with one hero object plus 2-3 proof labels.
- Too much text: split into multiple timed reveals.
- Generic background: use product silhouette, UI screenshot, data field, or original CSS/Canvas visual.
- Cheap glow: reduce blur and opacity; use sharper contrast.
- Weak composition: increase scale of the main object and add asymmetry.
- PPT feel: remove card borders, use full-bleed fields, masks, and camera motion.
- No premium feel: add source labels, data ticks, precise spacing, and fewer effects.
