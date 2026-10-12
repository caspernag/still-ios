#!/usr/bin/env python3
"""Lists user-facing string literals in Swift sources and checks them against the String Catalogs.

Usage: python3 Scripts/strings_audit.py [--list]
Exit code 1 if a literal used as UI text has no entry (with an nb translation) in its target's catalog.
"""
import json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Source folder -> catalogs whose bundle resolves its strings at runtime.
TARGETS = {
    "Still": ["Still/Resources/Localizable.xcstrings"],
    "StillKit/Sources/DesignSystem": ["Still/Resources/Localizable.xcstrings", "StillWidgets/Localizable.xcstrings"],
    "StillWidgets": ["StillWidgets/Localizable.xcstrings"],
    "StillShieldConfig": ["StillShieldConfig/Localizable.xcstrings"],
}
# Calls whose string-literal arguments are localized (LocalizedStringKey / LocalizationValue).
PATTERNS = [
    r'(?<![A-Za-z])Text\(\s*"((?:[^"\\]|\\.)*)"',
    r'String\(localized:\s*"((?:[^"\\]|\\.)*)"',
    r'LocalizedStringKey\(\s*"((?:[^"\\]|\\.)*)"',
    r'(?:StatusPill|HoldButton|StillSectionHeader|StillBadge|section|linkRow)\(\s*"((?:[^"\\]|\\.)*)"',
    r'step\(\d+,\s*"((?:[^"\\]|\\.)*)"',
    r'feature\("[^"]*",\s*"((?:[^"\\]|\\.)*)"',
    r'accessibilityLabel:\s*"((?:[^"\\]|\\.)*)"',
    r'title:\s*"((?:[^"\\]|\\.)*)",\s*\n?\s*subtitle',
    r'(?<![A-Za-z])Label\(\s*"((?:[^"\\]|\\.)*)"',
    r'Button\(\s*"((?:[^"\\]|\\.)*)"',
    r'\.value\(\s*"((?:[^"\\]|\\.)*)"',
]

def normalize(s):
    s = re.sub(r'\\\((?:[^()]|\([^()]*\))*\)', '%', s)   # \(expr) -> %
    s = re.sub(r'%(?:lld|ld|d|@|f|\.\d+f|\d+\$@|\d+\$lld)', '%', s)
    return s.replace('\\n', '\n').replace('\\"', '"')

def catalog_keys(path):
    full = os.path.join(ROOT, path)
    if not os.path.exists(full):
        return {}
    data = json.load(open(full))
    out = {}
    for key, entry in data["strings"].items():
        nb = entry.get("localizations", {}).get("nb")
        out[normalize(key)] = nb is not None
    return out

def literals(folder):
    found = {}
    for dirpath, _, files in os.walk(os.path.join(ROOT, folder)):
        for name in files:
            if not name.endswith(".swift"):
                continue
            path = os.path.join(dirpath, name)
            text = open(path).read()
            for pattern in PATTERNS:
                for m in re.finditer(pattern, text):
                    literal = m.group(1)
                    if not literal.strip() or literal.startswith("verbatim"):
                        continue
                    line = text[:m.start()].count("\n") + 1
                    found.setdefault(normalize(literal), []).append(f"{os.path.relpath(path, ROOT)}:{line}")
    return found

def main():
    missing = 0
    listing = "--list" in sys.argv
    for folder, catalogs in TARGETS.items():
        lits = literals(folder)
        for catalog in catalogs:
            keys = catalog_keys(catalog)
            for lit, where in sorted(lits.items()):
                if listing:
                    print(f"{folder}\t{catalog}\t{lit!r}\t{where[0]}")
                    continue
                if lit not in keys:
                    print(f"MISSING in {catalog}: {lit!r}  ({where[0]})")
                    missing += 1
                elif not keys[lit]:
                    print(f"NO nb TRANSLATION in {catalog}: {lit!r}")
                    missing += 1
    if not listing:
        print("OK: every UI string has an nb translation." if missing == 0 else f"{missing} problem(s).")
    sys.exit(1 if missing else 0)

if __name__ == "__main__":
    main()
