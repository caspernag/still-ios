#!/usr/bin/env python3
"""Copies PNG attachments exported by `xcresulttool export attachments` to <out>/<attachment name>.png.

Usage: export_attachments.py <export dir with manifest.json> <out dir> [name prefix filter]
"""
import json, os, shutil, sys

raw, out = sys.argv[1], sys.argv[2]
prefixes = sys.argv[3:]
os.makedirs(out, exist_ok=True)
manifest = json.load(open(os.path.join(raw, "manifest.json")))
count = 0
for test in manifest:
    for attachment in test.get("attachments", []):
        name = attachment.get("suggestedHumanReadableName") or attachment["exportedFileName"]
        base = name.rsplit(".", 1)[0]
        # xcresulttool appends "_<index>_<uuid>"; keep the name we gave the attachment.
        parts = base.split("_")
        base = parts[0]
        if prefixes and not any(base.startswith(p) for p in prefixes):
            continue
        shutil.copy(os.path.join(raw, attachment["exportedFileName"]), os.path.join(out, base + ".png"))
        count += 1
print(f"Exported {count} screenshots to {out}")
