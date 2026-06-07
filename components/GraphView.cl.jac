"""A small framed panel that embeds the runtime's Jac Graph Visualizer
(`/graph`). It renders the live node/edge topology the server holds - including
whatever littleX (just above) has written - as a server view surfaced beside the
app. Sits side-by-side with `DocsView` below the littleX embed."""

import from "lucide-react" { Waypoints, ArrowUpRight }

def:pub GraphView -> JsxElement {
    return
        <div className="overflow-hidden rounded-xl border border-border bg-card shadow-lg shadow-black/20">
            <div
                className="flex items-center gap-1.5 border-b border-border/70 bg-white/[0.02] px-3 py-2 font-mono text-xs text-muted-foreground"
            >
                <Waypoints size={13} className="text-primary"/>
                /graph - live Jac graph visualizer
                <a
                    href="/graph"
                    target="_blank"
                    rel="noreferrer"
                    className="ml-auto flex items-center gap-1 rounded-md px-2 py-0.5 transition hover:bg-white/5 hover:text-foreground"
                >
                    open
                    <ArrowUpRight size={13}/>
                </a>
            </div>
            <iframe
                src="/graph"
                title="Jac Graph Visualizer"
                className="h-[440px] w-full border-0 bg-background"
            />
            <p
                className="border-t border-border/70 px-3 py-2 text-[0.7rem] leading-snug text-muted-foreground"
            >
                Anonymous, this shows the <span className="text-foreground">public graph</span>
                (the guestbook). Log in to littleX above and it switches to that
                user's graph - profiles, tweets and follows you create.
            </p>
        </div>;
}
