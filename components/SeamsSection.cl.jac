"""Cohesion section: the closing argument. We rebuilt this exact site WITHOUT
Jac (React + FastAPI + Postgres + a C/WASM module). The line count barely moved -
but five seams reappeared, each a boundary between systems you keep in sync by
hand. Jac collapses every one of them into a single language. This section makes
that visible: per seam, the conventional stack's joint vs Jac's one-thing."""

import from "lucide-react" {
    ArrowLeftRight, Database, Network, Boxes, Languages, Check, X, GitMerge,
    Cpu, Server, Globe, Box
}
import from .SectionShell { SectionShell }

"""The five seams the non-Jac twin had to add back - each with the conventional
pain on the left and the Jac collapse on the right."""
glob _SEAMS: list[dict] = [
    {
        "icon": <ArrowLeftRight size={18}/>,
        "title": "A client/server type boundary",
        "without": "Client TypeScript types and server schemas, kept in sync by hand. They drift - and the drift is a runtime bug.",
        "withjac": "One typed definition spans both sides. `await add_todo(...)` in the browser IS the server function - same types, no boundary to sync."
    },
    {
        "icon": <Database size={18}/>,
        "title": "An ORM and a migration system",
        "without": "ORM models map objects to tables; Alembic migrations evolve the schema every time it changes.",
        "withjac": "`root ++> Visitor(...)`. Persistence is the language - no tables, no ORM, no migrations to author or run."
    },
    {
        "icon": <Network size={18}/>,
        "title": "Build, proxy and CORS glue",
        "without": "A Vite proxy, CORS rules, and env wiring tie the frontend to a separately-running backend.",
        "withjac": "`jac serve`. One origin, one process - the client and the server are the same program."
    },
    {
        "icon": <Cpu size={18}/>,
        "title": "A native toolchain for WebAssembly",
        "without": "A second language (C) and its toolchain - clang, wasm-ld - a separate build, and exports/imports hand-wired across the JS boundary.",
        "withjac": "The `na {}` block is Jac, in the same file. `jac build` emits the `.wasm` - Jac ships its own LLVM and wasm linker, so there is no external toolchain."
    },
    {
        "icon": <Boxes size={18}/>,
        "title": "Two deploy units",
        "without": "A frontend container and a backend container, plus nginx and Docker Compose to run them as one.",
        "withjac": "One artifact. The runtime is the server - there is nothing to wire together to ship it."
    },
    {
        "icon": <Languages size={18}/>,
        "title": "Five languages",
        "without": "TypeScript, Python, C, SQL and YAML - five toolchains, five mental models, five context switches.",
        "withjac": "One language for the graph, the server, the browser, and the metal."
    }
];

"""A bottom-line collapse chip: `<from> -> <dest>`."""
def:pub CollapseChip(from_: str, dest: str) -> JsxElement {
    return
        <span
            className="inline-flex items-center gap-1.5 rounded-full border border-primary/30 bg-primary/10 px-3 py-1 font-mono text-xs text-primary"
        >
            <span className="text-muted-foreground line-through decoration-destructive/60">{from_}</span>
            <GitMerge size={13}/>
            <span className="font-semibold">{dest}</span>
        </span>;
}

"""The conventional twin's processes - the N programs that have to talk to each
other over the wire (the not-jac build ran exactly these five)."""
glob _PROGRAMS: list[dict] = [
    {"label": "Browser SPA", "icon": <Globe size={15}/>},
    {"label": "API server", "icon": <Server size={15}/>},
    {"label": "Analytics svc", "icon": <Cpu size={15}/>},
    {"label": "Postgres", "icon": <Database size={15}/>},
    {"label": "Redis", "icon": <Box size={15}/>}
];

"""One small dashed box in the 'N programs' cluster."""
def:pub ProgBox(label: str, icon: any) -> JsxElement {
    return
        <div
            className="flex items-center gap-1.5 rounded-lg border border-dashed border-border/70 bg-background/40 px-2.5 py-1.5 text-xs text-muted-foreground"
        >
            {icon}
            {label}
        </div>;
}

