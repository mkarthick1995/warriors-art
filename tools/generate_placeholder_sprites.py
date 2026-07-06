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
    staff_len: float = STAFF_LEN,
    shield: bool = False,
    whip_curve: float = 0.0,
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
    # Weapon through/from the front hand.
    if staff_angle is not None and whip_curve != 0.0:
        # Urumi: flexible blade drawn as a curving polyline FROM the hand.
        hx, hy = hands["front"]
        hx += staff_offset
        seg = staff_len / 8.0
        ang = staff_angle
        pts = [(hx, hy)]
        for _ in range(8):
            hx += math.cos(ang) * seg
            hy -= math.sin(ang) * seg
            pts.append((hx, hy))
            ang -= whip_curve
        d.line(pts, fill=STAFF, width=STAFF_W - 2, joint="curve")
    elif staff_angle is not None:
        hx, hy = hands["front"]
        hx += staff_offset
        half = staff_len / 2
        dx, dy = math.cos(staff_angle) * half, -math.sin(staff_angle) * half
        d.line([(hx - dx, hy - dy), (hx + dx, hy + dy)], fill=STAFF, width=STAFF_W)
    # Round shield (farri) on the rear hand.
    if shield:
        sx, sy = hands["rear"]
        d.ellipse([sx - 16, sy - 16, sx + 16, sy + 16], fill=BODY)


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


def silambar_animations() -> dict:
    """Tamil Nadu Silambam zoner: longer staff (150), horizontal spin style."""
    s = {"staff_len": 150.0}
    idle = [dict(hip_y=118 + bob, staff_angle=0.35, front_arm=-0.4, **s) for bob in (0, 2, 3, 2)]
    walk = [
        dict(
            hip_y=116 + (2 if i % 3 == 0 else 0),
            front_foot=lerp(30, -6, (i % 3) / 2.0),
            rear_foot=lerp(-26, 8, (i % 3) / 2.0),
            staff_angle=0.35,
            **s,
        )
        for i in range(6)
    ]
    poke = [
        dict(staff_angle=0.3, front_arm=-0.4, **s),
        dict(staff_angle=0.05, front_arm=-0.1, staff_offset=26, lean=0.3, **s),
        dict(staff_angle=0.0, front_arm=0.0, staff_offset=44, lean=0.45, **s),
        dict(staff_angle=0.2, front_arm=-0.3, staff_offset=14, lean=0.2, **s),
    ]
    low_poke = [
        dict(hip_y=150, staff_angle=-0.1, front_arm=-0.3, **s),
        dict(hip_y=152, staff_angle=-0.25, front_arm=-0.1, staff_offset=34, lean=0.35, **s),
        dict(hip_y=152, staff_angle=-0.28, front_arm=-0.1, staff_offset=40, lean=0.35, **s),
        dict(hip_y=150, staff_angle=-0.1, front_arm=-0.3, staff_offset=10, **s),
    ]
    spin = [
        dict(staff_angle=i * math.tau / 6, front_arm=i * math.tau / 6, lean=0.1, **s)
        for i in range(6)
    ]
    lunge = [
        dict(staff_angle=0.5, front_arm=0.4, lean=-0.2, **s),
        dict(staff_angle=0.2, front_arm=0.1, lean=0.2, staff_offset=20, **s),
        dict(staff_angle=0.0, front_arm=0.0, lean=0.55, staff_offset=52, front_foot=42, **s),
        dict(staff_angle=0.0, front_arm=0.0, lean=0.6, staff_offset=58, front_foot=46, **s),
        dict(staff_angle=0.15, front_arm=-0.2, lean=0.3, staff_offset=24, **s),
    ]
    air = [
        dict(hip_y=110, front_foot=10, rear_foot=-8, staff_angle=-0.55, front_arm=-0.6, **s),
        dict(hip_y=110, front_foot=12, rear_foot=-6, staff_angle=-0.75, front_arm=-0.8,
             staff_offset=12, **s),
        dict(hip_y=110, front_foot=12, rear_foot=-6, staff_angle=-0.75, front_arm=-0.8,
             staff_offset=16, **s),
        dict(hip_y=110, front_foot=10, rear_foot=-8, staff_angle=-0.55, front_arm=-0.6, **s),
    ]
    hit = [
        dict(lean=-0.45, front_arm=1.8, rear_arm=1.4, staff_angle=0.9, **s),
        dict(lean=-0.6, front_arm=2.0, rear_arm=1.7, staff_angle=1.1, hip_y=122, **s),
    ]
    jump = [
        dict(hip_y=112, front_foot=12, rear_foot=-10, staff_angle=0.4, **s),
        dict(hip_y=104, front_foot=6, rear_foot=-4, staff_angle=0.35, **s),
        dict(hip_y=112, front_foot=14, rear_foot=-12, staff_angle=0.4, **s),
    ]
    crouch = [
        dict(hip_y=146, front_foot=30, rear_foot=-24, staff_angle=0.5, **s),
        dict(hip_y=148, front_foot=30, rear_foot=-24, staff_angle=0.5, **s),
    ]
    knockdown = [
        dict(lean=-0.8, hip_y=140, front_arm=2.2, rear_arm=1.9, **s),
        dict(lying=1.0),
        dict(lying=1.0),
    ]
    return {
        "idle": (8, idle),
        "walk": (10, walk),
        "poke": (20, poke),
        "low_poke": (18, low_poke),
        "spin": (14, spin),
        "lunge": (16, lunge),
        "ex_lunge": (18, lunge),
        "super_spin": (16, spin + spin[:3] + [lunge[3]] * 2),
        "air_poke": (15, air),
        "hit": (12, hit),
        "jump": (8, jump),
        "crouch": (8, crouch),
        "knockdown": (10, knockdown),
    }


