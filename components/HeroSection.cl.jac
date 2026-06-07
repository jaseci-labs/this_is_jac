"""Landing hero: the pitch, an install line, and a one-file teaser that hints at
the cl / sv / na trio the rest of the page unpacks."""

import from "lucide-react" { ArrowDown, Terminal }
import from .ui.button { Button }
import from .CodeBlock { CodeBlock }

glob _TEASER: str = """# one file - the graph, the server, the browser, the metal.

node Account { has balance: int = 0; }

walker deposit {
    has amount: int;
    can run with `root entry {
        here ++> Account(balance=self.amount);
        report "saved to the graph";
    }
}

cl {
    def:pub app -> JsxElement {
        return <h1>This is Jac.</h1>;
    }
}

na {
    def add(a: i64, b: i64) -> i64 { return a + b; }  # -> machine code
}""";

def:pub HeroSection -> JsxElement {
    return
        <section
            id="top"
            className="relative flex min-h-screen flex-col items-center justify-center overflow-hidden px-6 pt-16"
        >
            <div className="tij-grid absolute inset-0 -z-10"/>
            <div className="tij-glow absolute inset-x-0 top-0 -z-10 h-[600px]"/>

            <div className="tij-fade-up flex w-full max-w-5xl flex-col items-center text-center">
                <div
                    className="mb-6 inline-flex items-center gap-2 rounded-full border border-border bg-card/60 px-4 py-1.5 text-sm text-muted-foreground backdrop-blur"
                >
                    <span className="size-2 rounded-full bg-primary tij-pulse"/>
                    One language. Frontend, backend, and native.
                </div>

                <h1
                    className="font-display text-6xl font-bold leading-[0.95] tracking-tight text-foreground md:text-8xl"
                >
                    This is <span className="tij-gradient-text">Jac</span>.
                </h1>

                <p className="mt-6 max-w-2xl text-balance text-xl text-muted-foreground">
                    A superset of Python where the program is a graph, the agents
                    are walkers, and the same source runs on the server, in the
                    browser, and on bare metal. Scroll to see it - everything below
                    is built in Jac, and the live demos really run.
                </p>

                <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
                    <a href="#fullstack">
                        <Button size="lg" className="rounded-full px-7 font-semibold">
                            Take the tour
                            <ArrowDown size={18}/>
                        </Button>
                    </a>
                    <div
                        className="flex items-center gap-2 rounded-full border border-border bg-card/60 px-4 py-2.5 font-mono text-sm text-foreground backdrop-blur"
                    >
                        <Terminal size={15} className="text-primary"/>
                        pip install jaclang
                    </div>
                </div>

                <div className="mt-14 w-full max-w-2xl text-left">
                    <CodeBlock code={_TEASER} filename="hello.jac"/>
                </div>
            </div>

            <a
                href="#fullstack"
                className="tij-bounce absolute bottom-8 text-muted-foreground"
                aria-label="Scroll down"
            >
                <ArrowDown size={24}/>
            </a>
        </section>;
}