"""One seam row: the conventional joint (left, muted/destructive) collapsing into
the Jac one-thing (right, primary)."""
def:pub SeamCard(title: str, without: str, withjac: str, icon: any) -> JsxElement {
    return
        <div className="rounded-xl border border-border bg-card/60 p-5">
            <div className="mb-4 flex items-center gap-3">
                <span
                    className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary/15 text-primary"
                >
                    {icon}
                </span>
                <div className="font-display font-bold leading-tight text-foreground">
                    {title}
                </div>
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
                <div className="rounded-lg border border-destructive/25 bg-destructive/[0.06] p-3.5">
                    <div
                        className="mb-1.5 flex items-center gap-1.5 font-mono text-[10px] font-semibold uppercase tracking-wider text-destructive/80"
                    >
                        <X size={13}/>
                        without jac
                    </div>
                    <p className="text-sm leading-relaxed text-muted-foreground">{without}</p>
                </div>
                <div className="rounded-lg border border-primary/30 bg-primary/[0.06] p-3.5">
                    <div
                        className="mb-1.5 flex items-center gap-1.5 font-mono text-[10px] font-semibold uppercase tracking-wider text-primary"
                    >
                        <Check size={13}/>
                        with jac
                    </div>
                    <p className="text-sm leading-relaxed text-foreground/85">{withjac}</p>
                </div>
            </div>
        </div>;
}

def:pub SeamsSection -> JsxElement {
    return
        <SectionShell
            id="seams"
            eyebrow="Cohesion"
            title="Fewer lines isn't the point. Fewer seams is."
            subtitle="We rebuilt this exact site without Jac - React, FastAPI, Postgres, a C/WASM module. The line count barely moved. But six seams reappeared - boundaries between systems you keep in sync by hand, where things drift and break. Jac collapses each into one language, one program."
        >
            <div className="mx-auto flex max-w-4xl flex-col gap-4">
                {[
                    <SeamCard
                        key={s["title"]}
                        title={s["title"]}
                        without={s["without"]}
                        withjac={s["withjac"]}
                        icon={s["icon"]}
                    />
                    for s in _SEAMS
                ]}

                <div
                    className="mt-4 rounded-2xl border border-primary/40 bg-primary/[0.05] p-6 shadow-lg shadow-primary/10 md:p-8"
                >
                    <div className="mb-6 text-center">
                        <div
                            className="mb-2 font-mono text-[11px] uppercase tracking-widest text-primary"
                        >
                            the bottom line
                        </div>
                        <h3 className="font-display text-2xl font-bold text-foreground md:text-3xl">
                            One program - not{" "}
                            <span className="tij-gradient-text">N programs talking to each other</span>.
                        </h3>
                    </div>
                    <div className="grid items-stretch gap-4 md:grid-cols-[1fr_auto_1fr]">
                        <div className="rounded-xl border border-destructive/25 bg-destructive/[0.05] p-4">
                            <div
                                className="mb-3 flex items-center gap-1.5 font-mono text-[10px] font-semibold uppercase tracking-wider text-destructive/80"
                            >
                                <X size={13}/>
                                without jac - 5 programs
                            </div>
                            <div className="flex flex-wrap gap-2">
                                {[
                                    <ProgBox key={p["label"]} label={p["label"]} icon={p["icon"]}/>
                                    for p in _PROGRAMS
                                ]}
                            </div>
                            <p className="mt-3 text-xs leading-relaxed text-muted-foreground">
                                Five processes, talking over HTTP, SQL and RESP. Every arrow between them is a thing that can fail, drift, or fall out of sync.
                            </p>
                        </div>
                        <div className="flex items-center justify-center">
                            <span
                                className="font-mono text-xs uppercase tracking-widest text-muted-foreground"
                            >
                                vs
                            </span>
                        </div>
                        <div className="flex flex-col rounded-xl border border-primary/30 bg-primary/[0.05] p-4">
                            <div
                                className="mb-3 flex items-center gap-1.5 font-mono text-[10px] font-semibold uppercase tracking-wider text-primary"
                            >
                                <Check size={13}/>
                                with jac - 1 program
                            </div>
                            <div
                                className="flex items-center gap-3 rounded-lg border border-primary/40 bg-primary/10 p-4"
                            >
                                <span
                                    className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary font-mono text-base font-bold text-primary-foreground"
                                >
                                    J
                                </span>
                                <div>
                                    <div className="font-mono text-sm font-bold text-foreground">
                                        your_app.jac
                                    </div>
                                    <div className="text-xs text-muted-foreground">
                                        cl + sv + na - one process
                                    </div>
                                </div>
                            </div>
                            <p className="mt-3 text-xs leading-relaxed text-muted-foreground">
                                Client, server, and native in one program. There is no wire between them to break.
                            </p>
                        </div>
                    </div>
                </div>

                <div className="mt-4 flex flex-wrap items-center justify-center gap-2.5">
                    <CollapseChip from_="5 languages" dest="1"/>
                    <CollapseChip from_="5 programs" dest="1"/>
                    <CollapseChip from_="hand-synced types" dest="0"/>
                    <CollapseChip from_="migrations" dest="0"/>
                    <CollapseChip from_="proxy + CORS glue" dest="0"/>
                    <CollapseChip from_="native toolchain" dest="0"/>
                </div>
            </div>
        </SectionShell>;
}
