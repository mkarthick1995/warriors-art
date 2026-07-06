"""Generate placeholder stick-silhouette sprite strips for Warrior's Art.

Dev tool only — real art replaces these PNGs with the same names/layout.
Output: assets/sprites/<character>/<anim>@<frames>x<fps>.png (horizontal strips).
Canvas per frame: 128x192, feet baseline at y=188, facing RIGHT (the game
flips the sprite for left-facing). Drawn in light gray so the per-player
body_color modulate tints it.

Run from the repo root:  python tools/generate_placeholder_sprites.py
Then rebuild SpriteFrames:  godot --headless --path . -s res://tools/build_sprite_frames.gd
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw

FRAME_W, FRAME_H = 128, 192
BASELINE = 188  # feet y
CX = 56  # body center x (slightly back so pokes extend right)
BODY = (225, 225, 225, 255)
STAFF = (245, 235, 210, 255)
LIMB_W = 9
STAFF_W = 6
STAFF_LEN = 116


def draw_pose(
    d: ImageDraw.ImageDraw,
    hip_y: float = 118.0,
    lean: float = 0.0,
    front_arm: float = -0.5,
    rear_arm: float = -2.4,
    front_foot: float = 22.0,
    rear_foot: float = -18.0,
    staff_angle: float | None = None,
    staff_offset: float = 0.0,
    lying: float = 0.0,
) -> None:
    """Draw one stick-fighter pose. Angles in radians, 0 = toward +x (forward).

    lying: 0..1 rotates the whole figure toward horizontal (knockdown).
    """
    if lying > 0:
        # Simple lying figure: torso along the ground.
        y = BASELINE - 14
        x0 = CX - 40
        d.line([(x0, y), (x0 + 78, y)], fill=BODY, width=LIMB_W + 4)
        d.ellipse(
            [x0 - 26, y - 13, x0, y + 13],
            fill=BODY,
        )
        return

    hip = (CX + lean * 10, hip_y)
    neck = (hip[0] + lean * 16, hip[1] - 42)
    head_c = (neck[0] + lean * 6, neck[1] - 18)
    shoulder = (neck[0], neck[1] + 5)

    # Legs (hip -> foot on the baseline).
    for foot_dx in (front_foot, rear_foot):
        d.line([hip, (CX + foot_dx, BASELINE)], fill=BODY, width=LIMB_W)
    # Torso.
    d.line([hip, neck], fill=BODY, width=LIMB_W + 3)
    # Head.
    r = 13
    d.ellipse(
        [head_c[0] - r, head_c[1] - r, head_c[0] + r, head_c[1] + r],
        fill=BODY,
    )
    # Arms.
    arm_len = 32
    hands = {}
    for name, ang in (("front", front_arm), ("rear", rear_arm)):
        hx = shoulder[0] + math.cos(ang) * arm_len
        hy = shoulder[1] - math.sin(ang) * arm_len
        d.line([shoulder, (hx, hy)], fill=BODY, width=LIMB_W - 1)
        hands[name] = (hx, hy)
    # Staff (lathi) through the front hand.
    if staff_angle is not None:
        hx, hy = hands["front"]
        hx += staff_offset
        half = STAFF_LEN / 2
        dx, dy = math.cos(staff_angle) * half, -math.sin(staff_angle) * half
        d.line([(hx - dx, hy - dy), (hx + dx, hy + dy)], fill=STAFF, width=STAFF_W)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def lathiyal_animations() -> dict:
    """anim name -> (fps, [pose kwargs per frame])"""
    idle = [
        dict(hip_y=118 + bob, staff_angle=1.15, front_arm=-0.6)
        for bob in (0, 2, 3, 2)
    ]
    walk = [
        dict(
            hip_y=116 + (2 if i % 3 == 0 else 0),
            front_foot=lerp(30, -6, (i % 3) / 2.0),
            rear_foot=lerp(-26, 8, (i % 3) / 2.0),
            staff_angle=1.15,
        )
        for i in range(6)
    ]
    jab = [
        dict(staff_angle=0.9, front_arm=-0.5),
        dict(staff_angle=0.15, front_arm=-0.1, staff_offset=14, lean=0.25),
        dict(staff_angle=0.0, front_arm=0.0, staff_offset=30, lean=0.4),
        dict(staff_angle=0.35, front_arm=-0.3, staff_offset=10, lean=0.2),
    ]
    swing = [
        dict(staff_angle=2.2, front_arm=2.0, lean=-0.3),
        dict(staff_angle=1.6, front_arm=1.4, lean=-0.15),
        dict(staff_angle=0.9, front_arm=0.6, lean=0.1),
        dict(staff_angle=0.2, front_arm=0.1, lean=0.35, staff_offset=16),
        dict(staff_angle=-0.35, front_arm=-0.4, lean=0.4, staff_offset=18),
        dict(staff_angle=-0.1, front_arm=-0.4, lean=0.25),
    ]
    whirl = [
        dict(hip_y=124, staff_angle=i * math.tau / 8, front_arm=i * math.tau / 8, lean=0.15)
        for i in range(8)
    ]
    air = [
        dict(hip_y=110, front_foot=10, rear_foot=-8, staff_angle=-0.7, front_arm=-0.7),
        dict(hip_y=110, front_foot=12, rear_foot=-6, staff_angle=-0.9, front_arm=-0.9, staff_offset=10),
        dict(hip_y=110, front_foot=12, rear_foot=-6, staff_angle=-0.9, front_arm=-0.9, staff_offset=14),
        dict(hip_y=110, front_foot=10, rear_foot=-8, staff_angle=-0.7, front_arm=-0.7),
    ]
    hit = [
        dict(lean=-0.45, front_arm=1.8, rear_arm=1.4, staff_angle=1.5),
        dict(lean=-0.6, front_arm=2.0, rear_arm=1.7, staff_angle=1.7, hip_y=122),
    ]
    jump = [
        dict(hip_y=112, front_foot=12, rear_foot=-10, staff_angle=1.1),
        dict(hip_y=104, front_foot=6, rear_foot=-4, staff_angle=1.0),
        dict(hip_y=112, front_foot=14, rear_foot=-12, staff_angle=1.1),
    ]
    crouch = [
        dict(hip_y=146, front_foot=30, rear_foot=-24, staff_angle=1.3),
        dict(hip_y=148, front_foot=30, rear_foot=-24, staff_angle=1.3),
    ]
    knockdown = [
        dict(lean=-0.8, hip_y=140, front_arm=2.2, rear_arm=1.9),
        dict(lying=1.0),
        dict(lying=1.0),
    ]
    return {
        "idle": (8, idle),
        "walk": (10, walk),
        "jab": (20, jab),
        "low_rap": (20, [dict(**p, hip_y=150) for p in [
            dict(staff_angle=0.5, front_arm=-0.4),
            dict(staff_angle=-0.2, front_arm=-0.1, staff_offset=22, lean=0.3),
            dict(staff_angle=-0.25, front_arm=-0.1, staff_offset=26, lean=0.3),
            dict(staff_angle=0.2, front_arm=-0.3, staff_offset=8),
        ]]),
        "swing": (15, swing),
        "whirlwind": (15, whirl),
        "ex_whirlwind": (18, whirl),
        "super_storm": (16, whirl + [dict(staff_angle=0.0, front_arm=0.0, staff_offset=34, lean=0.45)] * 2),
        "air_jab": (15, air),
        "hit": (12, hit),
        "jump": (8, jump),
        "crouch": (8, crouch),
        "knockdown": (10, knockdown),
    }


def write_strips(character: str, animations: dict) -> None:
    out_dir = Path("assets/sprites") / character
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, (fps, poses) in animations.items():
        strip = Image.new("RGBA", (FRAME_W * len(poses), FRAME_H), (0, 0, 0, 0))
        for i, pose in enumerate(poses):
            frame = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
            hip_y = pose.pop("hip_y", 118)
            draw_pose(ImageDraw.Draw(frame), hip_y=hip_y, **pose)
            strip.paste(frame, (i * FRAME_W, 0))
        path = out_dir / f"{name}@{len(poses)}x{fps}.png"
        strip.save(path)
        print(f"wrote {path}")


if __name__ == "__main__":
    write_strips("bengal_lathi", lathiyal_animations())