def gatka_animations() -> dict:
    """Punjab Gatka dual-wielder: short sword (70) + round shield, chakram throw."""
    s = {"staff_len": 70.0, "shield": True}
    idle = [dict(hip_y=118 + bob, staff_angle=0.9, front_arm=-0.5, rear_arm=-2.6, **s)
            for bob in (0, 2, 3, 2)]
    walk = [
        dict(
            hip_y=116 + (2 if i % 3 == 0 else 0),
            front_foot=lerp(30, -6, (i % 3) / 2.0),
            rear_foot=lerp(-26, 8, (i % 3) / 2.0),
            staff_angle=0.9, rear_arm=-2.6, **s,
        )
        for i in range(6)
    ]
    slash = [
        dict(staff_angle=1.7, front_arm=1.4, rear_arm=-2.6, lean=-0.15, **s),
        dict(staff_angle=0.6, front_arm=0.4, rear_arm=-2.6, lean=0.2, staff_offset=8, **s),
        dict(staff_angle=-0.2, front_arm=-0.2, rear_arm=-2.6, lean=0.35, staff_offset=14, **s),
        dict(staff_angle=0.3, front_arm=-0.3, rear_arm=-2.6, lean=0.15, **s),
    ]
    low_cut = [dict(**{**p, "hip_y": 150}) for p in slash]
    twin = slash + [
        dict(staff_angle=1.2, front_arm=1.0, rear_arm=-2.6, lean=0.0, **s),
        dict(staff_angle=-0.3, front_arm=-0.3, rear_arm=-2.6, lean=0.4, staff_offset=16, **s),
    ]
    throw = [
        dict(staff_angle=0.9, front_arm=-2.6, rear_arm=-0.5, lean=-0.25, **s),
        dict(staff_angle=0.9, front_arm=-2.9, rear_arm=-0.4, lean=-0.35, **s),
        dict(staff_angle=0.9, front_arm=0.1, rear_arm=-0.6, lean=0.4, **s),
        dict(staff_angle=0.9, front_arm=0.0, rear_arm=-0.6, lean=0.45, **s),
    ]
    air = [
        dict(hip_y=110, front_foot=10, rear_foot=-8, staff_angle=-0.7, front_arm=-0.7,
             rear_arm=-2.6, **s),
        dict(hip_y=110, front_foot=12, rear_foot=-6, staff_angle=-0.9, front_arm=-0.9,
             rear_arm=-2.6, staff_offset=8, **s),
        dict(hip_y=110, front_foot=12, rear_foot=-6, staff_angle=-0.9, front_arm=-0.9,
             rear_arm=-2.6, staff_offset=10, **s),
    ]
    spin = [dict(staff_angle=i * math.tau / 6, front_arm=i * math.tau / 6, rear_arm=-2.6,
                 lean=0.1, **s) for i in range(6)]
    hit = [
        dict(lean=-0.45, front_arm=1.8, rear_arm=1.4, staff_angle=1.5, **s),
        dict(lean=-0.6, front_arm=2.0, rear_arm=1.7, staff_angle=1.7, hip_y=122, **s),
    ]
    jump = [
        dict(hip_y=112, front_foot=12, rear_foot=-10, staff_angle=1.0, rear_arm=-2.6, **s),
        dict(hip_y=104, front_foot=6, rear_foot=-4, staff_angle=0.95, rear_arm=-2.6, **s),
        dict(hip_y=112, front_foot=14, rear_foot=-12, staff_angle=1.0, rear_arm=-2.6, **s),
    ]
    crouch = [dict(hip_y=146, front_foot=30, rear_foot=-24, staff_angle=1.1, rear_arm=-2.6, **s),
              dict(hip_y=148, front_foot=30, rear_foot=-24, staff_angle=1.1, rear_arm=-2.6, **s)]
    knockdown = [
        dict(lean=-0.8, hip_y=140, front_arm=2.2, rear_arm=1.9, **s),
        dict(lying=1.0),
        dict(lying=1.0),
    ]
    return {
        "idle": (8, idle),
        "walk": (10, walk),
        "slash": (20, slash),
        "low_cut": (18, low_cut),
        "twin": (16, twin),
        "chakram": (14, throw),
        "ex_chakram": (16, throw),
        "super_storm": (16, spin + spin[:3] + [slash[2]] * 2),
        "air_slash": (15, air),
        "hit": (12, hit),
        "jump": (8, jump),
        "crouch": (8, crouch),
        "knockdown": (10, knockdown),
    }


