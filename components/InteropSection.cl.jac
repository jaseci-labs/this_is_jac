"""Interop section: one `.jac` module imports straight from the Python and npm
ecosystems (packages AND local files) and links any C-ABI shared library by
name. An impressive funnel diagram - three ecosystem sources flowing into a
single Jac module."""

import from "lucide-react" { Boxes, Package, Cpu }
import from .SectionShell { SectionShell }

glob _PY_CODE: str = """import numpy as np;
import from sklearn.cluster { KMeans }
import from .models { User }""";

glob _NPM_CODE: str = """import from "react" { useState }
import from "d3-scale" { scaleLinear }
import from .Chart { Chart }""";

glob _C_CODE: str = """import from raylib {
    def InitWindow(w: i32, h: i32, t: str);
}
import from "libm.so.6" {
    def sqrt(x: f64) -> f64;
}""";

"""One ecosystem source card: an accent badge, a name + scope line, and a small
snippet of the real Jac import syntax for that ecosystem."""
def:pub EcoCard(name: str, sub: str, code: str, accent: str, icon: any) -> JsxElement {
    return
        <div className="flex flex-col rounded-xl border border-border bg-card/60 p-5">
            <div className="flex items-center gap-3">
                <span
                    className={"flex size-9 shrink-0 items-center justify-center rounded-lg " + accent}
                >
                    {icon}
                </span>
                <div className="min-w-0">
                    <div className="font-display font-bold leading-tight text-foreground">
                        {name}
                    </div>
                    <div className="text-xs text-muted-foreground">{sub}</div>
                </div>
            </div>
            <pre
                className="mt-4 overflow-x-auto rounded-lg border border-border bg-[#0c0e14] p-3 font-mono text-[12px] leading-relaxed text-foreground/85"
            >
                {code}
            </pre>
        </div>;
}

def:pub InteropSection -> JsxElement {
    return
        <SectionShell
            id="interop"
            eyebrow="Interop"
            title="Import anything, link anything"
            subtitle="One .jac module imports straight from Python and npm - packages and your own files - and links any C-ABI library by name. No generated bindings, no FFI boilerplate, no glue layer."
        >
            <div className="mx-auto max-w-5xl">
                <div className="grid gap-4 sm:grid-cols-3">
                    <EcoCard
                        name="Python"
                        sub="PyPI packages + local .py / .jac files"
                        code={_PY_CODE}
                        accent="bg-sky-400/15 text-sky-400"
                        icon={<Boxes size={18}/>}
                    />
                    <EcoCard
                        name="npm / web"
                        sub="npmjs packages + js · ts · jsx · tsx"
                        code={_NPM_CODE}
                        accent="bg-rose-400/15 text-rose-400"
                        icon={<Package size={18}/>}
                    />
                    <EcoCard
                        name="C-ABI FFI"
                        sub="any .so / .dylib / .dll, by logical name"
                        code={_C_CODE}
                        accent="bg-primary/15 text-primary"
                        icon={<Cpu size={18}/>}
                    />
                </div>

                <svg
                    viewBox="0 0 600 64"
                    preserveAspectRatio="none"
                    className="mx-auto h-12 w-full max-w-3xl"
                    aria-hidden="true"
                >
                    <path
                        className="tij-flow"
                        d="M100,2 C100,42 300,22 300,62"
                        fill="none"
                        stroke="var(--primary)"
                        strokeOpacity={0.55}
                        strokeWidth={2}
                    />
                    <path
                        className="tij-flow"
                        d="M300,2 L300,62"
                        fill="none"
                        stroke="var(--primary)"
                        strokeOpacity={0.55}
                        strokeWidth={2}
                    />
                    <path
                        className="tij-flow"
                        d="M500,2 C500,42 300,22 300,62"
                        fill="none"
                        stroke="var(--primary)"
                        strokeOpacity={0.55}
                        strokeWidth={2}
                    />
                </svg>

                <div
                    className="mx-auto flex max-w-sm items-center gap-3 rounded-2xl border border-primary/40 bg-primary/10 px-5 py-4 shadow-lg shadow-primary/10"
                >
                    <span
                        className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary font-mono text-base font-bold text-primary-foreground"
                    >
                        J
                    </span>
                    <div>
                        <div className="font-mono text-sm font-bold text-foreground">
                            your_module.jac
                        </div>
                        <div className="text-xs text-muted-foreground">
                            one file - type-checked across every boundary
                        </div>
                    </div>
                </div>
            </div>
        </SectionShell>;
}
