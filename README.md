# VoxCPM Video Maker

VoxCPM Video Maker is an AI agent skill for generating, repairing, and rendering automated daily AI news videos and product promos.

It orchestrates:
- **VoxCPM**: Local text-to-speech (TTS) voice generation.
- **HyperFrames**: Programmatic HTML-to-video rendering framework.
- **Anime.js & GSAP**: High-quality programmatic visual assets and animations.
- **Web Research**: Automated competitor scans, AI news collection, and source logging.

## Demo Video

Here is a sample daily AI video generated using this automated pipeline:

<video src="https://github.com/rfdiosuao/voxcpm-video-maker/raw/master/assets/daily_20260513.mp4" controls="controls" width="100%"></video>

*(If the video doesn't render directly, click [here](https://github.com/rfdiosuao/voxcpm-video-maker/raw/master/assets/daily_20260513.mp4) to view or download it.)*

## Overview

This repository contains the skill definitions and reference materials needed for an AI agent to execute a complete video generation pipeline flawlessly.

- `SKILL.md`: The core logic, core workflow constraints, and strict rules for handling video generation, debugging, and HTML composition.
- `references/`: Reference materials and standard operating procedures (SOPs):
  - `assets.md`: Animation blueprints for Anime.js and GSAP integration.
  - `black-screen-debug.md`: Strict troubleshooting guide for fixing local rendering black screens.
  - `product-short.md`: Design and scripting direction for premium 9:16 vertical shorts.
  - `sync.md`: Mandatory audio-video duration synchronization logic.
  - `variation.md`: Rules to ensure diverse and fresh visual output across multiple video generations.
  - `web-research.md`: Network-first workflow for fetching real context before generating a creative script.

## Usage

This skill is designed to be utilized by an AI agent (like Claude Code) running locally. To invoke the skill, ask your agent to "make a VoxCPM video" or have it load the `SKILL.md` directly.
