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

## Last Session Summary (2026-06-02)

- Coordinator: added `.venv` + `requirements.txt` (pyyaml), `docs/tooling.md` (jq, yq, venv reference)
- warewulf-node-images: refactored CI to native arm64 runners with dynamic matrix from `images.json`
- Tested dual-arch build end-to-end; containers booted correctly on both arches
- Two bugs found and fixed during testing: push/outputs conflict; missing `name=` in outputs

---

## Pending (hpc-lab)

- openeuler-22.03 / warewulf3 / openpbs — next test target after node-images PRs land
- openeuler-24.03: only warewulf+slurm in tests/; no openchami/confluent — intentional?
- openEuler 4.x: COPR SP3 publish pending upstream (needed for yq)
- Split `clouds/jetstream/openstack.tf` → `network.tf` + `compute.tf`

---

## Key Rules (carry forward)

hpc-lab:

- `tests/` scripts are generated — fix goes in `ohpc-3.x/docs/install/templates/`, rebuild+copy
- Do NOT run `create.sh`, `create-net.sh`, `delete.sh`, `delete-net.sh` without confirmation
- Do NOT push Terraform state files or `local.tfvars`
- `config/run.ini` is TOML, not INI

upstream repos:

- Never commit to upstream tracking branches without PR
- 3.x fixes do not need to be ported to 4.x in-session

warewulf-node-images:

- `sudo` required for `wwctl` — run test script as `sudo python3 ./test-warewulf-images.py`
- Use `./run.py --workflow=warewulf` to spin up test cluster (not ohpc workflow)
- Rocky Makefile edits (9.8/10.2) uncommitted — commit with CI entries together once Docker Hub publishes
- `images.json` is the source of truth for CI matrix — edit it, not the workflow

---

## Known Bugs / Quirks

**Warewulf BIOS DHCP bug** — upstream fix needed; workaround in
`hpc-lab/tests/rocky10-x86_64-warewulf-slurm.sh`. See `hpc-lab/docs/warewulf-bios-dhcp-bug.md`.

**Proxy (mitmproxy)** — `hpc-lab/proxy/start-proxy.sh` / `stop-proxy.sh`.
Full reference: `hpc-lab/docs/proxy.md`.

---

## Infrastructure State

- **Local**: macOS aarch64, qemu via `hpc-lab/clouds/qemu/`
- **Remote x86_64**: `jetstream.ini200001.projects.jetstream-cloud.org`
- qemu cluster: status unknown — check before use
- Proxy: check `hpc-lab/proxy/local.env`

---

## Quick Reference

```bash
# Node image testing (from hpc-lab/)
export CLOUD=qemu && source ./scripts/get-env.sh
scp scripts/test-warewulf-images.py scripts/test-warewulf-images.json scp://$OHPC_USER@$OHPC_HEAD:$OHPC_PORT/
ssh ssh://$OHPC_USER@$OHPC_HEAD:$OHPC_PORT
sudo python3 ./test-warewulf-images.py --dry-run --os almalinux --fixed
sudo python3 ./test-warewulf-images.py --os almalinux --fixed

# SSH/SCP connection pattern (established codebase convention — confirmed working)
# scp://user@host:port/  and  ssh ssh://user@host:port  are the project-standard forms.
# Used in test-recipe-run.sh, ohpc-run.sh, wait.sh, warewulf-run.sh.
# Do NOT switch to scp -P or bare ssh user@host — that would break consistency.

# warewulf-node-images
cd ~/projects/hpc/warewulf-node-images
git log --oneline -5
git diff   # check Rocky Makefile dirty state

# Coordinator Python tools
cd ~/projects/hpc
.venv/bin/python3 .github/workflows/gen-matrix.py  # test matrix generation locally
```
