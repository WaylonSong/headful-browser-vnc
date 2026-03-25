# headful-browser-vnc

Overview

headful-browser-vnc provides a controlled, auditable, headful Chromium browsing environment on a server for cases where full browser rendering and occasional human interaction are required. It combines Xvfb, a window manager, and x11vnc (optional noVNC) to present the server-side browser UI to an operator, while offering programmatic integration points (Chrome Remote Debugging / CDP) for automated capture of cookies, rendered HTML, and screenshots.

Primary objective

- Enable reliable, repeatable automation workflows that require the ability to escalate to a human operator for tasks that cannot be solved purely by automation (CAPTCHA solving, challenge pages, multi-factor authentication, manual login flows). The skill's intent is to: (1) run a headful Chrome instance in an isolated profile; (2) expose a secure operator-visible UI to the server browser (VNC/noVNC) so a human can intervene; (3) preserve and export the resulting browser session artifacts (cookies, outerHTML, screenshots) back into automated pipelines for continued processing.

Key capabilities

- Headful browser execution: launch Google Chrome / Chromium with an isolated user data directory and configurable flags (proxy, remote-debugging-port, extra args) on a server X display provided by Xvfb.
- Operator UI: present the running browser to an operator via x11vnc (or optional noVNC web proxy). Operators can connect over SSH-forwarded ports or noVNC with token gating to perform manual actions (solve CAPTCHAs, authenticate), then signal the system to capture artifacts.
- Programmatic capture: export rendered outerHTML, full-page screenshots, and cookies using Chrome CDP (Playwright/Puppeteer compatible). Exports are intended for downstream automated analysis or storage.
- Safe restart and recovery: helpers to restart Chrome when flags change, with explicit user confirmation required for any action that may terminate existing browser instances.
- Artifact hygiene: captured artifacts are written to an artifacts directory with restrictive file permissions. The skill logs actions and writes diagnostic artifacts to facilitate debugging and comparison-based analysis.

Security, privacy, and operational notes

- VNC security: the skill creates per-session passfiles (rfbauth) when possible; noVNC should be bound to loopback or token-gated. Do not expose VNC/noVNC endpoints to the public internet without additional access controls. Store passfiles with mode 600.
- Sensitive artifacts: cookies and rendered page artifacts are sensitive. They are stored under the skill's out/ directory with restrictive permissions; users are responsible for secure storage and timely cleanup.
- Privileged operations: installing system packages and enabling systemd units require sudo and explicit user consent. The scripts will not perform privileged actions automatically unless the operator explicitly enables the auto-install path (see below).

Supported VNC implementations

- The skill supports multiple VNC backends; behavior is controlled via the skill-local .env file (VNC_IMPLEMENTATION): auto (default), tigervnc, tightvnc, realvnc. When possible the skill prefers non-interactive rfbauth generation via vncpasswd; when unavailable it prompts the operator and documents fallback behavior.

Operational interface (scripts)

Scripts are located in skills/headful-browser-vnc/scripts/ and provide a concise, script-level interface for integrators and operators.

- start_vnc.sh <session_id> [display=:99] [widthxheight]
  Launch Xvfb, window manager (optional), and x11vnc for an interactive session. Prints a one-line summary of the actual VNC listening port after startup.

- stop_vnc.sh <session_id> [display=:99]
  Stop the x11vnc/Xvfb session associated with the session id.

- start_chrome_debug.sh <session_id> [--proxy=...] [remote-debug-port]
  Launch a headful Chrome instance attached to the session's DISPLAY and with a dedicated user-data directory. Sets up Chrome remote debugging for programmatic attachment.

- export_page.sh <session_id> <url> [devtools-port]
  Use Chrome CDP to load the URL in the running headful Chrome and export rendered outerHTML and a full-page screenshot.

- export_cookies.sh <session_id> [devtools-port]
  Export cookies from the running Chrome instance via CDP.

Usage patterns

- Manual recovery / investigation: operators can start a session, attach via VNC/noVNC, perform manual remediation (solve CAPTCHA, authenticate), then call export_page.sh/export_cookies.sh to capture artifacts for automated pipelines.
- One-by-one deep retry: the recommended debugging workflow is to run single-item retries through the headful path (start session → run Chrome → escalate to operator if needed → capture artifacts → record comparison samples). This reduces WAF/anti-bot escalation caused by high concurrency and preserves reproducible debugging traces.

Configuration (.env)

Place a skill-local skills/headful-browser-vnc/.env (chmod 600) to persist runtime defaults. Key fields:

- VNC_PASSFILE: path to passfile (e.g. /tmp/vnc/passwd)
- VNC_PORT: optional explicit TCP port to bind x11vnc (if omitted the script will report the actual port in use)
- VNC_IMPLEMENTATION: auto|tigervnc|tightvnc|realvnc
- VNC_DISPLAY: X display (default :99)
- VNC_RESOLUTION: screen resolution (default 1366x768)
- REMOTE_DEBUG_PORT: Chrome remote debugging port (default 9222)
- PROXY_URL / HTTP_PROXY / HTTPS_PROXY: optional proxy settings

Install and dependencies

- INSTALL.sh contains interactive guidance and optional prompts for installing Chrome, node, Playwright, and VNC helper tools. The installer will not run sudo operations without explicit consent.
- Programmatic export paths prefer Node + Playwright; a Python fallback is available but optional.

