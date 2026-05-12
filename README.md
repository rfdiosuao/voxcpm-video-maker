# VoxCPM Video Maker

> AI 新闻视频全自动制作工具 — 从资讯采集到成片渲染，一条命令搞定。

一个专为 Claude Code / SOLO 等 AI 助手设计的 Skill，用于自动化制作 AI 新闻视频。支持 AI HOT 资讯自动抓取、VoxCPM 语音生成、HyperFrames HTML 动画合成，以及 Anime.js 视觉特效集成。

[在线演示视频](https://github.com/rfdiosuao/voxcpm-video-maker/blob/master/assets/daily_20260513.mp4)

---

## 功能特性

| 功能 | 说明 |
|------|------|
| **AI HOT 资讯采集** | 自动从 aihot.virxact.com 抓取当日精选 AI 行业热点 |
| **VoxCPM 语音合成** | 本地模型生成专业中文旁白，无需外部 TTS 服务 |
| **HyperFrames 渲染** | HTML + GSAP 动画合成 1920x1080 高清视频 |
| **五种视觉路线** | 每天自动切换风格，告别千篇一律 |
| **Anime.js 特效库** | 粒子星场、线条绘制、打字机等 6+ 种视觉资产 |
| **音画精确同步** | 误差 < 0.2 秒，基于实际音频时长动态分配场景 |
| **黑屏诊断流程** | 七步定位法：lint → validate → inspect → blackdetect |
| **一键自动化** | PowerShell 脚本全链路：资讯 → 旁白 → 合成 → 渲染 → QA |

---

## 五种视觉路线

每条视频可选择不同的视觉风格，确保输出不重复：

| 路线 | 适用场景 | 视觉特征 |
|------|----------|----------|
| **Signal Radar** | 突发 AI 行业新闻 | 雷达扫描、环形网格、青色点缀 |
| **Deep Space Briefing** | 模型发布/研究 | 星空、视差滚动、缓慢宇宙运动 |
| **Command Center** | 工具/安全/商业更新 | 终端代码块、数据面板、仪表盘 |
| **Magazine Motion** | 日常新闻回顾 | 编辑级排版、干净卡片、大引号 |
| **Neon Dataflow** | 技术/工具故事 | 流光线条、粒子、图表、流动路径 |

---

## 系统要求

- **操作系统**: Windows 10/11
- **HyperFrames**: 视频渲染引擎 ([npm](https://www.npmjs.com/package/hyperframes))
- **FFmpeg**: 音视频处理工具
- **VoxCPM**: 本地语音合成模型（需单独配置）
- **Node.js**: 用于运行 HyperFrames CLI

---

## 快速开始

### 1. 环境准备

```powershell
# 安装 HyperFrames
npm install -g hyperframes

# 确保 FFmpeg 在 PATH 中
ffmpeg -version

# 配置 VoxCPM 语音模型路径
# （见 video-project/generate_voice_template.py）
```

### 2. 项目结构

```text
video-project/
  daily\YYYYMMDD\          # 每日视频项目文件夹
    index.html              # 主合成文件
    script.txt              # 旁白脚本
    narration\              # 语音输出
      daily_YYYYMMDD.wav
    compositions\           # 场景子合成
      daily-intro.html
      news-item-1.html
      ...
      daily-outro.html
  make_daily_video.ps1      # 一键脚本
```

### 3. 制作每日视频

```powershell
# 方式一：一键全自动
cd D:\VoxCPM\VoxCPM-2.0.3\video-project
.\make_daily_video.ps1

# 方式二：分步手动
# 1. 编写脚本 → 2. 生成语音 → 3. 测量时长 → 4. 编写场景 → 5. 渲染
```

---

## 技术规范

### 合成文件规范

```html
<!DOCTYPE html>
<html data-width="1920" data-height="1080">
<head><meta charset="UTF-8"></head>
<body>
  <div data-composition-id="news-item-1"
       data-width="1920" data-height="1080">
    <!-- 场景内容 -->
  </div>
  <script src="https://cdn.jsdelivr.net/npm/gsap@3.12.5/dist/gsap.min.js"></script>
  <script>
    window.__timelines = window.__timelines || {};
    const tl = gsap.timeline({ paused: true });
    tl.fromTo(".element", {opacity: 0}, {opacity: 1, duration: 1});
    window.__timelines["news-item-1"] = tl;
  </script>
</body>
</html>
```

### 关键规则

- 始终使用 `fromTo()` 而非 `from()`，确保 seek 渲染确定性
- Timeline 总时长必须等于场景 `data-duration`
- 所有资源放在项目文件夹内，避免 `../../` 路径
-  narration 音频必须放在 `daily\YYYYMMDD\narration\`

### 渲染与 QA 检查清单

```powershell
cd video-project\daily\YYYYMMDD
npx hyperframes lint
npx hyperframes validate
npx hyperframes inspect
npx hyperframes render --output draft.mp4 --fps 30 --quality draft

# 黑屏检测
ffmpeg -hide_banner -i draft.mp4 -vf blackdetect=d=0.5:pic_th=0.98 -an -f null -

# 音画同步验证
ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 draft.mp4

# 标准质量渲染
npx hyperframes render --output final.mp4 --fps 30 --quality standard
```

---

## 参考文档

| 文档 | 内容 |
|------|------|
| [references/assets.md](references/assets.md) | Anime.js 视觉资产映射与适配指南 |
| [references/web-research.md](references/web-research.md) | 网络调研、竞品扫描、source 日志规范 |
| [references/product-short.md](references/product-short.md) | 9:16 竖屏产品推广短视频工作流 |
| [references/sync.md](references/sync.md) | 音画同步、场景时间分配、QA 流程 |
| [references/variation.md](references/variation.md) | 视觉变化系统与非重复性设计 |
| [references/black-screen-debug.md](references/black-screen-debug.md) | 黑屏诊断与修复工作流 |

---

## 技术栈

- **渲染引擎**: HyperFrames (HTML → MP4)
- **动画**: GSAP 3.12 + Anime.js
- **语音**: VoxCPM (本地 TTS)
- **数据源**: AI HOT (aihot.virxact.com)
- **处理**: FFmpeg, ffprobe
- **脚本**: PowerShell

---

## 贡献

欢迎提交 Issue 和 PR。在贡献前请阅读相关参考文档，确保遵循项目规范。

---

## License

MIT License

---

<p align="center">
  Made with <a href="https://github.com/rfdiosuao/voxcpm-video-maker">VoxCPM Video Maker</a>
</p>
