# Session Handoff — hpc coordinator

To resume: open this file and tell Claude `continue with handoff-prompt.md`.

---

## Before Starting

**Pause before investigating.** Ask the user: "Do you have new context, logs, or observations
before I start?" Do not open files or grep until the user has had a chance to share.

---

## Active Work

**Infrastructure / recipe testing** — see `hpc-lab/handoff-prompt.md` for current state.
Last confirmed working: openEuler 22.03 / warewulf3 / openpbs — fix committed (2026-05-08).
Next: run rocky-9 and almalinux-9 with warewulf3+openpbs (same fix likely applies); then leap-15.
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

OpenPBS fix committed and confirmed working on openEuler 22.03 / warewulf3.
virtio_pci fix integrated. Warewulf base image rebuilt for SP3.
Cleaned up `scripts/test-recipe-patch.sed` (removed merged warewulf VNFS line).
OBS repo setup moved from `test-recipe-config-*.sh` into `test-recipe-head-setup.sh`.
`obs_minor` added to all `[target.*]` in `run.ini`; set to `"4.1"` for branch-4 EL targets,
`""` for all others. Setting `obs_minor` enables the OBS repo; blank disables it.
COPR: not needed for 3.x (removed upstream); still needed for 4.x openeuler (provides yq);
SP3 publish for 24.03 LTS still pending upstream.

---

## Pending (hpc-lab)

- Run rocky-9 + warewulf3 + openpbs — same fix as openeuler; verify it applies cleanly
- Run almalinux-9 + warewulf3 + openpbs — same
- Run leap-15 + warewulf3 + openpbs
- openeuler-24.03: only warewulf+slurm in tests/; no openchami/confluent — is this intentional?
- openEuler 4.x: COPR SP3 publish pending upstream (needed for yq); see `hpc-lab/docs/openeuler.md`
- 3.x OBS: enable by setting `obs_minor = "3.4"` in branch-3 EL targets in `run.ini` if needed
- Split `clouds/jetstream/openstack.tf` → `network.tf` + `compute.tf`
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
