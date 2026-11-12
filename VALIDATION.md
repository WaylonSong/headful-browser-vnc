# Validation record — 2026-11-12

Release artifact: 2.0.0, imported from the ClawHub 1.0.2 release.
This record describes verification at packaging time; registry publication does
not add Linux runtime verification. No GitHub release is part of this task.

## Completed on this macOS host

- `npm test`: 9 exporter behavior tests passed.
- `python3 -m unittest discover -s tests -p 'test_*.py'`: 11 passed,
  1 Linux /proc process-isolation test skipped.
- `npm run test:browser`: real Google Chrome CDP integration passed with
  Playwright 1.65.0, a private temporary profile and local HTTP fixture.
  Verified no reload/new tab, retained unsaved input/sessionStorage, scoped cookie
  export, current-origin localStorage, stale-target rejection, and a live browser
  after the export client disconnected. The test browser was headless; this does
  not validate the Linux display/VNC pipeline.
- Bash syntax, Python compilation and JavaScript syntax checks passed.
- skill-creator quick_validate.py: passed, using PyYAML in a temporary venv.
- Dependency lockfile version matches package.json. Skill/package/card metadata
  consistently identifies version 2.0.0.

## Not completed here

The full Linux lifecycle test was not run: this host has no Linux Xvfb/x11vnc
runtime, and its installed Docker application could not start. The smoke script
correctly exits nonzero on this unsupported host.

The supplied Linux test covers sandboxed headful Chrome, authenticated Xvfb,
process-owned loopback listeners, noVNC serving, per-session isolation, capture,
cooperative handoff and repeated stop. The GitHub Actions workflow invokes it,
but that workflow has not been dispatched or observed in this task.

Outstanding verification: run `./tests/smoke_test.sh` as a non-root Linux user with the
documented dependencies, and verify operator interaction through a real VNC
viewer/noVNC. There is no verified Docker image in this release.

## Deliberate limits

- Pause/resume requires cooperation from external automation controllers.
- Storage export omits IndexedDB, sessionStorage and device-bound credentials.
- HTML and screenshot capture is sequential, not an atomic/offline archive.
- Profiles, logs and exports are retained after stop; deletion is explicit.
- Loopback listeners do not isolate the browser from other local tenants.
