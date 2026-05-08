#!/usr/bin/env python3
"""Enemy sprite processor — background removal, crop, resize, and .tres texture linking."""

import argparse
import re
import sys
from collections import deque
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Error: Pillow is required. Install with: pip3 install Pillow")
    sys.exit(1)

PROJECT_ROOT = Path(__file__).resolve().parent.parent
ENEMIES_SPRITE_DIR = PROJECT_ROOT / "assets" / "sprites" / "enemies"
ENEMIES_RES_DIR = PROJECT_ROOT / "resources" / "enemies"


# ---------------------------------------------------------------------------
# Background removal strategies
# ---------------------------------------------------------------------------

def _flood_fill_bg(img, is_bg_fn):
    """Flood-fill from image edges to mark connected background pixels."""
    w, h = img.size
    pixels = img.load()
    visited = [[False] * w for _ in range(h)]
    bg_mask = [[False] * w for _ in range(h)]
    queue = deque()

    for x in range(w):
        for y in [0, h - 1]:
            if not visited[y][x]:
                r, g, b, a = pixels[x, y]
                if is_bg_fn(r, g, b):
                    queue.append((x, y))
                    visited[y][x] = True
                    bg_mask[y][x] = True
    for y in range(h):
        for x in [0, w - 1]:
            if not visited[y][x]:
                r, g, b, a = pixels[x, y]
                if is_bg_fn(r, g, b):
                    queue.append((x, y))
                    visited[y][x] = True
                    bg_mask[y][x] = True

    while queue:
        cx, cy = queue.popleft()
        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nx, ny = cx + dx, cy + dy
            if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx]:
                visited[ny][nx] = True
                r, g, b, a = pixels[nx, ny]
                if is_bg_fn(r, g, b):
                    bg_mask[ny][nx] = True
                    queue.append((nx, ny))

    count = 0
    for y in range(h):
        for x in range(w):
            if bg_mask[y][x]:
                pixels[x, y] = (0, 0, 0, 0)
                count += 1
    return count


def is_bg_green(r, g, b):
    """For green/colored sprites — standard gray checkerboard detection."""
    avg = (r + g + b) / 3.0
    if avg < 40 or avg > 200:
        return False
    return max(r, g, b) - min(r, g, b) < 15


def is_bg_metallic(r, g, b):
    """For gray/metallic sprites — tighter range targeting checkerboard tiles."""
    avg = (r + g + b) / 3.0
    spread = max(r, g, b) - min(r, g, b)
    if 25 < avg < 55 and spread < 12:
        return True
    if 90 < avg < 130 and spread < 18:
        return True
    return False


BG_STRATEGIES = {
    "green": is_bg_green,
    "metallic": is_bg_metallic,
}


# ---------------------------------------------------------------------------
# Body extraction (remove thin beams/effects)
# ---------------------------------------------------------------------------

def _crop_body_only(img, density_threshold=0.15):
    """Keep only the dense body region, removing thin beams/effects."""
    w, h = img.size
    pixels = img.load()

    col_counts = [0] * w
    row_counts = [0] * h
    for y in range(h):
        for x in range(w):
            if pixels[x, y][3] > 0:
                col_counts[x] += 1
                row_counts[y] += 1

    max_col = max(col_counts) if max(col_counts) > 0 else 1
    max_row = max(row_counts) if max(row_counts) > 0 else 1
    col_thresh = max_col * density_threshold
    row_thresh = max_row * density_threshold

    body_min_x, body_max_x = w, 0
    body_min_y, body_max_y = h, 0
    for x in range(w):
        if col_counts[x] > col_thresh:
            body_min_x = min(body_min_x, x)
            body_max_x = max(body_max_x, x)
    for y in range(h):
        if row_counts[y] > row_thresh:
            body_min_y = min(body_min_y, y)
            body_max_y = max(body_max_y, y)

    if body_min_x >= body_max_x or body_min_y >= body_max_y:
        return img

    for y in range(h):
        for x in range(w):
            if pixels[x, y][3] > 0:
                if x < body_min_x or x > body_max_x or y < body_min_y or y > body_max_y:
                    pixels[x, y] = (0, 0, 0, 0)
    return img


