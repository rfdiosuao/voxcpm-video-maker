#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
新闻图片截图工具 - 使用 Playwright 给每条新闻截图
"""

import os
import sys
import json
import time
from pathlib import Path
from playwright.sync_api import sync_playwright, Error

def capture_screenshot(url, output_path, width=1280, height=720, max_retries=2):
    """
    截取网页截图，带重试机制
    返回: (success: bool, error_message: str)
    """
    for retry in range(max_retries + 1):
        try:
            print(f"  尝试截图 {url} (尝试 {retry + 1}/{max_retries + 1})...")

            with sync_playwright() as p:
                browser = p.chromium.launch(headless=True)
                context = browser.new_context(
                    viewport={'width': width, 'height': height},
                    user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
                )
                page = context.new_page()

                # 设置超时
                page.set_default_timeout(30000)

                # 导航
                response = page.goto(url, wait_until="networkidle")
                print(f"    状态码: {response.status}")

                # 等待一下让内容渲染
                time.sleep(2)

                # 截图
                page.screenshot(path=output_path, type='jpeg', quality=85, clip=None)

                browser.close()

                # 检查文件
                if os.path.exists(output_path) and os.path.getsize(output_path) > 10000:
                    return True, f"成功，大小 {os.path.getsize(output_path)//1024} KB"
                else:
                    print(f"    截图文件过小: {os.path.getsize(output_path)} bytes")

            browser.close()
        except Error as e:
            print(f"    Playwright 错误: {e}")
            if retry < max_retries:
                print(f"    等待 3 秒后重试...")
                time.sleep(3)
            continue
        except Exception as e:
            print(f"    意外错误: {e}")
            if retry < max_retries:
                print(f"    等待 3 秒后重试...")
                time.sleep(3)
            continue

    return False, f"{max_retries + 1} 次尝试都失败了"

def process_news_images(daily_dir, news_items_json, images_dir="images", max_retries=2):
    """
    处理多条新闻的截图
    """
    daily_path = Path(daily_dir)
    images_path = daily_path / images_dir
    images_path.mkdir(exist_ok=True, parents=True)

    with open(news_items_json, 'r', encoding='utf-8') as f:
        news_items = json.load(f)

    results = []

    for i, item in enumerate(news_items):
        num = i + 1
        url = item.get('url', '').strip()
        title = item.get('title', f'news_{num}')

        if not url:
            print(f"[新闻 {num}] 跳过: 无URL")
            results.append({
                'num': num,
                'title': title,
                'url': url,
                'success': False,
                'reason': 'no_url',
                'path': None
            })
            continue

        output_path = images_path / f"news_{num:02d}.jpg"

        print(f"\n[新闻 {num}] {title}")
        print(f"  URL: {url}")
        print(f"  输出: {output_path}")

        success, msg = capture_screenshot(url, str(output_path), max_retries=max_retries)

        results.append({
            'num': num,
            'title': title,
            'url': url,
            'success': success,
            'reason': msg,
            'path': str(output_path) if success else None
        })

        if success:
            print(f"  ✅ {msg}")
        else:
            print(f"  ❌ {msg}")

    # 保存结果
    result_file = daily_path / 'screenshot_results.json'
    with open(result_file, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    success_count = sum(1 for r in results if r['success'])
    total_count = len(results)
    print(f"\n{'='*50}")
    print(f"截图完成: {success_count}/{total_count} 成功")
    print(f"结果保存: {result_file}")
    print(f"{'='*50}")

    return results

def main():
    if len(sys.argv) < 3:
        print("Usage: python screenshot_news.py <daily_dir> <aihot_items_json>")
        print("Example: python screenshot_news.py ./daily/20260516 ./daily/20260516/aihot_items.json")
        sys.exit(1)

    daily_dir = sys.argv[1]
    aihot_items = sys.argv[2]

    results = process_news_images(daily_dir, aihot_items)
    success_count = sum(1 for r in results if r['success'])
    sys.exit(0 if success_count > 0 else 1)

if __name__ == "__main__":
    main()
