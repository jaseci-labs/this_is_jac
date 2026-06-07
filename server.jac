"""This is Jac - the live object-spatial backend.

Two demos run against a real persistent graph:

  - **Guestbook** - every signature is a `Visitor` node hung off a root and
    wired with a `Signed` edge. `get_guestbook` fans out across all roots and
    gathers them. Data lives in the graph; it survives restarts.
  - **Graph traversal** - a small fixed topic graph (`Topic` nodes joined by
    `Link` edges) that a walker explores, recording the exact order it visited
    nodes so the client can animate the path the walker took.

Walkers are the mobile agents the client `root spawn`s. Each declares where it
starts (`with Root entry`) and how it reacts at each node type (`with Topic
entry`). Traversal is always `visit`, never a hand-rolled loop.
"""

import datetime;

def _now -> str {
    return datetime.datetime.now(datetime.UTC).replace(tzinfo=None).isoformat() + "Z";
}

# ─── View models: the typed contract handed back to the client ───────────────
obj GuestEntry {
    has id: str,
        name: str,
        message: str,
        created_at: str;
}

obj GraphNodeView {
    has id: str,
        label: str,
        kind: str;
}

obj GraphSnapshot {
    has nodes: list[GraphNodeView],
        edges: list[list[str]],
        path: list[str],
        log: list[str];
}

# ─── Edges: the relationships in the graph ───────────────────────────────────
edge Signed {}
edge Link {}

# ─── Nodes: data plus the method that presents it as a view ──────────────────
node Visitor {
    has name: str = "",
        message: str = "",
        created_at: str = "";

    def to_view -> GuestEntry {
        return GuestEntry(
            id=jid(self),
            name=self.name,
            message=self.message,
            created_at=self.created_at
        );
    }
}

node Topic {
    has label: str = "",
        kind: str = "topic";

    def to_view -> GraphNodeView {
        return GraphNodeView(id=jid(self), label=self.label, kind=self.kind);
    }
}

# ─── Guestbook walkers ───────────────────────────────────────────────────────
walker:pub sign_guestbook {
    has name: str = "",
        message: str = "",
        reports: list[GuestEntry] = [];

    can run with Root entry {
        clean_name = self.name.strip()[:40] or "anonymous";
        clean_msg = self.message.strip()[:200];
        if not clean_msg {
            return;
        }
        fresh = here +>: Signed() :+> Visitor(
            name=clean_name, message=clean_msg, created_at=_now()
        );
        grant(fresh[0], level=ConnectPerm);
        report fresh[0].to_view();
    }
}

walker:pub get_guestbook {
    has results: list[GuestEntry] = [],
        seen: dict[str, bool] = {},
        reports: list[list[GuestEntry]] = [];

    can run with Root entry {
        for r in allroots() {
            visit [r-->[?:Visitor]];
        }
    }

    can gather with Visitor entry {
        vid = jid(here);
        if vid not in self.seen {
            self.seen[vid] = True;
            self.results.append(here.to_view());
        }
    }

    can deliver with Root exit {
        self.results.sort(key=lambda e: GuestEntry : e.created_at, reverse=True);
        report self.results[:50];
    }
}

# ─── Graph-traversal demo ────────────────────────────────────────────────────
# Build a small, fixed topic graph the first time it is asked for. The shape is
# hand-wired so the traversal animation is legible: a central `Jac` topic
# branches into the four pillars, each of which links to a concrete capability.
def _build_demo_graph(anchor: Topic) -> None {
    if [anchor-->[?:Topic]] {
        return;
    }
    osp = anchor ++> Topic(label="Object-Spatial", kind="pillar");
    ai = anchor ++> Topic(label="AI-native", kind="pillar");
    native = anchor ++> Topic(label="Native", kind="pillar");
    web = anchor ++> Topic(label="Fullstack", kind="pillar");

    osp[0] ++> Topic(label="walkers", kind="leaf");
    osp[0] ++> Topic(label="nodes & edges", kind="leaf");
    ai[0] ++> Topic(label="by llm()", kind="leaf");
    native[0] ++> Topic(label="wasm", kind="leaf");
    native[0] ++> Topic(label="machine code", kind="leaf");
    web[0] ++> Topic(label="one language", kind="leaf");
}

walker:pub explore_graph {
    has nodes: list[GraphNodeView] = [],
        edges: list[list[str]] = [],
        path: list[str] = [],
        log: list[str] = [],
        seen: dict[str, bool] = {},
        reports: list[GraphSnapshot] = [];

    can run with Root entry {
        matches = [
            t
            for t in [-->[?:Topic]]
            if t.label == "Jac"
        ];
        if matches {
            anchor = matches[0];
        } else {
            anchor = (here ++> Topic(label="Jac", kind="root"))[0];
        }
        _build_demo_graph(anchor);
        self.log.append("walker spawned at Jac");
        visit [anchor];
    }

    can walk with Topic entry {
        tid = jid(here);
        if tid not in self.seen {
            self.seen[tid] = True;
            self.nodes.append(here.to_view());
            self.path.append(tid);
            self.log.append("visited " + here.label);
        }
        for n in [-->[?:Topic]] {
            self.edges.append([tid, jid(n)]);
        }
        visit [-->[?:Topic]];
    }

    can deliver with Root exit {
        self.log.append("traversal complete: " + str(len(self.path)) + " nodes");
        report GraphSnapshot(
            nodes=self.nodes, edges=self.edges, path=self.path, log=self.log
        );
    }
}