def kalari_animations() -> dict:
    """Kerala Kalaripayattu: urumi whip-sword (curved), acrobatic stance."""
    w = {"staff_len": 130.0}
    idle = [dict(hip_y=116 + bob, staff_angle=-1.1, whip_curve=0.12, front_arm=-0.7, **w)
            for bob in (0, 2, 3, 2)]
    walk = [
        dict(
            hip_y=114 + (2 if i % 3 == 0 else 0),
            front_foot=lerp(32, -8, (i % 3) / 2.0),
            rear_foot=lerp(-28, 8, (i % 3) / 2.0),
            staff_angle=-1.1, whip_curve=0.12, front_arm=-0.7, **w,
        )
        for i in range(6)
    ]
    dagger = [
        dict(staff_angle=0.6, staff_len=45.0, front_arm=-0.3),
        dict(staff_angle=0.1, staff_len=45.0, front_arm=-0.05, staff_offset=16, lean=0.3),
        dict(staff_angle=0.0, staff_len=45.0, front_arm=0.0, staff_offset=22, lean=0.35),
        dict(staff_angle=0.4, staff_len=45.0, front_arm=-0.3, staff_offset=6),
    ]
    low_dagger = [dict(**{**p, "hip_y": 150}) for p in dagger]
    lash = [
        dict(staff_angle=2.0, whip_curve=-0.2, front_arm=1.8, lean=-0.25, **w),
        dict(staff_angle=1.2, whip_curve=0.1, front_arm=1.0, lean=0.0, **w),
        dict(staff_angle=0.5, whip_curve=0.28, front_arm=0.3, lean=0.3, **w),
        dict(staff_angle=0.1, whip_curve=0.34, front_arm=0.0, lean=0.45, staff_offset=8, **w),
        dict(staff_angle=-0.2, whip_curve=0.3, front_arm=-0.3, lean=0.35, **w),
    ]
    spin_whip = [
        dict(staff_angle=i * math.tau / 6, whip_curve=0.3, front_arm=i * math.tau / 6,
             lean=0.1, **w)
        for i in range(6)
    ]
    air = [
        dict(hip_y=108, front_foot=14, rear_foot=-10, staff_angle=-0.6, whip_curve=0.25,
             front_arm=-0.6, **w),
        dict(hip_y=108, front_foot=16, rear_foot=-8, staff_angle=-0.85, whip_curve=0.3,
             front_arm=-0.85, staff_offset=8, **w),
        dict(hip_y=108, front_foot=16, rear_foot=-8, staff_angle=-0.85, whip_curve=0.3,
             front_arm=-0.85, staff_offset=10, **w),
    ]
    hit = [
        dict(lean=-0.45, front_arm=1.8, rear_arm=1.4, staff_angle=1.4, whip_curve=0.2, **w),
        dict(lean=-0.6, front_arm=2.0, rear_arm=1.7, staff_angle=1.6, whip_curve=0.2,
             hip_y=122, **w),
    ]
    jump = [
        dict(hip_y=110, front_foot=12, rear_foot=-10, staff_angle=-1.0, whip_curve=0.15, **w),
        dict(hip_y=102, front_foot=6, rear_foot=-4, staff_angle=-0.95, whip_curve=0.15, **w),
        dict(hip_y=110, front_foot=14, rear_foot=-12, staff_angle=-1.0, whip_curve=0.15, **w),
    ]
    crouch = [
        dict(hip_y=146, front_foot=30, rear_foot=-24, staff_angle=-1.0, whip_curve=0.15, **w),
        dict(hip_y=148, front_foot=30, rear_foot=-24, staff_angle=-1.0, whip_curve=0.15, **w),
    ]
    knockdown = [
        dict(lean=-0.8, hip_y=140, front_arm=2.2, rear_arm=1.9),
        dict(lying=1.0),
        dict(lying=1.0),
    ]
    return {
        "idle": (8, idle),
        "walk": (10, walk),
        "dagger": (20, dagger),
        "low_dagger": (18, low_dagger),
        "lash": (14, lash),
        "urumi_spin": (14, spin_whip),
        "ex_urumi_spin": (16, spin_whip),
        "super_marma": (16, spin_whip + [lash[3]] * 3),
        "air_lash": (15, air),
        "hit": (12, hit),
        "jump": (8, jump),
        "crouch": (8, crouch),
        "knockdown": (10, knockdown),
    }


