# Mandatory Web Research And Asset Sourcing

Use this reference before making any new video. Real network research is required. Do not invent competitor claims, product features, screenshots, logos, or market facts from memory.

## Research Goals

Collect enough evidence to write a grounded script and design visuals:

- Official product facts.
- Competitor features and positioning.
- Proof points for "stronger/better" claims.
- Category language users already understand.
- Visual references and usable assets.
- Copyright-safe image/video candidates.

## Required Source Types

Use at least these source groups when available:

| Source type | Purpose |
| --- | --- |
| Official website/product docs | Verify product features, UI, claims, pricing, screenshots |
| Official social/press pages | Find launch language, visuals, brand tone |
| Competitor official pages | Build the comparison matrix |
| App store/download pages | Confirm supported platforms, current version, ratings |
| Reputable reviews/tutorials | Understand user pain points and real-world positioning |
| Image/video search | Find visual references and asset candidates |
| Royalty-free libraries | Source generic background footage if official assets are not usable |

## Search Pattern

For a product video, run searches like:

```text
<product name> official
<product name> features
<product name> screenshots
<product name> download
<product category> competitors
<competitor name> official features
<category> review comparison
<category> pain points
<product category> royalty free video
<product category> product photo
```

For Chinese products, search both Chinese pinyin and English terms:

```text
<product-name-in-chinese-or-pinyin> official website / guanwang
<product-name-in-chinese-or-pinyin> features / gongneng
<product-name-in-chinese-or-pinyin> screenshots / jietu
<category-in-chinese-or-pinyin> competitors / jingpin
<category-in-chinese-or-pinyin> comparison / duibi
<category-in-chinese-or-pinyin> user pain points / tongdian
<category-in-chinese-or-pinyin> channel partner reseller / zhaoshang daili
<product category> competitor
<product category> review comparison
```

## Source Log

Create `source-log.md` in the video project folder. Keep it short but specific:

```markdown
# Source Log

Research date: YYYY-MM-DD

## Product Sources
- Title: URL - key facts

## Competitor Sources
- Title: URL - key facts

## Claims
- Claim: "..."
  Evidence: URL
  Use in video: scene/time

## Asset Candidates
- URL/path:
  Type: screenshot/video/photo/logo/reference
  Rights note:
  Use/reject:

## Final Assets Used
- Local path:
  Source:
  Scene:
```

## Competitor Matrix

For every product promo, create a simple matrix before writing the script:

```markdown
| Feature | Product | Competitor A | Competitor B | Evidence |
| --- | --- | --- | --- | --- |
| USB boot creation | yes | yes | yes | URLs |
| Driver/PE/toolbox | ... | ... | ... | URLs |
| One-click workflow | ... | ... | ... | URLs |
| Data safety | ... | ... | ... | URLs |
| Commercial/partner model | ... | ... | ... | URLs |
```

Only make "better than competitors" claims when the matrix has evidence. Otherwise phrase as "positioned for", "designed to", or "focuses on".

## Asset Rules

Prefer in this order:

1. User-provided product assets.
2. Official product screenshots or logos if allowed by the project/user.
3. Screenshots captured from official pages for commentary/comparison.
4. Generated abstract visuals based on product concepts.
5. Royalty-free background footage or images.

Avoid:

- Random watermarked product images.
- Competitor logos as decoration without a clear comparison purpose.
- Stock clips that do not show the actual product, UI, workflow, device, or category.
- Any asset with unclear rights when the video is for public promotion.

## Visual Capture Notes

When using website screenshots:

- Capture the actual page or product UI.
- Save with descriptive names under `assets\web\`.
- Record source URL in `source-log.md`.
- Crop to the relevant feature; do not make it the entire visual language.

When using web video references:

- Use them as motion references unless rights are explicit.
- Recreate the style with original HTML/CSS/GSAP/Anime.js instead of copying the clip.

## Stop Conditions

Stop and report a blocker if:

- Official product facts cannot be found.
- Competitor claims cannot be verified.
- The user asks for "better than competitors" but no evidence supports it.
- All usable visual assets are copyrighted/unclear and no generated or user-provided fallback exists.
