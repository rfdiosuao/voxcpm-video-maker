# VoxCPM Video Maker

VoxCPM Video Maker 是一个专为 AI 智能体设计的技能（Skill），用于自动生成、修复和渲染每日 AI 资讯视频以及产品推广短视频。

它可以协同调用并控制以下工具和框架：
- **VoxCPM**: 本地文本转语音 (TTS) 以及声音克隆。
- **HyperFrames**: 编程式 HTML 转视频渲染引擎。
- **Anime.js & GSAP**: 高质量编程式视觉素材与时间轴动画控制。
- **Web 联网调研**: 自动竞品分析、AI 资讯抓取及信息源背书记录。

## 演示视频

这是一个使用该自动化管线生成的“每日 AI 资讯”视频示例：

<video src="https://github.com/rfdiosuao/voxcpm-video-maker/raw/master/assets/daily_20260513.mp4" controls="controls" width="100%"></video>

*（如果视频无法直接在页面内播放，请点击 [这里](https://github.com/rfdiosuao/voxcpm-video-maker/raw/master/assets/daily_20260513.mp4) 查看或下载。）*

## 项目概览

本仓库包含了 AI 智能体流畅执行、排错及渲染完整视频管线所需的**核心系统指令**和**操作手册**。

- `SKILL.md`: 核心逻辑、工作流限制，以及处理视频生成、Bug排查（如黑屏问题）、HTML 画面合成的严格法则。
- `references/`: 专属参考资料库及标准作业程序（SOP）：
  - `assets.md`: Anime.js 与 GSAP 动效整合蓝图及高端特效库参考。
  - `black-screen-debug.md`: 针对本地渲染中引发“黑屏”、“无动画”等疑难杂症的严格排错指南。
  - `product-short.md`: 9:16 高级感、带营销招商属性的竖屏推广视频的设计与脚本指导。
  - `sync.md`: 音视频合成中强制性的时长同步逻辑分析。
  - `variation.md`: 视觉丰富度与多样性规则，确保连续自动生成的视频视觉不重复、不疲劳。
  - `web-research.md`: 网络优先工作流，强制 AI 在撰写脚本与合成视觉前进行真实有效的数据与素材搜集。

## 如何使用

本 Skill 专为运行在本地的 AI Agent（如 Claude Code 等）设计。

想要唤起该技能，你只需向你的智能体下达指令，例如 `“帮我用 VoxCPM 制作一个视频”`，或者直接要求它读取并遵循本目录下的 `SKILL.md` 文件即可开启自动化工作流。