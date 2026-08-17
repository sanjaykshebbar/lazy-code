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
import html
import json
import sys
import urllib.parse
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
README = REPO_ROOT / "README.md"
DOCS_HTML = REPO_ROOT / "docs" / "index.html"

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
    """One table row per script.

    Rows rather than stacked blocks: 39 scripts as blocks ran to ~9 lines each,
    which is unreadable and made Ctrl+F results hard to place.
    """
    url = f"{RAW_BASE}/{urllib.parse.quote(entry['path'])}"
    interp = entry["interpreter"]

    if interp == "powershell":
        command = f"irm {url} | iex"
    elif interp == "python3":
        command = f"curl -fsSL {url} -o report.py && python3 report.py"
    else:
        command = f"curl -fsSL {url} | {interp}"

    # A literal pipe would end the table cell.
    command = command.replace("|", "\\|")

    name = Path(entry["path"]).name
    return (
        f"| [`{name}`]({urllib.parse.quote(entry['path'])}) "
        f"| {entry['description']} "
        f"| `{command}` |"
    )


def render(found: dict[str, list[dict]]) -> str:
    out: list[str] = [BEGIN, ""]

    total = sum(len(v) for v in found.values())
    out.append(f"> **{total} scripts.** Press <kbd>Ctrl</kbd>+<kbd>F</kbd> "
               "(<kbd>⌘</kbd>+<kbd>F</kbd> on macOS) to search this page - every "
               "section below is expanded by default so find-in-page reaches it.")
    out.append(">")
    out.append("> This section is generated. Do not edit it by hand - "
               "see [Adding a script](#adding-a-script).")
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

            # `open` matters for more than tidiness: Firefox and Safari will not
            # find text inside a collapsed <details>, so leaving these shut would
            # silently break Ctrl+F for most of the page.
            out.append("<details open>")
            out.append(f"<summary><b>{icon} {heading}</b> &nbsp;<code>{len(entries)}</code></summary>")
            out.append("")
            out.append("| Script | What it does | Install |")
            out.append("|:--|:--|:--|")
            for entry in entries:
                out.append(render_entry(entry))
            out.append("")
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


def build_command(entry: dict) -> str:
    """The runnable one-liner for a script, unescaped."""
    url = f"{RAW_BASE}/{urllib.parse.quote(entry['path'])}"
    interp = entry["interpreter"]
    if interp == "powershell":
        return f"irm {url} | iex"
    if interp == "python3":
        return f"curl -fsSL {url} -o report.py && python3 report.py"
    return f"curl -fsSL {url} | {interp}"


HTML_TEMPLATE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Lazy Code - script search</title>
<style>
  :root {
    --bg:#ffffff; --fg:#1f2328; --muted:#59636e; --line:#d1d9e0;
    --card:#f6f8fa; --accent:#0969da; --code:#f6f8fa; --hit:#fff8c5;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg:#0d1117; --fg:#e6edf3; --muted:#9198a1; --line:#3d444d;
      --card:#151b23; --accent:#4493f8; --code:#151b23; --hit:#3f2e00;
    }
  }
  * { box-sizing:border-box; }
  body {
    margin:0; padding:2rem 1rem 4rem; background:var(--bg); color:var(--fg);
    font:16px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;
  }
  .wrap { max-width:1000px; margin:0 auto; }
  h1 { font-size:1.6rem; margin:0 0 .25rem; }
  .sub { color:var(--muted); margin:0 0 1.5rem; }
  .sub a { color:var(--accent); }
  .searchbar { position:sticky; top:0; background:var(--bg); padding:.75rem 0 1rem; z-index:5; }
  input[type=search] {
    width:100%; padding:.7rem .9rem; font-size:1rem; color:var(--fg);
    background:var(--card); border:1px solid var(--line); border-radius:8px;
  }
  input[type=search]:focus { outline:2px solid var(--accent); outline-offset:1px; }
  .count { color:var(--muted); font-size:.85rem; margin-top:.5rem; }
  h2 { font-size:1.05rem; margin:1.75rem 0 .6rem; padding-bottom:.3rem; border-bottom:1px solid var(--line); }
  .item { padding:.7rem 0; border-bottom:1px solid var(--line); }
  .top { display:flex; gap:.5rem; align-items:baseline; flex-wrap:wrap; }
  .name { font-weight:600; }
  .name a { color:var(--accent); text-decoration:none; }
  .name a:hover { text-decoration:underline; }
  .path { color:var(--muted); font-size:.8rem; font-family:ui-monospace,SFMono-Regular,Menlo,monospace; }
  .desc { color:var(--fg); margin:.15rem 0 .45rem; }
  .cmdrow { display:flex; gap:.5rem; align-items:stretch; }
  code.cmd {
    flex:1; display:block; background:var(--code); border:1px solid var(--line);
    border-radius:6px; padding:.45rem .6rem; font-size:.8rem; overflow-x:auto;
    white-space:pre; font-family:ui-monospace,SFMono-Regular,Menlo,monospace;
  }
  button.copy {
    border:1px solid var(--line); background:var(--card); color:var(--fg);
    border-radius:6px; padding:0 .7rem; cursor:pointer; font-size:.8rem; white-space:nowrap;
  }
  button.copy:hover { border-color:var(--accent); color:var(--accent); }
  mark { background:var(--hit); color:inherit; padding:0 .1em; border-radius:2px; }
  .empty { color:var(--muted); padding:2rem 0; }
  kbd {
    border:1px solid var(--line); border-bottom-width:2px; border-radius:4px;
    padding:0 .35em; font-size:.8em; background:var(--card);
  }
