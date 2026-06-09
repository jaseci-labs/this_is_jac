"""This is Jac - frontend handler implementations.

Each handler spawns a `guestbook.jac` walker on the graph (`root spawn ...`) and
folds its `reports` back into client state. Identical call shape to the server
- no fetch, no client SDK, no serializers."""

impl Showcase.loadInitial -> None {
    gb = root spawn get_guestbook();
    guestbook = gb.reports[0] if gb.reports else [];
    gr = root spawn explore_graph();
    snapshot = gr.reports[0] if gr.reports else None;
}

impl Showcase.signGuestbook -> None {
    if not gbMessage.strip() {
        return;
    }
    gbSigning = True;
    root spawn sign_guestbook(name=gbName, message=gbMessage);
    gbMessage = "";
    gb = root spawn get_guestbook();
    guestbook = gb.reports[0] if gb.reports else [];
    gbSigning = False;
    # bump the nonce so GraphView reloads its /graph iframe with the new node
    graphNonce += 1;
}

impl Showcase.runExplore -> None {
    exploring = True;
    gr = root spawn explore_graph();
    snapshot = gr.reports[0] if gr.reports else snapshot;
    exploring = False;
}

impl Showcase.runStats -> None {
    microRunning = True;
    microStats = await guestbook_stats();
    microRunning = False;
}

impl Showcase.loadSource -> None {
    srcFiles = await list_source_files();
    srcLoading = True;
    srcFile = await get_source_file("frontend.cl.jac");
    srcLoading = False;
}

impl Showcase.openSource(path: str) -> None {
    srcLoading = True;
    srcFile = await get_source_file(path);
    srcLoading = False;
}
