# VoxCPM Audio Segmentation

Use this when narration is long, audio becomes metallic/electronic near the end, or scene timing drifts.

## Default Strategy

Generate short audio segments, then render one final HyperFrames video:

1. Split the narration into semantic blocks: `intro`, `news-1..N`, `outro`.
2. Keep each block short enough that the expected generated audio stays below about 30 seconds.
3. If one semantic block is still too long, split it into `news-3-part-1`, `news-3-part-2`, etc. while keeping `scene_id: news-3`.
4. Load VoxCPM once and generate all segment WAVs in one process.
5. Join WAV segments with FFmpeg concat into `daily\YYYYMMDD\narration\daily_YYYYMMDD.wav`.
6. Measure every segment with `ffprobe`.
7. Pass exact segment durations into `generate_html.py` as `segments`.
8. Set each scene `data-start` / `data-duration` from the measured segment timeline, summing all parts with the same `scene_id`.
9. Render one MP4 and run the normal QA.

This is usually better than rendering many MP4 clips first. It fixes long-form TTS degradation while preserving one timeline, one audio file, cross-scene transitions, and one QA target.

## When To Split Video Too

Only render separate MP4 clips and concatenate video when HyperFrames itself becomes unstable on a long project, browser memory is exhausted, or a single timeline cannot render reliably. In that case, each clip must still pass black-frame and duration QA before final FFmpeg concat.

## Current Automation

The canonical `make_daily_video.ps1` already implements the default strategy:

- creates `voice_segments.json`
- calls `generate_voice_template.py --segments-json ... --output-dir ...`
- writes segment WAVs under `daily\YYYYMMDD\narration\segments`
- joins them into `daily_YYYYMMDD.wav`
- writes `audio_timing.json`
- passes measured `segments` into `generate_html.py`

If a future agent changes the script, preserve these invariants.
