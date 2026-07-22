# VoxCPM Video Maker

[中文](README.md) | **English**

> An automated AI-news video pipeline from source collection to final rendering.

VoxCPM Video Maker is a Skill created for the Trae SOLO assistant. It combines AI-news collection, local Chinese speech synthesis, HTML animation, video rendering, and quality checks in one reproducible workflow.

[Watch the example video](https://github.com/rfdiosuao/voxcpm-video-maker/blob/master/assets/daily_20260513.mp4)

## What it does

- Collects selected AI-industry stories from AI HOT
- Generates Chinese narration with a local VoxCPM model
- Builds 1920×1080 animated scenes with HyperFrames and Anime.js
- Renders and packages videos with FFmpeg
- Checks black frames, duration, and audio/video synchronization
- Supports five visual directions for different editorial styles

## Requirements

- Node.js 18+
- Python 3.10+
- FFmpeg 6+
- HyperFrames
- A locally available VoxCPM 2+ model and its Python dependencies

The model files are not bundled with this repository. Follow the provider's terms when obtaining and using them.

## Quick start

Verify the dependencies first:

```powershell
cd video-project
.\pre_flight_check.ps1
```

Run the complete daily pipeline:

```powershell
.\make_daily_video.ps1
```

The scripts in `video-project/` also expose the individual generation, publishing, and QA stages when you need manual control.

## Project layout

```text
assets/          Example media and screenshots
references/      Workflow and production references
video-project/   PowerShell and Python production pipeline
SKILL.md         Agent-facing instructions
```

## Quality checklist

Before publishing, confirm that narration matches the script, scenes contain no black frames, captions are readable, media rights are clear, and the final duration matches the audio track.

## Responsible use

Verify collected stories before publication and respect the licenses, attribution requirements, and privacy rights of all source material. Generated output still requires human editorial review.

## License status

The original README declares the MIT License, but no standalone license file is currently included. Add or verify the complete license text before redistribution.
