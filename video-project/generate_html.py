#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
HTML 场景生成 - AI 动态生成版本
根据每条新闻内容，让 AI 现场生成独特的 HTML 布局
"""

import os
import sys
import json
import requests
from datetime import datetime

# ========== 固定模板作为 Fallback ==========
INTRO_TEMPLATE = '''<!DOCTYPE html>
<html data-width="1920" data-height="1080">
<head>
  <meta charset="UTF-8">
  <style>
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", sans-serif; background: {bg}; color: #fff; overflow: hidden; }}
    .scene-content {{ width: 100%; height: 100%; display: flex; flex-direction: column; justify-content: center; align-items: center; position: relative; }}
    .bg-gradient {{ position: absolute; inset: 0; background: radial-gradient(ellipse at 50% 0%, rgba({p_r}{p_g}{p_b},0.15) 0%, transparent 60%), linear-gradient(180deg, {bg} 0%, #111118 100%); z-index: 0; }}
    .grid-lines {{ position: absolute; inset: 0; background-image: linear-gradient(rgba(255,255,255,0.02) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.02) 1px, transparent 1px); background-size: 60px 60px; z-index: 1; }}
    .glow-orb {{ position: absolute; border-radius: 50%; filter: blur(100px); z-index: 0; }}
    .glow-orb-1 {{ width: 400px; height: 400px; background: rgba({p_r}{p_g}{p_b},0.25); top: -100px; right: 100px; }}
    .glow-orb-2 {{ width: 300px; height: 300px; background: rgba({s_r}{s_g}{s_b},0.2); bottom: -50px; left: 150px; }}
    .intro-container {{ position: relative; z-index: 10; text-align: center; }}
    .date-badge {{ font-size: 20px; color: rgba(132,150,255,0.9); letter-spacing: 4px; margin-bottom: 24px; }}
    .main-title {{ font-size: 100px; font-weight: 800; background: linear-gradient(135deg, #fff 0%, #c7d2fe 52%, #8ea2ff 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; margin-bottom: 20px; }}
    .subtitle {{ font-size: 32px; color: rgba(255,255,255,0.75); font-weight: 300; letter-spacing: 2px; margin-bottom: 40px; }}
    .divider {{ width: 120px; height: 3px; background: linear-gradient(90deg, {p}, {s}); border-radius: 2px; margin: 0 auto 24px; }}
    .news-count {{ font-size: 20px; color: rgba(255,255,255,0.6); letter-spacing: 2px; }}
    .style-label {{ font-size: 14px; color: rgba(255,255,255,0.4); letter-spacing: 3px; margin-top: 20px; text-transform: uppercase; }}
  </style>
</head>
<body>
  <div data-composition-id="daily-intro" data-width="1920" data-height="1080">
    <div class="scene-content">
      <div class="bg-gradient"></div>
      <div class="grid-lines"></div>
      <div class="glow-orb glow-orb-1"></div>
      <div class="glow-orb glow-orb-2"></div>
      <div class="intro-container">
        <div class="date-badge">{date_str} · {week_day}</div>
        <h1 class="main-title">AI HOT 日报</h1>
        <p class="subtitle">今日 AI 行业重要资讯</p>
        <div class="divider"></div>
        <p class="news-count">{news_count} 条精选</p>
        <p class="style-label">{style_label} · {style_name}</p>
      </div>
    </div>
  </div>
  <script src="https://cdn.jsdelivr.net/npm/gsap@3.12.5/dist/gsap.min.js"></script>
  <script>
    window.__timelines = window.__timelines || {{}};
    const totalDuration = {intro_duration};
    const tl = gsap.timeline({{ paused: true }});
    tl.fromTo(".bg-gradient", {{ opacity: 0 }}, {{ opacity: 1, duration: 0.8, ease: "power2.out" }}, 0)
      .fromTo(".glow-orb-1", {{ scale: 0.88, opacity: 0 }}, {{ scale: 1, opacity: 1, duration: 1.2, ease: "power3.out" }}, 0.2)
      .fromTo(".glow-orb-2", {{ scale: 0.88, opacity: 0 }}, {{ scale: 1, opacity: 1, duration: 1.2, ease: "power3.out" }}, 0.4)
      .fromTo(".grid-lines", {{ opacity: 0 }}, {{ opacity: 1, duration: 0.8, ease: "power2.out" }}, 0.6)
      .fromTo(".date-badge", {{ y: 30, opacity: 0 }}, {{ y: 0, opacity: 1, duration: 0.6, ease: "power3.out" }}, 0.8)
      .fromTo(".main-title", {{ y: 60, opacity: 0 }}, {{ y: 0, opacity: 1, duration: 1, ease: "power3.out" }}, 1)
      .fromTo(".subtitle", {{ y: 40, opacity: 0 }}, {{ y: 0, opacity: 1, duration: 0.8, ease: "power2.out" }}, 1.2)
      .fromTo(".divider", {{ scaleX: 0, opacity: 0 }}, {{ scaleX: 1, opacity: 1, duration: 0.6, ease: "power2.out" }}, 1.4)
      .fromTo(".news-count", {{ y: 20, opacity: 0 }}, {{ y: 0, opacity: 1, duration: 0.5, ease: "power2.out" }}, 1.6)
      .fromTo(".style-label", {{ y: 15, opacity: 0 }}, {{ y: 0, opacity: 1, duration: 0.5, ease: "power2.out" }}, 1.8)
      .to(".glow-orb-1", {{ x: 20, y: 10, duration: totalDuration - 2, ease: "sine.inOut" }}, 2)
      .to(".glow-orb-2", {{ x: -15, y: -10, duration: totalDuration - 2, ease: "sine.inOut" }}, 2);
    window.__timelines["daily-intro"] = tl;
  </script>
</body>
</html>'''

OUTRO_TEMPLATE = '''<!DOCTYPE html>
<html data-width="1920" data-height="1080">
<head>
  <meta charset="UTF-8">
  <style>
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", sans-serif; background: #0a0a0f; color: #fff; overflow: hidden; }}
    .scene-content {{ width: 100%; height: 100%; display: flex; flex-direction: column; justify-content: center; align-items: center; position: relative; }}
    .bg-gradient {{ position: absolute; inset: 0; background: radial-gradient(ellipse at 50% 100%, rgba({p_r}{p_g}{p_b},0.12) 0%, transparent 60%), linear-gradient(180deg, #111118 0%, {bg} 100%); z-index: 0; }}
    .grid-lines {{ position: absolute; inset: 0; background-image: linear-gradient(rgba(255,255,255,0.02) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.02) 1px, transparent 1px); background-size: 60px 60px; z-index: 1; }}
    .outro-container {{ position: relative; z-index: 10; text-align: center; }}
    .main-title {{ font-size: 72px; font-weight: 800; background: linear-gradient(135deg, #fff 0%, #c7d2fe 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; margin-bottom: 24px; }}
    .subtitle {{ font-size: 32px; color: rgba(255,255,255,0.7); font-weight: 300; margin-bottom: 40px; }}
    .divider {{ width: 100px; height: 3px; background: linear-gradient(90deg, {p}, {s}); border-radius: 2px; margin: 0 auto 32px; }}
    .logo-text {{ font-size: 28px; font-weight: 700; color: rgba(132,150,255,0.9); letter-spacing: 2px; }}
    .date-text {{ font-size: 18px; color: rgba(255,255,255,0.5); margin-top: 16px; }}
  </style>
</head>
<body>
  <div data-composition-id="daily-outro" data-width="1920" data-height="1080">
    <div class="scene-content">
      <div class="bg-gradient"></div>
      <div class="grid-lines"></div>
      <div class="outro-container">
        <div class="divider"></div>
        <h1 class="main-title">明天同一时间</h1>
        <p class="subtitle">我们继续关注 AI 行业动态</p>
        <div class="divider"></div>
        <p class="logo-text">AI HOT 每日科技资讯</p>
        <p class="date-text">{date_str} · {week_day} · 真实证据 · 深度解读</p>
      </div>
    </div>
  </div>
  <script src="https://cdn.jsdelivr.net/npm/gsap@3.12.5/dist/gsap.min.js"></script>
  <script>
    window.__timelines = window.__timelines || {{}};
    const totalDuration = {outro_duration};
    const tl = gsap.timeline({{ paused: true }});
    tl.fromTo(".bg-gradient", {{ opacity: 0 }}, {{ opacity: 1, duration: 0.8, ease: "power2.out" }}, 0)
      .fromTo(".divider", {{ scaleX: 0, opacity: 0 }}, {{ scaleX: 1, opacity: 1, duration: 0.6, ease: "power2.out" }}, 0.3)
      .fromTo(".main-title", {{ y: 50, opacity: 0 }}, {{ y: 0, opacity: 1, duration: 1, ease: "power3.out" }}, 0.6)
      .fromTo(".subtitle", {{ y: 30, opacity: 0 }}, {{ y: 0, opacity: 1, duration: 0.8, ease: "power2.out" }}, 1)
      .fromTo(".logo-text", {{ y: 20, opacity: 0 }}, {{ y: 0, opacity: 1, duration: 0.6, ease: "power2.out" }}, 1.4)
      .fromTo(".date-text", {{ y: 15, opacity: 0 }}, {{ y: 0, opacity: 1, duration: 0.5, ease: "power2.out" }}, 1.7);
    window.__timelines["daily-outro"] = tl;
  </script>
</body>
</html>'''

INDEX_TEMPLATE = '''<!DOCTYPE html>
<html data-width="1920" data-height="1080">
<head>
  <meta charset="UTF-8">
  <style>
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    body {{ background: #0a0a0f; overflow: hidden; }}
    video, audio {{ display: none; }}
  </style>
</head>
<body>
  <div data-composition-id="root" data-width="1920" data-height="1080" data-start="0" data-duration="{total_duration}">
    <div id="scene-intro"
         data-composition-id="daily-intro"
         data-composition-src="compositions/daily-intro.html"
         data-start="0"
         data-duration="{intro_duration}"
         data-track-index="1">
    </div>
{scenes}
    <div id="scene-outro"
         data-composition-id="daily-outro"
         data-composition-src="compositions/daily-outro.html"
         data-start="{current_start}"
         data-duration="{outro_duration}"
         data-track-index="1">
    </div>
    <audio id="narration" data-start="0" data-duration="{total_duration}" data-track-index="2" data-volume="1" src="narration/daily_{date}.wav"></audio>
  </div>
  <script src="https://cdn.jsdelivr.net/npm/gsap@3.12.5/dist/gsap.min.js"></script>
  <script>
    window.__timelines = window.__timelines || {{}};
  </script>
</body>
</html>'''

INDEX_SCENE_ENTRY = '''    <div id="scene-news{num}"
         data-composition-id="news-item-{num}"
         data-composition-src="compositions/news-item-{num}.html"
         data-start="{start}"
         data-duration="{duration}"
         data-track-index="1">
    </div>'''

# Fallback 模板（AI失败时使用）
FALLBACK_NEWS_TEMPLATE = '''<!DOCTYPE html>
<html data-width="1920" data-height="1080">
<head>
  <meta charset="UTF-8">
  <style>
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", sans-serif; background: #0a0a0f; color: #fff; overflow: hidden; }}
    .scene-content {{ width: 100%; height: 100%; padding: 60px 100px; display: flex; flex-direction: column; justify-content: center; position: relative; }}
    .bg-gradient {{ position: absolute; inset: 0; background: radial-gradient(ellipse at 30% 50%, rgba({accent_r}{accent_g}{accent_b},0.12) 0%, transparent 52%), radial-gradient(ellipse at 90% 20%, rgba({a_r}{a_g}{a_b},0.06) 0%, transparent 48%), linear-gradient(135deg, #0a0a0f 0%, #111118 100%); z-index: 0; }}
    .accent-line {{ position: absolute; left: 0; top: 0; width: 6px; height: 100%; background: linear-gradient(180deg, {accent} 0%, {s} 50%, {a} 100%); z-index: 1; transform-origin: top; }}
    .news-container {{ position: relative; z-index: 10; max-width: 1720px; display: grid; grid-template-columns: 1fr 580px; gap: 48px; align-items: center; }}
    .news-text {{ }}
    .news-header {{ display: flex; align-items: flex-start; gap: 24px; margin-bottom: 24px; }}
    .news-number {{ min-width: 100px; font-size: 64px; font-weight: 800; background: linear-gradient(135deg, #8ea2ff 0%, #a885ff 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; line-height: 1; }}
    .news-title {{ font-size: 42px; font-weight: 700; color: #fff; line-height: 1.25; flex: 1; }}
    .news-summary {{ font-size: 24px; color: rgba(255,255,255,0.75); line-height: 1.6; margin-bottom: 24px; }}
    .news-footer {{ display: flex; justify-content: space-between; align-items: center; }}
    .news-source {{ font-size: 18px; color: rgba(255,255,255,0.6); }}
    .news-category {{ font-size: 14px; color: rgba(140,160,255,0.9); padding: 6px 14px; border: 1px solid rgba(132,150,255,0.4); border-radius: 20px; }}
    .news-image-container {{ position: relative; }}
    .news-image {{ width: 100%; height: 520px; border-radius: 12px; box-shadow: 0 8px 40px rgba(0,0,0,0.5); overflow: hidden; border: 1px solid rgba(255,255,255,0.1); }}
    .news-image img {{ width: 100%; height: 100%; object-fit: cover; }}
    .image-border {{ position: absolute; inset: -2px; border-radius: 14px; background: linear-gradient(135deg, {accent}, {a}); z-index: -1; filter: blur(8px); opacity: 0.6; }}
    .image-badge {{ position: absolute; top: 12px; right: 12px; background: rgba(0,0,0,0.6); backdrop-filter: blur(4px); color: #fff; font-size: 12px; padding: 6px 12px; border-radius: 6px; border: 1px solid rgba(255,255,255,0.2); }}
    .no-image {{ background: linear-gradient(135deg, rgba({accent_r},{accent_g},{accent_b},0.2), rgba({a_r},{a_g},{a_b},0.1)); display: flex; align-items: center; justify-content: center; color: rgba(255,255,255,0.5); font-size: 18px; }}
  </style>
</head>
<body>
  <div data-composition-id="news-item-{num}" data-width="1920" data-height="1080">
    <div class="scene-content">
      <div class="bg-gradient"></div>
      <div class="accent-line"></div>
      <div class="news-container">
        <div class="news-text">
          <div class="news-header">
            <span class="news-number">{num_str}</span>
            <h2 class="news-title">{title}</h2>
          </div>
          <p class="news-summary">{summary}</p>
          <div class="news-footer">
            <span class="news-source">来源: {source}</span>
            <span class="news-category">AI HOT 精选</span>
          </div>
        </div>
        <div class="news-image-container">
          <div class="image-border"></div>
          <div class="news-image">
            {image_html}
          </div>
          <div class="image-badge">原文截图</div>
        </div>
      </div>
    </div>
  </div>
  <script src="https://cdn.jsdelivr.net/npm/gsap@3.12.5/dist/gsap.min.js"></script>
  <script>
    window.__timelines = window.__timelines || {{}};
    const totalDuration = {duration};
    const tl = gsap.timeline({{ paused: true }});
    tl.fromTo(".bg-gradient", {{ opacity: 0 }}, {{ opacity: 1, duration: 0.6, ease: "power2.out" }}, 0)
      .fromTo(".accent-line", {{ scaleY: 0, opacity: 0 }}, {{ scaleY: 1, opacity: 1, duration: 0.8, ease: "power3.out" }}, 0.2)
      .fromTo(".news-number", {{ x: -44, opacity: 0 }}, {{ x: 0, opacity: 1, duration: 0.6, ease: "power3.out" }}, 0.4)
      .fromTo(".news-title", {{ x: 44, opacity: 0 }}, {{ x: 0, opacity: 1, duration: 0.8, ease: "power3.out" }}, 0.5)
      .fromTo(".news-summary", {{ y: 30, opacity: 0 }}, {{ y: 0, opacity: 1, duration: 0.7, ease: "power2.out" }}, 0.7)
      .fromTo(".image-border", {{ scale: 0.9, opacity: 0 }}, {{ scale: 1, opacity: 1, duration: 0.8, ease: "power3.out" }}, 0.6)
      .fromTo(".news-image", {{ x: 40, opacity: 0 }}, {{ x: 0, opacity: 1, duration: 0.8, ease: "power3.out" }}, 0.7)
      .fromTo(".image-badge", {{ y: -10, opacity: 0 }}, {{ y: 0, opacity: 1, duration: 0.5, ease: "power2.out" }}, 1.0)
      .fromTo(".news-source", {{ y: 20, opacity: 0 }}, {{ y: 0, opacity: 1, duration: 0.5, ease: "power2.out" }}, 0.9)
      .fromTo(".news-category", {{ y: 20, opacity: 0 }}, {{ y: 0, opacity: 1, duration: 0.5, ease: "power2.out" }}, 1)
      .to(".bg-gradient", {{ backgroundPosition: "12% 50%", duration: totalDuration - 1.2, ease: "none" }}, 1.2)
      .to(".news-container", {{ y: -8, duration: totalDuration - 2, ease: "sine.inOut" }}, 2);
    window.__timelines["news-item-{num}"] = tl;
  </script>
</body>
</html>'''

def hex_to_rgb(hex_color):
    """Convert #RRGGBB to (r, g, b)"""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def truncate_text(text, max_len):
    """Truncate text if too long"""
    if len(text) > max_len:
        return text[:max_len-3] + "..."
    return text