def _extract_body_by_outline(img):
    """For metallic sprites — find sprite component via colored/dark/bright pixels,
    then flood-fill exterior to isolate the body."""
    w, h = img.size
    pixels = img.load()

    mask = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            spread = max(r, g, b) - min(r, g, b)
            avg = (r + g + b) / 3.0
            if b > r + 20 and b > 80:
                mask[y][x] = True
            elif avg < 15:
                mask[y][x] = True
            elif avg > 210:
                mask[y][x] = True
            elif spread > 30:
                mask[y][x] = True
            elif avg > 150 and spread < 15:
                mask[y][x] = True

    visited_cc = [[False] * w for _ in range(h)]
    best = []
    for sy in range(h):
        for sx in range(w):
            if mask[sy][sx] and not visited_cc[sy][sx]:
                comp = []
                q = deque([(sx, sy)])
                visited_cc[sy][sx] = True
                while q:
                    cx, cy = q.popleft()
                    comp.append((cx, cy))
                    for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < h and not visited_cc[ny][nx] and mask[ny][nx]:
                            visited_cc[ny][nx] = True
                            q.append((nx, ny))
                if len(comp) > len(best):
                    best = comp

    if not best:
        return img

    xs = [p[0] for p in best]
    ys = [p[1] for p in best]
    pad = 5
    bx1, by1 = max(0, min(xs) - pad), max(0, min(ys) - pad)
    bx2, by2 = min(w - 1, max(xs) + pad), min(h - 1, max(ys) + pad)
    bw, bh = bx2 - bx1 + 1, by2 - by1 + 1
    comp_set = set(best)

    exterior = [[False] * bw for _ in range(bh)]
    ext_visited = [[False] * bw for _ in range(bh)]
    eq = deque()

    for lx in range(bw):
        for ly in [0, bh - 1]:
            gx, gy = lx + bx1, ly + by1
            if (gx, gy) not in comp_set and not ext_visited[ly][lx]:
                ext_visited[ly][lx] = True
                exterior[ly][lx] = True
                eq.append((lx, ly))
    for ly in range(bh):
        for lx in [0, bw - 1]:
            gx, gy = lx + bx1, ly + by1
            if (gx, gy) not in comp_set and not ext_visited[ly][lx]:
                ext_visited[ly][lx] = True
                exterior[ly][lx] = True
                eq.append((lx, ly))

    while eq:
        cx, cy = eq.popleft()
        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nx, ny = cx + dx, cy + dy
            if 0 <= nx < bw and 0 <= ny < bh and not ext_visited[ny][nx]:
                gx, gy = nx + bx1, ny + by1
                if (gx, gy) not in comp_set:
                    ext_visited[ny][nx] = True
                    exterior[ny][nx] = True
                    eq.append((nx, ny))

    for y in range(h):
        for x in range(w):
            if x < bx1 or x > bx2 or y < by1 or y > by2:
                pixels[x, y] = (0, 0, 0, 0)
            else:
                lx, ly = x - bx1, y - by1
                if exterior[ly][lx]:
                    pixels[x, y] = (0, 0, 0, 0)
    return img


# ---------------------------------------------------------------------------
# .tres texture linking
# ---------------------------------------------------------------------------

def _link_texture(tres_path: Path, texture_res_path: str, uid: str | None = None):
    """Add texture ext_resource and field to an EnemyData .tres file."""
    text = tres_path.read_text(encoding="utf-8")

    if "texture = ExtResource" in text:
        print(f"  [skip] {tres_path.name} already has texture linked")
        return False

    m = re.search(r"load_steps=(\d+)", text)
    if not m:
        print(f"  [error] Cannot parse load_steps in {tres_path.name}")
        return False

    old_steps = int(m.group(1))
    new_steps = old_steps + 1
    text = text.replace(f"load_steps={old_steps}", f"load_steps={new_steps}")

    new_id = str(new_steps)
    if uid:
        ext_line = f'[ext_resource type="Texture2D" uid="{uid}" path="{texture_res_path}" id="{new_id}"]'
    else:
        ext_line = f'[ext_resource type="Texture2D" path="{texture_res_path}" id="{new_id}"]'

    text = text.replace(
        "\n[resource]",
        f"\n{ext_line}\n\n[resource]",
    )

    text = text.replace(
        "\nspawn_count",
        f'\ntexture = ExtResource("{new_id}")\nspawn_count',
    )
    if "\nspawn_on_death" in text and "texture" not in text.split("spawn_on_death")[0].split("[resource]")[-1]:
        text = text.replace(
            "\nspawn_on_death",
            f'\ntexture = ExtResource("{new_id}")\nspawn_on_death',
        )

    tres_path.write_text(text, encoding="utf-8")
    return True


