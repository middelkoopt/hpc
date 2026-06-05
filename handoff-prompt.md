# Session Handoff — hpc coordinator

To resume: open this file and tell Claude `continue with handoff-prompt.md`.

---

## Before Starting

**Pause before investigating.** Ask the user: "Do you have new context, logs, or observations
before I start?" Do not open files or grep until the user has had a chance to share.

---

## Active Work

### ohpc PR testing — PRs #2598 (3.x) / #2599 (4.x) — COMPLETE ✓

Both PRs verified end-to-end on aarch64 qemu (AlmaLinux 9 / AlmaLinux 10):

- `localtime` overlay: timezone propagated (America/Chicago CDT) ✓
- `makestep 1.0 3` in `/etc/chrony.conf` on compute node ✓
- chrony synchronized to head ✓

Review comments posted by user. TEMP sed patches removed, data/ cleared.

Remaining: restore ohpc branch state (both repos still on `test/pr-*` branches):

```bash
cd ~/projects/hpc/ohpc-3.x && git checkout tm-openeuler-openpbs-3.x
cd ~/projects/hpc/ohpc-4.x && git checkout main
```

---

**warewulf-node-images — PRs / branches in flight:**

1. `tm-update-almalinux` — AlmaLinux 9.8 / 10.2 update. PR open.
2. `tm-image-build-use-aarch64-runners` — native arm64 CI + dynamic matrix. PR open (or ready to open).
3. `tm-update-rocky` — Rocky 9.8 / 10.2 Makefile bumps. Committed, not yet pushed. Waiting on Docker Hub publishing `rockylinux/rockylinux:9.8` / `10.2` base images before opening PR.
4. `tm-wait-online-image` — forces network fully up (`NetworkManager-wait-online`) in almalinux-9 and rockylinux-9 Containerfiles. Committed, not yet pushed.

**Rocky Linux**: once Docker Hub publishes `rockylinux:9.8` / `10.2`, add CI entries to `images.json` and open PR.

---

## Sub-Repo Branch State

| Repo | Branch |
| ---- | ------ |
| `ohpc-3.x/` | `test/pr-2598` (PR review/test branch — **not upstream work branch**) |
| `ohpc-4.x/` | `test/pr-2599` (PR review/test branch — **not upstream work branch**) |
| `warewulf/` | `tm-dsa-8.x` (PR submitted) |
| `warewulf-node-images/` | `tm-image-build-use-aarch64-runners` (active) |
| `hpc-lab/` | `main` |

**Always verify branches before working.**

---

## Last Session Summary (2026-06-05)

- PRs #2598 and #2599 fully tested and verified; review comments posted
- Key finding: `chrony.conf.ww` is in `examples-ohpc` (`examples.spec`), not `docs-ohpc`
- Created `hpc-lab/docs/index.md` and `docs/index.md`
- Updated `ohpc-pr-testing.md`, `rpm-build.md`, `recipe-testing.md`: correct spec, image upgrade step, tmux console debugging, srun verification
- Created `hpc/.claude/settings.json` with project-level allowlist (takes effect next session)

---

## Pending (hpc-lab)

- Restore ohpc branch state (see above)
- openeuler-22.03 / warewulf3 / openpbs — next test target
- openeuler-24.03: only warewulf+slurm in tests/; no openchami/confluent — intentional?
- openEuler 4.x: COPR SP3 publish pending upstream (needed for yq)
- Split `clouds/jetstream/openstack.tf` → `network.tf` + `compute.tf`
- Trim recipe boot sleeps (120s + 90s) — unnecessarily long

---

## Key Rules (session-specific reminders only)

- Rocky Makefile bumps are on `tm-update-rocky` (not yet pushed) — add CI entries and open PR once Docker Hub publishes `rockylinux:9.8` / `10.2` base images
- `images.json` is the source of truth for CI matrix — edit it, not the workflow YAML directly
- Permanent rules (create.sh, Terraform state, TOML format, upstream PRs) are in `hpc-lab/CLAUDE.md`
- Do not save current project state to `~/.claude` memory — use handoff-prompt.md

---

## Infrastructure State

- **Local**: macOS aarch64, qemu via `hpc-lab/clouds/qemu/`
- **Remote x86_64**: `jetstream.ini200001.projects.jetstream-cloud.org` — Ubuntu 24.04 VM running qemu; SSH configured in `~/.ssh/config`, connect with just the hostname
- qemu cluster: almalinux-9 image freshly upgraded; almalinux-10 not yet upgraded
- Proxy: check `hpc-lab/proxy/local.env`
- `clouds/qemu/id_rsa` must exist before running qemu tests (SSH key for head node)

---

## Quick Reference

```bash
# Check Rocky dirty state (uncommitted 9.8/10.2 bumps)
cd ~/projects/hpc/warewulf-node-images && git diff

# Coordinator matrix tool
cd ~/projects/hpc && .venv/bin/python3 .github/workflows/gen-matrix.py
```
