#!/usr/bin/env python3
"""Validate product-page assets, structure, and diagram references."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


def validate_product_page(root: Path) -> list[str]:
    errors: list[str] = []
    page = root / "product-page" / "index.html"
    if not page.is_file():
        return [f"missing {page.relative_to(root)}"]

    content = page.read_text(encoding="utf-8")

    # Check for linked static assets
    for asset in ("common.css", "common.js"):
        asset_path = root / "product-page" / asset
        if not asset_path.is_file():
            errors.append(f"missing asset: {asset_path.relative_to(root)}")

    # Check data-mmd diagram references exist on disk
    mmd_matches = re.findall(r'data-mmd=["\']([^"\']+)["\']', content)
    if not mmd_matches:
        errors.append("no data-mmd diagram attributes found in index.html")
    for mmd_rel in mmd_matches:
        diagram_path = root / mmd_rel
        if not diagram_path.is_file():
            errors.append(f"referenced diagram file not found: {mmd_rel}")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate product page integrity.")
    parser.add_argument("--root", default=".", help="Repository root path")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    errors = validate_product_page(root)
    if errors:
        for err in errors:
            print(f"[FAIL] {err}", file=sys.stderr)
        return 1

    print("[PASS] Product page structure and referenced diagrams are valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