def thangta_animations() -> dict:
    """Manipur Thang-Ta: sword (short) normals, spear (long) specials."""
    sword = {"staff_len": 75.0}
    spear = {"staff_len": 145.0}
    idle = [dict(hip_y=118 + bob, staff_angle=0.7, front_arm=-0.5, **sword)
            for bob in (0, 2, 3, 2)]
    walk = [
        dict(
            hip_y=116 + (2 if i % 3 == 0 else 0),
            front_foot=lerp(30, -6, (i % 3) / 2.0),
            rear_foot=lerp(-26, 8, (i % 3) / 2.0),
            staff_angle=0.7, **sword,
        )
        for i in range(6)
    ]
    slash = [
        dict(staff_angle=1.6, front_arm=1.3, lean=-0.15, **sword),
        dict(staff_angle=0.5, front_arm=0.3, lean=0.2, staff_offset=8, **sword),
        dict(staff_angle=-0.2, front_arm=-0.2, lean=0.35, staff_offset=12, **sword),
        dict(staff_angle=0.3, front_arm=-0.3, lean=0.15, **sword),
    ]
    low_slash = [dict(**{**p, "hip_y": 150}) for p in slash]
    thrust = [
        dict(staff_angle=0.25, front_arm=-0.4, **spear),
        dict(staff_angle=0.05, front_arm=-0.1, staff_offset=28, lean=0.3, **spear),
        dict(staff_angle=0.0, front_arm=0.0, staff_offset=46, lean=0.45, **spear),
        dict(staff_angle=0.15, front_arm=-0.25, staff_offset=16, lean=0.2, **spear),
    ]
    charge = [
        dict(staff_angle=0.4, front_arm=0.3, lean=-0.15, **spear),
        dict(staff_angle=0.1, front_arm=0.05, lean=0.25, staff_offset=24, **spear),
        dict(staff_angle=0.0, front_arm=0.0, lean=0.55, staff_offset=54, front_foot=44, **spear),
        dict(staff_angle=0.0, front_arm=0.0, lean=0.6, staff_offset=58, front_foot=46, **spear),
        dict(staff_angle=0.2, front_arm=-0.2, lean=0.3, staff_offset=20, **spear),
    ]
    spin = [dict(staff_angle=i * math.tau / 6, front_arm=i * math.tau / 6, lean=0.1, **spear)
            for i in range(6)]
    air = [
        dict(hip_y=110, front_foot=10, rear_foot=-8, staff_angle=-0.7, front_arm=-0.7, **spear),
        dict(hip_y=110, front_foot=12, rear_foot=-6, staff_angle=-0.9, front_arm=-0.9,
             staff_offset=10, **spear),
        dict(hip_y=110, front_foot=12, rear_foot=-6, staff_angle=-0.9, front_arm=-0.9,
             staff_offset=12, **spear),
    ]
    hit = [
        dict(lean=-0.45, front_arm=1.8, rear_arm=1.4, staff_angle=1.5, **sword),
        dict(lean=-0.6, front_arm=2.0, rear_arm=1.7, staff_angle=1.7, hip_y=122, **sword),
    ]
    jump = [
        dict(hip_y=112, front_foot=12, rear_foot=-10, staff_angle=0.8, **sword),
        dict(hip_y=104, front_foot=6, rear_foot=-4, staff_angle=0.75, **sword),
        dict(hip_y=112, front_foot=14, rear_foot=-12, staff_angle=0.8, **sword),
    ]
    crouch = [
        dict(hip_y=146, front_foot=30, rear_foot=-24, staff_angle=0.9, **sword),
        dict(hip_y=148, front_foot=30, rear_foot=-24, staff_angle=0.9, **sword),
    ]
    knockdown = [
        dict(lean=-0.8, hip_y=140, front_arm=2.2, rear_arm=1.9),
        dict(lying=1.0),
        dict(lying=1.0),
    ]
    return {
        "idle": (8, idle),
        "walk": (10, walk),
        "slash": (20, slash),
        "low_slash": (18, low_slash),
        "thrust": (18, thrust),
        "charge": (16, charge),
        "ex_charge": (18, charge),
        "super_chainu": (16, spin + spin[:3] + [charge[3]] * 2),
        "air_thrust": (15, air),
        "hit": (12, hit),
        "jump": (8, jump),
        "crouch": (8, crouch),
        "knockdown": (10, knockdown),
    }


