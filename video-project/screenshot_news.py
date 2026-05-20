#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os, sys, json, time
from pathlib import Path
from playwright.sync_api import sync_playwright, Error

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

def capture_screenshot(url, output_path, width=1280, height=720, max_retries=1):
    for retry in range(max_retries + 1):
        try:
            print(f"  尝试截图 {url} (尝试 {retry + 1}/{max_retries + 1})...")
            with sync_playwright() as p:
                chrome_path = None
                for path in [r"C:\Program Files\Google\Chrome\Application\chrome.exe", r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"]:
                    if os.path.exists(path):
                        chrome_path = path
                        break
                if chrome_path:
                    browser = p.chromium.launch(headless=True, executable_path=chrome_path)
                else:
                    browser = p.chromium.launch(headless=True)
                context = browser.new_context(
                    viewport={'width': width, 'height': height},
                    user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36",
                )
                page = context.new_page()
                page.set_default_timeout(15000)
                response = page.goto(url, wait_until="domcontentloaded", timeout=15000)
                print(f"    状态码: {response.status if response else 'unknown'}")
                time.sleep(1.5)
                page.screenshot(path=output_path, type='jpeg', quality=85, timeout=15000)
                browser.close()
                if os.path.exists(output_path) and os.path.getsize(output_path) > 10000:
                    return True, f"成功，大小 {os.path.getsize(output_path)//1024} KB"
                else:
                    continue
        except Error as e:
            print(f"    截图失败: {str(e)[:100]}")
            if retry < max_retries:
                time.sleep(1.5)
                continue
            return False, str(e)
        except Exception as e:
            print(f"    未知错误: {str(e)[:100]}")
            return False, str(e)
    return False, "所有重试都失败了"

def main():
    if len(sys.argv) < 3:
        print("用法: python screenshot_news.py <daily_dir> <style_json_path>")
        sys.exit(1)
    daily_dir = Path(sys.argv[1])
    style_json_path = sys.argv[2]
    images_dir = daily_dir / "images"
    images_dir.mkdir(exist_ok=True)
    with open(style_json_path, 'r', encoding='utf-8-sig') as f:
        data = json.load(f)
    # 处理data可能是list或dict的情况
    if isinstance(data, list):
        news_items = data
    elif isinstance(data, dict):
        news_items = data.get('news_items', data.get('items', []))
    else:
        news_items = []
    print(f"\n开始为 {len(news_items)} 条新闻截图...")
    success_count = 0
    fail_count = 0
    for i, item in enumerate(news_items, 1):
        url = item.get('url', '')
        if not url:
            print(f"\n[新闻 {i}] 跳过，无URL")
            continue
        output_path = images_dir / f"news_{i:02d}.jpg"
        print(f"\n[新闻 {i}] {item.get('title', 'Unknown')[:50]}...")
        success, msg = capture_screenshot(url, str(output_path))
        if success:
            print(f"  [OK] {msg}")
            success_count += 1
        else:
            print(f"  [FAIL] {msg}")
            fail_count += 1
            if output_path.exists():
                output_path.unlink()
    print(f"\n=== 截图完成 ===\n  成功: {success_count}\n  失败: {fail_count}")

if __name__ == "__main__":
    main()
