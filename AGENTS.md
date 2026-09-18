# Project guidance

- Discuss plans, bugs and results with the user in natural Hinglish. Keep source code, comments and project documents in professional English.
- Build a useful basic app first. Add one feature at a time after usage feedback; do not implement the entire roadmap unprompted.
- Preserve a reliable normal/click-through mode and a reachable escape/quit path.
- Prefer native APIs and no dependencies unless a concrete requirement justifies one.
- Run `bash scripts/test.sh` for drawing-state changes and `bash scripts/build.sh` for app changes. Report GUI verification separately from compile/test success.
- Keep the app offline. Do not add analytics, accounts, licensing services, publishing or paid enrollment without explicit scope.
- Do not change global security settings or install system tooling without need and authorization.
- Preserve unrelated changes. Do not push or publish without explicit authorization.
