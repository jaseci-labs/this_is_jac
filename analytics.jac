"""This is Jac - the analytics microservice (the provider).

A standalone server module. The guestbook server `sv import`s this; the first
time it calls `analyze(...)` the runtime spawns THIS module as its own
`jac start` process and routes the call to it. `pid` is this process's own
os.getpid() - proof it is not the caller's process."""

import os;

obj AnalyticsReport {
    has pid: int,
        score: float,
        service: str = "analytics";
}

def:pub analyze(signatures: int) -> AnalyticsReport {
    # runs in analytics' OWN process - pid proves it
    return AnalyticsReport(pid=os.getpid(), score=float(signatures) * 1.5);
}
