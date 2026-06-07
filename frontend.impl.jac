"""This is Jac - frontend handler implementations.

Each handler spawns a `server.jac` walker on the graph (`root spawn ...`) and
folds its `reports` back into client state. Identical call shape to the server
- no fetch, no client SDK, no serializers."""

impl app.loadInitial -> None {
    gb = root spawn get_guestbook();
    guestbook = gb.reports[0] if gb.reports else [];
    gr = root spawn explore_graph();
    snapshot = gr.reports[0] if gr.reports else None;
}

impl app.signGuestbook -> None {
    if not gbMessage.strip() {
        return;
    }
    gbSigning = True;
    root spawn sign_guestbook(name=gbName, message=gbMessage);
    gbMessage = "";
    gb = root spawn get_guestbook();
    guestbook = gb.reports[0] if gb.reports else [];
    gbSigning = False;
}

impl app.runExplore -> None {
    exploring = True;
    gr = root spawn explore_graph();
    snapshot = gr.reports[0] if gr.reports else snapshot;
    exploring = False;
}
