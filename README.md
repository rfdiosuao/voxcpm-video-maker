# VoxCPM Video Maker

> AI 新闻视频全自动制作工具 — 从资讯采集到成片渲染，一条命令搞定。

一个专为 **Trae SOLO** AI 助手设计的 Skill，用于自动化制作 AI 新闻视频。支持 AI HOT 资讯自动抓取、VoxCPM 语音生成、HyperFrames HTML 动画合成，以及 Anime.js 视觉特效集成。

[在线演示视频](https://github.com/rfdiosuao/voxcpm-video-maker/blob/master/assets/daily_20260513.mp4)

---

## 成功案例

| 视频预览 | 生成结果 |
|:--------:|:--------:|
| [![视频演示](https://github.com/rfdiosuao/voxcpm-video-maker/raw/master/assets/daily_20260513.mp4)](https://github.com/rfdiosuao/voxcpm-video-maker/blob/master/assets/daily_20260513.mp4) | ![生成结果截图](https://github.com/rfdiosuao/voxcpm-video-maker/raw/master/assets/success-screenshot.png) |
| **时长**: 47.72 秒 · **分辨率**: 1920×1080 · **大小**: 3.1 MB | **音画同步**: ✅ 差值 0.04s · **黑屏检测**: ✅ 无异常 |

> 以上视频由 Trae SOLO 全自动生成，从脚本撰写到最终渲染全程无需人工干预。

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

## 前置条件

### 必需组件

| 组件 | 版本要求 | 用途 | 安装方式 |
|------|----------|------|----------|
| **Node.js** | >= 18.x | 运行 HyperFrames CLI | [官网下载](https://nodejs.org/) 或 `winget install OpenJS.NodeJS` |
| **HyperFrames** | 最新版 | HTML → MP4 视频渲染引擎 | `npm install -g hyperframes` |
| **FFmpeg** | >= 6.0 | 音视频处理、黑屏检测、时长验证 | [官网下载](https://ffmpeg.org/download.html) 或 `winget install Gyan.FFmpeg` |
| **VoxCPM** | 2.0+ | 本地中文语音合成模型 | 见下方部署流程 |
| **Python** | >= 3.10 | 运行 VoxCPM 语音生成脚本 | [官网下载](https://python.org/) 或 `winget install Python.Python.3.12` |

### 可选组件

| 组件 | 用途 |
|------|------|
| **Anime.js** | 增强视觉特效（粒子、星场、线条绘制等） |
| **GitHub CLI (gh)** | 仓库管理、代码推送 |
| **Git** | 版本控制 |

---

## 部署流程

### 第一步：安装基础环境

```powershell
# 1. 安装 Node.js（如未安装）
winget install OpenJS.NodeJS.LTS

# 2. 安装 Python（如未安装）
winget install Python.Python.3.12

# 3. 安装 FFmpeg
winget install Gyan.FFmpeg

# 4. 刷新环境变量（或重启终端）
$env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# 验证安装
node --version
python --version
ffmpeg -version
```

### 第二步：安装 HyperFrames

```powershell
# 全局安装 HyperFrames
npm install -g hyperframes

# 验证安装
npx hyperframes --version
```

### 第三步：部署 VoxCPM 语音模型

```powershell
# 1. 下载 VoxCPM 模型（需自行获取模型文件）
# 模型文件通常包含：
#   - voxcpm_model.bin（模型权重）
#   - config.json（模型配置）
#   - tokenizer/（分词器文件）

# 2. 安装 VoxCPM Python 依赖
cd D:\VoxCPM\VoxCPM-2.0.3
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt

# 3. 验证 VoxCPM 语音生成
python video-project\generate_voice_template.py --text "测试语音" --output test.wav
```

### 第四步：配置项目结构

```powershell
# 创建项目目录
mkdir -p D:\VoxCPM\VoxCPM-2.0.3\video-project\daily
mkdir -p D:\VoxCPM\VoxCPM-2.0.3\video-project\narration

# 复制一键脚本
# make_daily_video.ps1 已包含在 video-project/ 目录中
```

### 第五步：验证完整环境

```powershell
# 运行完整验证脚本
cd D:\VoxCPM\VoxCPM-2.0.3\video-project

# 检查所有依赖
node --version          # 应输出 v18.x 或更高
npx hyperframes --version  # 应输出版本号
ffmpeg -version         # 应输出 FFmpeg 版本
python --version        # 应输出 Python 3.10+

# 测试 VoxCPM 语音生成
.\venv\Scripts\python.exe generate_voice_template.py --text "环境测试成功" --output test_env.wav
```

---

## 快速开始

### 方式一：一键全自动

```powershell
cd D:\VoxCPM\VoxCPM-2.0.3\video-project
.\make_daily_video.ps1
```

### 方式二：分步手动

```powershell
# 1. 编写旁白脚本 → 2. 生成语音 → 3. 测量时长 → 4. 编写场景 → 5. 渲染
```

---

## 项目结构

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
  generate_voice_template.py # VoxCPM 语音生成脚本
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
- narration 音频必须放在 `daily\YYYYMMDD\narration\`

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

## 关于 Trae SOLO

本项目由 **[Trae SOLO](https://www.trae.ai/)** AI 助手自主完成，包括：

- 📝 旁白脚本撰写
- 🎙️ VoxCPM 语音生成
- 🎨 HyperFrames HTML 场景设计
- 🎬 视频渲染与 QA 验证
- 📦 GitHub 仓库创建与推送

展示了 Trae SOLO 在**多步骤复杂任务编排**、**代码生成**、**系统命令执行**和**自动化工作流**方面的能力。

---

## 贡献

欢迎提交 Issue 和 PR。在贡献前请阅读相关参考文档，确保遵循项目规范。

---

## License

MIT License

---

<p align="center">
  Made with ❤️ by <a href="https://www.trae.ai/">Trae SOLO</a> · <a href="https://github.com/rfdiosuao/voxcpm-video-maker">VoxCPM Video Maker</a>
</p>
