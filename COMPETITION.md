# VoxCPM Video Maker — 基于国产大模型的 AI 新闻视频全自动制作 Skill

> **参赛项目**: Trae SOLO 模式 Skill 创新大赛  
> **项目名称**: VoxCPM Video Maker  
> **开发者**: 贺昂  
> **GitHub**: [github.com/rfdiosuao/voxcpm-video-maker](https://github.com/rfdiosuao/voxcpm-video-maker)

---

## 项目概述

**VoxCPM Video Maker** 是一个专为 **Trae SOLO** AI 助手设计的自动化视频制作 Skill，能够**完全基于国产大模型**实现从 AI 行业资讯采集、中文语音合成、HTML 动画场景设计到最终 MP4 视频渲染的全流程自动化。

本项目展示了国产 AI 生态在**复杂多步骤任务编排**、**代码生成**、**系统命令执行**和**自动化工作流**方面的强大能力，全程无需人工干预即可产出专业级 AI 新闻视频。

---

## 核心亮点

### 🇳 纯国产技术栈

| 组件 | 技术 | 说明 |
|------|------|------|
| **大模型** | Trae SOLO (qwen3.6-plus) | 国产大模型驱动全流程决策与代码生成 |
| **语音合成** | VoxCPM | 国产开源中文 TTS 模型，本地部署 |
| **渲染引擎** | HyperFrames | HTML + GSAP 动画合成视频 |
| **数据源** | AI HOT | 国产 AI 资讯聚合平台 |
| **脚本** | PowerShell | Windows 原生自动化 |

### 🤖 全自动工作流

```
AI HOT 资讯采集 → 旁白脚本撰写 → VoxCPM 语音生成 → 场景时间规划 → 
HTML 动画设计 → HyperFrames 渲染 → 音画同步 QA → 最终 MP4 输出
```

全程由 Trae SOLO 自主完成，用户只需一条命令：

```powershell
.\make_daily_video.ps1
```

###  五种视觉路线

系统内置五种视觉风格，每天自动切换，确保输出不重复：

| 路线 | 适用场景 | 视觉特征 |
|------|----------|----------|
| **Signal Radar** | 突发 AI 行业新闻 | 雷达扫描、环形网格、青色点缀 |
| **Deep Space Briefing** | 模型发布/研究 | 星空、视差滚动、缓慢宇宙运动 |
| **Command Center** | 工具/安全/商业更新 | 终端代码块、数据面板、仪表盘 |
| **Magazine Motion** | 日常新闻回顾 | 编辑级排版、干净卡片、大引号 |
| **Neon Dataflow** | 技术/工具故事 | 流光线条、粒子、图表、流动路径 |

---

## 成功案例

### 2026-05-13 每日 AI 新闻视频

| 指标 | 结果 |
|------|------|
| **时长** | 47.72 秒 |
| **分辨率** | 1920×1080 |
| **帧率** | 30fps |
| **文件大小** | 3.1 MB |
| **音画同步** | ✅ 差值 0.04s（< 0.2s 标准） |
| **黑屏检测** | ✅ 无异常黑屏 |

> 以上视频由 Trae SOLO 全自动生成，从脚本撰写到最终渲染全程无需人工干预。

**在线预览**: [daily_20260513.mp4](https://github.com/rfdiosuao/voxcpm-video-maker/blob/master/assets/daily_20260513.mp4)

---

## 技术实现

### 1. 资讯采集与脚本生成

Trae SOLO 通过调用 AI HOT API 获取当日精选 AI 行业资讯，自动筛选最具价值的新闻点，撰写约 60 秒的中文旁白脚本。

### 2. 语音合成

使用国产 VoxCPM 模型生成专业中文旁白，无需外部 TTS 服务，完全本地化运行。

### 3. 场景时间规划

系统自动测量生成音频的实际时长，根据脚本结构动态分配各场景时间，确保音画精确同步（误差 < 0.2 秒）。

### 4. HTML 动画合成

Trae SOLO 自主编写 HyperFrames HTML 场景文件，使用 GSAP 3.12 实现流畅动画效果，遵循严格的合成规范：

- 始终使用 `fromTo()` 确保 seek 渲染确定性
- Timeline 总时长等于场景 `data-duration`
- 所有资源放在项目文件夹内

### 5. 渲染与 QA

系统自动执行完整的 QA 检查清单：

```powershell
npx hyperframes lint      # 语法检查
npx hyperframes validate  # 结构验证
npx hyperframes inspect   # 资源检查
ffmpeg blackdetect        # 黑屏检测
ffprobe duration          # 时长验证
```

---

## 项目结构

```text
voxcpm-video-maker/
├── README.md                    # 项目说明文档
├── SKILL.md                     # Skill 完整规范
├── assets/
│   ├── daily_20260513.mp4       # 成功案例视频
│   ── success-screenshot.png   # 生成结果截图
└── references/
    ├── assets.md                # Anime.js 视觉资产映射
    ├── black-screen-debug.md    # 黑屏诊断流程
    ├── product-short.md         # 9:16 产品推广短视频规范
    ├── sync.md                  # 音画同步规则
    ├── variation.md             # 视觉变化系统
    └── web-research.md          # 网络调研流程
```

---

## 部署与使用

### 前置条件

- **操作系统**: Windows 10/11
- **Node.js**: >= 18.x
- **Python**: >= 3.10
- **FFmpeg**: >= 6.0
- **HyperFrames**: 最新版
- **VoxCPM**: 2.0+

### 快速开始

```powershell
# 1. 克隆仓库
git clone https://github.com/rfdiosuao/voxcpm-video-maker.git

# 2. 安装依赖
npm install -g hyperframes

# 3. 运行一键脚本
cd video-project
.\make_daily_video.ps1
```

详细部署流程请参考 [README.md](https://github.com/rfdiosuao/voxcpm-video-maker/blob/master/README.md)。

---

## 创新价值

### 1. 国产大模型能力展示

本项目完全基于国产技术栈实现，证明了国产大模型在**复杂工程任务**中的实际应用价值：

- **多步骤任务编排**: 自主规划从资讯采集到视频渲染的完整工作流
- **代码生成**: 自主编写 HTML、CSS、JavaScript 动画代码
- **系统命令执行**: 自主调用 PowerShell、FFmpeg、HyperFrames CLI
- **错误诊断与修复**: 自主执行 lint/validate/inspect 并修复问题

### 2. 自动化视频生产

传统视频制作需要专业团队数小时完成的工作，本 Skill 可在 **40 分钟内**全自动完成，大幅降低 AI 新闻视频的生产成本。

### 3. 可扩展架构

Skill 采用模块化设计，支持：

- 新增视觉路线
- 接入其他数据源
- 适配不同分辨率（9:16 竖屏、16:9 横屏）
- 集成更多动画特效库

---

## 技术栈

| 类别 | 技术 |
|------|------|
| **大模型** | Trae SOLO (qwen3.6-plus) |
| **渲染引擎** | HyperFrames (HTML → MP4) |
| **动画** | GSAP 3.12 + Anime.js |
| **语音** | VoxCPM (本地 TTS) |
| **数据源** | AI HOT (aihot.virxact.com) |
| **处理** | FFmpeg, ffprobe |
| **脚本** | PowerShell |

---

## 仓库地址

🔗 **GitHub**: [github.com/rfdiosuao/voxcpm-video-maker](https://github.com/rfdiosuao/voxcpm-video-maker)

---

## 结语

VoxCPM Video Maker 展示了国产大模型在**自动化内容生产**领域的巨大潜力。通过 Trae SOLO 的强大能力，我们实现了从"想法"到"成品视频"的全自动转化，为 AI 新闻视频生产提供了一套完整、高效、可复用的解决方案。

---

<p align="center">
  Made with ❤️ by <a href="https://www.trae.ai/">Trae SOLO</a> · <a href="https://github.com/rfdiosuao/voxcpm-video-maker">VoxCPM Video Maker</a>
</p>
