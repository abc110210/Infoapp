# -*- coding: utf-8 -*-
"""由 QQ图片20260812161716.png 生成 AppIcon 全套尺寸 + Contents.json。
用法: python tools/make_icons.py
输出到 HoshinoPlayer/Resources/Assets.xcassets/AppIcon.appiconset/
"""
import json
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
# 本工具仅本机使用：logo 位于仓库上一级（musicapp/ 根）
SRC = os.path.join(ROOT, "..", "..", "QQ图片20260812161716.png")
DST = os.path.join(ROOT, "HoshinoPlayer", "Resources", "Assets.xcassets", "AppIcon.appiconset")

# (idiom, size, scale, filename)
SPEC = [
    ("iphone",  "20", "1x", "iphone20-1x.png"),
    ("iphone",  "20", "2x", "iphone20-2x.png"),
    ("iphone",  "20", "3x", "iphone20-3x.png"),
    ("iphone",  "29", "1x", "iphone29-1x.png"),
    ("iphone",  "29", "2x", "iphone29-2x.png"),
    ("iphone",  "29", "3x", "iphone29-3x.png"),
    ("iphone",  "40", "1x", "iphone40-1x.png"),
    ("iphone",  "40", "2x", "iphone40-2x.png"),
    ("iphone",  "40", "3x", "iphone40-3x.png"),
    ("iphone",  "60", "2x", "iphone60-2x.png"),
    ("iphone",  "60", "3x", "iphone60-3x.png"),
    ("ipad",    "20", "1x", "ipad20-1x.png"),
    ("ipad",    "20", "2x", "ipad20-2x.png"),
    ("ipad",    "29", "1x", "ipad29-1x.png"),
    ("ipad",    "29", "2x", "ipad29-2x.png"),
    ("ipad",    "40", "1x", "ipad40-1x.png"),
    ("ipad",    "40", "2x", "ipad40-2x.png"),
    ("ipad",    "76", "1x", "ipad76-1x.png"),
    ("ipad",    "76", "2x", "ipad76-2x.png"),
    ("ipad",    "83.5", "2x", "ipad83-2x.png"),
    ("ios-marketing", "1024", "1x", "appstore-1024.png"),
]


def square_crop(img: Image.Image) -> Image.Image:
    w, h = img.size
    side = min(w, h)
    left = (w - side) // 2
    top = int((h - side) * 0.30)  # 玩偶主体偏高，裁剪时保留上部
    top = max(0, min(top, h - side))
    return img.crop((left, top, left + side, top + side))


def main():
    os.makedirs(DST, exist_ok=True)
    img = Image.open(SRC).convert("RGBA")
    square = square_crop(img)

    for idiom, size, scale, fname in SPEC:
        px = int(round(float(size) * float(scale.strip("x"))))
        square.resize((px, px), Image.LANCZOS).save(os.path.join(DST, fname))
        print(f"  [{idiom}] {size}@{scale} = {px:5d}px -> {fname}")

    images = []
    for idiom, size, scale, fname in SPEC:
        images.append({
            "filename": fname,
            "idiom": idiom,
            "scale": scale,
            "size": f"{size}x{size}",
        })
    contents = {
        "images": images,
        "info": {"author": "xcode", "version": 1},
    }
    with open(os.path.join(DST, "Contents.json"), "w", encoding="utf-8") as f:
        json.dump(contents, f, indent=2, ensure_ascii=False)
    print("Done, Contents.json written")


if __name__ == "__main__":
    main()