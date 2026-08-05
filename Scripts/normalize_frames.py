"""Normalise device artwork so every frame shares one canvas and one panel circle.

Frames are exported at different scales and canvas sizes, which makes the device
jump when switching. Each frame is detected, scaled so its panel radius matches
the reference, and translated so the panel centre lands on the reference centre.
Output: same-size PNGs plus a frames.json where all frames share geometry.

    python3 normalize_frames.py <out_dir> <art...>
"""
import cv2, numpy as np, json, sys, pathlib

REFERENCE = "steel-white"
MIN_CIRCULARITY = 0.90


def load(path):
    img = cv2.imread(str(path), cv2.IMREAD_UNCHANGED)
    if img.shape[2] == 3:
        img = cv2.cvtColor(img, cv2.COLOR_BGR2BGRA)
        white = (img[:, :, :3] > 244).all(axis=2)
        img[white, 3] = 0
    return img


def detect_panel(img):
    gray = cv2.cvtColor(img[:, :, :3], cv2.COLOR_BGR2GRAY)
    gray[img[:, :, 3] < 10] = 255
    _, dark = cv2.threshold(gray, 70, 255, cv2.THRESH_BINARY_INV)
    dark = cv2.morphologyEx(dark, cv2.MORPH_CLOSE, np.ones((15, 15), np.uint8))
    dark = cv2.morphologyEx(dark, cv2.MORPH_OPEN, np.ones((9, 9), np.uint8))
    contours, _ = cv2.findContours(dark, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    h, w = gray.shape
    best, best_area = None, -1
    for c in contours:
        area = cv2.contourArea(c)
        if area < w * h * 0.02:
            continue
        (cx, cy), r = cv2.minEnclosingCircle(c)
        circ = area / (np.pi * r * r)
        if circ > MIN_CIRCULARITY and area > best_area:
            best, best_area = (cx, cy, r, circ), area
    return best


def alpha_bbox(img):
    ys, xs = np.where(img[:, :, 3] > 10)
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())


out_dir = pathlib.Path(sys.argv[1])
sources = {p.stem: p for p in map(pathlib.Path, sys.argv[2:])}
images = {name: load(path) for name, path in sources.items()}
panels = {name: detect_panel(img) for name, img in images.items()}

ref_img = images[REFERENCE]
ref = panels[REFERENCE]
if ref is None:
    raise SystemExit(f"reference {REFERENCE} panel not detected")
ref_cx, ref_cy, ref_r, ref_circ = ref
CANVAS_H, CANVAS_W = ref_img.shape[:2]
print(f"reference {REFERENCE}: canvas {CANVAS_W}x{CANVAS_H} "
      f"centre=({ref_cx:.1f},{ref_cy:.1f}) r={ref_r:.1f} circ={ref_circ:.4f}")

for name in sorted(images):
    img = images[name]
    panel = panels[name]
    if panel is None:
        box = alpha_bbox(img)
        match = next(
            (o for o in panels
             if panels[o] is not None
             and images[o].shape[:2] == img.shape[:2]
             and all(abs(a - b) <= 2 for a, b in zip(alpha_bbox(images[o]), box))),
            None,
        )
        if match is None:
            raise SystemExit(f"{name}: panel undetectable and no frame to borrow from")
        panel = panels[match]
        print(f"{name}: panel undetectable, borrowing geometry from {match}")

    cx, cy, r, _ = panel
    scale = ref_r / r
    scaled = cv2.resize(img, None, fx=scale, fy=scale, interpolation=cv2.INTER_AREA
                        if scale < 1 else cv2.INTER_CUBIC)
    sx, sy = cx * scale, cy * scale

    canvas = np.zeros((CANVAS_H, CANVAS_W, 4), np.uint8)
    dx, dy = int(round(ref_cx - sx)), int(round(ref_cy - sy))
    src_x0, src_y0 = max(0, -dx), max(0, -dy)
    dst_x0, dst_y0 = max(0, dx), max(0, dy)
    w = min(scaled.shape[1] - src_x0, CANVAS_W - dst_x0)
    h = min(scaled.shape[0] - src_y0, CANVAS_H - dst_y0)
    canvas[dst_y0:dst_y0 + h, dst_x0:dst_x0 + w] = \
        scaled[src_y0:src_y0 + h, src_x0:src_x0 + w]

    cv2.imwrite(str(out_dir / f"{name}.png"), canvas)

    # Cutout variant: panel disc punched out so the stage can composite
    # black -> live panel -> frame on top, letting the bezel occlude the edge.
    # Supersampled disc gives a clean anti-aliased boundary.
    SS = 4
    disc = np.zeros((CANVAS_H * SS, CANVAS_W * SS), np.uint8)
    cv2.circle(disc, (int(round(ref_cx * SS)), int(round(ref_cy * SS))),
               int(round((ref_r - 0.5) * SS)), 255, -1, lineType=cv2.LINE_AA)
    disc = cv2.resize(disc, (CANVAS_W, CANVAS_H), interpolation=cv2.INTER_AREA)
    cutout = canvas.copy()
    cutout[:, :, 3] = (cutout[:, :, 3].astype(np.float32)
                       * (1.0 - disc.astype(np.float32) / 255.0)).astype(np.uint8)
    cv2.imwrite(str(out_dir / f"{name}-cutout.png"), cutout)

    print(f"{name}: scaled {scale:.4f}x, shifted ({dx:+d},{dy:+d}) "
          f"-> {CANVAS_W}x{CANVAS_H} (+ cutout)")

frames = [{
    "id": name,
    "name": name.replace("-", " ").title(),
    "image": name,
    "cutout_image": f"{name}-cutout",
    "image_width": CANVAS_W,
    "image_height": CANVAS_H,
    "center_x_frac": round(ref_cx / CANVAS_W, 5),
    "center_y_frac": round(ref_cy / CANVAS_H, 5),
    "radius_frac": round(ref_r / CANVAS_W, 5),
    "panel_px": 412,
    "normalized_to": REFERENCE,
} for name in sorted(images)]

(out_dir / "frames.json").write_text(json.dumps({"frames": frames}, indent=2) + "\n")
print(f"wrote {out_dir/'frames.json'} ({len(frames)} frames, shared geometry)")
