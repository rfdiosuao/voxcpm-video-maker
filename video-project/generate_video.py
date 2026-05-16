"""
VoxCPM 2.0 宣传视频生成脚本
使用 moviepy + Pillow 创建高级质感视频
"""

import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from moviepy import VideoClip, AudioFileClip, CompositeVideoClip, concatenate_videoclips

# 配置
WIDTH, HEIGHT = 1920, 1080
FPS = 30
OUTPUT_PATH = r"d:\VoxCPM\VoxCPM-2.0.3\video-project\voxcpm-intro.mp4"
NARRATION_DIR = r"d:\VoxCPM\VoxCPM-2.0.3\video-project\narration"

# 颜色主题
BG_DARK = (10, 5, 20)
PURPLE_PRIMARY = (138, 43, 226)
BLUE_PRIMARY = (65, 105, 225)
PURPLE_LIGHT = (186, 85, 211)
BLUE_LIGHT = (100, 149, 237)
WHITE = (255, 255, 255)
GRAY_LIGHT = (200, 200, 220)
GOLD_ACCENT = (255, 215, 0)

# 音频文件时长
AUDIO_DURATIONS = {
    'intro': 7.04,
    'features': 14.08,
    'quote': 7.20,
    'outro': 6.08
}


def get_font(size, bold=False):
    """获取字体，优先使用系统字体"""
    font_paths = [
        r"C:\Windows\Fonts\msyh.ttc",  # 微软雅黑
        r"C:\Windows\Fonts\simhei.ttf",  # 黑体
        r"C:\Windows\Fonts\arial.ttf",
    ]
    for fp in font_paths:
        if os.path.exists(fp):
            try:
                return ImageFont.truetype(fp, size)
            except:
                continue
    return ImageFont.load_default()


def create_gradient_bg(width, height, color1, color2, angle=45):
    """创建渐变背景"""
    img = Image.new('RGB', (width, height), BG_DARK)
    draw = ImageDraw.Draw(img)
    
    # 创建渐变
    for y in range(height):
        ratio = y / height
        r = int(color1[0] * (1 - ratio) + color2[0] * ratio)
        g = int(color1[1] * (1 - ratio) + color2[1] * ratio)
        b = int(color1[2] * (1 - ratio) + color2[2] * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))
    
    return img


def add_particles(img, count=50, opacity=30):
    """添加粒子效果"""
    draw = ImageDraw.Draw(img, 'RGBA')
    np.random.seed(42)
    for _ in range(count):
        x = np.random.randint(0, img.width)
        y = np.random.randint(0, img.height)
        size = np.random.randint(2, 6)
        alpha = np.random.randint(10, opacity)
        draw.ellipse([x, y, x + size, y + size], fill=(255, 255, 255, alpha))
    return img


def add_glow_circle(draw, cx, cy, radius, color, glow_radius=20):
    """绘制带光晕的圆形"""
    for r in range(radius + glow_radius, radius - 1, -1):
        alpha = int(255 * (1 - (r - radius) / glow_radius)) if r > radius else 255
        c = (*color, alpha)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=c)


