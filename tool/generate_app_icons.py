"""Generate padded PropKart launcher / favicon masters from assets/logo.png."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "logo.png"
OUT = ROOT / "assets" / "branding"
WEB = ROOT / "web"

BG = (0, 0, 0)
# NB monogram sits above the PropertyTech wordmark.
MONOGRAM_BOX = (0, 24, 900, 552)


def content_bbox(im: Image.Image, thresh: int = 36) -> tuple[int, int, int, int]:
    rgb = im.convert("RGB")
    px = rgb.load()
    w, h = rgb.size
    minx, miny, maxx, maxy = w, h, 0, 0
    found = False
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if r + g + b > thresh:
                found = True
                if x < minx:
                    minx = x
                if y < miny:
                    miny = y
                if x > maxx:
                    maxx = x
                if y > maxy:
                    maxy = y
    if not found:
        return (0, 0, w, h)
    return (minx, miny, maxx + 1, maxy + 1)


def to_transparent(im: Image.Image, thresh: int = 28) -> Image.Image:
    rgba = im.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    for y in range(h):
        for x in range(w):
            r, g, b, _ = px[x, y]
            if r + g + b < thresh:
                px[x, y] = (0, 0, 0, 0)
    return rgba


def place(src: Image.Image, size: int, pad_ratio: float, bg: tuple[int, int, int] = BG) -> Image.Image:
    """Center trimmed artwork on a square canvas. pad_ratio is inset on each side."""
    work = src.convert("RGB")
    box = content_bbox(work)
    trimmed = work.crop(box)
    inner = max(1, int(round(size * (1 - 2 * pad_ratio))))
    tw, th = trimmed.size
    scale = min(inner / tw, inner / th)
    nw = max(1, int(round(tw * scale)))
    nh = max(1, int(round(th * scale)))
    hi = trimmed.resize((nw * 2, nh * 2), Image.Resampling.LANCZOS)
    resized = hi.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGB", (size, size), bg)
    canvas.paste(resized, ((size - nw) // 2, (size - nh) // 2))
    return canvas


def save_png(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, "PNG", optimize=True)


def main() -> None:
    logo = Image.open(SRC)
    monogram = logo.crop(MONOGRAM_BOX)

    OUT.mkdir(parents=True, exist_ok=True)

    mark = to_transparent(monogram)
    mark = mark.crop(content_bbox(mark.convert("RGB")))
    # Master transparent mark for in-app tiles (no baked margin).
    mark.resize((1024, int(1024 * mark.height / mark.width)), Image.Resampling.LANCZOS).save(
        OUT / "brand_mark.png", "PNG", optimize=True
    )

    # iOS / web / Windows / macOS — ~20% safe margin so OS masks never clip the serifs.
    app_icon = place(monogram, 1024, 0.20)
    save_png(app_icon, OUT / "app_icon.png")

    # Android adaptive foreground — extra inset for the 66% safe zone.
    save_png(place(monogram, 1024, 0.26), OUT / "app_icon_foreground.png")

    # Maskable / PWA — content stays inside the inner 60%.
    maskable = place(monogram, 1024, 0.22)
    save_png(maskable, OUT / "app_icon_maskable.png")

    # Full lockup with margin, if a square poster asset is needed later.
    save_png(place(logo, 1024, 0.18), OUT / "app_icon_lockup.png")

    # Favicons — monogram only; wordmark is illegible at 16–32px.
    fav_src = place(monogram, 256, 0.22)
    save_png(fav_src.resize((32, 32), Image.Resampling.LANCZOS), WEB / "favicon.png")
    save_png(fav_src.resize((16, 16), Image.Resampling.LANCZOS), WEB / "favicon-16.png")
    save_png(fav_src.resize((32, 32), Image.Resampling.LANCZOS), WEB / "favicon-32.png")
    fav_src.resize((256, 256), Image.Resampling.LANCZOS).save(
        WEB / "favicon.ico",
        format="ICO",
        sizes=[(16, 16), (32, 32), (48, 48)],
    )

    print("Wrote branding masters to", OUT)
    print("Wrote favicons to", WEB)


if __name__ == "__main__":
    main()
