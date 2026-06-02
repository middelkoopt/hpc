# Session Handoff — hpc coordinator

To resume: open this file and tell Claude `continue with handoff-prompt.md`.

---

## Before Starting

**Pause before investigating.** Ask the user: "Do you have new context, logs, or observations
before I start?" Do not open files or grep until the user has had a chance to share.

---

## Active Work

**warewulf-node-images — two PRs in flight:**

1. `tm-update-almalinux` — AlmaLinux 9.8 / 10.2 update. PR open.
2. `tm-image-build-use-aarch64-runners` — native arm64 CI + dynamic matrix. PR open (or ready to open).

### Branch `tm-image-build-use-aarch64-runners` — what changed

- `images.json` — single source of truth for all image configs (7 OS groups, 27 entries, 2 arches)
- `.github/workflows/gen-matrix.py` — generates build matrix (images × arches) and merge matrix at runtime
- `.github/workflows/container-publish.yml` — restructured: `setup → build → merge`; native runners; push-by-digest; cosign signs manifest index
- Tested: dual-arch (amd64 + arm64) build, manifest merge, and container boot confirmed working

**Key fixes found during testing:**

- `push:` and `outputs:` can't both be set — push must be embedded in the outputs string (`push=${{ ... }}`)
- `name=ghcr.io/...` must be in outputs for push-by-digest to know the registry target

**Rocky Linux**: once Docker Hub publishes `rockylinux/rockylinux:9.8` and `10.2`,
commit the dirty Makefile changes + add Rocky CI entries, test, then open follow-up PR.

### Uncommitted State

| Repo | Status |
| ---- | ------ |
| `warewulf-node-images/` | Rocky `rockylinux-9/Makefile` and `rockylinux-10/Makefile` dirty (9.8/10.2 bumps) — intentionally not staged |

---

## Sub-Repo Branch State

| Repo | Branch |
| ---- | ------ |
| `ohpc-3.x/` | `tm-warewulf-4.7-3.x` (4.7.0 PR merged upstream — may need branch cleanup) |
| `ohpc-4.x/` | `tm-warewulf-4.7-3.x` (same) |
| `warewulf/` | `tm-dsa-8.x` (PR submitted) |
| `warewulf-node-images/` | `tm-image-build-use-aarch64-runners` (active) |
| `hpc-lab/` | `main` |

**Always verify branches before working.**

---

## Last Session Summary (2026-06-01)

- Fixed three latent bugs in `hpc-lab/playbooks/` (manifested on fresh Jetstream, hidden locally by `creates:` guards): Ansible `default(omit)` in `environment:` blocks, `image_dist` not passed to Ansible, shell template `warewulf-${dist}linux` wrong for almalinux
- Added per-target `image_dist` field to all `[target.*]` sections in `run.ini`; updated docs
- Confirmed `--target=almalinux-10 --workflow=warewulf` on Jetstream pulls correct image

---

## Pending (hpc-lab)

- openeuler-22.03 / warewulf3 / openpbs — next test target after node-images PRs land
- openeuler-24.03: only warewulf+slurm in tests/; no openchami/confluent — intentional?
- openEuler 4.x: COPR SP3 publish pending upstream (needed for yq)
- Split `clouds/jetstream/openstack.tf` → `network.tf` + `compute.tf`

---

## Key Rules (session-specific reminders only)

- Rocky Makefile edits (`rockylinux-9/`, `rockylinux-10/`) uncommitted — commit with CI entries together once Docker Hub publishes `rockylinux:9.8` / `10.2`
- `images.json` is the source of truth for CI matrix — edit it, not the workflow YAML directly
- Permanent rules (create.sh, Terraform state, TOML format, upstream PRs) are in `hpc-lab/CLAUDE.md`

---

## Infrastructure State

- **Local**: macOS aarch64, qemu via `hpc-lab/clouds/qemu/`
- **Remote x86_64**: `jetstream.ini200001.projects.jetstream-cloud.org` — Ubuntu 24.04 VM running qemu; SSH configured in `~/.ssh/config`, connect with just the hostname
- qemu cluster: status unknown — check before use
- Proxy: check `hpc-lab/proxy/local.env`

---

## Quick Reference

```bash
# Check Rocky dirty state (uncommitted 9.8/10.2 bumps)
cd ~/projects/hpc/warewulf-node-images && git diff

# Warewulf workflow — see hpc-lab/CLAUDE.md for SSH/SCP and run.py patterns
# Full image test reference: hpc-lab/docs/warewulf-image-tests.md

# Coordinator matrix tool
cd ~/projects/hpc && .venv/bin/python3 .github/workflows/gen-matrix.py
```
