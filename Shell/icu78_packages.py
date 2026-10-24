#!/usr/bin/env python3

import os
import re
import sys
from collections import defaultdict

try:
    from elftools.elf.elffile import ELFFile
    from elftools.common.exceptions import ELFError
except ImportError:
    sys.exit(
        "ERROR: pyelftools is not installed.\n"
        "Install it with: python3 -m pip install pyelftools"
    )

CP = "/var/lib/custom-packages"
DIRECTORIES = ("/usr/bin", "/usr/lib", "/usr/libexec", "/opt/rustc/bin", "/opt/rustc/lib", "/opt/texlive/2026/bin/x86_64-linux", "/opt/texlive/2026/lib", "/opt/sage/bin", "/opt/sage/lib", "/opt/qt6/bin", "/opt/qt6/lib")
ICU_PATTERN = re.compile(r"^libicu.*\.so\.78$")


def load_inventories():
    """Build an absolute-path-to-package reverse index."""
    owners = defaultdict(set)

    try:
        entries = os.scandir(CP)
    except OSError as exc:
        sys.exit(f"ERROR: Cannot access {CP}: {exc}")

    with entries:
        for entry in entries:
            if not entry.is_file(follow_symlinks=False):
                continue

            package = entry.name

            try:
                with open(entry.path, "r", encoding="utf-8",
                          errors="replace") as inventory:
                    for line in inventory:
                        path = line.strip()

                        if path.startswith("/"):
                            owners[os.path.normpath(path)].add(package)

            except OSError as exc:
                print(
                    f"WARNING: Cannot read inventory {entry.path}: {exc}",
                    file=sys.stderr,
                )

    return owners


def has_direct_icu78_dependency(path):
    """Check ELF DT_NEEDED entries without invoking external programs."""
    try:
        with open(path, "rb") as stream:
            if stream.read(4) != b"\x7fELF":
                return False

            stream.seek(0)
            elf = ELFFile(stream)

            for section in elf.iter_sections():
                if section.header.sh_type != "SHT_DYNAMIC":
                    continue

                for tag in section.iter_tags():
                    if (
                        tag.entry.d_tag == "DT_NEEDED"
                        and ICU_PATTERN.fullmatch(tag.needed)
                    ):
                        return True

    except (OSError, ELFError, ValueError, KeyError):
        pass

    return False


def main():
    print(f"Reading package inventories from {CP}...", file=sys.stderr)
    owners = load_inventories()
    print(f"Indexed {len(owners)} installed paths.", file=sys.stderr)

    matches = 0

    packages_found = set()

    for directory in DIRECTORIES:
        for root, _, filenames in os.walk(directory):
            for filename in filenames:
                path = os.path.normpath(os.path.join(root, filename))

                if not has_direct_icu78_dependency(path):
                    continue

                packages_found.update(owners.get(path, ()))

    print(" ".join(sorted(packages_found)))

if __name__ == "__main__":
    main()