def _find_uid(import_path: Path) -> str | None:
    if not import_path.exists():
        return None
    for line in import_path.read_text().splitlines():
        if line.startswith("uid="):
            return line.split("=", 1)[1].strip().strip('"')
    return None


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def process_sprite(
    name: str,
    size: int = 64,
    strategy: str = "green",
    body_only: bool = False,
    outline_body: bool = False,
    skip_tres: bool = False,
):
    png_candidates = list(ENEMIES_SPRITE_DIR.glob(f"*{name}*Concept*.png"))
    png_candidates = [p for p in png_candidates if ".import" not in p.name]
    if not png_candidates:
        print(f"Error: No concept image found for '{name}' in {ENEMIES_SPRITE_DIR}")
        sys.exit(1)
    if len(png_candidates) > 1:
        print(f"Multiple matches: {[p.name for p in png_candidates]}")
        sys.exit(1)

    src_path = png_candidates[0]
    print(f"Source: {src_path.name}")

    img = Image.open(src_path).convert("RGBA")
    orig_size = img.size
    print(f"  Original size: {orig_size[0]}x{orig_size[1]}")

    bg_fn = BG_STRATEGIES.get(strategy)
    if bg_fn is None:
        print(f"Error: Unknown strategy '{strategy}'. Choose from: {list(BG_STRATEGIES.keys())}")
        sys.exit(1)

    removed = _flood_fill_bg(img, bg_fn)
    print(f"  Background removed: {removed} pixels (strategy={strategy})")

    if outline_body:
        img = _extract_body_by_outline(img)
        print("  Body extracted via outline detection")
    elif body_only:
        img = _crop_body_only(img)
        print("  Body cropped (beams/effects removed)")

    bbox = img.getbbox()
    if bbox is None:
        print("Error: Image is completely transparent after processing")
        sys.exit(1)

    cropped = img.crop(bbox)
    print(f"  Cropped: {cropped.size[0]}x{cropped.size[1]}")

    resized = cropped.resize((size, size), Image.NEAREST)

    out_name = re.sub(r"\s+", "", src_path.name)
    out_path = ENEMIES_SPRITE_DIR / out_name
    resized.save(out_path)
    print(f"  Saved: {out_path.name} ({size}x{size})")

    if src_path.name != out_name and src_path.exists():
        src_path.unlink()
        import_file = src_path.with_suffix(".png.import")
        if import_file.exists():
            import_file.unlink()
        print(f"  Cleaned up original: {src_path.name}")

    if skip_tres:
        print("  [skip] .tres linking skipped")
        return

    snake = re.sub(r"_?Concept.*", "", out_name.replace(".png", ""))
    snake = re.sub(r"(?<!^)(?=[A-Z])", "_", snake).lower()
    tres_path = ENEMIES_RES_DIR / f"{snake}.tres"

    if not tres_path.exists():
        print(f"  [warn] Resource not found: {tres_path.name}")
        return

    texture_res_path = f"res://assets/sprites/enemies/{out_name}"
    uid = _find_uid(out_path.with_name(out_name + ".import"))

    if _link_texture(tres_path, texture_res_path, uid):
        print(f"  Linked texture in {tres_path.name}")

    print("Done!")


def main():
    parser = argparse.ArgumentParser(
        description="Process enemy concept sprites: remove background, resize, link texture.",
        epilog="""
Examples:
  python3 tools/process_enemy_sprite.py MiniSlime
  python3 tools/process_enemy_sprite.py MirrorCraft --strategy metallic --outline-body
  python3 tools/process_enemy_sprite.py LaserPointer --body-only
  python3 tools/process_enemy_sprite.py SteelCanGate --strategy metallic --outline-body --size 96
        """,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("name", help="Enemy name to match (e.g. MiniSlime, LaserPointer)")
    parser.add_argument("--size", type=int, default=64, help="Output size in pixels (default: 64)")
    parser.add_argument(
        "--strategy",
        choices=list(BG_STRATEGIES.keys()),
        default="green",
        help="Background removal strategy (default: green)",
    )
    parser.add_argument(
        "--body-only",
        action="store_true",
        help="Remove thin beams/effects, keep only dense body",
    )
    parser.add_argument(
        "--outline-body",
        action="store_true",
        help="Extract body via outline detection (for metallic sprites with glow)",
    )
    parser.add_argument(
        "--skip-tres",
        action="store_true",
        help="Skip .tres texture linking",
    )
    args = parser.parse_args()

    process_sprite(
        name=args.name,
        size=args.size,
        strategy=args.strategy,
        body_only=args.body_only,
        outline_body=args.outline_body,
        skip_tres=args.skip_tres,
    )


if __name__ == "__main__":
    main()
