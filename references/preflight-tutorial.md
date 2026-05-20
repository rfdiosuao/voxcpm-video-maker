# 前置教程：让 `voxcpm-video-maker` + `auto-publish-video` 跑通

这份教程面向“把 Skill 和项目放到同一台电脑、同一套目录里，直接跑完整流程”的场景。

## 目标

你最终要能跑通两条链路：

1. 生成视频
2. 生成视频后自动发布到全平台

## 推荐目录结构

把 Skill 仓库和业务项目放在同一层，路径尽量固定：

```text
D:\VoxCPM\
  .agents\
    skills\
      voxcpm-video-maker\
      auto-publish-video
  VoxCPM-2.0.3\
    video-project\
  MediaPublishPlatform\
```

核心原则：

- `voxcpm-video-maker` 负责视频生成、QA、发布衔接
- `auto-publish-video` 负责账号上传和平台发布
- `MediaPublishPlatform` 负责本地后端服务

## 你需要先准备好的东西

### 1. 基础运行环境

- Windows 10/11
- PowerShell
- Python 3.10+
- Node.js 18+
- Git
- FFmpeg

### 2. 视频生成链路

- `D:\VoxCPM\VoxCPM-2.0.3\video-project\make_daily_video.ps1`
- `D:\VoxCPM\VoxCPM-2.0.3\video-project\generate_voice_template.py`
- `D:\VoxCPM\VoxCPM-2.0.3\video-project\generate_html.py`
- `D:\VoxCPM\VoxCPM-2.0.3\video-project\qa_video.ps1`

### 3. 发布链路

- `D:\VoxCPM\MediaPublishPlatform\MediaPublishPlatform\sau_backend\sau_backend.py`
- `D:\VoxCPM\MediaPublishPlatform\MediaPublishPlatform\cookiesFile\`
- 各平台 cookie 文件
- `publish_daily_video.ps1`
- `run_daily_pipeline.ps1`

### 4. 模型与资产

- VoxCPM 模型文件已落到 `D:\VoxCPM\VoxCPM-2.0.3\models\`
- React-bits / Anime.js / HyperFrames 资产已按 Skill 约定存在
- `video-project` 下的 HTML、脚本、参考文档齐全

## 安装顺序

### 第一步：确认基础命令可用

```powershell
node -v
python -V
git --version
ffmpeg -version
npx hyperframes --version
```

### 第二步：确认 VoxCPM 能出音频

在 `D:\VoxCPM\VoxCPM-2.0.3\video-project` 下执行一条最小测试，确保能生成 wav。

### 第三步：确认 HyperFrames 能渲染

先跑 lint，再跑 draft render，再跑 QA。

### 第四步：确认 MPP 后端能启动

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\VoxCPM\MediaPublishPlatform\MediaPublishPlatform\ensure_backend_running.ps1
```

访问 `http://127.0.0.1:5409/getValidAccounts` 能返回账号列表，才算发布链路可用。

## 一次性跑通检查清单

### 生成侧

- AI HOT 数据能拉到
- 配音能生成
- 配音时长能测出来
- HTML 场景能生成
- `hyperframes lint` 通过
- `hyperframes inspect` 通过
- draft render 通过
- 标准渲染通过
- 黑屏 QA 通过

### 发布侧

- MPP 后端启动成功
- `getValidAccounts` 有返回
- cookie 文件存在
- `publish_daily_video.ps1` 只传 cookie 文件名，不传昵称
- 标签是整词，不是逐字符 `#A#I` 这种格式

## 正确的运行方式

### 只生成，不发布

```powershell
cd D:\VoxCPM\VoxCPM-2.0.3\video-project
.\run_daily_pipeline.ps1 -Date 20260521 -NoPublish
```

### 生成并全平台发布

```powershell
cd D:\VoxCPM\VoxCPM-2.0.3\video-project
.\run_daily_pipeline.ps1 -Date 20260521
```

### 只做发布

```powershell
cd D:\VoxCPM\VoxCPM-2.0.3\video-project
.\publish_daily_video.ps1 -Date 20260521
```

## 发布前必须满足的条件

- 横版视频存在
- 竖版视频存在则优先发竖版
- QA 通过
- MPP 后端在线
- cookie 文件名有效
- 标签是整词

## 常见失败点

- `No command specified`：HyperFrames 命令参数传错
- 黑屏：HTML 场景资源路径错、root duration 错、动画 seek 不稳定
- 音画不同步：未按真实音频时长分配场景
- 发布失败：`accountList` 传了昵称而不是 cookie 文件名
- 标签异常：把一个字符串当字符数组逐字处理了

## 复制到别的电脑时的最小要求

只要把下面三块一起带过去，路径保持一致，基本就能复现：

1. `voxcpm-video-maker` Skill 仓库
2. `VoxCPM-2.0.3\video-project`
3. `MediaPublishPlatform`

如果路径变了，就把脚本里的硬编码路径一起改掉。
