#!/usr/bin/env python3
"""Add every 'literal'.tr string in lib/ to assets/l10n/en.json for Weblate.

Add-only: keyed strings and `variable.tr` can't be detected statically, so
entries that look unused may still be in use.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EN = ROOT / "assets/l10n/en.json"

STR = r"""r?'''[\s\S]*?'''|r?\"\"\"[\s\S]*?\"\"\"|r?'(?:[^'\\\n]|\\.)*'|r?"(?:[^"\\\n]|\\.)*\""""
# Comments and strings are consumed in order so quotes can't misalign.
TOKEN = re.compile(
    rf"//[^\n]*|/\*[\s\S]*?\*/|(?P<lits>(?:{STR})(?:\s*(?:{STR}))*)(?P<tr>\s*\.(?:tr|trParams|trPlural)\b)?"
)
PART = re.compile(STR)
# The settings registry stores plain strings (they also form stable IDs) and
# settings.dart translates them at display.
REGISTRY = ROOT / "lib/screens/settings/registry/settings_registry.dart"
REGISTRY_FIELD = re.compile(rf"\b(?:title|description|groupTitle|section|category)\s*:\s*({STR})")
ESCAPES = {"n": "\n", "t": "\t", "r": "\r"}


def decode(literal):
    """Return a Dart string literal's value, or None if it interpolates."""
    raw = literal.startswith("r")
    body = literal[1:] if raw else literal
    quote = 3 if body[:3] in ("'''", '"""') else 1
    body = body[quote:-quote]
    if raw:
        return body
    if re.search(r"(?<!\\)(?:\\\\)*\$", body):
        return None
    return re.sub(r"\\(.)", lambda m: ESCAPES.get(m[1], m[1]), body, flags=re.S)


def extract(source):
    """Yield (value, literal) for each .tr literal; value is None if dynamic."""
    for m in TOKEN.finditer(source):
        if m["tr"]:
            parts = [decode(p) for p in PART.findall(m["lits"])]
            yield (None if None in parts else "".join(parts)), m["lits"]


def main():
    en = json.loads(EN.read_text(encoding="utf-8"))
    new = set()
    for path in sorted((ROOT / "lib").rglob("*.dart")):
        for value, literal in extract(path.read_text(encoding="utf-8", errors="replace")):
            if value is None:
                print(f"::warning file={path.relative_to(ROOT).as_posix()}::"
                      f"Interpolated .tr can't be translated, use @param: {literal}")
            elif value and value not in en:
                new.add(value)
    for literal in REGISTRY_FIELD.findall(REGISTRY.read_text(encoding="utf-8")):
        value = decode(literal)
        if value and value not in en:
            new.add(value)
    if new:
        en.update((s, s) for s in sorted(new, key=str.lower))
        EN.write_text(json.dumps(en, ensure_ascii=False, indent=4) + "\n",
                      encoding="utf-8", newline="\n")
    print(f"Added {len(new)} strings to {EN.relative_to(ROOT).as_posix()}")


if __name__ == "__main__":
    main()
