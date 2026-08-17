#!/usr/bin/env python3
"""
Regenerate the script tables in README.md from the repository itself.

The README is the published surface of this repo, and it used to be maintained by
hand -- so scripts were missing from it, and some documented `curl ... | sh` lines
piped a bash script into sh. This script derives every table from the files on
disk instead, so adding a script is all that is needed to have it documented.

Everything between the AUTOGEN markers is replaced. Anything outside them is
hand-written and is left alone.

Usage:
    python scripts/generate_readme.py          # rewrite README.md in place
    python scripts/generate_readme.py --check  # exit 1 if README.md is stale
"""

from __future__ import annotations

import argparse
import sys
import urllib.parse
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
README = REPO_ROOT / "README.md"

RAW_BASE = "https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main"

BEGIN = "<!-- BEGIN:AUTOGEN-SCRIPTS -->"
END = "<!-- END:AUTOGEN-SCRIPTS -->"

# Directories the generator never walks into.
#   archive/     - superseded scripts, kept only for history
#   SentinelOps/ - agent distribution; real endpoints fetch these paths as
#                  SYSTEM/root, it has its own README and must not be reshuffled
SKIP_DIRS = {".git", ".github", "archive", "SentinelOps", "scripts", "node_modules"}

SCRIPT_SUFFIXES = {".sh", ".ps1", ".py"}

# Section order and headings. Each entry: (path prefix, tab, heading, icon)
SECTIONS = [
    ("Windows", "standard", "Windows", "🪟"),
    ("Linux", "standard", "Linux", "🐧"),
    ("macOS", "standard", "macOS", "🍎"),
    ("DockerFiles", "standard", "Docker", "🐳"),
    ("Intune", "intune", "macOS", "🍎"),
]


def is_stub(text: str) -> bool:
    """Redirect stubs left at old paths are documentation noise, not scripts."""
    return "# lazy-code-stub: true" in text


def read_header(path: Path) -> tuple[str | None, str]:
    """Return (description, interpreter) parsed from the file's own header."""
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None, "bash"

    if is_stub(text):
        return None, "bash"

    description = None
    interpreter = "bash"

    lines = text.splitlines()

    # Interpreter comes from the shebang, so the documented pipe target always
    # matches what the script actually expects.
    if lines and lines[0].startswith("#!"):
        shebang = lines[0]
        for candidate in ("zsh", "bash", "sh"):
            if candidate in shebang:
                interpreter = candidate
                break

    if path.suffix == ".py":
        interpreter = "python3"
    elif path.suffix == ".ps1":
        interpreter = "powershell"

    for line in lines[:20]:
        stripped = line.strip()
        if stripped.startswith("# Description:"):
            description = stripped.split(":", 1)[1].strip()
            break

    return description, interpreter


def humanise(path: Path) -> str:
    """Fallback label when a script has no Description header yet."""
    name = path.stem
    for prefix in ("install-", "install_", "uninstall-", "setup-"):
        if name.startswith(prefix):
            name = name[len(prefix):]
            break
    return name.replace("-", " ").replace("_", " ").strip().capitalize()


def collect() -> dict[str, list[dict]]:
    """Walk the repo and bucket every real script under its section heading."""
    found: dict[str, list[dict]] = {}

    for path in sorted(REPO_ROOT.rglob("*")):
        if not path.is_file() or path.suffix not in SCRIPT_SUFFIXES:
            continue

        rel = path.relative_to(REPO_ROOT)
        if any(part in SKIP_DIRS for part in rel.parts):
            continue

        text = path.read_text(encoding="utf-8", errors="replace")
        if is_stub(text):
            continue

        section = next(
            (s for s in SECTIONS if rel.parts and rel.parts[0] == s[0]),
            None,
        )
        if section is None:
            continue

        prefix, tab, heading, icon = section
        description, interpreter = read_header(path)

        found.setdefault(f"{tab}|{heading}|{icon}", []).append(
            {
                "path": rel.as_posix(),
                "description": description or humanise(path),
                "interpreter": interpreter,
                "name": path.name,
            }
        )

    return found


def render_entry(entry: dict) -> str:
    url = f"{RAW_BASE}/{urllib.parse.quote(entry['path'])}"
    interp = entry["interpreter"]

    if interp == "powershell":
        command = f"irm {url} | iex"
    elif interp == "python3":
        command = f"curl -fsSL {url} -o report.py && python3 report.py"
    else:
        command = f"curl -fsSL {url} | {interp}"

    return (
        f"**{entry['description']}**\n\n"
        f"`{entry['path']}`\n\n"
        "```bash\n"
        f"{command}\n"
        "```\n"
    )


def render(found: dict[str, list[dict]]) -> str:
    out: list[str] = [BEGIN, ""]

    total = sum(len(v) for v in found.values())
    out.append(f"> {total} scripts, generated automatically from the repository.")
    out.append("> Do not edit this section by hand - see [Adding a script](#adding-a-script).")
    out.append("")

    for tab, tab_title in (("standard", "Standard Scripts"), ("intune", "Intune Based Scripts")):
        keys = [k for k in found if k.startswith(f"{tab}|")]
        if not keys:
            continue

        tab_count = sum(len(found[k]) for k in keys)
        out.append(f"<details open>")
        out.append(f"<summary><h3>&nbsp;{tab_title} &nbsp;<code>{tab_count}</code></h3></summary>")
        out.append("")

        if tab == "intune":
            out.append(
                "Packaged for deployment through Microsoft Intune. These run as root "
                "in the Intune agent's context, not as the signed-in user."
            )
            out.append("")

        # keep SECTIONS order rather than dict order
        for prefix, s_tab, heading, icon in SECTIONS:
            key = f"{s_tab}|{heading}|{icon}"
            if s_tab != tab or key not in found:
                continue

            # Sort by path so subdirectory scripts group together at the end of
            # a section, rather than interleaving by basename.
            entries = sorted(found[key], key=lambda e: e["path"])
            out.append(f"<details>")
            out.append(f"<summary><b>{icon} {heading}</b> &nbsp;<code>{len(entries)}</code></summary>")
            out.append("")
            for entry in entries:
                out.append(render_entry(entry))
            out.append("</details>")
            out.append("")

        out.append("</details>")
        out.append("")

    # Platforms with no scripts yet still get a visible placeholder, so the
    # tab structure the repo promises is not silently missing.
    if not any(k.startswith("standard|Windows") for k in found):
        out.append("> **Windows:** no standard scripts yet. Drop a `.ps1` into `Windows/`")
        out.append("> with a `# Description:` line and it will appear here automatically.")
        out.append("")

    out.append(END)
    return "\n".join(out)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="exit 1 if README is stale")
    args = parser.parse_args()

    if not README.exists():
        print("README.md not found", file=sys.stderr)
        return 1

    current = README.read_text(encoding="utf-8")

    if BEGIN not in current or END not in current:
        print(f"Markers {BEGIN} / {END} not found in README.md", file=sys.stderr)
        return 1

    head, _, rest = current.partition(BEGIN)
    _, _, tail = rest.partition(END)

    updated = head + render(collect()) + tail

    if args.check:
        if updated != current:
            print("README.md is out of date - run: python scripts/generate_readme.py")
            return 1
        print("README.md is up to date.")
        return 0

    if updated == current:
        print("README.md already up to date.")
        return 0

    README.write_text(updated, encoding="utf-8", newline="\n")
    print("README.md regenerated.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
