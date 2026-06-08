"""This is Jac - the live object-spatial backend.

Two demos run against a real persistent graph:

  - **Guestbook** - every signature is a `Visitor` node grouped under a `Day`
    node for the date it was signed: `root -> Day -> Visitor`. `get_guestbook`
    fans out across all roots, descends each day, and gathers them. Data lives
    in the graph; it survives restarts.
  - **Graph traversal** - `explore_graph` walks the REAL graph from the root,
    crossing each `Day` and the `Visitor`s under it, recording the order it
    crossed them, so the client draws the actual live topology (no demo data).

Walkers are the mobile agents the client `root spawn`s. Each declares where it
starts (`with Root entry`) and how it reacts at each node type (`with Visitor
entry`). Traversal is always `visit`, never a hand-rolled loop.
"""

import datetime;

def _now -> str {
    return datetime.datetime.now(datetime.UTC).replace(tzinfo=None).isoformat() + "Z";
}

def _today -> str {
    return datetime.datetime.now(datetime.UTC).date().isoformat();
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
edge OnDay {}  # root -> Day

edge Signed {}  # Day -> Visitor


# ─── Nodes: data plus the method that presents it as a view ──────────────────
# Signatures are grouped under the day they were signed.
node Day {
    has date: str = "";
}

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
        # find-or-create today's Day node, then hang the signature under it
        today = _today();
        days = [
            d
            for d in [here-->[?:Day]]
            if d.date == today
        ];
        if days {
            day = days[0];
        } else {
            day = (here +>: OnDay() :+> Day(date=today))[0];
            grant(day, level=ConnectPerm);
        }
        fresh = day +>: Signed() :+> Visitor(
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
            visit [r-->[?:Day]];
        }
    }

    can descend with Day entry {
        visit [here-->[?:Visitor]];
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

# ─── Graph traversal (real data) ─────────────────────────────────────────────
# Walk the real graph from the root: visit every Visitor the guestbook created,
# recording the visit order + the root->visitor edges, so the OSP section draws
# the actual live topology. No synthetic/demo nodes.
walker:pub explore_graph {
    has rid: str = "",
        nodes: list[GraphNodeView] = [],
        edges: list[list[str]] = [],
        path: list[str] = [],
        log: list[str] = [],
        reports: list[GraphSnapshot] = [];

    can run with Root entry {
        self.rid = jid(here);
        self.nodes.append(GraphNodeView(id=self.rid, label="root", kind="root"));
        self.path.append(self.rid);
        self.log.append("walker spawned at root");
        visit [-->[?:Day]];
    }

    can walk_day with Day entry {
        did = jid(here);
        self.nodes.append(GraphNodeView(id=did, label=here.date, kind="day"));
        self.edges.append([self.rid, did]);
        self.path.append(did);
        self.log.append("entered " + here.date);
        visit [-->[?:Visitor]];
    }

    can walk with Visitor entry {
        vid = jid(here);
        parents = [here<--[?:Day]];
        did = jid(parents[0]) if parents else self.rid;
        self.nodes.append(GraphNodeView(id=vid, label=here.name, kind="visitor"));
        self.edges.append([did, vid]);
        self.path.append(vid);
        self.log.append("visited " + here.name);
    }

    can deliver with Root exit {
        self.log.append("traversal complete: " + str(len(self.nodes)) + " nodes");
        report GraphSnapshot(
            nodes=self.nodes, edges=self.edges, path=self.path, log=self.log
        );
    }
}
