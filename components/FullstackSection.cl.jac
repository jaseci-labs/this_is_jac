"""Fullstack section: one language across the wire. The left panel is the real
server + client code; the right panel is a LIVE guestbook backed by the
`sign_guestbook` / `get_guestbook` walkers in `guestbook.jac`. What you type is a
node written into a persistent graph and read back by a walker."""

import from "lucide-react" { Send, MessageSquare, Database, Footprints, Play }
import from .ui.card { Card, CardContent }
import from .ui.input { Input }
import from .ui.textarea { Textarea }
import from .ui.button { Button }
import from .ui.avatar { Avatar, AvatarFallback }
import from .ui.badge { Badge }
import from .CodeBlock { CodeBlock }
import from .GraphView { GraphView }
import from .SectionShell { SectionShell }
sv import from ..guestbook { Visitor, GraphSnapshot }

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

    can run with Root entry {
        visit [root.shared-->[?:Day]]; # step onto the day nodes
    }
    can walk_day with Day entry {
        visit [-->[?:Visitor]];        # then each day's signatures
    }
    can walk with Visitor entry {
        self.path.append(here.name);   # record the visit
    }
}""";

"""Column layout for the walker viz: root on the left, Day nodes in the middle
column, Visitor nodes on the right, each Day vertically centered on its own
visitors. Returns {"pos": {node_id: {"x", "y"}}, "h": svg_height}."""
def _wlayout(snap: GraphSnapshot) -> dict {
    days: list = [];
    vis: list = [];
    for n in snap.nodes {
        if n.kind == "day" {
            days.append(n);
        }
        if n.kind == "visitor" {
            vis.append(n);
        }
    }
    rows = max(len(vis), len(days), 1);
    h = 70 + rows * 46;
    pos: dict = {};
    for i in range(len(vis)) {
        pos[vis[i].id] = {"x": 430.0, "y": 56.0 + i * 46};
    }
    for i in range(len(days)) {
        ys: list = [];
        for e in snap.edges {
            if e[0] == days[i].id and e[1] in pos {
                ys.append(pos[e[1]]["y"]);
            }
        }
        dy = (sum(ys) / len(ys)) if ys else (56.0 + i * 46);
        pos[days[i].id] = {"x": 255.0, "y": dy};
    }
    for n in snap.nodes {
        if n.kind == "root" {
            pos[n.id] = {"x": 70.0, "y": h / 2.0};
        }
    }
    return {"pos": pos, "h": h};
}

def _nfill(kind: str) -> str {
    if kind == "root" {
        return "fill-primary";
    }
    if kind == "day" {
        return "fill-primary/40";
    }
    return "fill-foreground/25";
}

def:pub FullstackSection(
    entries: list[Visitor],
    name: str,
    message: str,
    onNameChange: Callable[[str], None],
    onMessageChange: Callable[[str], None],
    onSign: Callable[[], None],
    signing: bool,
    graphRefresh: int = 0,
    walkerSnap: GraphSnapshot | None = None,
    exploring: bool = False,
    onExplore: Callable[[], None] | None = None,
) -> JsxElement {
    ly: dict = _wlayout(walkerSnap) if walkerSnap else {};
    return
        <SectionShell
            id="fullstack"
            eyebrow="Fullstack"
            title="Introducing a New Paradigm, for a New Way of Problem Solving."
            subtitle="Use graph centric PL semantics to solve problems in an intuitive and elegant way. Sign below and it's persisted to a real graph. (and yes, this is a secret weapon for agentic ai harness building, but that's for another demo ;-))"
        >
            <div>
                <div className="grid items-start gap-8 lg:grid-cols-2">
                    <Card className="border-border bg-card/60">
                        <CardContent className="flex flex-col gap-4 p-6">
                            <div className="flex items-center justify-between">
                                <span
                                    className="flex items-center gap-2 text-sm font-medium text-foreground"
                                >
                                    <MessageSquare size={15} className="text-primary"/>
                                    Live guestbook
                                </span>
                                <Badge
                                    variant="secondary"
                                    className="gap-1 font-normal"
                                >
                                    <Database size={11}/>
                                    {str(len(entries))}{" "}
                                    in graph
                                </Badge>
                            </div>
                            <div className="flex flex-col gap-2">
                                <Input
                                    placeholder="Your name"
                                    value={name}
                                    maxLength={40}
                                    onChange={lambda (e: ChangeEvent) { onNameChange(
                                        e.target.value
                                    ); }}
                                />
                                <Textarea
                                    placeholder="Leave a message for the graph..."
                                    value={message}
                                    rows={2}
                                    maxLength={200}
                                    className="resize-none"
                                    onChange={lambda (e: ChangeEvent) { onMessageChange(
                                        e.target.value
                                    ); }}
                                />
                                <Button
                                    className="self-end rounded-full px-5 font-semibold"
                                    disabled={signing or not message.strip()}
                                    onClick={lambda { onSign(); }}
                                >
                                    <Send size={15}/>
                                    {"Signing..." if signing else "Sign the graph"}
                                </Button>
                            </div>
                            <div
                                className="flex max-h-72 flex-col gap-3 overflow-y-auto pr-1"
                            >
                                {if len(entries) == 0 {
                                    <div
                                        className="py-8 text-center text-sm text-muted-foreground"
                                    >
                                        No signatures yet - be the first node.
                                    </div>
                                }}
                                {[
                                    <div className="tij-fade-up flex gap-3" key={jid(e)}>
                                        <Avatar className="size-9 shrink-0">
                                            <AvatarFallback
                                                className="bg-primary/15 text-sm text-primary"
                                            >
                                                {(e.name[0].upper() if e.name else "?")}
                                            </AvatarFallback>
                                        </Avatar>
                                        <div
                                            className="min-w-0 flex-1 rounded-lg border border-border bg-background/50 px-3 py-2"
                                        >
                                            <div
                                                className="text-sm font-semibold text-foreground"
                                            >
                                                {e.name}
                                            </div>
                                            <div
                                                className="break-words text-sm text-muted-foreground"
                                            >
                                                {e.message}
                                            </div>
                                        </div>
                                    </div> for e in entries
                                ]}
                            </div>
                        </CardContent>
                    </Card>
                    <CodeBlock code={_CODE} filename="guestbook.jac"/>
                </div>
                <div className="mt-8 grid items-start gap-8 lg:grid-cols-2">
                    <Card className="border-border bg-card/60">
                        <CardContent className="flex flex-col gap-4 p-6">
                            <div className="flex items-center justify-between">
                                <span
                                    className="flex items-center gap-2 text-sm font-medium text-foreground"
                                >
                                    <Footprints size={15} className="text-primary"/>
                                    explore_graph - live walker traversal
                                </span>
                                <Button
                                    size="sm"
                                    className="rounded-full px-4 font-semibold"
                                    disabled={exploring}
                                    onClick={lambda { onExplore(); }}
                                >
                                    <Play size={14}/>
                                    {"Walking..." if exploring else "Spawn the walker"}
                                </Button>
                            </div>
                            {if walkerSnap {
                                <div className="flex flex-col gap-3">
                                    <svg
                                        viewBox={"0 0 520 " + str(ly["h"])}
                                        className="w-full rounded-lg border border-border bg-background/50"
                                        style={{"maxHeight": "300px"}}
                                    >
                                        {[
                                            <line
                                                key={"e" + str(i)}
                                                x1={ly["pos"][walkerSnap.edges[i][0]]["x"]}
                                                y1={ly["pos"][walkerSnap.edges[i][0]]["y"]}
                                                x2={ly["pos"][walkerSnap.edges[i][1]]["x"]}
                                                y2={ly["pos"][walkerSnap.edges[i][1]]["y"]}
                                                className="stroke-border"
                                                strokeWidth={1.5}
                                            /> for i in range(len(walkerSnap.edges))
                                        ]}
                                        {[
                                            <g key={"n" + walkerSnap.nodes[i].id}>
                                                <circle
                                                    cx={ly["pos"][walkerSnap.nodes[i].id]["x"]}
                                                    cy={ly["pos"][walkerSnap.nodes[i].id]["y"]}
                                                    r={13 if walkerSnap.nodes[i].kind == "root" else 10}
                                                    className={_nfill(walkerSnap.nodes[i].kind)}
                                                />
                                                <text
                                                    x={ly["pos"][walkerSnap.nodes[i].id]["x"]}
                                                    y={ly["pos"][walkerSnap.nodes[i].id]["y"] + 26}
                                                    textAnchor="middle"
                                                    className="fill-muted-foreground font-mono text-[10px]"
                                                >
                                                    {walkerSnap.nodes[i].label[:14]}
                                                </text>
                                            </g> for i in range(len(walkerSnap.nodes))
                                        ]}
                                        {[
                                            <g key={"p" + str(i)}>
                                                <circle
                                                    cx={ly["pos"][walkerSnap.path[i]]["x"] + 14}
                                                    cy={ly["pos"][walkerSnap.path[i]]["y"] - 14}
                                                    r={8}
                                                    className="fill-primary"
                                                />
                                                <text
                                                    x={ly["pos"][walkerSnap.path[i]]["x"] + 14}
                                                    y={ly["pos"][walkerSnap.path[i]]["y"] - 11}
                                                    textAnchor="middle"
                                                    className="fill-primary-foreground text-[9px] font-bold"
                                                >
                                                    {str(i + 1)}
                                                </text>
                                            </g> for i in range(len(walkerSnap.path))
                                        ]}
                                    </svg>
                                    <div
                                        className="max-h-28 overflow-y-auto rounded-lg border border-border bg-background/50 p-3 font-mono text-xs text-muted-foreground"
                                    >
                                        {[
                                            <div key={"l" + str(i)}>
                                                {"> " + walkerSnap.log[i]}
                                            </div> for i in range(len(walkerSnap.log))
                                        ]}
                                    </div>
                                </div>
                            }}
                            {if not walkerSnap {
                                <div
                                    className="flex h-48 items-center justify-center rounded-lg border border-dashed border-border text-center text-sm text-muted-foreground"
                                >
                                    Spawn the walker to traverse the real graph -
                                    root, each Day, every signature - in visit order.
                                </div>
                            }}
                        </CardContent>
                    </Card>
                    <GraphView refreshKey={graphRefresh}/>
                </div>
            </div>
        </SectionShell>;
}
