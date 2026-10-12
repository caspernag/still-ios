#!/usr/bin/env python3
"""Prints the UDID of an available simulator whose name matches a regex.

Usage: pick_simulator.py "<name regex>" [preferred iOS version, e.g. 26.2]
Prefers the given iOS runtime, then the newest runtime with a matching device.
"""
import json, re, subprocess, sys

pattern = re.compile(sys.argv[1])
preferred = sys.argv[2] if len(sys.argv) > 2 else None
data = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"]))

candidates = []
for runtime, devices in data["devices"].items():
    m = re.search(r"iOS-(\d+)-(\d+)", runtime)
    if not m:
        continue
    version = (int(m.group(1)), int(m.group(2)))
    for device in devices:
        if pattern.search(device["name"]):
            candidates.append((version, device["name"], device["udid"]))

if not candidates:
    sys.exit("No simulator matches " + sys.argv[1])
if preferred:
    want = tuple(int(x) for x in preferred.split("."))
    exact = [c for c in candidates if c[0] == want]
    if exact:
        candidates = exact
candidates.sort(reverse=True)
version, name, udid = candidates[0]
print(f"{name} (iOS {version[0]}.{version[1]})", file=sys.stderr)
print(udid)
