---
name: RPM test workflow via Jetstream2 data directory
description: How to build and deploy custom RPMs for live testing on Jetstream2
type: feedback
---

To test a modified RPM on the Jetstream2 cluster, build it via lima and copy to `~/projects/ohpc-jetstream2/data/` (note: `projects` with an 's').

**Why:** User confirmed this is the standard workflow for testing packages on the live cluster.

**How to apply:** Whenever the user asks to "build and test" an RPM, or after modifying a spec file and wanting to test it:

1. Build: `lima sudo python3 tests/ci/run_build.py tmiddelkoop <path/to/SPECS/foo.spec>`
2. Find output RPM in `/home/tmiddelkoop.guest/rpmbuild/RPMS/<arch>/`
3. Copy to Jetstream2 data dir: `lima cp <rpm_path> ~/projects/ohpc-jetstream2/data/`
4. Create `~/projects/ohpc-jetstream2/data/` if it doesn't exist (use `mkdir -p`)
