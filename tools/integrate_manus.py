# 마누스 납품 풀세트(고해상 투명 PNG)를 게임용으로 다운스케일·오토크롭해 repo assets/에 통합한다.
import os, glob, shutil
from PIL import Image

SRC = "/tmp/manus_assets/assets"
DST = "/Users/taewookkim/dev/guju-jaengpae/assets"

def autocrop(im):
    im = im.convert("RGBA")
    bbox = im.split()[3].getbbox()  # 알파 기준 여백 제거
    return im.crop(bbox) if bbox else im

def scale_h(im, h):
    if im.height <= h:
        return im
    return im.resize((max(1, round(im.width * h / im.height)), h), Image.LANCZOS)

def scale_fit(im, maxdim):
    s = min(maxdim / im.width, maxdim / im.height, 1.0)
    return im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.LANCZOS)

def save(im, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path)

count = 0
for src in glob.glob(SRC + "/sprites/**/*.png", recursive=True):
    rel = os.path.relpath(src, SRC)            # sprites/units/shu/infantry.png
    name = os.path.basename(src)
    dst = os.path.join(DST, rel)
    im = Image.open(src)
    if "/bg/" in src.replace("\\", "/"):
        im = im.convert("RGB").resize((1920, 1080), Image.LANCZOS)
    elif "/iso/" in src.replace("\\", "/"):
        im = autocrop(im).resize((256, 128), Image.LANCZOS)
    elif "/buildings/" in src.replace("\\", "/"):
        im = scale_h(autocrop(im), 320)
    elif "/ui/" in src.replace("\\", "/"):
        if name.startswith("card_frame"):
            im = scale_h(autocrop(im), 360)
        elif name.startswith("panel"):
            im = scale_fit(autocrop(im), 160)
        else:
            im = scale_fit(autocrop(im), 112)
    elif "/units/" in src.replace("\\", "/"):
        im = autocrop(im)
        if name.startswith("boss_"):
            im = scale_h(im, 448)
        elif name.startswith("general_"):
            im = scale_h(im, 256)
        else:
            im = scale_h(im, 192)
    else:
        continue
    save(im, dst)
    count += 1

# 현재 게임 코드가 쓰는 demon 진영 = 낙양마궁(보스 동탁 소속)으로 채워 보스·잡병 비주얼 통일
luo = os.path.join(DST, "sprites/units/luoyang")
dem = os.path.join(DST, "sprites/units/demon")
os.makedirs(dem, exist_ok=True)
for f in ["infantry.png", "archer.png", "cavalry.png", "boss_dongzhuo.png"]:
    s = os.path.join(luo, f)
    if os.path.exists(s):
        shutil.copy(s, os.path.join(dem, f))

# 폰트
for ttf in glob.glob(SRC + "/fonts/*.ttf") + glob.glob(SRC + "/fonts/*.otf"):
    save_dir = os.path.join(DST, "fonts"); os.makedirs(save_dir, exist_ok=True)
    shutil.copy(ttf, os.path.join(save_dir, os.path.basename(ttf)))

# 보고
import subprocess
sz = subprocess.run(["du", "-sh", os.path.join(DST, "sprites")], capture_output=True, text=True).stdout.strip()
print(f"처리 PNG: {count}, demon 매핑 완료, sprites 총량: {sz}")
print("factions:", sorted(os.listdir(os.path.join(DST, "sprites/units"))))
print("bg themes:", sorted(os.listdir(os.path.join(DST, "sprites/bg"))))