def escape_html(text):
    """Escape HTML quotes"""
    return text.replace('"', '&quot;').replace('<', '&lt;').replace('>', '&gt;')

def load_ai_config():
    """Load AI configuration from ai_config.json"""
    config_path = os.path.join(os.path.dirname(__file__), 'ai_config.json')
    if os.path.exists(config_path):
        with open(config_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    return None

def generate_ai_html(news_item, num, has_image, primary_color, secondary_color, accent_color, duration, config):
    """Use AI to generate unique HTML for this news item"""
    if not config or not config.get('openai_api_key') or config['openai_api_key'] == 'your-api-key-here':
        print(f"  [新闻 {num}] AI配置无效，使用 fallback 模板")
        return None

    title = news_item['title']
    summary = news_item.get('summary', '')
    source = news_item.get('source', 'AI HOT')
    image_path = f"../images/news_{num:02d}.jpg" if has_image else None

    prompt = f"""你是一位前端设计师，为视频创作一个 1920x1080 的 HTML 新闻场景。

新闻信息：
- 序号：{num}
- 标题：{title}
- 摘要：{summary}
- 来源：{source}
- 已有截图：{'是，截图路径: ' + image_path if has_image else '否，没有截图'}
- 主题色：{primary_color}
- 次要色：{secondary_color}
- 强调色：{accent_color}
- 场景时长：{duration} 秒

要求：
1. 输出必须是完整的 HTML 文件，从 <!DOCTYPE html> 开始到 </html> 结束
2. 必须遵循 HyperFrames 格式：
   - 根 html 需要属性: data-width="1920" data-height="1080"
   - 内容容器需要: <div data-composition-id="news-item-{num}" data-width="1920" data-height="1080">
   - 结尾引入 GSAP: <script src="https://cdn.jsdelivr.net/npm/gsap@3.12.5/dist/gsap.min.js"></script>
   - 必须有 GSAP 动画时间线：
     ```javascript
     window.__timelines = window.__timelines || {{}};
     const totalDuration = {duration};
     const tl = gsap.timeline({{ paused: true }});
     // ... your animations ...
     window.__timelines["news-item-{num}"] = tl;
     ```
3. 设计一个独特的布局，配合标题文字和（如果有的话）截图。可以自由发挥创意布局。
4. 背景深色科技风格，文字清晰可读，尊重原始色值
5. CODE ONLY：只输出完整的 HTML 代码，不要任何解释文字

现在输出完整的 HTML 代码："""

    api_key = config['openai_api_key']
    base_url = config.get('openai_base_url', 'https://api.openai.com/v1')
    model = config.get('model', 'gpt-4o')
    timeout = config.get('timeout', 120)

    headers = {
        'Authorization': f'Bearer {api_key}',
        'Content-Type': 'application/json'
    }

    data = {
        'model': model,
        'messages': [
            {'role': 'system', 'content': 'You are an expert HTML/CSS/GSAP designer for video scenes. Output only complete, working HTML code.'},
            {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7,
        'max_tokens': 4000
    }

    try:
        url = f"{base_url.rstrip('/')}/chat/completions"
        response = requests.post(url, json=data, headers=headers, timeout=timeout)
        response.raise_for_status()
        result = response.json()
        html_content = result['choices'][0]['message']['content'].strip()

        # Clean up: remove ```html and ``` markers
        html_content = html_content.replace('```html', '').replace('```', '').strip()

        # Verify it's a complete HTML
        if '<!DOCTYPE html' not in html_content and '<html' not in html_content:
            print(f"  [新闻 {num}] AI 输出不是完整 HTML，使用 fallback")
            return None

        if f'data-composition-id="news-item-{num}"' not in html_content:
            print(f"  [新闻 {num}] AI 输出缺少 composition-id，使用 fallback")
            return None

        print(f"  [新闻 {num}] AI 生成成功 ({len(html_content)} bytes)")
        return html_content

    except Exception as e:
        print(f"  [新闻 {num}] AI 生成失败: {e}，使用 fallback")
        return None

def main():
    if len(sys.argv) != 8:
        print("Usage: python generate_html.py <daily_dir> <date> <p_primary> <s_secondary> <a_accent> <bg_color> <style_json>")
        print("Example: python generate_html.py ./daily/20260516 20260516 #667eea #764ba2 #00d4ff #0a0a0f style.json")
        sys.exit(1)

    daily_dir = sys.argv[1]
    date = sys.argv[2]
    p_primary = sys.argv[3]
    s_secondary = sys.argv[4]
    a_accent = sys.argv[5]
    bg_color = sys.argv[6]
    style_json_path = sys.argv[7]

    # Load AI config
    ai_config = load_ai_config()
    if ai_config:
        print(f"  ✓ 已加载 AI 配置，使用模型: {ai_config.get('model', 'gpt-4o')}")
    else:
        print(f"  ! 未找到 ai_config.json 或配置无效，将使用 fallback 模板")

    # Load style info and news items
    with open(style_json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    news_items = data['news_items']
    style_name = data['style_name']
    style_label = data['style_label']
    intro_duration = data['intro_duration']
    outro_duration = data['outro_duration']
    news_duration = data['news_duration']
    total_duration = data['total_duration']

    # Convert colors
    p_r, p_g, p_b = hex_to_rgb(p_primary)
    s_r, s_g, s_b = hex_to_rgb(s_secondary)
    a_r, a_g, a_b = hex_to_rgb(a_accent)

    # Date formatting
    date_obj = datetime.strptime(date, "%Y%m%d")
    date_str = date_obj.strftime("%Y年%m月%d日")
    week_day = date_obj.strftime("%A")
    # Chinese weekday
    weekday_cn = {
        'Monday': '星期一', 'Tuesday': '星期二', 'Wednesday': '星期三',
        'Thursday': '星期四', 'Friday': '星期五', 'Saturday': '星期六', 'Sunday': '星期日'
    }
    week_day = weekday_cn.get(week_day, week_day)

    # Create compositions directory
    comp_dir = os.path.join(daily_dir, 'compositions')
    os.makedirs(comp_dir, exist_ok=True)

    # Generate intro (intro is fixed template, no need AI)
    intro_html = INTRO_TEMPLATE.format(
        bg=bg_color,
        p=p_primary,
        p_r=p_r, p_g=p_g, p_b=p_b,
        s=s_secondary,
        s_r=s_r, s_g=s_g, s_b=s_b,
        date_str=date_str,
        week_day=week_day,
        news_count=len(news_items),
        style_label=style_label,
        style_name=style_name,
        intro_duration=intro_duration
    )
    intro_path = os.path.join(comp_dir, 'daily-intro.html')
    with open(intro_path, 'w', encoding='utf-8') as f:
        f.write(intro_html)
    print(f"  Created: compositions/daily-intro.html")

    # Generate news items - AI generates each one uniquely
    accent_colors = ["#667eea", "#764ba2", "#00d4ff", "#f59e0b"]
    ai_success_count = 0
    fallback_count = 0

    for i, item in enumerate(news_items):
        num = i + 1
        num_str = f"{num:02d}"
        accent = accent_colors[i % len(accent_colors)]
        accent_r, accent_g, accent_b = hex_to_rgb(accent)

        title = truncate_text(item['title'], 80)
        summary = truncate_text(item.get('summary', ''), 200)
        title = escape_html(title)
        summary = escape_html(summary)
        source = escape_html(item.get('source', 'AI HOT'))

        # Check if screenshot exists
        image_path = os.path.join(daily_dir, 'images', f'news_{num:02d}.jpg')
        has_image = os.path.exists(image_path) and os.path.getsize(image_path) > 10000

        # Try AI generation
        ai_html = generate_ai_html(item, num, has_image, p_primary, s_secondary, a_accent, news_duration, ai_config)

        if ai_html is not None:
            final_html = ai_html
            ai_success_count += 1
        else:
            # Fallback to template
            if has_image:
                image_html = f'<img src="../images/news_{num:02d}.jpg" alt="新闻截图">'
            else:
                image_html = '<div class="no-image">暂无截图</div>'
            final_html = FALLBACK_NEWS_TEMPLATE.format(
                num=num,
                num_str=num_str,
                title=title,
                summary=summary,
                source=source,
                image_html=image_html,
                accent=accent,
                accent_r=accent_r, accent_g=accent_g, accent_b=accent_b,
                s=s_secondary,
                a=a_accent,
                a_r=a_r, a_g=a_g, a_b=a_b,
                duration=news_duration
            )
            fallback_count += 1

        news_path = os.path.join(comp_dir, f'news-item-{num}.html')
        with open(news_path, 'w', encoding='utf-8') as f:
            f.write(final_html)
        print(f"  Saved: compositions/news-item-{num}.html")

    # Generate outro
    outro_html = OUTRO_TEMPLATE.format(
        p=p_primary,
        p_r=p_r, p_g=p_g, p_b=p_b,
        s=s_secondary,
        bg=bg_color,
        date_str=date_str,
        week_day=week_day,
        outro_duration=outro_duration
    )
    outro_path = os.path.join(comp_dir, 'daily-outro.html')
    with open(outro_path, 'w', encoding='utf-8') as f:
        f.write(outro_html)
    print(f"  Created: compositions/daily-outro.html")

    # Generate index
    current_start = intro_duration
    scenes_html = ""
    for i in range(len(news_items)):
        num = i + 1
        scenes_html += INDEX_SCENE_ENTRY.format(
            num=num,
            start=current_start,
            duration=news_duration
        )
        current_start += news_duration

    index_html = INDEX_TEMPLATE.format(
        total_duration=total_duration,
        intro_duration=intro_duration,
        scenes=scenes_html,
        current_start=current_start,
        outro_duration=outro_duration,
        date=date
    )
    index_path = os.path.join(daily_dir, 'index.html')
    with open(index_path, 'w', encoding='utf-8') as f:
        f.write(index_html)
    print(f"  Created: index.html")

    # List created files for verification
    created_files = [intro_path]
    for i in range(len(news_items)):
        created_files.append(os.path.join(comp_dir, f'news-item-{i+1}.html'))
    created_files.append(outro_path)
    created_files.append(index_path)

    print(f"\n=== Summary: Created {len(created_files)} files ===")
    print(f"  AI 成功生成: {ai_success_count} 条")
    print(f"  Fallback 模板: {fallback_count} 条")
    for f in created_files:
        if not os.path.exists(f):
            print(f"  ERROR: Missing {f}")
            sys.exit(1)
        else:
            size = os.path.getsize(f)
            print(f"  ✓ {os.path.relpath(f, daily_dir)} - {size} bytes")

    print("\n[OK] All HTML files generated successfully")

if __name__ == "__main__":
    main()
