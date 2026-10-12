#!/usr/bin/env python3
"""Generates Still's app icon (light, dark, tinted) and the shield icon with Pillow.

Usage: python3 Scripts/generate_icons.py   (from the repository root)

App icon: warm paper background (#F7F6F3), a centered ink circle (#1B1F24) at 56% of
the width and an apricot dot (#FF9F7A) at 16% of the width. No text.
Dark: ink background, a slightly lighter ink circle and the apricot dot.
Tinted: grayscale on black (iOS applies the tint).
"""
import json
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SUPERSAMPLE = 4


def hex_rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def circle(draw, center, diameter, color):
    r = diameter / 2
    draw.ellipse([center - r, center - r, center + r, center + r], fill=color)


def render(size, background, layers, transparent=False):
    """layers: list of (diameter_fraction, color)."""
    big = size * SUPERSAMPLE
    mode = "RGBA" if transparent else "RGB"
    bg = (0, 0, 0, 0) if transparent else hex_rgb(background)
    image = Image.new(mode, (big, big), bg)
    draw = ImageDraw.Draw(image)
    for fraction, color in layers:
        rgb = hex_rgb(color)
        circle(draw, big / 2, big * fraction, rgb + ((255,) if transparent else ()))
    return image.resize((size, size), Image.LANCZOS)


def write_json(path, payload):
    with open(path, "w") as f:
        json.dump(payload, f, indent=2)
        f.write("\n")


def app_icons():
    folder = os.path.join(ROOT, "Still/Resources/Assets.xcassets/AppIcon.appiconset")
    os.makedirs(folder, exist_ok=True)
    render(1024, "#F7F6F3", [(0.56, "#1B1F24"), (0.16, "#FF9F7A")]).save(os.path.join(folder, "AppIcon.png"))
    render(1024, "#1B1F24", [(0.56, "#2E3540"), (0.16, "#FF9F7A")]).save(os.path.join(folder, "AppIcon-Dark.png"))
    render(1024, "#000000", [(0.56, "#3C3C3C"), (0.16, "#FFFFFF")]).save(os.path.join(folder, "AppIcon-Tinted.png"))
    write_json(os.path.join(folder, "Contents.json"), {
        "images": [
            {"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
            {
                "appearances": [{"appearance": "luminosity", "value": "dark"}],
                "filename": "AppIcon-Dark.png", "idiom": "universal", "platform": "ios", "size": "1024x1024",
            },
            {
                "appearances": [{"appearance": "luminosity", "value": "tinted"}],
                "filename": "AppIcon-Tinted.png", "idiom": "universal", "platform": "ios", "size": "1024x1024",
            },
        ],
        "info": {"author": "xcode", "version": 1},
    })
    # A copy for App Store Connect / the README.
    os.makedirs(os.path.join(ROOT, "AppStore"), exist_ok=True)
    render(1024, "#F7F6F3", [(0.56, "#1B1F24"), (0.16, "#FF9F7A")]).save(os.path.join(ROOT, "AppStore/AppIcon-1024.png"))


def shield_icon():
    """The shield's logo: halo ring, 1 px border, ink circle and apricot dot (116 pt)."""
    folder = os.path.join(ROOT, "StillShieldConfig/Assets.xcassets/ShieldIcon.imageset")
    os.makedirs(folder, exist_ok=True)
    variants = {
        "light": ("#EFEDE8", "#E7E5DF", "#1B1F24"),
        "dark": ("#252930", "#2C3037", "#2E3540"),
    }
    images = []
    for appearance, (halo, border, ink) in variants.items():
        for scale in (2, 3):
            size = 116 * scale
            name = f"ShieldIcon-{appearance}@{scale}x.png"
            render(size, "#000000", [
                (1.0, halo), (98 / 116, border), (96 / 116, ink), (20 / 116, "#FF9F7A"),
            ], transparent=True).save(os.path.join(folder, name))
            entry = {"filename": name, "idiom": "universal", "scale": f"{scale}x"}
            if appearance == "dark":
                entry["appearances"] = [{"appearance": "luminosity", "value": "dark"}]
            images.append(entry)
    write_json(os.path.join(folder, "Contents.json"), {"images": images, "info": {"author": "xcode", "version": 1}})
    write_json(os.path.join(ROOT, "StillShieldConfig/Assets.xcassets/Contents.json"), {"info": {"author": "xcode", "version": 1}})


if __name__ == "__main__":
    app_icons()
    shield_icon()
    print("Icons written.")
