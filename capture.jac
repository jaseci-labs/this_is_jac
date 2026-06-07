"""This is Jac - capture/automation script (written in Jac).

Drives the sibling `raylib_shooter` example and writes artifacts into
`assets/captures/` for the site to embed:

  1. Benchmark   - runs `raylib_shooter/demo.sh --bench`, parses the Jac-vs-Zig
                   avg/max FPS table, and writes `benchmark.json` (the
                   NativeSection fetches it at runtime). RELIABLE.
  2. Screenshots - best-effort: launches the freshly-built native binaries,
                   grabs their window with ImageMagick `import`, and saves
                   `shooter_jac.png` / `shooter_zig.png`. Needs an X display;
                   on headless / pure-Wayland boxes it records "skipped" and
                   keeps going (the live WASM section still shows the game).
  3. Manifest    - `manifest.json` records what each step did + timestamps.

Each step is independently guarded: a failure logs and the run continues.

    jac run capture.jac                 # benchmark + screenshots
    jac run capture.jac --skip-bench    # screenshots only
    jac run capture.jac --skip-shots    # benchmark only
"""

import os;
import sys;
import json;
import time;
import subprocess;
import datetime;

glob HERE: str = os.path.dirname(os.path.abspath(__file__));

"""Locate the sibling `raylib_shooter` example by walking up from HERE, so this
script works wherever `this_is_jac` lives (jac/examples/, _planning/, or a
standalone checkout next to raylib_shooter). Returns "" if not found - the
benchmark/screenshot steps then skip cleanly."""
def _find_shooter_dir -> str {
    d = HERE;
    for _i in range(10) {
        in_repo = os.path.join(d, "jac", "examples", "raylib_shooter");
        if os.path.exists(os.path.join(in_repo, "demo.sh")) {
            return in_repo;
        }
        sibling = os.path.join(d, "raylib_shooter");
        if os.path.exists(os.path.join(sibling, "demo.sh")) {
            return sibling;
        }
        parent = os.path.dirname(d);
        if parent == d {
            break;
        }
        d = parent;
    }
    return "";
}

glob SHOOTER_DIR: str = _find_shooter_dir();
glob CAPTURES: str = os.path.join(HERE, "assets", "captures");
glob BENCH_TIMEOUT: int = 900;


def _today -> str {
    return datetime.datetime.now(datetime.UTC).strftime("%Y-%m-%d");
}

def _iso -> str {
    return datetime.datetime.now(datetime.UTC).replace(tzinfo=None).isoformat() + "Z";
}

def _platform -> str {
    try {
        u = os.uname();
        return f"{u.sysname} {u.machine}";
    } except Exception as e {
        return "unknown";
    }
}

"""Pull one ('Jac'|'Zig') row out of demo.sh's benchmark table.

Rows look like:  `  Jac            461.7          719.9         3694`
An unavailable build prints `n/a` cells; those parse to None."""
def _parse_row(text: str, label: str) -> dict | None {
    for line in text.splitlines() {
        parts = line.split();
        if len(parts) >= 4 and parts[0] == label {
            try {
                return {
                    "avg": float(parts[1]),
                    "max": float(parts[2]),
                    "frames": int(parts[3])
                };
            } except ValueError as e {
                return None;
            }
        }
    }
    return None;
}