def mardani_animations() -> dict:
    """Maharashtra Mardani Khel: patta gauntlet-sword bruiser, vita throw."""
    p = {"staff_len": 95.0}
    idle = [dict(hip_y=120 + bob, staff_angle=0.5, front_arm=-0.4, **p) for bob in (0, 1, 2, 1)]
    walk = [
        dict(
            hip_y=118 + (2 if i % 3 == 0 else 0),
            front_foot=lerp(26, -4, (i % 3) / 2.0),
            rear_foot=lerp(-22, 6, (i % 3) / 2.0),
            staff_angle=0.5, **p,
        )
        for i in range(6)
    ]
    patta = [
        dict(staff_angle=1.5, front_arm=1.2, lean=-0.1, **p),
        dict(staff_angle=0.5, front_arm=0.3, lean=0.2, staff_offset=10, **p),
        dict(staff_angle=-0.1, front_arm=-0.1, lean=0.3, staff_offset=16, **p),
        dict(staff_angle=0.3, front_arm=-0.3, lean=0.1, **p),
    ]
    low_patta = [dict(**{**q, "hip_y": 150}) for q in patta]
    chhed = [
        dict(staff_angle=0.4, front_arm=-0.4, lean=-0.2, **p),
        dict(staff_angle=0.05, front_arm=-0.05, staff_offset=30, lean=0.35, **p),
        dict(staff_angle=0.0, front_arm=0.0, staff_offset=42, lean=0.5, front_foot=40, **p),
        dict(staff_angle=0.2, front_arm=-0.25, staff_offset=14, lean=0.2, **p),
    ]
    vita = [
        dict(staff_angle=0.5, staff_len=120.0, front_arm=-2.7, rear_arm=-0.5, lean=-0.3),
        dict(staff_angle=0.3, staff_len=120.0, front_arm=-2.9, rear_arm=-0.4, lean=-0.35),
        dict(staff_angle=0.05, staff_len=120.0, front_arm=0.1, rear_arm=-0.6, lean=0.45),
        dict(staff_angle=0.0, staff_len=120.0, front_arm=0.0, rear_arm=-0.6, lean=0.5),
    ]
    spin = [dict(staff_angle=i * math.tau / 6, front_arm=i * math.tau / 6, lean=0.1, **p)
            for i in range(6)]
    air = [
        dict(hip_y=112, front_foot=10, rear_foot=-8, staff_angle=-0.7, front_arm=-0.7, **p),
        dict(hip_y=112, front_foot=12, rear_foot=-6, staff_angle=-0.9, front_arm=-0.9,
             staff_offset=8, **p),
        dict(hip_y=112, front_foot=12, rear_foot=-6, staff_angle=-0.9, front_arm=-0.9,
             staff_offset=10, **p),
    ]
    hit = [
        dict(lean=-0.4, front_arm=1.8, rear_arm=1.4, staff_angle=1.4, **p),
        dict(lean=-0.5, front_arm=2.0, rear_arm=1.7, staff_angle=1.6, hip_y=124, **p),
    ]
    jump = [
        dict(hip_y=114, front_foot=12, rear_foot=-10, staff_angle=0.6, **p),
        dict(hip_y=108, front_foot=6, rear_foot=-4, staff_angle=0.55, **p),
        dict(hip_y=114, front_foot=14, rear_foot=-12, staff_angle=0.6, **p),
    ]
    crouch = [dict(hip_y=148, front_foot=28, rear_foot=-22, staff_angle=0.7, **p),
              dict(hip_y=150, front_foot=28, rear_foot=-22, staff_angle=0.7, **p)]
    knockdown = [
        dict(lean=-0.8, hip_y=142, front_arm=2.2, rear_arm=1.9),
        dict(lying=1.0),
        dict(lying=1.0),
    ]
    return {
        "idle": (8, idle),
        "walk": (9, walk),
        "patta": (20, patta),
        "low_patta": (18, low_patta),
        "chhed": (16, chhed),
        "vita": (14, vita),
        "ex_vita": (16, vita),
        "super_vaadal": (16, spin + spin[:3] + [chhed[2]] * 2),
        "air_patta": (15, air),
        "hit": (12, hit),
        "jump": (8, jump),
        "crouch": (8, crouch),
        "knockdown": (10, knockdown),
    }


