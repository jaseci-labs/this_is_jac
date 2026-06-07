"""'A whole app, one component' - the entire littleX social app embedded as a
single `<LittleX/>`. This is the real littleX from `littlex/` (auth, feed,
follows, channels, profiles); its `sv import` walkers register in this very
server, so it reads and writes the SAME persistent graph as the rest of the
showcase. littleX scales to its container (its `min-h-screen` was changed to
`h-full`), so it fills this responsive 'app window' frame; the full standalone
app is one click away at `/littlex`."""

import from "lucide-react" { AppWindow, ArrowUpRight }
import from "@jac/runtime" { Link }
import from .SectionShell { SectionShell }
import from ..littlex.frontend { app as LittleX }

def:pub LittleXSection -> JsxElement {
    return
        <SectionShell
            id="littlex"
            eyebrow="Real apps"
            title="A whole social app, one component, same graph"
            subtitle="littleX - a full Twitter-style app with auth, feeds, follows, channels and profiles - dropped in as a single component. Its walkers run in this very server and persist to the same graph as everything above."
        >
            <div className="mx-auto max-w-5xl">
                <div
                    className="overflow-hidden rounded-2xl border border-border bg-card shadow-2xl shadow-black/40"
                >
                    <div
                        className="flex items-center gap-2 border-b border-border/70 bg-white/[0.02] px-4 py-2.5"
                    >
                        <span className="size-3 rounded-full bg-[#ff5f57]"/>
                        <span className="size-3 rounded-full bg-[#febc2e]"/>
                        <span className="size-3 rounded-full bg-[#28c840]"/>
                        <span
                            className="ml-2 flex items-center gap-1.5 font-mono text-xs text-muted-foreground"
                        >
                            <AppWindow size={13}/>
                            littlex - embedded live app, same graph
                        </span>
                        <Link
                            to="/littlex"
                            className="ml-auto flex items-center gap-1 rounded-md px-2 py-1 text-xs text-muted-foreground transition hover:bg-white/5 hover:text-foreground"
                        >
                            open full app
                            <ArrowUpRight size={13}/>
                        </Link>
                    </div>
                    <div className="h-[78vh] min-h-[600px] max-h-[860px] overflow-hidden bg-background">
                        <LittleX/>
                    </div>
                </div>
                <p className="mt-4 text-center text-sm text-muted-foreground">
                    Sign up inside the frame to try it - your account and posts persist in the shared graph.
                    Or <Link to="/littlex" className="font-medium text-primary hover:underline">open the full app at /littlex</Link>.
                </p>
            </div>
        </SectionShell>;
}
