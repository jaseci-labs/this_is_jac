# This is Jac

A scroll-driven showcase site that demonstrates Jac's range in one codebase -
**fullstack, object-spatial, AI-native, and native-compiled** - and a Jac
automation script that benchmarks and screenshots the native demos for the page
to embed.

Everything here is built in Jac. The live demos really run.

![sections](assets/jac-logo.svg)

## What it shows

Each section is its own component under [`components/`](components/), composed by
[`frontend.cl.jac`](frontend.cl.jac):

| Section | Capability | Live? |
| ------- | ---------- | ----- |
| **Hero** | the pitch + a one-file `cl` / `na` / walker teaser | static |
| **Fullstack** | one language across the wire | **live** - a guestbook backed by `sign_guestbook` / `get_guestbook` walkers, persisted to a real graph |
| **Object-Spatial** | the program is a graph; walkers walk it | **live** - renders the actual path the `explore_graph` walker took through the server's graph |
| **AI-native** | a function body delegated to an LLM with `by llm()` | static (code + illustrated call) |
| **Native** | `jac nacompile` to machine code, no C toolchain | **data** - Jac-vs-Zig FPS bars + screenshots from `capture.jac` |
| **WebAssembly** | the *same* `na {}` shooter, compiled to wasm | **live** - playable in-browser via a WebGL shim |
| **Outro** | install + links | static |

The same `na {}` cube-shooter game lives in [`main.jac`](main.jac): the client
build compiles it to `/static/main.wasm`, and the WebAssembly section renders it
live through [`raylib_shim.cl.jac`](raylib_shim.cl.jac) - byte-for-byte the rlgl
pipeline from the bundled [`raylib_shooter/`](raylib_shooter) example.

## Run it

```bash
jac install        # first time: installs python + npm deps
jac start          # build cl bundle + na->wasm, serve on http://localhost:8000
jac start --dev    # same, with hot reload
```

Open <http://localhost:8000> and scroll. Sign the guestbook, spawn the walker,
and launch the in-browser shooter - all of it hits real Jac.

`jac build` produces the same artifacts under `.jac/client/dist/` without serving.

## Layout

```
main.jac              cl{} app delegate + na{} rlgl shooter (-> main.wasm)
frontend.cl.jac       app shell: shared state, section order, sv handler decls
frontend.impl.jac     handler bodies (root spawn ... walkers)
server.jac            object-spatial backend: Visitor/Topic nodes, walkers
raylib_shim.cl.jac    WebGL/DOM shim for the wasm shooter
capture.jac           the automation script (below)
components/           Nav, SectionShell, CodeBlock, StatBar + one file per section
components/ui/         shadcn primitives (button, card, badge, ...)
assets/captures/      benchmark.json + shooter screenshots (refreshed by capture.jac)
raylib_shooter/       the bundled native demo capture.jac benchmarks + screenshots
```

## The capture script (`capture.jac`)

A Jac program that drives the bundled `raylib_shooter/` example and writes
artifacts the **Native** section embeds. It locates `raylib_shooter` by walking
up from its own directory, so it works bundled here or beside the upstream
example. Each step is independently guarded - a failure logs and the run
continues.

```bash
jac run capture.jac                 # benchmark + screenshots
jac run capture.jac --skip-shots    # benchmark only
jac run capture.jac --skip-bench    # screenshots only
```

1. **Benchmark** - runs `raylib_shooter/demo.sh --bench` (first run downloads the
   Zig toolchain + precompiled raylib and builds both binaries), parses the
   Jac-vs-Zig avg/max FPS table, and writes `assets/captures/benchmark.json`.
   The Native section fetches it at runtime; a representative fallback is
   committed so the page is complete before any capture run.
2. **Screenshots** - launches the freshly-built native binaries and grabs their
   window with ImageMagick `import` into `shooter_jac.png` / `shooter_zig.png`.
   Needs an **X display**: blank grabs (e.g. pure-Wayland boxes, where the GL
   window is invisible to `import`) are detected and skipped, and the Native
   section falls back to a placeholder. The live WebAssembly section still
   renders the game regardless.
3. **Manifest** - `manifest.json` records what each step did, with timestamps.

`benchmark.json` and the shooter screenshots are committed as representative
artifacts (re-run `capture.jac` to refresh them); only `manifest.json` is
git-ignored.

## Requirements

- `jac` with the `jac-client` plugin (this repo's `.venv`, or `pip install jaclang jac-client`).
- For `capture.jac`: `bash`, `curl`, ImageMagick (`import` / `convert` / `identify`);
  the benchmark also needs the Zig toolchain (auto-downloaded by `demo.sh`) and a
  GL-capable display. Screenshots additionally need an X11 display.