def parikhanda_animations() -> dict:
    """Bihar Pari-Khanda: balanced khanda sword + pari shield."""
    k = {"staff_len": 82.0, "shield": True}
    idle = [dict(hip_y=118 + bob, staff_angle=1.1, front_arm=-0.55, rear_arm=-2.5, **k)
            for bob in (0, 2, 3, 2)]
    walk = [
        dict(
            hip_y=116 + (2 if i % 3 == 0 else 0),
            front_foot=lerp(28, -6, (i % 3) / 2.0),
            rear_foot=lerp(-24, 8, (i % 3) / 2.0),
            staff_angle=1.1, rear_arm=-2.5, **k,
        )
        for i in range(6)
    ]
    slash = [
        dict(staff_angle=1.8, front_arm=1.5, rear_arm=-2.5, lean=-0.15, **k),
        dict(staff_angle=0.7, front_arm=0.5, rear_arm=-2.5, lean=0.15, staff_offset=8, **k),
        dict(staff_angle=-0.15, front_arm=-0.15, rear_arm=-2.5, lean=0.3, staff_offset=12, **k),
        dict(staff_angle=0.4, front_arm=-0.3, rear_arm=-2.5, lean=0.1, **k),
    ]
    low_slash = [dict(**{**q, "hip_y": 150}) for q in slash]
    bash = [
        dict(staff_angle=1.3, front_arm=-2.8, rear_arm=-0.6, lean=-0.2, **k),
        dict(staff_angle=1.3, front_arm=-3.0, rear_arm=-0.3, lean=0.15, **k),
        dict(staff_angle=1.3, front_arm=-3.1, rear_arm=-0.1, lean=0.4, front_foot=36, **k),
        dict(staff_angle=1.3, front_arm=-2.9, rear_arm=-0.4, lean=0.15, **k),
    ]
    overhead = [
        dict(staff_angle=2.2, front_arm=1.9, rear_arm=-2.5, lean=-0.25, **k),
        dict(staff_angle=1.6, front_arm=1.3, rear_arm=-2.5, lean=0.0, **k),
        dict(staff_angle=0.35, front_arm=0.2, rear_arm=-2.5, lean=0.4, staff_offset=12, **k),
        dict(staff_angle=-0.4, front_arm=-0.45, rear_arm=-2.5, lean=0.5, staff_offset=14, **k),
    ]
    spin = [dict(staff_angle=i * math.tau / 6, front_arm=i * math.tau / 6, rear_arm=-2.5,
                 lean=0.1, **k) for i in range(6)]
    air = [
        dict(hip_y=110, front_foot=10, rear_foot=-8, staff_angle=-0.7, front_arm=-0.7,
             rear_arm=-2.5, **k),
        dict(hip_y=110, front_foot=12, rear_foot=-6, staff_angle=-0.9, front_arm=-0.9,
             rear_arm=-2.5, staff_offset=8, **k),
        dict(hip_y=110, front_foot=12, rear_foot=-6, staff_angle=-0.9, front_arm=-0.9,
             rear_arm=-2.5, staff_offset=10, **k),
    ]
    hit = [
        dict(lean=-0.45, front_arm=1.8, rear_arm=1.4, staff_angle=1.5, **k),
        dict(lean=-0.6, front_arm=2.0, rear_arm=1.7, staff_angle=1.7, hip_y=122, **k),
    ]
    jump = [
        dict(hip_y=112, front_foot=12, rear_foot=-10, staff_angle=1.2, rear_arm=-2.5, **k),
        dict(hip_y=104, front_foot=6, rear_foot=-4, staff_angle=1.15, rear_arm=-2.5, **k),
        dict(hip_y=112, front_foot=14, rear_foot=-12, staff_angle=1.2, rear_arm=-2.5, **k),
    ]
    crouch = [dict(hip_y=146, front_foot=30, rear_foot=-24, staff_angle=1.2, rear_arm=-2.5, **k),
              dict(hip_y=148, front_foot=30, rear_foot=-24, staff_angle=1.2, rear_arm=-2.5, **k)]
    knockdown = [
        dict(lean=-0.8, hip_y=140, front_arm=2.2, rear_arm=1.9),
        dict(lying=1.0),
        dict(lying=1.0),
    ]
    return {
        "idle": (8, idle),
        "walk": (10, walk),
        "slash": (20, slash),
        "low_slash": (18, low_slash),
        "bash": (18, bash),
        "overhead": (16, overhead),
        "ex_overhead": (18, overhead),
        "super_vijay": (16, spin + spin[:3] + [overhead[3]] * 2),
        "air_slash": (15, air),
        "hit": (12, hit),
        "jump": (8, jump),
        "crouch": (8, crouch),
        "knockdown": (10, knockdown),
    }


