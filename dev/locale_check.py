"""Check MapSearch's translations against the English keys the code uses.

Run from the addon root: python dev/locale_check.py .   (exit 0 = clean)

Keys are collected from T["..."] and the `other` form of Locale.Plural{...} in the
addon's Lua files. Every Locale/<code>.lua must translate exactly those keys, each
translation must keep its key's format slots (or positional %n$ equivalents) and
|-escapes, and the .toc must load every locale file behind its AllowLoadTextLocale.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

LOCALES = ["deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW"]
PLURAL_FORMS = {"one", "few", "many", "other"}
STRING = r'"((?:[^"\\]|\\.)*)"'
SLOT = re.compile(r"%(?:(\d+)\$)?[-+ #0]*\d*(?:\.\d+)?([cdiouxXeEfgGqs])|%%")
ESCAPE = re.compile(r"\|c[0-9a-fA-F]{8}|\|[rn]|\|T.*?\|t|\|H.*?\|h|\|\|")


def unescape(s: str) -> str:
    return bytes(s, "utf-8").decode("unicode_escape").encode("latin-1").decode("utf-8")


def slots(s: str) -> list[tuple[int | None, str]]:
    return [(int(m[1]) if m[1] else None, m[2]) for m in SLOT.finditer(s) if m[2]]


def escapes(s: str) -> list[str]:
    return sorted(ESCAPE.findall(s))


def form_ok(key: str, form: str, plural: bool) -> str | None:
    k, f = slots(key), slots(form)
    if escapes(key) != escapes(form):
        return "escape mismatch"
    if any(i is not None for i, _ in f):
        for i, conv in f:
            if i is None or i > len(k) or k[i - 1][1] != conv:
                return "slot mismatch"
        return None
    if len(f) > len(k) or (not plural and len(f) != len(k)):
        return "slot count mismatch"
    if any(fc != kc for (_, fc), (_, kc) in zip(f, k)):
        return "slot type mismatch"
    return None


def code_keys(root: Path) -> set[str]:
    keys: set[str] = set()
    for path in root.glob("*.lua"):
        # Drop line comments (usage examples live there); no key contains "--".
        text = re.sub(r"--[^\n]*", "", path.read_text(encoding="utf-8"))
        keys.update(unescape(m) for m in re.findall(r"T\[" + STRING + r"\]", text))
        for block in re.findall(r"Locale\.Plural\(\{(.*?)\}\)", text, re.S):
            other = re.search(r"other\s*=\s*" + STRING, block)
            if other:
                keys.add(unescape(other[1]))
    return keys


def locale_entries(path: Path) -> dict[str, object]:
    text = path.read_text(encoding="utf-8")
    entries: dict[str, object] = {}
    for m in re.finditer(r"\[" + STRING + r"\]\s*=\s*(\{.*?\}|" + STRING + r")\s*,", text, re.S):
        key, value = unescape(m[1]), m[2]
        if value.startswith("{"):
            entries[key] = {n: unescape(v) for n, v in re.findall(r"(\w+)\s*=\s*" + STRING, value)}
        else:
            entries[key] = unescape(m[3])
    return entries


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    keys = code_keys(root)
    toc = (root / "HandyNotes_MapSearch.toc").read_text(encoding="utf-8")
    problems: list[str] = []
    for code in LOCALES:
        path = root / "Locale" / f"{code}.lua"
        if f"Locale\\{code}.lua [AllowLoadTextLocale {code}]" not in toc:
            problems.append(f"{code}: not loaded by the .toc")
        if not path.exists():
            problems.append(f"{code}: missing file")
            continue
        if f'Register("{code}"' not in path.read_text(encoding="utf-8"):
            problems.append(f"{code}: does not register as {code}")
        entries = locale_entries(path)
        for key in sorted(keys - entries.keys()):
            problems.append(f"{code}: missing {key!r}")
        for key in sorted(entries.keys() - keys):
            problems.append(f"{code}: unused {key!r}")
        for key, value in entries.items():
            if isinstance(value, dict):
                if "other" not in value or set(value) - PLURAL_FORMS:
                    problems.append(f"{code}: bad plural forms for {key!r}")
                for form in value.values():
                    why = form_ok(key, form, True)
                    if why:
                        problems.append(f"{code}: {why} in {key!r}")
            else:
                why = form_ok(key, value, False)
                if why:
                    problems.append(f"{code}: {why} in {key!r}")
    for p in problems:
        print(p)
    print(f"{len(keys)} keys, {len(LOCALES)} locales, {len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
