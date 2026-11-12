# Headful Browser (VNC)

Publisher: waylonsong. Version: 2.0.0. License: MIT-0.

Persistent Linux Chrome sessions with VNC/noVNC human takeover and CDP capture
of existing tabs. Runtime: Python 3.10+, Node 22+, Xvfb, xauth, x11vnc,
xdpyinfo, Chrome/Chromium and the locked Playwright dependency.

Capabilities: tracked session start/status/stop; cooperative pause/resume;
targetId-based HTML/PNG capture; explicit URL-scoped cookie export; selected-origin
cookie/localStorage export. noVNC is optional and uses installed assets.

Defaults: non-root Chrome with sandbox; Xauthority; loopback VNC/CDP/noVNC;
private state and artifacts; owned-process cleanup; explicit failure reporting.

Limits: pause does not prevent independent CDP clients from acting. Exported
state is incomplete (no IndexedDB/sessionStorage/device-bound credentials).
Profiles and outputs are retained. Loopback is not isolation from local tenants.
No verified Docker image is included; see README.docker.md.

Setup only checks dependencies or interactively creates a new VNC passfile.
It does not execute package managers or remote installer scripts.

See README.md for migration from 1.0.2, deployment and validation.