</style>
</head>
<body>
<div class="wrap">
  <h1>Lazy Code</h1>
  <p class="sub">__TOTAL__ setup scripts &middot;
    <a href="https://github.com/sanjaykshebbar/lazy-code">repository</a></p>

  <div class="searchbar">
    <input type="search" id="q" placeholder="Search by name, description or platform..."
           autocomplete="off" autofocus aria-label="Search scripts">
    <div class="count" id="count">Press <kbd>/</kbd> to focus &middot; <kbd>Esc</kbd> to clear</div>
  </div>

  <div id="results"></div>
</div>

<script>
const DATA = __DATA__;
const q = document.getElementById('q');
const results = document.getElementById('results');
const count = document.getElementById('count');

function esc(s) {
  return s.replace(/[&<>"']/g, c => (
    {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]
  ));
}

function mark(text, term) {
  const safe = esc(text);
  if (!term) return safe;
  // Escape regex metacharacters so a query like "c++" cannot throw.
  const re = new RegExp('(' + term.replace(/[.*+?^${}()|[\\]\\\\]/g, '\\\\$&') + ')', 'ig');
  return safe.replace(re, '<mark>$1</mark>');
}

function render() {
  const term = q.value.trim();
  const lower = term.toLowerCase();

  const hits = DATA.filter(d =>
    !lower ||
    d.name.toLowerCase().includes(lower) ||
    d.description.toLowerCase().includes(lower) ||
    d.platform.toLowerCase().includes(lower) ||
    d.path.toLowerCase().includes(lower)
  );

  count.textContent = term
    ? hits.length + ' of ' + DATA.length + ' scripts match "' + term + '"'
    : DATA.length + ' scripts';

  if (!hits.length) {
    results.innerHTML = '<p class="empty">No scripts match that search.</p>';
    return;
  }

  const groups = {};
  hits.forEach(d => (groups[d.group] = groups[d.group] || []).push(d));

  results.innerHTML = Object.keys(groups).map(g => (
    '<h2>' + esc(g) + ' <span class="path">' + groups[g].length + '</span></h2>' +
    groups[g].map(d =>
      '<div class="item">' +
        '<div class="top">' +
          '<span class="name"><a href="https://github.com/sanjaykshebbar/lazy-code/blob/main/' +
            encodeURI(d.path) + '">' + mark(d.name, term) + '</a></span>' +
          '<span class="path">' + mark(d.path, term) + '</span>' +
        '</div>' +
        '<div class="desc">' + mark(d.description, term) + '</div>' +
        '<div class="cmdrow">' +
          '<code class="cmd">' + esc(d.command) + '</code>' +
          '<button class="copy" data-cmd="' + esc(d.command) + '">Copy</button>' +
        '</div>' +
      '</div>'
    ).join('')
  )).join('');
}

results.addEventListener('click', e => {
  const btn = e.target.closest('button.copy');
  if (!btn) return;
  navigator.clipboard.writeText(btn.dataset.cmd).then(() => {
    const old = btn.textContent;
    btn.textContent = 'Copied';
    setTimeout(() => { btn.textContent = old; }, 1200);
  });
});

q.addEventListener('input', render);

document.addEventListener('keydown', e => {
  if (e.key === '/' && document.activeElement !== q) { e.preventDefault(); q.focus(); }
  if (e.key === 'Escape' && document.activeElement === q) { q.value = ''; render(); }
});

render();
</script>
</body>
</html>
"""


def render_html(found: dict[str, list[dict]]) -> str:
    """A standalone search page for GitHub Pages.

    A live search box cannot work inside README.md - GitHub strips <script> from
    rendered markdown - so the searchable view is published separately and
    linked from the README. Regenerated by the same command, from the same data.
    """
    tab_titles = {"standard": "Standard", "intune": "Intune"}
    records: list[dict] = []

    for prefix, tab, heading, icon in SECTIONS:
        key = f"{tab}|{heading}|{icon}"
        for entry in sorted(found.get(key, []), key=lambda e: e["path"]):
            records.append(
                {
                    "name": Path(entry["path"]).name,
                    "path": entry["path"],
                    "description": entry["description"],
                    "platform": heading,
                    "group": f"{icon} {tab_titles[tab]} - {heading}",
                    "command": build_command(entry),
                }
            )

    payload = json.dumps(records, indent=1).replace("</", "<\\/")

    return (
        HTML_TEMPLATE
        .replace("__DATA__", payload)
        .replace("__TOTAL__", str(len(records)))
    )


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

    found = collect()
    updated = head + render(found) + tail
    page = render_html(found)

    current_page = DOCS_HTML.read_text(encoding="utf-8") if DOCS_HTML.exists() else None

    if args.check:
        stale = []
        if updated != current:
            stale.append("README.md")
        if page != current_page:
            stale.append("docs/index.html")
        if stale:
            print(f"Out of date: {', '.join(stale)} - "
                  "run: python scripts/generate_readme.py")
            return 1
        print("README.md and docs/index.html are up to date.")
        return 0

    changed = []
    if updated != current:
        README.write_text(updated, encoding="utf-8", newline="\n")
        changed.append("README.md")
    if page != current_page:
        DOCS_HTML.parent.mkdir(parents=True, exist_ok=True)
        DOCS_HTML.write_text(page, encoding="utf-8", newline="\n")
        changed.append("docs/index.html")

    print(f"Regenerated: {', '.join(changed)}" if changed else "Already up to date.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
