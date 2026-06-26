"""Generate Tunofy app icon — bold 'Tunofy' wordmark, both parts orange."""

from PIL import Image, ImageDraw, ImageFont
import os

SIZE = 1024
ORANGE = (255, 107, 0, 255)
DARK = (26, 26, 46, 255)
OUT_DIR = r"C:\Users\Administrator\tunofy\assets\icon"
FONT_PATH = r"C:\Windows\Fonts\segoeuib.ttf"


def get_text_size(draw, text, font):
    bbox = draw.textbbox((0, 0), text, font=font)
    return bbox[2] - bbox[0], bbox[3] - bbox[1]


def find_font_size(target_width_ratio=0.82):
    font_size = 100
    font = ImageFont.truetype(FONT_PATH, font_size)
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    w, h = get_text_size(draw, "Tunofy", font)
    target_w = SIZE * target_width_ratio
    scale = target_w / w
    font_size = int(font_size * scale)
    font = ImageFont.truetype(FONT_PATH, font_size)
    w, h = get_text_size(draw, "Tunofy", font)
    print(f"  Font size: {font_size}, text: {w}x{h} ({w/SIZE*100:.0f}% x {h/SIZE*100:.0f}%)")
    return font, w, h


def render_icon(bg_color):
    font, tw, th = find_font_size(0.82)
    img = Image.new("RGBA", (SIZE, SIZE), bg_color)
    draw = ImageDraw.Draw(img)
    x = (SIZE - tw) // 2
    y = (SIZE - th) // 2 - int(th * 0.12)
    draw.text((x, y), "Tunofy", font=font, fill=ORANGE)
    return img


if __name__ == "__main__":
    print("=== app_icon.png ===")
    render_icon(DARK).save(os.path.join(OUT_DIR, "app_icon.png"))
    print("=== app_icon_foreground.png ===")
    render_icon((0, 0, 0, 0)).save(os.path.join(OUT_DIR, "app_icon_foreground.png"))
    print("Done.")
