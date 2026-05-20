#!/usr/bin/env python
# -*- coding: utf-8 -*-
import argparse
import json
import os
import re
import sys
from pathlib import Path

import soundfile as sf
import torch

os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "expandable_segments:True"
sys.path.insert(0, r"d:\VoxCPM\VoxCPM-2.0.3\src")

from voxcpm import VoxCPM


MODEL_PATH = r"d:\VoxCPM\VoxCPM-2.0.3\models\openbmb__VoxCPM2"
REFERENCE_WAV = r"D:\VoxCPM\宇航的克隆素材_wav\第一段.wav"


def safe_id(value: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9_.-]+", "-", value.strip())
    return cleaned.strip("-") or "segment"


def load_model() -> VoxCPM:
    try:
        model = VoxCPM(
            voxcpm_model_path=MODEL_PATH,
            enable_denoiser=False,
            optimize=True,
        )
    except OSError as exc:
        message = str(exc)
        if "1455" in message or "page file" in message.lower() or "页面文件" in message or "虚拟内存" in message:
            raise RuntimeError(
                "VoxCPM 模型加载失败，Windows 虚拟内存/页面文件不足。"
                "请先关闭浏览器、视频编辑器和其他占内存程序，再把页面文件提高到 32GB 以上后重试。"
            ) from exc
        raise
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
        used = torch.cuda.memory_allocated() / 1024**3
        total = torch.cuda.get_device_properties(0).total_memory / 1024**3
        print(f"GPU memory: {used:.2f}GB / {total:.2f}GB")
    return model


def generate_one(model: VoxCPM, text: str, output_file: Path) -> None:
    output_file.parent.mkdir(parents=True, exist_ok=True)
    wav = model.generate(
        text=text,
        reference_wav_path=REFERENCE_WAV,
        cfg_value=2.0,
        inference_timesteps=10,
    )
    sf.write(str(output_file), wav, model.tts_model.sample_rate)


def run_single(args: argparse.Namespace) -> None:
    with open(args.script_file, "r", encoding="utf-8-sig") as f:
        text = f.read().strip()
    if not text:
        raise ValueError("script file is empty")

    print("Loading VoxCPM once...")
    model = load_model()
    print("Generating narration...")
    generate_one(model, text, Path(args.output_file))
    print(f"Narration saved: {args.output_file}")


def run_segments(args: argparse.Namespace) -> None:
    with open(args.segments_json, "r", encoding="utf-8-sig") as f:
        segments = json.load(f)
    if not isinstance(segments, list) or not segments:
        raise ValueError("segments-json must be a non-empty list")

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"Loading VoxCPM once for {len(segments)} segments...")
    model = load_model()

    results = []
    for index, segment in enumerate(segments, 1):
        seg_id = safe_id(str(segment.get("id") or f"segment-{index:02d}"))
        text = str(segment.get("text") or "").strip()
        if not text:
            raise ValueError(f"segment {seg_id} is empty")

        output_file = output_dir / f"{seg_id}.wav"
        print(f"[{index}/{len(segments)}] Generating {seg_id}: {len(text)} chars")
        generate_one(model, text, output_file)
        results.append(
            {
                "id": seg_id,
                "scene_id": segment.get("scene_id", seg_id),
                "type": segment.get("type", ""),
                "title": segment.get("title", ""),
                "text_length": len(text),
                "path": str(output_file),
            }
        )

    result_path = output_dir / "segments_result.json"
    with open(result_path, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    print(f"Segments saved: {output_dir}")
    print(f"Manifest saved: {result_path}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--script-file")
    parser.add_argument("--output-file")
    parser.add_argument("--segments-json")
    parser.add_argument("--output-dir")
    args = parser.parse_args()

    if args.segments_json or args.output_dir:
        if not args.segments_json or not args.output_dir:
            parser.error("--segments-json and --output-dir must be used together")
    else:
        if not args.script_file or not args.output_file:
            parser.error("--script-file and --output-file are required for single-file mode")
    return args


def main() -> None:
    args = parse_args()
    if args.segments_json:
        run_segments(args)
    else:
        run_single(args)


if __name__ == "__main__":
    main()
