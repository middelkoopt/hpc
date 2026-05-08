# Session Handoff — hpc coordinator

To resume: open this file and tell Claude `continue with handoff-prompt.md`.

---

## Before Starting

**Pause before investigating.** Ask the user: "Do you have new context, logs, or observations
before I start?" Do not open files or grep until the user has had a chance to share.

---

## Active Work

**Infrastructure / recipe testing** — see `hpc-lab/handoff-prompt.md` for current state.

**Cross-cutting / design** — none in progress.

---

## Last Session Summary (2026-05-08)

Set up the `~/projects/hpc/` workspace coordinator. Repos cloned in:
`hpc-lab/`, `ohpc-3.x/`, `ohpc-4.x/`, `warewulf/`, `warewulf-node-images/`.
Coordinator files written: `CLAUDE.md`, `PROCESS.md`, `handoff-prompt.md`,
`hpc.code-workspace`, `docs/workspace-design.md`.

`ohpc-jetstream2` is now historical (tm-dev removed). Active infra work continues in `hpc-lab/`.

---

## Pending

- [x] Update `hpc-lab/` remote from `ohpc-jetstream2` → `middelkoopt/hpc-lab`
- [x] Update `hpc-lab/CLAUDE.md` header (still says "ohpc-jetstream2")
- [x] Push coordinator to `middelkoopt/hpc`
- [x] Push `hpc-lab/tm-dev` as `main` to `middelkoopt/hpc-lab`

---

## Infrastructure State

- Proxy: unknown — check `hpc-lab/proxy/local.env`
- Cloud VMs: none running (last known state)

---

## Quick Reference

```bash
# Infrastructure work
cd ~/projects/hpc/hpc-lab
./run.py --target=openeuler-22.03 --provisioner=warewulf3   # last active run

# OpenHPC docs
cd ~/projects/hpc/ohpc-4.x/docs/install
make

# Warewulf
cd ~/projects/hpc/warewulf
git log middelkoopt/main..HEAD --oneline
```
