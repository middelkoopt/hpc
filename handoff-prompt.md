# Session Handoff — hpc coordinator

To resume: open this file and tell Claude `continue with handoff-prompt.md`.

---

## Before Starting

**Pause before investigating.** Ask the user: "Do you have new context, logs, or observations
before I start?" Do not open files or grep until the user has had a chance to share.

---

## Active Work

**Infrastructure / recipe testing** — see `hpc-lab/handoff-prompt.md` for current state.
Last confirmed working: leap-15 / warewulf3 / openpbs — confirmed (2026-05-08).
Last run command: `./run.py --target=leap-15 --provisioner=warewulf3`

**OpenHPC docs** — active work in `ohpc-3.x/docs/install/` (3.x branch `tm-openeuler-openpbs-3.x`).
Next: openeuler-22.03 / warewulf3 / openpbs — recipe exists, not yet tested.

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

### Session 2 (2026-05-08) — leap15/openpbs fix + workflow corrections

leap-15 / warewulf3 / openpbs confirmed working.

ohpc-3.x fix committed to `tm-openeuler-openpbs-3.x`:

- `compute-install-scheduler.md.j2`: add `echo "${sms_ip} ${sms_name}" >> $CHROOT/etc/hosts`
  before `pbs_habitat` call, inside `{% if is_sles %}` guard. SUSE chroot `/etc/hosts` only has
  localhost entries — `pbs_habitat` can't resolve `PBS_SERVER=head` without this. EL chroots
  work without it due to different nsswitch/hosts defaults.

Workflow corrections (docs + memory updated):

- `tests/` scripts are generated artifacts — edits always go in templates, rebuild+copy, then run.
  `git diff tests/` (from `hpc-lab/`) after rebuild is the review step — user commits a clean
  `tests/` baseline before a debugging session.
- Removed the "fix tests/ directly, user backports separately" rule — artifact of disconnected
  sessions, no longer applicable now that ohpc-3.x and hpc-lab are co-located.
- 3.x fixes do not port forward to 4.x in-session — user handles manually.

### Session 1 (2026-05-08) — SUSE bring-up

almalinux-9 / warewulf3 / openpbs confirmed working.
leap-15 / warewulf3 / slurm working — first SUSE target.

hpc-lab SUSE infrastructure additions (all in `scripts/head/`):

- `test-recipe-head-setup.sh`: SUSE branches for CA cert install, zypper package manager,
  nftables-nat.service oneshot (Leap ships no nftables.service), kernel-based reboot detection,
  zypper repo mirror patching + disable backports/sle repos Purdue doesn't carry.
  Reboot backgrounded (`systemctl reboot & disown`) so SSH exits cleanly.
- `test-recipe-mirrors.sh`: `MIRROR=https://plug-mirror.rcac.purdue.edu/opensuse` for leap.
  Mirror was later removed for SUSE (proxy cache sufficient; only needed for openeuler due to speed).

ohpc-3.x fixes committed to `tm-openeuler-openpbs-3.x`:

- `pkg_install_keys` variable (zypper --gpg-auto-import-keys) for ohpc-base install
- `leap15.yaml`: add `mariadb_cnf`/`mariadb_service`; move max_allowed_packet setup before
  SLES/EL branch so it runs on both; remove duplicate mysql handling
- `cp -L --remove-destination` for resolv.conf (handles symlinks)
- Guard SuSEfirewall2 disable/stop with `|| true` (service absent on newer Leap images)

Proxy: no changes needed — `/repodata/` no-cache rule already covers zypper metadata.

---

## Pending (hpc-lab)

- openeuler-22.03 / warewulf3 / openpbs — next test target
- openeuler-24.03: only warewulf+slurm in tests/; no openchami/confluent — is this intentional?
- openEuler 4.x: COPR SP3 publish pending upstream (needed for yq); see `hpc-lab/docs/openeuler.md`
- 3.x OBS: enable by setting `obs_minor = "3.4"` in branch-3 EL targets in `run.ini` if needed
- Split `clouds/jetstream/openstack.tf` → `network.tf` + `compute.tf`
- Add sles target when ready

---

## Key Rules (carry from previous session)

hpc-lab (infrastructure):

- `tests/` scripts are generated — fix goes in `ohpc-3.x/docs/install/templates/`, rebuild+copy;
  patching `tests/` directly is only a temporary debug shortcut
- Do NOT run `create.sh`, `create-net.sh`, `delete.sh`, `delete-net.sh` without confirmation
- Do NOT push Terraform state files or `local.tfvars`
- `config/run.ini` is TOML, not INI — tomllib parses it

upstream repos (ohpc-3.x, ohpc-4.x, warewulf, warewulf-node-images):

- Never commit to upstream tracking branches without going through upstream review / PR
- 3.x fixes do not need to be ported to 4.x in-session — user handles backports manually

---

## Known Bugs / Quirks

**Warewulf BIOS DHCP bug** — upstream fix needed; workaround in
`hpc-lab/tests/rocky10-x86_64-warewulf-slurm.sh`. See `hpc-lab/docs/warewulf-bios-dhcp-bug.md`.

**Proxy (mitmproxy)** — `hpc-lab/proxy/start-proxy.sh` / `stop-proxy.sh` writes/removes
`proxy/local.env`. Full reference: `hpc-lab/docs/proxy.md`.
Zypper metadata (under `/repodata/`) is already excluded from caching — no SUSE-specific changes needed.

**SUSE / Leap 15 head-setup quirks**:

- No `nftables.service` unit — use `nftables-nat.service` oneshot written by head-setup
- No `needs-restarting` — kernel reboot detection via `rpm -q --last kernel-default` vs `uname -r`
- `SuSEfirewall2` may not be installed on newer images — disable/stop guarded with `|| true`

**SUSE / Leap 15 chroot + OpenPBS**:

- `pbs_habitat` (run in chroot) needs `PBS_SERVER` hostname to be resolvable inside the chroot.
  SUSE chroot `/etc/hosts` only has localhost — add `${sms_ip} ${sms_name}` to `$CHROOT/etc/hosts`
  before calling `pbs_habitat`. Fixed in `compute-install-scheduler.md.j2` under `{% if is_sles %}`.
  EL chroots work without this due to different nsswitch/hosts defaults.

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
./run.py --target=openeuler-22.03 --provisioner=warewulf3   # next target (openpbs)

# OpenHPC docs (active: 3.x branch)
cd ~/projects/hpc/ohpc-3.x/docs/install
make PYTHON=.venv/bin/python && cp -v build/*.sh ../../../hpc-lab/tests/

# Warewulf
cd ~/projects/hpc/warewulf
git log middelkoopt/main..HEAD --oneline
```
