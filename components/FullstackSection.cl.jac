"""Fullstack section: one language across the wire. The left panel is the real
server + client code; the right panel is a LIVE guestbook backed by the
`sign_guestbook` / `get_guestbook` walkers in `server.jac`. What you type is a
node written into a persistent graph and read back by a walker."""

import from "lucide-react" { Send, MessageSquare, Database }
import from .ui.card { Card, CardContent }
import from .ui.input { Input }
import from .ui.textarea { Textarea }
import from .ui.button { Button }
import from .ui.avatar { Avatar, AvatarFallback }
import from .ui.badge { Badge }
import from .CodeBlock { CodeBlock }
import from .GraphView { GraphView }
import from .SectionShell { SectionShell }
sv import from ..server { GuestEntry }

glob _CODE: str = """# server.jac - a walker IS the endpoint. No routes, no
# controllers; spawning it on the graph runs it server-side.
walker:pub sign_guestbook {
    has name: str, message: str;
    can run with `root entry {
        here +>: Signed() :+> Visitor(
            name=self.name, message=self.message
        );
        report "written to the graph";
    }
}

# frontend.cl.jac - the SAME types, called from the browser.
sv import from .server { sign_guestbook }

impl app.sign {
    root spawn sign_guestbook(name=self.name, msg=self.msg);
}""";

def:pub FullstackSection(
    entries: list[GuestEntry],
    name: str,
    message: str,
    onNameChange: Callable[[str], None],
    onMessageChange: Callable[[str], None],
    onSign: Callable[[], None],
    signing: bool,
) -> JsxElement {
    return
        <SectionShell
            id="fullstack"
            eyebrow="Fullstack"
            title="One language, server to browser"
            subtitle="No REST boilerplate, no client SDK, no type drift. The browser spawns the very same walker that runs on the server - sign below and it's persisted to a real graph."
        >
            <div>
            <div className="grid items-start gap-8 lg:grid-cols-2">
                <Card className="border-border bg-card/60">
                    <CardContent className="flex flex-col gap-4 p-6">
                        <div className="flex items-center justify-between">
                            <span className="flex items-center gap-2 text-sm font-medium text-foreground">
                                <MessageSquare size={15} className="text-primary"/>
                                Live guestbook
                            </span>
                            <Badge variant="secondary" className="gap-1 font-normal">
                                <Database size={11}/>
                                {str(len(entries))} in graph
                            </Badge>
                        </div>

                        <div className="flex flex-col gap-2">
                            <Input
                                placeholder="Your name"
                                value={name}
                                maxLength={40}
                                onChange={lambda e: ChangeEvent { onNameChange(e.target.value); }}
                            />
                            <Textarea
                                placeholder="Leave a message for the graph..."
                                value={message}
                                rows={2}
                                maxLength={200}
                                className="resize-none"
                                onChange={lambda e: ChangeEvent { onMessageChange(e.target.value); }}
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

                        <div className="flex max-h-72 flex-col gap-3 overflow-y-auto pr-1">
                            {if len(entries) == 0 {
                                <div className="py-8 text-center text-sm text-muted-foreground">
                                    No signatures yet - be the first node.
                                </div>
                            }}
                            {[
                                <div className="tij-fade-up flex gap-3" key={e.id}>
                                    <Avatar className="size-9 shrink-0">
                                        <AvatarFallback className="bg-primary/15 text-sm text-primary">
                                            {(e.name[0].upper() if e.name else "?")}
                                        </AvatarFallback>
                                    </Avatar>
                                    <div className="min-w-0 flex-1 rounded-lg border border-border bg-background/50 px-3 py-2">
                                        <div className="text-sm font-semibold text-foreground">
                                            {e.name}
                                        </div>
                                        <div className="break-words text-sm text-muted-foreground">
                                            {e.message}
                                        </div>
                                    </div>
                                </div>
                                for e in entries
                            ]}
                        </div>
                    </CardContent>
                </Card>

                <CodeBlock code={_CODE} filename="server.jac + frontend.cl.jac"/>
            </div>
            <div className="mt-8">
                <GraphView/>
            </div>
            </div>
        </SectionShell>;
}
