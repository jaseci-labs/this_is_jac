"""Object-Spatial section: the program is a graph and the walker is the agent
that moves through it. The right panel renders the LIVE result of the
`explore_graph` walker in `server.jac` - the actual nodes it visited, the edges
it crossed, and the order it crossed them (the numbered badges), plus the
walker's own log. Hit re-run to spawn it again."""

import from "lucide-react" { Footprints, RefreshCw, GitBranch }
import from .ui.card { Card, CardContent }
import from .ui.button { Button }
import from .CodeBlock { CodeBlock }
import from .SectionShell { SectionShell }
sv import from ..server { GraphSnapshot }

glob _CODE: str = """# Nodes hold data; typed edges are the relationships.
node Topic { has label: str; }
edge Link {}

# A walker starts somewhere and reacts at each node it lands
# on. Traversal is `visit`, never a hand-rolled loop.
walker:pub explore_graph {
    has path: list[str] = [];

    can run with `root entry {
        visit [-->[?:Topic]];          # step onto the graph
    }
    can walk with Topic entry {
        self.path.append(here.label);  # record the visit
        visit [-->[?:Topic]];          # fan out to neighbours
    }
}""";

"""Fill color for a node by its role in the demo graph."""
def _node_fill(kind: str) -> str {
    if kind == "root" {
        return "var(--primary)";
    }
    if kind == "pillar" {
        return "color-mix(in oklch, var(--primary) 55%, transparent)";
    }
    return "var(--muted)";
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

    # Layered layout: root on top, pillars in the middle, leaves on the bottom.
    positions: dict[str, dict] = {};
    roots = [n for n in nodes if n.kind == "root"];
    pillars = [n for n in nodes if n.kind == "pillar"];
    leaves = [n for n in nodes if n.kind == "leaf"];
    for n in roots {
        positions[n.id] = {"x": 500.0, "y": 58.0};
    }
    for (i, n) in enumerate(pillars) {
        x = 500.0 if len(pillars) <= 1 else 140.0 + i * (720.0 / (len(pillars) - 1));
        positions[n.id] = {"x": x, "y": 250.0};
    }
    for (i, n) in enumerate(leaves) {
        x = 500.0 if len(leaves) <= 1 else 80.0 + i * (840.0 / (len(leaves) - 1));
        positions[n.id] = {"x": x, "y": 446.0};
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
            label_above = n.kind != "leaf";
            node_items.append(
                {
                    "x": p["x"],
                    "y": p["y"],
                    "label": n.label,
                    "fill": _node_fill(n.kind),
                    "r": 24.0 if n.kind == "root" else (20.0 if n.kind == "pillar" else 15.0),
                    "ord": str(order[n.id]) if n.id in order else "",
                    "ly": (p["y"] - 32.0) if label_above else (p["y"] + 30.0)
                }
            );
        }
    }

    return
        <SectionShell
            id="osp"
            eyebrow="Object-Spatial"
            title="The program is a graph; walkers walk it"
            subtitle="Data lives in nodes joined by typed edges. Logic rides on walkers that move through the topology. The graph on the right is the live output of a walker that just traversed the server's graph."
        >
            <div className="grid items-start gap-8 lg:grid-cols-2">
                <CodeBlock code={_CODE} filename="server.jac"/>

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
                    </CardContent>
                </Card>
            </div>
        </SectionShell>;
}
