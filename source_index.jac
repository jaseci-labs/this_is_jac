"""This is Jac - source-index + syntax-highlight helper for the "Browse the
source" section.

Enumerates the showcase repo's own source files (via git, so build artifacts and
node_modules are excluded for free) and highlights any one of them with Pygments
- using Jac's *own* canonical lexer (`source_lexer.JacLexer`) for every `.jac`
variant, and Pygments' built-in lexers for Python/CSS/TOML/Markdown/JSON/etc. The
client just drops the returned HTML into a <pre> via `unsafe_html`.
"""

import os;
import subprocess;
import from functools { lru_cache }
import from pygments { highlight }
import from pygments.formatters { HtmlFormatter }
import from pygments.lexers { get_lexer_by_name, get_lexer_for_filename }
import from pygments.lexers.special { TextLexer }
import from pygments.util { ClassNotFound }
import from source_lexer { JacLexer }

glob ROOT: str = os.path.dirname(os.path.abspath(__file__));
glob MAX_BYTES: int = 260000;  # cap a single file so a huge generated file can't wedge the UI

# Files git tracks (or that are untracked-but-not-ignored) we still don't want to
# render as text.
glob _BINARY_EXTS: set = {
    ".png", ".jpg", ".jpeg", ".gif", ".ico", ".webp", ".bmp",
    ".woff", ".woff2", ".ttf", ".otf", ".eot",
    ".wasm", ".so", ".dylib", ".dll", ".a", ".o", ".bin",
    ".zip", ".gz", ".tar", ".pdf", ".mp4", ".mov", ".jbc", ".pyc"
};

# Human-facing language label for the file badge.
glob _LANG: dict = {
    "jac": "Jac", "py": "Python", "css": "CSS", "toml": "TOML",
    "md": "Markdown", "json": "JSON", "svg": "SVG", "sh": "Shell",
    "ts": "TypeScript", "tsx": "TSX", "js": "JavaScript", "jsx": "JSX",
    "zig": "Zig", "html": "HTML", "txt": "Text", "yml": "YAML", "yaml": "YAML"
};

"""Pretty language label for a file path's badge."""
def _lang_label(rel: str) -> str {
    if rel.endswith(".jac") {
        return "Jac";
    }
    ext = rel.rsplit(".", 1)[-1].lower() if "." in os.path.basename(rel) else "";
    return _LANG.get(ext, ext.upper() or "Text");
}

"""The canonical Jac lexer for any `*.jac`; Pygments' best guess otherwise."""
def _lexer_for(path: str) -> any {
    if path.endswith(".jac") {
        return JacLexer(stripnl=False);
    }
    try {
        return get_lexer_for_filename(path, stripnl=False);
    } except ClassNotFound {
        if path.endswith(".svg") {
            return get_lexer_by_name("xml", stripnl=False);
        }
        return TextLexer(stripnl=False);
    }
}

"""Directory names that never hold viewable source (VCS, build output, deps).
The filesystem-walk fallback prunes these so it mirrors what git's
`--exclude-standard` drops for free."""
glob _SKIP_DIRS: set = {
    ".git", ".jac", "node_modules", "__pycache__", ".venv", "venv",
    "dist", "build", ".pytest_cache", ".mypy_cache", ".idea", ".vscode"
};

# NOTE: the per-tree parameter is `base_dir`, never `root` -- `root` is a
# reserved Jac keyword (the graph root) and using it as a param name ICEs the
# compiler (PyastGenPass "Empty py_ast on ParamVar"). See jaseci-labs#7010.
"""Candidate paths relative to `base_dir`. Prefer git (so `.gitignore` is
honored in dev and freshly-added files show up via `--others`); fall back to a
filesystem walk when git is unavailable -- e.g. a deploy pod that ships the
source tree without a `.git` dir or the `git` binary. Without the fallback the
source viewer lists nothing in-cluster while working locally."""
def _raw_files(base_dir: str) -> list {
    git_rels: list = [];
    try {
        out = subprocess.run(
            ["git", "ls-files", "--cached", "--others", "--exclude-standard"],
            cwd=base_dir, capture_output=True, text=True, timeout=15
        );
        git_rels = [r.strip() for r in out.stdout.splitlines() if r.strip()];
    } except Exception {
        git_rels = [];
    }
    if git_rels {
        return git_rels;
    }
    rels: list = [];
    for (dirpath, dirnames, filenames) in os.walk(base_dir) {
        dirnames[:] = [
            d for d in dirnames if (d not in _SKIP_DIRS) and (not d.startswith("."))
        ];
        for fn in filenames {
            rels.append(os.path.relpath(os.path.join(dirpath, fn), base_dir));
        }
    }
    return rels;
}

"""Viewable source files relative to `base_dir`, filtered + sorted. Cached per-dir."""
@lru_cache(maxsize=8)
def _source_files(base_dir: str) -> tuple {
    keep: list = [];
    for raw in _raw_files(base_dir) {
        rel = raw.strip();
        if not rel {
            continue;
        }
        if "__pycache__" in rel or os.path.basename(rel).startswith(".") {
            continue;
        }
        ext = os.path.splitext(rel)[1].lower();
        if ext in _BINARY_EXTS {
            continue;
        }
        if not os.path.isfile(os.path.join(base_dir, rel)) {
            continue;
        }
        keep.append(rel);
    }
    return tuple(sorted(keep));
}

"""Flat, sorted list of viewable source files with light metadata."""
def list_files(base_dir: str = "") -> list {
    base = base_dir or ROOT;
    files: list = [];
    for rel in _source_files(base) {
        try {
            size = os.path.getsize(os.path.join(base, rel));
        } except OSError {
            continue;
        }
        files.append({
            "path": rel,
            "name": os.path.basename(rel),
            "dir": os.path.dirname(rel),
            "lang": _lang_label(rel),
            "size": size
        });
    }
    return files;
}

"""Empty file payload carrying an error message."""
def _blank(rel: str, err: str) -> dict {
    return {
        "path": rel, "lang": "", "html": "", "lines": 0,
        "raw": "", "truncated": False, "error": err
    };
}

"""Read + highlight one file. Sandboxed to the repo's own file set."""
def get_file(rel: str, base_dir: str = "") -> dict {
    base = base_dir or ROOT;
    path = rel.lstrip("/").replace("\\", "/");
    if path not in _source_files(base) {
        return _blank(path, "File not found.");
    }
    full = os.path.realpath(os.path.join(base, path));
    if os.path.commonpath([full, os.path.realpath(base)]) != os.path.realpath(base) {
        return _blank(path, "Invalid path.");
    }
    try {
        data = open(full, encoding="utf-8", errors="replace").read();
    } except OSError {
        return _blank(path, "Could not read file.");
    }
    truncated = len(data) > MAX_BYTES;
    if truncated {
        data = data[:MAX_BYTES] + "\n... (truncated)\n";
    }
    data = data.rstrip("\n");
    # Count from the rendered HTML so the client's line gutter lines up exactly
    # (newlines render as line breaks inside <pre> regardless of span nesting).
    html = highlight(data, _lexer_for(path), HtmlFormatter(nowrap=True)).rstrip("\n");
    return {
        "path": path,
        "lang": _lang_label(path),
        "html": html,
        "lines": html.count("\n") + 1,
        "raw": data,
        "truncated": truncated,
        "error": ""
    };
}
