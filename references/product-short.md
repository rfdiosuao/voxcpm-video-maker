# Product Promo And Partner Short Video

Use this reference for product, feature-introduction, launch, channel, reseller, source-supplier, business-opportunity, website, Douyin, Xiaohongshu, or WeChat Channels videos. Keep the workflow reusable for any product; do not bake one specific product prompt into the skill.

## Default Format

Use unless the user asks otherwise:

```text
Aspect ratio: 9:16
Resolution: 1080x1920
Duration target: 55-70 seconds
Tone: premium launch film + data visualization
Platforms: Douyin, Xiaohongshu, WeChat Channels, product website
```

Build native 1080x1920 compositions for premium social output. Use horizontal-to-vertical padding only for quick derivatives, not for a first-class Douyin/Xiaohongshu/WeChat Channels video.

The target feel:

- Apple keynote clarity.
- Google I/O opening energy.
- Bloomberg data visualization density.
- Product truth and business logic, not generic hype.

Avoid:

- PPT-style page flipping.
- Cheap template cards.
- Generic stock tech tunnels.
- Endless bullet lists.
- Claims without sources.
- Product-specific examples that are not requested by the current user.

## Mandatory Inputs

Before scripting:

1. Run `web-research.md`.
2. Build `source-log.md`.
3. Build a competitor matrix based on the current product category.
4. Run `art-direction.md` and create `visual-direction.md`, `moodboard-notes.md`, and `keyframes-plan.md`.
5. Decide what can be shown visually: official screenshots, product UI, generated device mockups, data visualization, workflow diagrams, real photos, or permission-safe web assets.
6. Decide the CTA type: purchase, signup, demo, website visit, channel partner, reseller, regional agent, OEM/customization, source-supplier cooperation, or private-traffic conversion.

## One-Minute Structure

Use this as a starting point, then adjust to measured narration duration:

| Time | Beat | Purpose |
| --- | --- | --- |
| 0-4s | Hook | Name the user problem and category tension |
| 4-12s | Product reveal | Introduce the product as the solution |
| 12-28s | Core functions | Explain 3-4 highest-value functions |
| 28-40s | Competitor/category contrast | Show sourced differences, not vague attacks |
| 40-52s | Business or adoption logic | Explain why the product is worth buying, using, or partnering around |
| 52-65s | CTA | Invite the intended next action |

For a 9:16 video, keep each scene visually simple but layered. Use one strong focal point per beat.

## Research Pattern

Build the research plan from the user's product and category:

```text
<product name> official website
<product name> features
<product name> screenshots
<product name> pricing/download/demo
<product category> competitors
<competitor name> official features
<product category> review comparison
<product category> user pain points
<product category> market demand
<product category> royalty free video
<product category> product photo
```

For Chinese products, search both Chinese pinyin and English variants:

```text
<product-name-in-chinese-or-pinyin> official website / guanwang
<product-name-in-chinese-or-pinyin> features / gongneng
<product-name-in-chinese-or-pinyin> screenshots / jietu
<product-name-in-chinese-or-pinyin> download pricing demo
<category-in-chinese-or-pinyin> competitors / jingpin
<category-in-chinese-or-pinyin> comparison / duibi
<category-in-chinese-or-pinyin> user pain points / tongdian
<category-in-chinese-or-pinyin> channel partner reseller / zhaoshang daili
<product category> competitor
<product category> review comparison
```

Do not assume feature advantages. Verify them through sources.

## Visual System For Premium 9:16

Use a vertical launch-film layout:

- Full-height stage with controlled contrast.
- Product name or object as first-screen signal.
- Real UI, product object, generated device mockup, or category-specific hero visual.
- Thin data lines and precise labels.
- Big typographic claims, one per scene.
- Animated comparison matrix with sourced feature cells.
- Smooth camera-like push-ins, not slide transitions.
- UI/screenshot panels floating in depth.

Recommended visual route:

```text
Route: Product Launch + Data Proof
Hero asset: product screenshot/object/mockup/category visual
Supporting asset: data map / comparison matrix / workflow diagram / subtle particles
Palette: product brand colors if verified, plus restrained neutral and data accent colors
```

## Script Rules

Use concrete language:

```text
Do not say: "This product is powerful."
Say: "It solves <specific workflow> by combining <feature A>, <feature B>, and <feature C> in one flow."
```

For competitor or category contrast:

```text
Some tools focus on <competitor strength A>; others focus on <competitor strength B>.
This product should be positioned around <verified advantage or differentiated workflow>.
```

Only say "stronger", "better", "more complete", or "more suitable" after evidence supports the feature. If evidence is incomplete, use safer phrasing:

```text
The stronger positioning appears to be...
The product can be packaged as...
From a channel/business perspective, emphasize...
```

## Partner Or Business CTA

Use this section only when the user brief asks for partner recruitment, source-supplier positioning, channel sales, reseller conversion, zhaoshang, agency, or business-opportunity messaging.

The final 10-15 seconds should answer:

- Who should join or take action?
- What can they sell, promote, implement, or resell?
- Why does the category have demand?
- What is the next step?

Generic CTA shape:

```text
If you serve <target customer group> and already have <traffic/channel/scenario>,
this product can be packaged as <deliverable solution>, not just a standalone tool.
The next step is <website/contact/demo/consultation/channel application>.
```

## Required Deliverables

For product promo projects, create:

```text
source-log.md
competitor-matrix.md
visual-direction.md
moodboard-notes.md
keyframes-plan.md
script.txt
timing-plan.md
index.html
assets\
compositions\
```

Render QA:

- `lint` passes.
- `inspect` passes.
- `inspect` passes.
- Audio/video duration diff <= 0.2s.
- `blackdetect` has no long black segments.
- Sample frames show product, functions, proof/comparison, and the requested CTA.

