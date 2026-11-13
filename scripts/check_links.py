#!/usr/bin/env python3
"""Fail if a relative markdown link points at a file that does not exist.

Anchors and external URLs are skipped: the first would need a renderer, the
second would make CI depend on the internet. The links that break in practice
are the relative ones to files that moved.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LINK = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
SKIP_DIRS = {".venv", "dbt_packages", "target", "logs", "node_modules", ".git", "edr_target"}


def main() -> int:
    broken: list[tuple[Path, str]] = []
    checked = 0
    for md in ROOT.rglob("*.md"):
        if SKIP_DIRS & set(md.relative_to(ROOT).parts):
            continue
        text = md.read_text(errors="replace")
        for target in LINK.findall(text):
            target = target.strip()
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            path_part = target.split("#", 1)[0]
            if not path_part:
                continue
            checked += 1
            resolved = (md.parent / path_part).resolve()
            if not resolved.exists():
                broken.append((md.relative_to(ROOT), target))

    if broken:
        print("broken relative links:", file=sys.stderr)
        for md, target in broken:
            print(f"  {md}: {target}", file=sys.stderr)
        return 1
    print(f"ok  links: {checked} relative link(s) resolve")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
