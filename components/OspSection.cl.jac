"""Object-Spatial section: the program is a graph and the walker is the agent
that moves through it. The right panel renders the LIVE result of the
`explore_graph` walker in `guestbook.jac` - the actual nodes it visited, the edges
it crossed, and the order it crossed them (the numbered badges), plus the
walker's own log. Hit re-run to spawn it again."""

import from "lucide-react" { Footprints, RefreshCw, GitBranch }
import from .ui.card { Card, CardContent }
import from .ui.button { Button }
import from .CodeBlock { CodeBlock }
import from .SectionShell { SectionShell }
sv import from ..guestbook { GraphSnapshot }

glob _CODE: str = """# Signatures are grouped by date: root.shared -> Day -> Visitor,
# all real graph data, not a fixture. `root.shared` is the public
# graph every anonymous request runs on - one walk reads it all.
node Day { has date: str; }
node Visitor { has name: str, message: str; }
edge OnDay {}  edge Signed {}

# The walker starts at the shared root and reacts at each node
# type it lands on. Traversal is `visit`, never a hand-rolled loop.
walker:pub explore_graph {
    has path: list[str] = [];

    can run with `root entry {
        visit [root.shared-->[?:Day]]; # step onto the day nodes
    }
    can walk_day with Day entry {
        visit [-->[?:Visitor]];        # then each day's signatures
    }
    can walk with Visitor entry {
        self.path.append(here.name);   # record the visit
    }
}""";

"""Fill color for a node by its role in the real graph."""
def _node_fill(kind: str) -> str {
    if kind == "root" {
        return "var(--primary)";
    }
    if kind == "day" {
        return "color-mix(in oklch, var(--primary) 72%, var(--muted))";
    }
    return "color-mix(in oklch, var(--primary) 45%, var(--muted))";
}

def:pub OspSection(
    snapshot: GraphSnapshot | None,
    exploring: bool,
    onExplore: Callable[[], None],
) -> JsxElement {
    nodes = snapshot.nodes if snapshot else [];
    edges = snapshot.edges if snapshot else [];
    path = snapshot.path if snapshot else [];
    log = snapshot.log if snapshot else [];

    # Real layout: root on top, the Day nodes in a middle row, and each
    # signature (Visitor) spread along the bottom row under its day.
    positions: dict[str, dict] = {};
    roots = [n for n in nodes if n.kind == "root"];
    days = [n for n in nodes if n.kind == "day"];
    visitors = [n for n in nodes if n.kind == "visitor"];
    for n in roots {
        positions[n.id] = {"x": 500.0, "y": 60.0};
    }
    dcnt = len(days);
    for (i, n) in enumerate(days) {
        x = 500.0 if dcnt <= 1 else 160.0 + i * (680.0 / (dcnt - 1));
        positions[n.id] = {"x": x, "y": 250.0};
    }
    vcnt = len(visitors);
    for (i, n) in enumerate(visitors) {
        x = 500.0 if vcnt <= 1 else 90.0 + i * (820.0 / (vcnt - 1));
        positions[n.id] = {"x": x, "y": 430.0};
    }

    order: dict[str, int] = {};
    for (i, nid) in enumerate(path) {
        order[nid] = i + 1;
    }

    edge_lines = [];
    for e in edges {
        if e[0] in positions and e[1] in positions {
            a = positions[e[0]];
            b = positions[e[1]];
            edge_lines.append({"x1": a["x"], "y1": a["y"], "x2": b["x"], "y2": b["y"]});
        }
    }

    node_items = [];
    for n in nodes {
        if n.id in positions {
            p = positions[n.id];
            radius = 26.0;
            loff = 44.0;
            if n.kind == "day" {
                radius = 20.0;
                loff = 36.0;
            } elif n.kind == "visitor" {
                radius = 16.0;
                loff = 32.0;
            }
            node_items.append(
                {
                    "x": p["x"],
                    "y": p["y"],
                    "label": n.label,
                    "fill": _node_fill(n.kind),
                    "r": radius,
                    "ord": str(order[n.id]) if n.id in order else "",
                    "ly": p["y"] + loff
                }
            );
        }
    }

    return
        <SectionShell
            id="osp"
            eyebrow="Object-Spatial"
            title="The program is a graph; walkers walk it"
            subtitle="Data lives in nodes joined by typed edges; logic rides on walkers that move through the topology. The graph on the right is real - the walker just traversed this server's graph: each guestbook signature above, grouped under the day it was signed."
        >
            <div className="grid items-start gap-8 lg:grid-cols-2">
                <CodeBlock code={_CODE} filename="guestbook.jac"/>

                <Card className="border-border bg-card/60">
                    <CardContent className="flex flex-col gap-4 p-6">
                        <div className="flex items-center justify-between">
                            <span className="flex items-center gap-2 text-sm font-medium text-foreground">
                                <GitBranch size={15} className="text-primary"/>
                                explore_graph - live traversal
                            </span>
                            <Button
                                variant="outline"
                                size="sm"
                                className="gap-1.5 rounded-full"
                                disabled={exploring}
                                onClick={lambda { onExplore(); }}
                            >
                                <RefreshCw
                                    size={13}
                                    className={"animate-spin" if exploring else ""}
                                />
                                {"Walking..." if exploring else "Spawn walker"}
                            </Button>
                        </div>

                        <div className="overflow-hidden rounded-lg border border-border bg-background/40">
                            <svg viewBox="0 0 1000 520" className="w-full">
                                {[
                                    <line
                                        key={"e" + str(idx)}
                                        x1={ln["x1"]}
                                        y1={ln["y1"]}
                                        x2={ln["x2"]}
                                        y2={ln["y2"]}
                                        stroke="var(--primary)"
                                        strokeOpacity={0.28}
                                        strokeWidth={2}
                                    />
                                    for (idx, ln) in enumerate(edge_lines)
                                ]}
                                {[
                                    <g key={"n" + str(idx)}>
                                        <circle
                                            cx={nd["x"]}
                                            cy={nd["y"]}
                                            r={nd["r"]}
                                            fill={nd["fill"]}
                                            stroke="var(--background)"
                                            strokeWidth={3}
                                        />
                                        <text
                                            x={nd["x"]}
                                            y={nd["y"] + 5.0}
                                            textAnchor="middle"
                                            className="fill-primary-foreground font-mono text-[15px] font-bold"
                                        >
                                            {nd["ord"]}
                                        </text>
                                        <text
                                            x={nd["x"]}
                                            y={nd["ly"]}
                                            textAnchor="middle"
                                            className="fill-foreground text-[15px]"
                                        >
                                            {nd["label"]}
                                        </text>
                                    </g>
                                    for (idx, nd) in enumerate(node_items)
                                ]}
                            </svg>
                        </div>

                        <div className="flex items-start gap-2 text-xs text-muted-foreground">
                            <Footprints size={14} className="mt-0.5 shrink-0 text-primary"/>
                            <span className="font-mono leading-relaxed">
                                {" → ".join(log) if log else "spawn the walker to trace its path"}
                            </span>
                        </div>
                        {if len(node_items) <= 1 {
                            <div className="rounded-lg border border-border bg-background/50 p-3 text-xs text-muted-foreground">
                                Just the root so far.{" "}
                                <a href="#fullstack" className="font-medium text-primary hover:underline">
                                    Sign the guestbook
                                </a>
                                {" "}above, then re-spawn the walker to watch the graph grow.
                            </div>
                        }}
                    </CardContent>
                </Card>
            </div>
        </SectionShell>;
}
