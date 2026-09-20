#!/usr/bin/env python3
"""Render the hunter terminal splash as docs/img/terminal.png (README screenshot)."""
from PIL import Image, ImageDraw, ImageFont
import os

W, H = 1160, 820
FONT_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
LOGO = [
    "  ██   ██ ██   ██ ███    ██ ████████ ██████   ██████  ██    ██ ██████  ██    ██",
    "  ██   ██ ██   ██ ████   ██    ██    ██   ██ ██   ██ ██    ██ ██   ██ ██    ██",
    "  ███████ ██   ██ ██ ██  ██    ██    ██   ██ ██   ██ ██    ██ ██   ██ ██   ██ ██    ██",
    "  ██   ██ ██   ██ ██  ██ ██    ██    ██   ██ ██   ██ ██    ██ ██   ██ ██    ██",
    "  ██   ██  █████  ██   ████    ██    ██████   ██████   ██████  ██████   ██████",
]

TRANS = [
    "  hunter » pentest 192.168.1.10, goal is root",
    "",
    "  [hunter]  scope ok — 192.168.1.10 is authorised (home lab)",
    "  [hunter]  step 1 · surface — map hosts, find open services",
    "",
    "    $ nmap -sV -sC -T4 192.168.1.10",
    "      22/tcp  open  ssh     OpenSSH 8.9p1",
    "      80/tcp  open  http    nginx 1.22.0",
    "",
    "  [hunter]  step 2 · fingerprint — nginx 1.22, default page",
    "  [hunter]  next: target the web app via the research skill",
]

def font(sz): return ImageFont.truetype(FONT_PATH, sz)

img = Image.new("RGB", (W, H), (11, 15, 20))
d = ImageDraw.Draw(img)

# terminal chrome
cx, cy = 40, 40
d.rounded_rectangle((cx, cy, W - cx, H - cy), 22, fill=(22, 27, 34), outline=(45, 51, 59), width=2)
d.ellipse((cx + 34, cy + 28, cx + 46, cy + 40), fill=(255, 123, 114))
d.ellipse((cx + 58, cy + 28, cx + 70, cy + 40), fill=(250, 200, 100))
d.ellipse((cx + 82, cy + 28, cx + 94, cy + 40), fill=(126, 231, 135))
d.text((cx + 110, cy + 26), "kali@hunt — hunter", font=font(20), fill=(139, 148, 158))

# body
y = cy + 78
d.line((cx + 26, y, W - cx - 26, y), fill=(45, 51, 59), width=1)
y += 28
d.text((cx + 40, y), LOGO[0], font=font(24), fill=(247, 201, 72)); y += 34
d.text((cx + 40, y), LOGO[1], font=font(24), fill=(247, 201, 72)); y += 34
d.text((cx + 40, y), LOGO[2], font=font(24), fill=(247, 201, 72)); y += 34
d.text((cx + 40, y), LOGO[3], font=font(24), fill=(247, 201, 72)); y += 34
d.text((cx + 40, y), LOGO[4], font=font(24), fill=(247, 201, 72)); y += 40
d.text((cx + 40, y), "  AI pentest partner — recon to report · free OpenCode Zen brain",
       font=font(20), fill=(139, 148, 158)); y += 40

for line in TRANS:
    if line in ("",):
        y += 10; continue
    col = (110, 118, 129)
    if "hunter »" in line: col = (247, 201, 72)
    elif "[hunter]" in line: col = (226, 227, 229)
    elif line.startswith("      "): col = (225, 208, 153)
    elif "--" in line and "[hunter]" not in line: col = (255, 123, 114)
    else: col = (178, 186, 196)
    d.text((cx + 40, y), line, font=font(20), fill=col); y += 30

d.rectangle((cx + 40 + 200, y - 8, cx + 40 + 216, y + 2), fill=(247, 201, 72))

out = "img/terminal.png"
img.save(out)
print("wrote", out)