obj CaptureRunner {
    has results: list[dict] = [];

    def record(name: str, status: str, detail: str) -> None {
        self.results.append({"step": name, "status": status, "detail": detail});
        mark = "ok  " if status == "ok" else ("skip" if status == "skip" else "FAIL");
        print(f"  [{mark}] {name}: {detail}");
    }

    # ── 1. Benchmark ─────────────────────────────────────────────────────────
    def run_benchmark -> None {
        if not SHOOTER_DIR {
            self.record("benchmark", "fail", "raylib_shooter example not found (walked up from script dir)");
            return;
        }
        demo = os.path.join(SHOOTER_DIR, "demo.sh");
        if not os.path.exists(demo) {
            self.record("benchmark", "fail", f"demo.sh not found at {demo}");
            return;
        }
        print(">> running raylib shooter benchmark (builds both binaries, ~8s each)...");
        try {
            proc = subprocess.run(
                ["bash", demo, "--bench"],
                cwd=SHOOTER_DIR,
                capture_output=True,
                text=True,
                timeout=BENCH_TIMEOUT
            );
        } except subprocess.TimeoutExpired as e {
            self.record("benchmark", "fail", f"timed out after {BENCH_TIMEOUT}s");
            return;
        } except Exception as e {
            self.record("benchmark", "fail", f"{e}");
            return;
        }
        out = proc.stdout + "\n" + proc.stderr;
        jac = _parse_row(out, "Jac");
        zig = _parse_row(out, "Zig");
        if jac is None and zig is None {
            tail = "\n".join(out.strip().splitlines()[-6:]);
            self.record("benchmark", "fail", "could not parse FPS table (no display/GPU?)");
            print(f"     --- last output ---\n{tail}");
            return;
        }
        data = {
            "captured_at": _today(),
            "platform": _platform(),
            "note": "Measured by capture.jac",
            "jac": jac if jac else {"avg": 0.0, "max": 0.0, "frames": 0},
            "zig": zig if zig else {"avg": 0.0, "max": 0.0, "frames": 0}
        };
        with open(os.path.join(CAPTURES, "benchmark.json"), "w") as f {
            json.dump(data, f, indent=2);
        }
        ja = data["jac"]["avg"];
        za = data["zig"]["avg"];
        self.record("benchmark", "ok", f"Jac {ja} / Zig {za} avg fps -> benchmark.json");
    }

    # ── 2. Screenshots (best-effort) ──────────────────────────────────────────
    def _find_window(title: str) -> str {
        try {
            r = subprocess.run(
                ["xwininfo", "-root", "-tree"],
                capture_output=True, text=True, timeout=15
            );
            for line in r.stdout.splitlines() {
                if title in line {
                    parts = line.strip().split();
                    if parts and parts[0].startswith("0x") {
                        return parts[0];
                    }
                }
            }
        } except Exception as e {
            return "";
        }
        return "";
    }

    """A grab that comes back with almost no distinct colors is a blank
    XWayland-root capture (the game renders on Wayland, invisible to `import`),
    not a real frame. The shooter scene - grid, shaded cubes, bullets, FPS
    text - always has far more than this."""
    def _looks_blank(path: str) -> bool {
        try {
            r = subprocess.run(
                ["identify", "-format", "%k", path],
                capture_output=True, text=True, timeout=15
            );
            return int(r.stdout.strip()) < 16;
        } except Exception as e {
            return False;
        }
    }

    def _grab(title: str, out: str) -> bool {
        got = False;
        # Prefer grabbing the specific window by id (clean, no desktop chrome).
        wid = self._find_window(title);
        if wid {
            r = subprocess.run(
                ["import", "-window", wid, out], capture_output=True, timeout=25
            );
            got = r.returncode == 0 and os.path.exists(out);
        }
        # Fallback: grab the root and center-crop to the window size.
        if not got {
            r = subprocess.run(
                ["import", "-window", "root", out], capture_output=True, timeout=25
            );
            if r.returncode == 0 and os.path.exists(out) {
                subprocess.run(
                    ["convert", out, "-gravity", "center", "-crop", "960x600+0+0", "+repage", out],
                    capture_output=True
                );
                got = True;
            }
        }
        if not got {
            return False;
        }
        if self._looks_blank(out) {
            if os.path.exists(out) {
                os.remove(out);
            }
            return False;
        }
        self._postprocess(out);
        return True;
    }

    def _postprocess(out: str) -> None {
        subprocess.run(
            ["convert", out, "-resize", "960x600>", "-strip", out],
            capture_output=True
        );
    }

    def capture_one(binary: str, title: str, outname: str) -> None {
        bin_path = os.path.join(SHOOTER_DIR, binary);
        if not os.path.exists(bin_path) {
            self.record(
                outname, "skip", f"{binary} not built (run benchmark first)"
            );
            return;
        }
        # Make sure the dormant benchmark path stays off so the binary plays
        # interactively (and does not self-exit) while we grab a frame.
        bench_file = os.path.join(SHOOTER_DIR, ".bench_seconds");
        if os.path.exists(bench_file) {
            os.remove(bench_file);
        }
        proc = subprocess.Popen(
            [bin_path], cwd=SHOOTER_DIR,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        );
        try {
            time.sleep(3.5);
            if proc.poll() is not None {
                self.record(outname, "skip", "binary exited early (no display/GL)");
                return;
            }
            out = os.path.join(CAPTURES, outname);
            if self._grab(title, out) {
                kb = os.path.getsize(out) // 1024;
                self.record(outname, "ok", f"{outname} ({kb} KB)");
            } else {
                self.record(outname, "skip", "no X window grab (headless/Wayland)");
            }
        } except Exception as e {
            self.record(outname, "fail", f"{e}");
        } finally {
            proc.terminate();
            try {
                proc.wait(timeout=5);
            } except Exception as e {
                proc.kill();
            }
        }
    }

    def capture_screenshots -> None {
        print(">> capturing native shooter screenshots (best-effort)...");
        self.capture_one("shooter", "Jac Cube Shooter", "shooter_jac.png");
        self.capture_one("shooter_zig", "Jac Cube Shooter", "shooter_zig.png");
    }

    # ── 3. Manifest + summary ──────────────────────────────────────────────────
    def write_manifest -> None {
        manifest = {
            "generated_at": _iso(),
            "platform": _platform(),
            "steps": self.results
        };
        with open(os.path.join(CAPTURES, "manifest.json"), "w") as f {
            json.dump(manifest, f, indent=2);
        }
    }

    def summary -> int {
        oks = len([r for r in self.results if r["status"] == "ok"]);
        print("\n" + "=" * 56);
        print(f"  capture complete - {oks}/{len(self.results)} step(s) ok");
        print("  artifacts in: assets/captures/");
        print("=" * 56);
        return 0 if oks > 0 else 1;
    }
}


with entry {
    skip_bench = "--skip-bench" in sys.argv;
    skip_shots = "--skip-shots" in sys.argv;

    print("=" * 56);
    print("  this-is-jac :: capture");
    print(f"  shooter dir: {SHOOTER_DIR}");
    print("=" * 56);

    os.makedirs(CAPTURES, exist_ok=True);
    runner = CaptureRunner();
    if not skip_bench {
        runner.run_benchmark();
    }
    if not skip_shots {
        runner.capture_screenshots();
    }
    runner.write_manifest();
    sys.exit(runner.summary());
}
