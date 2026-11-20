import os
import sys
from PIL import Image, ImageDraw

ICONS = [
    'badge_success.png',
    'book_welcome.png',
    'brain_mind.png',
    'clipboard_quiz.png',
    'heart_support.png',
    'quiz_audio_headset.png',
    'rocket_fast.png',
    'scanner_camera.png',
    'sprout_discovery.png',
    'trophy_achievement.png',
]

SRC_DIR = r'c:\Users\Administrator\Desktop\french assistant app\assets\images\ui'
DST_DIR = r'c:\Users\Administrator\Desktop\french assistant app\app\assets\images\ui'

def process_image(filename):
    src_path = os.path.join(SRC_DIR, filename)
    dst_path = os.path.join(DST_DIR, filename)
    
    if not os.path.exists(src_path):
        print(f"ERROR: {src_path} not found!")
        return False
        
    print(f"Processing {filename}...")
    img = Image.open(src_path).convert('RGB')
    
    # Scale to 1024x1024 first for flood-fill speed & precision
    img_mid = img.resize((1024, 1024), Image.Resampling.LANCZOS)
    rgba_mid = img_mid.convert('RGBA')
    
    w, h = 1024, 1024
    step = 16
    points = []
    for x in range(0, w, step):
        points.append((x, 0))
        points.append((x, h - 1))
    for y in range(0, h, step):
        points.append((0, y))
        points.append((w - 1, y))

    for pt in points:
        cur = rgba_mid.getpixel(pt)
        if cur[3] != 0 and cur[0] >= 210 and cur[1] >= 210 and cur[2] >= 210:
            ImageDraw.floodfill(rgba_mid, pt, (255, 255, 255, 0), thresh=45)

    # Downsample to target 512x512 with LANCZOS for smooth anti-aliased edges
    final_img = rgba_mid.resize((512, 512), Image.Resampling.LANCZOS)
    os.makedirs(DST_DIR, exist_ok=True)
    final_img.save(dst_path, 'PNG')
    print(f"Saved: {dst_path} (512x512 RGBA)")
    return True

if __name__ == '__main__':
    success_count = 0
    for icon in ICONS:
        if process_image(icon):
            success_count += 1
    print(f"\nDone! Successfully processed {success_count}/{len(ICONS)} icons.")
