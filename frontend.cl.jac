"""This is Jac - frontend shell.

Owns the shared client state and the server-walker handlers, then composes the
scroll-driven showcase from the section components in `components/`. The
guestbook and graph-traversal sections are wired to live `server.jac` walkers;
the rest pair real Jac source with captured or in-browser demos. Handler bodies
live in `frontend.impl.jac`.
"""

sv import from .server {
    sign_guestbook,
    get_guestbook,
    explore_graph
}
sv import from .server { GuestEntry, GraphSnapshot }

import from .components.Nav { Nav }
import from .components.HeroSection { HeroSection }
import from .components.FullstackSection { FullstackSection }
import from .components.OspSection { OspSection }
import from .components.ByllmSection { ByllmSection }
import from .components.NativeSection { NativeSection }
import from .components.WasmShooterSection { WasmShooterSection }
import from .components.OutroSection { OutroSection }
import "./global.css";

def:pub app -> JsxElement {
    has darkMode: bool = True,
        guestbook: list[GuestEntry] = [],
        gbName: str = "",
        gbMessage: str = "",
        gbSigning: bool = False,
        snapshot: GraphSnapshot | None = None,
        exploring: bool = False;

    can with entry {
        loadInitial();
    }

    can with [darkMode] entry {
        if darkMode {
            document.documentElement.classList.add("dark");
        } else {
            document.documentElement.classList.remove("dark");
        }
    }

    async def loadInitial -> None;
    async def signGuestbook -> None;
    async def runExplore -> None;

    return
        <div className="min-h-screen bg-background text-foreground">
            <Nav {darkMode} onToggleTheme={lambda { darkMode = not darkMode; }}/>
            <main>
                <HeroSection/>
                <FullstackSection
                    entries={guestbook}
                    name={gbName}
                    message={gbMessage}
                    onNameChange={lambda v: str { gbName = v; }}
                    onMessageChange={lambda v: str { gbMessage = v; }}
                    onSign={signGuestbook}
                    signing={gbSigning}
                />
                <OspSection {snapshot} {exploring} onExplore={runExplore}/>
                <ByllmSection/>
                <NativeSection/>
                <WasmShooterSection/>
                <OutroSection/>
            </main>
        </div>;
}
