"""Source browser - the closing section. The whole showcase is written in Jac,
so this lets visitors read its OWN source. The file list and per-file syntax
highlighting both come from the `source_viewer.jac` server endpoints
(`source_index.py` colours each file with Jac's canonical Pygments lexer - the
same grammar the docs use). This component is the presentation layer: a grouped
file tree on the left, a highlighted code pane with a line gutter on the right.
Server state (`files` / `current` / `loading`) is owned by the frontend shell
and passed in; `onOpen(path)` asks it to load a file."""

import from "lucide-react" { Search, Copy, Check, FileCode2, Folder, Code2 }
import from .SectionShell { SectionShell }

"""Header label for the repo-root file group (files with no directory)."""
glob _ROOT_LABEL: str = "this_is_jac";

"""Tailwind text colour for a language, used on badges and active file icons."""
def _lang_color(lang: str) -> str {
    if lang == "Jac" { return "text-primary"; }
    if lang == "Python" { return "text-sky-300"; }
    if lang == "CSS" { return "text-violet-300"; }
    if lang == "TOML" or lang == "JSON" { return "text-amber-300"; }
    if lang == "Markdown" { return "text-emerald-300"; }
    return "text-sky-300";
}

def:pub SourceViewer(
    files: list[dict],
    current: dict | None,
    loading: bool,
    onOpen: Callable[[str], None],
) -> JsxElement {
    has query: str = "",
        active: str = "",
        copied: bool = False;

    # Keep the highlighted item in sync once a file finishes loading.
    can with [current] entry {
        if current {
            active = current["path"];
        }
    }

    # Filter, then bucket by directory. Path-sort interleaves root files with
    # subdirectory paths (analytics.jac < assets/... < capture.jac), so bucket
    # by dir (first-appearance order) rather than assuming contiguity.
    q = query.strip().lower();
    filtered = [f for f in files if q == "" or q in f["path"].lower()];
    buckets: dict = {};
    dirOrder: list[str] = [];
    for f in filtered {
        d = f["dir"];
        if d not in buckets {
            buckets[d] = [];
            dirOrder.append(d);
        }
        buckets[d].append(f);
    }
    groups = [{"dir": d, "files": buckets[d]} for d in dirOrder];

    curPath = current["path"] if current else "";
    curLang = current["lang"] if current else "";
    curHtml = current["html"] if current else "";
    curErr = current["error"] if current else "";
    curLines = current["lines"] if current else 0;
    curRaw = current["raw"] if current else "";

    do_copy = lambda {
        navigator.clipboard.writeText(curRaw);
        copied = True;
    };

    return
        <SectionShell
            id="source"
            eyebrow="Open source"
            title="Read this site's own source"
            subtitle="Every pixel you have scrolled is Jac - client, server, and native, in one project. Browse the actual files below, highlighted server-side by Jac's own lexer - the same grammar the docs use."
        >
            <div className="mx-auto max-w-6xl">
                <div
                    className="dark grid overflow-hidden rounded-2xl border border-border bg-card text-foreground shadow-xl shadow-black/30 lg:grid-cols-[290px_1fr]"
                >
                    <div
                        className="flex max-h-[600px] min-h-[440px] flex-col border-b border-border lg:border-b-0 lg:border-r"
                    >
                        <div className="flex items-center gap-2 border-b border-border/70 px-3 py-2.5">
                            <Search size={14} className="shrink-0 text-muted-foreground"/>
                            <input
                                value={query}
                                onChange={lambda e: ChangeEvent { query = e.target.value; }}
                                placeholder="Filter files..."
                                className="w-full bg-transparent text-sm text-foreground placeholder:text-muted-foreground focus:outline-none"
                            />
                            <span className="shrink-0 font-mono text-[10px] text-muted-foreground">
                                {len(filtered)}
                            </span>
                        </div>
                        <div className="flex-1 overflow-y-auto py-1">
                            {[
                                <div key={g["dir"]} className="mb-1">
                                    <div
                                        className="flex items-center gap-1.5 px-3 py-1 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground/70"
                                    >
                                        <Folder size={11} className="shrink-0"/>
                                        <span className="truncate">{g["dir"] or _ROOT_LABEL}</span>
                                    </div>
                                    {[
                                        <button
                                            key={f["path"]}
                                            onClick={lambda { active = f["path"]; onOpen(f["path"]); }}
                                            className={"flex w-full items-center gap-2 px-3 py-1 text-left text-[13px] transition " + (
                                                "bg-primary/15 text-foreground" if f["path"] == active else "text-muted-foreground hover:bg-white/5 hover:text-foreground"
                                            )}
                                        >
                                            <FileCode2
                                                size={13}
                                                className={"shrink-0 " + (_lang_color(f["lang"]) if f["path"] == active else "text-muted-foreground/50")}
                                            />
                                            <span className="truncate">{f["name"]}</span>
                                        </button>
                                        for f in g["files"]
                                    ]}
                                </div>
                                for g in groups
                            ]}
                        </div>
                    </div>

                    <div className="flex max-h-[600px] min-w-0 flex-col bg-[#0c0e14]">
                        <div className="flex items-center gap-2 border-b border-border/70 px-4 py-2.5">
                            <span className="size-3 shrink-0 rounded-full bg-[#ff5f57]"/>
                            <span className="size-3 shrink-0 rounded-full bg-[#febc2e]"/>
                            <span className="size-3 shrink-0 rounded-full bg-[#28c840]"/>
                            <span className="ml-2 truncate font-mono text-xs text-muted-foreground">
                                {curPath or "—"}
                            </span>
                            {if curLang {
                                <span
                                    className={"ml-1 shrink-0 rounded-md border border-border/60 px-1.5 py-0.5 font-mono text-[10px] " + _lang_color(curLang)}
                                >
                                    {curLang}
                                </span>
                            }}
                            <button
                                className="ml-auto flex shrink-0 items-center gap-1.5 rounded-md px-2 py-1 text-xs text-muted-foreground transition hover:bg-white/5 hover:text-foreground"
                                onClick={do_copy}
                                title="Copy file"
                            >
                                {if copied {
                                    <Check size={13} className="text-emerald-400"/>
                                } else {
                                    <Copy size={13}/>
                                }}
                                {"Copied" if copied else "Copy"}
                            </button>
                        </div>
                        <div className="relative flex-1 overflow-y-auto">
                            {if curErr {
                                <div className="p-8 text-center text-sm text-muted-foreground">
                                    {curErr}
                                </div>
                            } elif curHtml {
                                <div className="flex min-h-full">
                                    <div
                                        className="select-none border-r border-border/40 px-3 py-3 text-right font-mono text-[12.5px] leading-[1.55] text-muted-foreground/40"
                                    >
                                        {[
                                            <div key={i}>{i}</div>
                                            for i in range(1, curLines + 1)
                                        ]}
                                    </div>
                                    <pre
                                        className="tij-code flex-1 overflow-x-auto px-4 py-3 font-mono text-[12.5px] leading-[1.55]"
                                    >
                                        {unsafe_html(curHtml)}
                                    </pre>
                                </div>
                            } else {
                                <div className="flex h-full items-center justify-center gap-2 p-8 text-sm text-muted-foreground">
                                    <Code2 size={16}/>
                                    Select a file to view its source
                                </div>
                            }}
                            {if loading {
                                <div
                                    className="absolute inset-0 flex items-center justify-center bg-[#0c0e14]/60 backdrop-blur-[1px]"
                                >
                                    <div
                                        className="size-5 animate-spin rounded-full border-2 border-primary border-t-transparent"
                                    />
                                </div>
                            }}
                        </div>
                    </div>
                </div>
            </div>
        </SectionShell>;
}
