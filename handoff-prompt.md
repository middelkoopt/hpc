# Session Handoff — hpc coordinator

To resume: open this file and tell Claude `continue with handoff-prompt.md`.

---

## Before Starting

**Pause before investigating.** Ask the user: "Do you have new context, logs, or observations
before I start?" Do not open files or grep until the user has had a chance to share.

---

## Active Work

**Infrastructure / recipe testing** — see `hpc-lab/handoff-prompt.md` for current state.
Last confirmed working: openEuler 22.03 / warewulf3 / aarch64 / qemu (2026-05-07).
Last run command: `./run.py --target=openeuler-22.03 --provisioner=warewulf3`

**OpenHPC docs** — active work in `ohpc-3.x/docs/install/` (3.x branch). Need to decide
how docs are placed and how content migrates between 3.x and 4.x given the coordinator move.

---

## Sub-Repo Branch State

| Repo | Branch |
| ---- | ------ |
| `ohpc-3.x/` | `tm-openeuler-openpbs-3.x` |
| `ohpc-4.x/` | `main` (or upstream default) |
| `warewulf/` | personal working branch (check before starting) |
| `warewulf-node-images/` | personal working branch (check before starting) |
| `hpc-lab/` | `main` |

**Always verify branches before working** — wrong branch was the root cause of a session
confusion (2026-05-08).

---

## Last Session Summary (2026-05-08)

Set up the `~/projects/hpc/` workspace coordinator. Repos cloned in:
`hpc-lab/`, `ohpc-3.x/`, `ohpc-4.x/`, `warewulf/`, `warewulf-node-images/`.
Coordinator files written: `CLAUDE.md`, `PROCESS.md`, `handoff-prompt.md`,
`hpc.code-workspace`, `docs/workspace-design.md`.

`ohpc-jetstream2` is now historical (tm-dev removed). Active infra work continues in `hpc-lab/`.
`hpc-lab` was split from `ohpc-jetstream2/tm-dev` — 220 commits beyond main.

---

## Pending (hpc-lab)

- Remove `test-recipe-patch.sed` entries as upstream gains `has_*` guards
- Split `clouds/jetstream/openstack.tf` → `network.tf` + `compute.tf`
- **PRIORITY**: Move `obs_family`/`OHPC_OBS_FAMILY` into `[target.*]` in `run.ini` once
  a second consumer exists (TODO at `scripts/test-recipe-config-4.sh:58`)
- `virtio_pci` fix in `tests/rocky9-aarch64-warewulf3-slurm.sh` and
  `tests/openeuler22.03-aarch64-warewulf3-slurm.sh` (`modprobe += virtio_pci, virtio_net`)
- openEuler: Warewulf base image needs SP3 rebuild; OpenHPC COPR needs SP3 publish
  (see `hpc-lab/docs/openeuler.md`)
- Add sles target when ready

---

## Key Rules (carry from previous session)

hpc-lab (infrastructure):

- Only fix the one `tests/` script matching the current run — never bulk-patch; user
  backports upstream separately
- Do NOT run `create.sh`, `create-net.sh`, `delete.sh`, `delete-net.sh` without confirmation
- Do NOT push Terraform state files or `local.tfvars`
- `config/run.ini` is TOML, not INI — tomllib parses it

upstream repos (ohpc-3.x, ohpc-4.x, warewulf, warewulf-node-images):

- Never commit to upstream tracking branches without going through upstream review / PR

---

## Known Bugs / Quirks

**Warewulf BIOS DHCP bug** — upstream fix needed; workaround in
`hpc-lab/tests/rocky10-x86_64-warewulf-slurm.sh`. See `hpc-lab/docs/warewulf-bios-dhcp-bug.md`.

**Proxy (mitmproxy)** — `hpc-lab/proxy/start-proxy.sh` / `stop-proxy.sh` writes/removes
`proxy/local.env`. Full reference: `hpc-lab/docs/proxy.md`.

---

## Infrastructure State

- **Local**: macOS aarch64, qemu via `hpc-lab/clouds/qemu/` — primary aarch64 test platform
- **Remote x86_64 qemu**: `jetstream.ini200001.projects.jetstream-cloud.org`
  - iPXE ROM path: `/usr/lib/ipxe/qemu/efi-virtio.rom` (Ubuntu/Debian, not `/usr/share/`)
- Proxy: unknown — check `hpc-lab/proxy/local.env`
- Cloud VMs: none running (last known state)

---

## Quick Reference

```bash
# Infrastructure work
cd ~/projects/hpc/hpc-lab
./run.py --target=openeuler-22.03 --provisioner=warewulf3   # last active run

# OpenHPC docs (active: 3.x branch)
cd ~/projects/hpc/ohpc-3.x/docs/install
make

# Warewulf
cd ~/projects/hpc/warewulf
git log middelkoopt/main..HEAD --oneline
```