def draw_rounded_rect(draw, xy, radius, fill, outline=None, width=1):
    """绘制圆角矩形"""
    x0, y0, x1, y1 = xy
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def create_scene1_intro(t, audio_duration):
    """场景1: VoxCPM 2.0 Logo + 标题"""
    img = create_gradient_bg(WIDTH, HEIGHT, (15, 5, 30), (30, 10, 60))
    img = add_particles(img, count=80, opacity=40)
    draw = ImageDraw.Draw(img, 'RGBA')
    
    # 中心光晕效果
    cx, cy = WIDTH // 2, HEIGHT // 2 - 50
    for r in range(300, 0, -5):
        alpha = int(40 * (1 - r / 300))
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(138, 43, 226, alpha))
    
    # Logo 文字
    font_logo = get_font(120, bold=True)
    font_version = get_font(60)
    font_subtitle = get_font(48)
    
    # "VoxCPM" 主标题
    text_logo = "VoxCPM"
    bbox = draw.textbbox((0, 0), text_logo, font=font_logo)
    tw = bbox[2] - bbox[0]
    x = (WIDTH - tw) // 2
    y = cy - 80
    
    # 文字阴影
    draw.text((x + 3, y + 3), text_logo, fill=(0, 0, 0, 150), font=font_logo)
    # 主文字 - 渐变色效果
    draw.text((x, y), text_logo, fill=WHITE, font=font_logo)
    
    # "2.0" 版本
    text_ver = "2.0"
    bbox = draw.textbbox((0, 0), text_ver, font=font_version)
    tw = bbox[2] - bbox[0]
    x = (WIDTH - tw) // 2
    draw.text((x, y + 100), text_ver, fill=PURPLE_LIGHT, font=font_version)
    
    # 分隔线
    line_y = y + 170
    line_width = 400
    for i in range(line_width):
        alpha = int(255 * (1 - abs(i - line_width // 2) / (line_width // 2)))
        draw.line([(WIDTH // 2 - line_width // 2 + i, line_y), 
                   (WIDTH // 2 - line_width // 2 + i, line_y + 3)], 
                  fill=(138, 43, 226, alpha))
    
    # 副标题
    text_sub = "创意语音合成新时代"
    bbox = draw.textbbox((0, 0), text_sub, font=font_subtitle)
    tw = bbox[2] - bbox[0]
    x = (WIDTH - tw) // 2
    draw.text((x, line_y + 40), text_sub, fill=GRAY_LIGHT, font=font_subtitle)
    
    # 底部装饰文字
    font_small = get_font(28)
    text_bottom = "AI-Powered Voice Synthesis"
    bbox = draw.textbbox((0, 0), text_bottom, font=font_small)
    tw = bbox[2] - bbox[0]
    x = (WIDTH - tw) // 2
    draw.text((x, HEIGHT - 100), text_bottom, fill=(150, 150, 180, 180), font=font_small)
    
    return img


def create_scene2_features(t, audio_duration):
    """场景2: 三大核心能力介绍卡片"""
    img = create_gradient_bg(WIDTH, HEIGHT, (8, 3, 25), (20, 8, 45))
    img = add_particles(img, count=60, opacity=35)
    draw = ImageDraw.Draw(img, 'RGBA')
    
    # 标题
    font_title = get_font(64, bold=True)
    font_card_title = get_font(42, bold=True)
    font_card_desc = get_font(32)
    
    text_title = "三大核心能力"
    bbox = draw.textbbox((0, 0), text_title, font=font_title)
    tw = bbox[2] - bbox[0]
    x = (WIDTH - tw) // 2
    draw.text((x, 60), text_title, fill=WHITE, font=font_title)
    
    # 分隔线
    line_width = 200
    for i in range(line_width):
        alpha = int(255 * (1 - abs(i - line_width // 2) / (line_width // 2)))
        draw.line([(WIDTH // 2 - line_width // 2 + i, 135), 
                   (WIDTH // 2 - line_width // 2 + i, 138)], 
                  fill=(100, 149, 237, alpha))
    
    # 三个卡片
    cards = [
        {
            'icon': '🎙️',
            'title': '多模态语音生成',
            'desc': '文本、音频、视频多模态输入\n支持中英双语及多种音色',
            'color': (138, 43, 226)
        },
        {
            'icon': '⚡',
            'title': '实时流式输出',
            'desc': '首包延迟低至200ms\n支持WebSocket实时交互',
            'color': (65, 105, 225)
        },
        {
            'icon': '🎨',
            'title': '情感与风格控制',
            'desc': '精准控制语音情感表达\n支持多种播报风格切换',
            'color': (186, 85, 211)
        }
    ]
    
    card_width = 520
    card_height = 380
    card_spacing = 40
    total_width = card_width * 3 + card_spacing * 2
    start_x = (WIDTH - total_width) // 2
    card_y = 170
    
    for i, card in enumerate(cards):
        x = start_x + i * (card_width + card_spacing)
        
        # 卡片背景 - 半透明
        card_bg = (20, 15, 40, 180)
        draw_rounded_rect(draw, (x, card_y, x + card_width, card_y + card_height), 
                         radius=20, fill=card_bg, outline=(*card['color'], 100), width=2)
        
        # 图标区域圆形背景
        icon_cx = x + card_width // 2
        icon_cy = card_y + 80
        for r in range(50, 0, -2):
            alpha = int(150 * (1 - r / 50))
            draw.ellipse([icon_cx - r, icon_cy - r, icon_cx + r, icon_cy + r], 
                        fill=(*card['color'], alpha))
        
        # 图标文字
        font_icon = get_font(48)
        bbox = draw.textbbox((0, 0), card['icon'], font=font_icon)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        draw.text((icon_cx - tw // 2, icon_cy - th // 2), card['icon'], fill=WHITE, font=font_icon)
        
        # 卡片标题
        bbox = draw.textbbox((0, 0), card['title'], font=font_card_title)
        tw = bbox[2] - bbox[0]
        tx = x + (card_width - tw) // 2
        draw.text((tx, card_y + 150), card['title'], fill=WHITE, font=font_card_title)
        
        # 卡片描述
        desc_lines = card['desc'].split('\n')
        for j, line in enumerate(desc_lines):
            bbox = draw.textbbox((0, 0), line, font=font_card_desc)
            tw = bbox[2] - bbox[0]
            tx = x + (card_width - tw) // 2
            draw.text((tx, card_y + 220 + j * 45), line, fill=GRAY_LIGHT, font=font_card_desc)
    
    return img


def create_scene3_quote(t, audio_duration):
    """场景3: 金句展示页"""
    img = create_gradient_bg(WIDTH, HEIGHT, (12, 5, 28), (25, 10, 50))
    img = add_particles(img, count=100, opacity=50)
    draw = ImageDraw.Draw(img, 'RGBA')
    
    # 中心大光晕
    cx, cy = WIDTH // 2, HEIGHT // 2
    for r in range(400, 0, -5):
        alpha = int(60 * (1 - r / 400))
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(100, 149, 237, alpha))
    
    # 引号装饰
    font_quote_mark = get_font(200)
    draw.text((200, 100), "\u201C", fill=(138, 43, 226, 60), font=font_quote_mark)
    draw.text((WIDTH - 300, HEIGHT - 280), "\u201D", fill=(138, 43, 226, 60), font=font_quote_mark)
    
    # 金句文字
    font_quote = get_font(56, bold=True)
    font_author = get_font(36)
    
    quote_text = "让每一个声音\n都成为创意的延伸"
    
    # 计算文字位置居中
    lines = quote_text.split('\n')
    line_height = 80
    total_height = line_height * len(lines)
    start_y = cy - total_height // 2
    
    for i, line in enumerate(lines):
        bbox = draw.textbbox((0, 0), line, font=font_quote)
        tw = bbox[2] - bbox[0]
        x = (WIDTH - tw) // 2
        y = start_y + i * line_height
        
        # 文字阴影
        draw.text((x + 2, y + 2), line, fill=(0, 0, 0, 100), font=font_quote)
        # 主文字
        draw.text((x, y), line, fill=WHITE, font=font_quote)
    
    # 装饰线
    line_width = 300
    line_y = start_y + total_height + 40
    for i in range(line_width):
        alpha = int(255 * (1 - abs(i - line_width // 2) / (line_width // 2)))
        draw.line([(WIDTH // 2 - line_width // 2 + i, line_y), 
                   (WIDTH // 2 - line_width // 2 + i, line_y + 2)], 
                  fill=(186, 85, 211, alpha))
    
    # 作者/来源
    text_author = "— VoxCPM 2.0"
    bbox = draw.textbbox((0, 0), text_author, font=font_author)
    tw = bbox[2] - bbox[0]
    x = (WIDTH - tw) // 2
    draw.text((x, line_y + 30), text_author, fill=PURPLE_LIGHT, font=font_author)
    
    return img


def create_scene4_outro(t, audio_duration):
    """场景4: 结尾CTA"""
    img = create_gradient_bg(WIDTH, HEIGHT, (10, 5, 25), (35, 15, 60))
    img = add_particles(img, count=70, opacity=45)
    draw = ImageDraw.Draw(img, 'RGBA')
    
    cx, cy = WIDTH // 2, HEIGHT // 2 - 50
    
    # 背景光晕
    for r in range(350, 0, -5):
        alpha = int(50 * (1 - r / 350))
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(138, 43, 226, alpha))
    
    # 主标题
    font_main = get_font(72, bold=True)
    font_sub = get_font(48)
    font_cta = get_font(40, bold=True)
    font_url = get_font(32)
    
    text_main = "开启你的语音创意之旅"
    bbox = draw.textbbox((0, 0), text_main, font=font_main)
    tw = bbox[2] - bbox[0]
    x = (WIDTH - tw) // 2
    draw.text((x, cy - 120), text_main, fill=WHITE, font=font_main)
    
    # 分隔线
    line_width = 250
    line_y = cy - 30
    for i in range(line_width):
        alpha = int(255 * (1 - abs(i - line_width // 2) / (line_width // 2)))
        draw.line([(WIDTH // 2 - line_width // 2 + i, line_y), 
                   (WIDTH // 2 - line_width // 2 + i, line_y + 3)], 
                  fill=(100, 149, 237, alpha))
    
    # CTA按钮样式
    btn_text = "立即体验 VoxCPM 2.0"
    btn_width = 500
    btn_height = 80
    btn_x = (WIDTH - btn_width) // 2
    btn_y = line_y + 50
    
    # 按钮背景
    draw_rounded_rect(draw, (btn_x, btn_y, btn_x + btn_width, btn_y + btn_height), 
                     radius=40, fill=(138, 43, 226, 200), outline=(186, 85, 211, 255), width=3)
    
    # 按钮文字
    bbox = draw.textbbox((0, 0), btn_text, font=font_cta)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text((btn_x + (btn_width - tw) // 2, btn_y + (btn_height - th) // 2), 
              btn_text, fill=WHITE, font=font_cta)
    
    # 底部信息
    text_url = "github.com/open-mmlab/VoxCPM-2"
    bbox = draw.textbbox((0, 0), text_url, font=font_url)
    tw = bbox[2] - bbox[0]
    x = (WIDTH - tw) // 2
    draw.text((x, HEIGHT - 120), text_url, fill=GRAY_LIGHT, font=font_url)
    
    # VoxCPM Logo
    font_logo = get_font(36)
    text_logo = "VoxCPM 2.0"
    bbox = draw.textbbox((0, 0), text_logo, font=font_logo)
    tw = bbox[2] - bbox[0]
    x = (WIDTH - tw) // 2
    draw.text((x, HEIGHT - 70), text_logo, fill=PURPLE_LIGHT, font=font_logo)
    
    return img


def make_frame(t, scene_func, audio_duration):
    """将PIL图像转换为numpy数组"""
    img = scene_func(t, audio_duration)
    return np.array(img)


def create_video():
    """主函数：创建完整视频"""
    print("开始生成视频...")
    
    # 创建各个场景的视频片段
    scenes = [
        ('intro', create_scene1_intro, AUDIO_DURATIONS['intro']),
        ('features', create_scene2_features, AUDIO_DURATIONS['features']),
        ('quote', create_scene3_quote, AUDIO_DURATIONS['quote']),
        ('outro', create_scene4_outro, AUDIO_DURATIONS['outro']),
    ]
    
    video_clips = []
    audio_clips = []
    
    for name, scene_func, duration in scenes:
        print(f"生成场景: {name} ({duration:.2f}s)")
        
        # 创建视频片段 - 使用默认参数避免lambda闭包问题
        def make_frame_fixed(t, sf=scene_func, dur=duration):
            img = sf(t, dur)
            return np.array(img)
        
        video = VideoClip(make_frame_fixed, duration=duration).with_fps(FPS)
        
        # 加载音频
        audio_path = os.path.join(NARRATION_DIR, f"{name}.wav")
        audio = AudioFileClip(audio_path)
        
        # 确保音频和视频时长匹配
        if audio.duration > duration:
            audio = audio.with_duration(duration)
        
        video = video.with_audio(audio)
        video_clips.append(video)
        audio_clips.append(audio)
    
    # 合并所有片段
    print("合并视频片段...")
    final_video = concatenate_videoclips(video_clips, method="compose")
    
    # 输出视频
    print(f"输出视频到: {OUTPUT_PATH}")
    final_video.write_videofile(
        OUTPUT_PATH,
        fps=FPS,
        codec='libx264',
        audio_codec='aac',
        preset='medium',
        bitrate='8000k'
    )
    
    print("视频生成完成!")


if __name__ == "__main__":
    create_video()
