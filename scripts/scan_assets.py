#!/usr/bin/env python3
"""Scan a FiveM resources folder and report which streamed assets are Gen8 (Legacy).

Enhanced rejects Legacy-format assets and fails the whole resource on the first bad
file, so this tells you exactly what Alchemist needs to process before a restart.

    python3 scan_assets.py /path/to/resources

Exit code 1 if anything needs converting or parking (.ycd), 0 if clean.
"""

import os
import struct
import sys
from collections import Counter, defaultdict

# RAGE container extensions worth inspecting.
EXTENSIONS = {".ytd", ".ydr", ".yft", ".ydd", ".ypt", ".ycd", ".ybn", ".ymap", ".ytyp"}

# Versions Enhanced accepts. Anything else of these types must be converted.
# Derived from Alchemist output: .ytd 13->5, .ydr 165->159.
GEN9_OK = {
    ".ytd": {5},
    ".ydr": {159},
    ".yft": {162, 171},
    ".ydd": {159, 165},
    ".ypt": {68},
    # Not version-gated by the server in practice.
    ".ybn": None,
    ".ymap": None,
    ".ytyp": None,
    # Cannot be converted by Alchemist at all.
    ".ycd": None,
}


def resource_of(relpath):
    """Best guess at the owning resource: the folder just above `stream/`."""
    parts = relpath.split(os.sep)
    for i, seg in enumerate(parts):
        if seg.lower() == "stream" and i > 0:
            return parts[i - 1]
    return parts[1] if len(parts) > 1 else parts[0]


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2

    root = os.path.abspath(sys.argv[1])
    if not os.path.isdir(root):
        print(f"Not a directory: {root}")
        return 2

    found = defaultdict(Counter)
    needs_work = defaultdict(Counter)
    unconvertible = defaultdict(Counter)
    total = 0

    for dirpath, _dirnames, filenames in os.walk(root):
        for name in filenames:
            ext = os.path.splitext(name)[1].lower()
            if ext not in EXTENSIONS:
                continue

            path = os.path.join(dirpath, name)
            resource = resource_of(os.path.relpath(path, root))
            total += 1

            try:
                with open(path, "rb") as handle:
                    header = handle.read(8)
            except OSError:
                found[resource]["UNREADABLE"] += 1
                continue

            if header[:4] not in (b"RSC7", b"RSC8") or len(header) < 8:
                found[resource][f"raw {ext}"] += 1
                continue

            version = struct.unpack("<I", header[4:8])[0]
            found[resource][f"{ext} v{version}"] += 1

            allowed = GEN9_OK.get(ext)
            if ext == ".ycd":
                unconvertible[resource][f"{ext} v{version}"] += 1
            elif allowed is not None and version not in allowed:
                needs_work[resource][f"{ext} v{version}"] += 1

    if not total:
        print(f"No streamed assets found under {root}")
        return 0

    print(f"Scanned {total} asset files under {root}\n")

    for resource in sorted(found):
        flag = ""
        if needs_work.get(resource):
            flag = "  <-- NEEDS CONVERSION"
        elif unconvertible.get(resource):
            flag = "  <-- CANNOT BE CONVERTED (.ycd)"
        print(f"{resource}{flag}")
        for kind, count in sorted(found[resource].items()):
            marker = ""
            if kind in needs_work.get(resource, {}):
                marker = "  *convert*"
            elif kind in unconvertible.get(resource, {}):
                marker = "  *no conversion path*"
            print(f"    {count:5d}  {kind}{marker}")
        print()

    if needs_work:
        print("Run Alchemist over these resources:")
        for resource in sorted(needs_work):
            print(f"  - {resource}")

    if unconvertible:
        print(
            "\nThese ship custom .ycd animations, which Alchemist passes through\n"
            "unchanged. They cannot start on Enhanced — park them in an unensured\n"
            "category folder such as resources/[disabled]/ :"
        )
        for resource in sorted(unconvertible):
            print(f"  - {resource}")

    if not needs_work and not unconvertible:
        print("Clean — every asset is already Gen9.")

    return 1 if (needs_work or unconvertible) else 0


if __name__ == "__main__":
    sys.exit(main())