def musti_animations() -> dict:
    """Varanasi Musti Yuddha: unarmed brawler — no weapon, fists do the work."""
    idle = [dict(hip_y=119 + bob, front_arm=-0.4, rear_arm=-2.7) for bob in (0, 1, 2, 1)]
    walk = [
        dict(
            hip_y=117 + (2 if i % 3 == 0 else 0),
            front_foot=lerp(28, -4, (i % 3) / 2.0),
            rear_foot=lerp(-24, 6, (i % 3) / 2.0),
            front_arm=-0.4, rear_arm=-2.7,
        )
        for i in range(6)
    ]
    jab = [
        dict(front_arm=-0.35, rear_arm=-2.7),
        dict(front_arm=-0.05, rear_arm=-2.7, lean=0.25),
        dict(front_arm=0.0, rear_arm=-2.7, lean=0.35),
        dict(front_arm=-0.3, rear_arm=-2.7, lean=0.1),
    ]
    low_palm = [dict(**{**p, "hip_y": 150}) for p in jab]
    cross = [
        dict(front_arm=-0.5, rear_arm=-2.9, lean=-0.2),
        dict(front_arm=-1.0, rear_arm=-1.2, lean=0.1),
        dict(front_arm=-1.4, rear_arm=0.05, lean=0.45),
        dict(front_arm=-1.2, rear_arm=0.0, lean=0.5),
        dict(front_arm=-0.8, rear_arm=-1.6, lean=0.2),
    ]
    rising = [
        dict(hip_y=140, front_arm=-1.0, rear_arm=-2.5, lean=0.1),
        dict(hip_y=118, front_arm=1.35, rear_arm=-2.6, lean=0.05),
        dict(hip_y=106, front_arm=1.55, rear_arm=-2.7, lean=-0.05, front_foot=8, rear_foot=-6),
        dict(hip_y=112, front_arm=1.5, rear_arm=-2.7, lean=0.0),
    ]
    elbow = [
        dict(hip_y=110, front_foot=10, rear_foot=-8, front_arm=-0.9, rear_arm=-2.6),
        dict(hip_y=110, front_foot=12, rear_foot=-6, front_arm=-1.2, rear_arm=-2.6, lean=0.2),
        dict(hip_y=110, front_foot=12, rear_foot=-6, front_arm=-1.25, rear_arm=-2.6, lean=0.25),
    ]
    flurry = [
        dict(front_arm=0.0, rear_arm=-2.7, lean=0.35),
        dict(front_arm=-1.3, rear_arm=0.05, lean=0.4),
        dict(front_arm=0.05, rear_arm=-2.6, lean=0.35),
        dict(front_arm=-1.35, rear_arm=0.0, lean=0.45),
        dict(front_arm=0.0, rear_arm=-2.7, lean=0.4),
        dict(front_arm=-1.4, rear_arm=0.05, lean=0.5),
    ]
    hit = [
        dict(lean=-0.45, front_arm=1.8, rear_arm=1.4),
        dict(lean=-0.6, front_arm=2.0, rear_arm=1.7, hip_y=122),
    ]
    jump = [
        dict(hip_y=113, front_foot=12, rear_foot=-10, front_arm=-0.5, rear_arm=-2.7),
        dict(hip_y=106, front_foot=6, rear_foot=-4, front_arm=-0.5, rear_arm=-2.7),
        dict(hip_y=113, front_foot=14, rear_foot=-12, front_arm=-0.5, rear_arm=-2.7),
    ]
    crouch = [
        dict(hip_y=147, front_foot=28, rear_foot=-22, front_arm=-0.5, rear_arm=-2.7),
        dict(hip_y=149, front_foot=28, rear_foot=-22, front_arm=-0.5, rear_arm=-2.7),
    ]
    knockdown = [
        dict(lean=-0.8, hip_y=141, front_arm=2.2, rear_arm=1.9),
        dict(lying=1.0),
        dict(lying=1.0),
    ]
    return {
        "idle": (8, idle),
        "walk": (10, walk),
        "jab": (20, jab),
        "low_palm": (18, low_palm),
        "cross": (16, cross),
        "rising_musti": (16, rising),
        "ex_rising_musti": (18, rising),
        "super_kashi": (18, flurry + [cross[3]] * 2),
        "air_elbow": (15, elbow),
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
    write_strips("varanasi_musti", musti_animations())
    write_strips("tamilnadu_silambam", silambar_animations())
    write_strips("punjab_gatka", gatka_animations())
    write_strips("kerala_kalari", kalari_animations())
    write_strips("manipur_thangta", thangta_animations())
    write_strips("maharashtra_mardani", mardani_animations())
    write_strips("bihar_parikhanda", parikhanda_animations())