Auto-install behaviour and safety (new)

- The installer supports an optional auto-install path but it is gated behind two explicit confirmations to avoid accidental privileged operations:
  - CLI flag: --auto-install (sets an internal AUTO_INSTALL=true for the current run).
  - Runtime confirmation: when the installer proposes a distro-specific command it will first ask for confirmation via the usual prompt, then it will print the exact command and require the operator to type the full word yes (not y). Only if both confirmations are provided will the installer execute the command.
- Default behavior remains conservative: by default the installer only prints distro-appropriate install commands and waits for the operator to run them manually. If you prefer to never allow automatic installs, run INSTALL.sh without --auto-install.

Templates and integration

- templates/x11vnc.service.j2 — systemd unit template for persistent sessions (requires sudo to install)
- templates/novnc.service.j2 — noVNC service template

Integration guidance for maintainers

- Use Chrome CDP (devtools) for deterministic exports. Prefer attaching to an already-running headful Chrome instance rather than launching short-lived headless instances when reproducing a previously observed UI state.
- Persist session artifacts and index them (timestamp, URL, session id, VNC port, devtools port) so comparison automation can operate on operator-validated examples.
- When embedding into automated pipelines, clearly separate automated actions from operator interventions; require explicit human confirmation for destructive actions (Chrome restarts, service reconfiguration).

Testing

- A non-privileged smoke test is provided at skills/headful-browser-vnc/tests/smoke_test.sh. It performs a basic start → launch → export → cleanup sequence and is useful for CI verification.

Support and contribution

- The skill is maintained in this workspace. When contributing changes, follow the repository conventions: create backups before modifying INSTALL.sh or start/stop scripts, run bash -n for syntax validation, and preserve audit logs and artifacts.

License

- Include an appropriate LICENSE file when publishing (e.g., MIT). Update author/maintainer fields in SKILL.md prior to external publication.

Portability and supported environments

This skill is designed primarily for Linux environments (Debian/Ubuntu and comparable distributions). Two supported deployment targets are described below:

- Native Linux: The scripts and INSTALL.sh provide distro-specific guidance (apt/dnf/pacman). The runtime contract expects Xvfb, x11vnc, a VNC passfile, and a headful Chrome/Chromium binary. Systemd units (templates/x11vnc.service.j2) are provided for persistent deployments.

- Docker: To maximise portability across hosts, a Docker reference image and docker-compose example are provided in the docker/ directory. The container bundles Xvfb, x11vnc, Chromium, and helper scripts so the same skill can run consistently on different hosts that support Docker.

Notes on other OSes

- macOS and Windows can run headful Chrome, but lack a native Xvfb/X11 stack and differ in VNC tooling and service management. For portability it is recommended to run this skill inside a Linux VM or Docker container on those platforms rather than attempt a full native port.

If you want, I can (1) create a hardened Docker image (smaller base, non-root user, Google Chrome .deb) — reply make-docker-refine, or (2) extend INSTALL.sh with more distro branches — reply linux-harden.

Example: safe auto-install run

To allow the installer to perform distro package manager actions automatically, run with explicit --auto-install and be prepared to type the full confirmation word. Example:

  AUTO_INSTALL=true ./skills/headful-browser-vnc/scripts/INSTALL.sh --auto-install

The script will: (1) detect your distro and print the exact command it plans to run; (2) ask for a normal y/N confirmation; (3) print the command and require you to type the exact word yes to proceed; (4) only then execute the command.

If you prefer to always review and run commands manually, omit --auto-install and the script will only print distro-appropriate commands for you to run yourself.


---

Short example run transcript (what prompts look like)

Below is a short, representative transcript demonstrating the installer flow when a few components are missing and the operator chooses the manual path (no auto-install). Prompts shown are exact prompts produced by the current INSTALL.sh.

$ ./skills/headful-browser-vnc/scripts/INSTALL.sh
Platform install hints (guidance-only — these commands will NOT be run automatically):

Debian / Ubuntu (apt):
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends \
    xvfb x11vnc fluxbox x11-utils tigervnc-standalone-server tightvnc-tools \
    fonts-noto-cjk fontconfig chromium-browser google-chrome-stable \
    nodejs npm python3-pip

---
Missing requirements: Xvfb x11vnc chrome node VNC_PASSFILE .env
--- Handling missing: Xvfb ---
Install Xvfb? (y/N) n
Skip. Manual: sudo apt-get install xvfb
Press Enter when done...
--- Handling missing: x11vnc ---
Install x11vnc? (y/N) y
VNC Port [5901]: 5901
Enter VNC passfile path [/home/user/vnc_passwd]: /home/user/.vnc/passwd
Tool 'vncpasswd' found. Preparing automated generation...
Enter VNC password (hidden): ********
Confirm password: ********
SUCCESS: rfbauth generated at /home/user/.vnc/passwd
--- Handling missing: chrome ---
Select Chrome version:
1) Google Chrome (Recommended)
2) Chromium (Snap)
3) Skip
Choice [1-3] (default 1): 3
Skipped.
--- Handling missing: node ---
Install Node.js v22+ using suggested command? (y/N) n
Skipped automatic install. Please run the printed command manually.
--- Handling missing: .env ---
Create template .env? (y/N) y
Created skills/headful-browser-vnc/.env


