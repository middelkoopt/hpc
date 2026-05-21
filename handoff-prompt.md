# Session Handoff — hpc coordinator

To resume: open this file and tell Claude `continue with handoff-prompt.md`.

---

## Before Starting

**Pause before investigating.** Ask the user: "Do you have new context, logs, or observations
before I start?" Do not open files or grep until the user has had a chance to share.

---

## Active Work

**warewulf 4.7.0 test run — FAILING.** Bugs from the upgrade changes; not yet diagnosed.
Last run: `./run.py --target=rocky-9 --provisioner=warewulf` (or similar — confirm before starting).
Next: collect failure logs and debug.

**OpenHPC warewulf 4.7.0** — `tm-warewulf-4.7-3.x` (ohpc-3.x and ohpc-4.x). **Uncommitted.**
Spec fixes this session (on top of 2026-05-18 work):

- Moved `## OHPC:` comment out of `make defaults \` continuation (was silently dropping all args after it)
- Fixed `mig` overlay ordering to match upstream (`systemd.mount` → `systemd.swap` → `mig`)
- Added `## OHPC: upstream %%changelog removed` at end of spec

RPM builds successfully (`warewulf-ohpc-4.7.0-19999.ci.ohpc.aarch64.rpm` in `hpc-lab/data/`).
Next: debug test run failures, then commit.

**Warewulf upstream** — branch `tm-dsa-8.x`: DSA removed from default ssh key types. **PR submitted.**
hosts.ww `.localdomain` — OHPC carries hardcoded patch; upstream fix requires a `domain` config field
in `warewulf.conf` so `hosts.ww` can emit a site-specific FQDN alias. No upstream PR until that is designed.

---

## Sub-Repo Branch State

| Repo | Branch |
| ---- | ------ |
| `ohpc-3.x/` | `tm-warewulf-4.7-3.x` |
| `ohpc-4.x/` | `tm-warewulf-4.7-3.x` (same changes applied) |
| `warewulf/` | `tm-dsa-8.x` (PR submitted) |
| `warewulf-node-images/` | personal working branch (check before starting) |
| `hpc-lab/` | `main` |

**Always verify branches before working** — wrong branch was the root cause of a session
confusion (2026-05-08).

---

## Last Session Summary (2026-05-19)

### Session (2026-05-19) — spec review + RPM build workflow + first test run

**ohpc-3.x and ohpc-4.x** (`tm-warewulf-4.7-3.x`, still uncommitted):

- Spec review: fixed three issues from 2026-05-18 session
  - `## OHPC:` comment inside `make defaults \` continuation silently dropped `LOCALSTATEDIR`, `SRVDIR`, and all subsequent args — moved comment to before the block
  - `mig` overlay was inserted before `systemd.mount`/`systemd.swap`; restored to upstream order (after both)
  - Added `## OHPC: upstream %%changelog removed` at end of spec
- RPM build: first build of `warewulf-ohpc-4.7.0` using Lima (`rocky-9` instance); succeeded after comment fix

**hpc-lab** (`main`):

- New doc: `docs/rpm-build.md` — Lima-based RPM build workflow, path conventions, pitfalls
- `CLAUDE.md`: updated Local Package Testing section with build steps and rpm-build.md reference
- `hpc-lab/tests/` rebuilt from ohpc-3.x templates and copied
- Test run attempted; **failing** — bugs from 4.7.0 upgrade changes, not yet diagnosed

**Coordinator**:

- `CLAUDE.md`: noted `## OHPC:` comment-in-make-continuation bug as spec authoring rule (in rpm-build.md)

---

## Last Session Summary (2026-05-18)

### Session (2026-05-18) — warewulf 4.7.0 OHPC packaging + upstream DSA fix

**ohpc-3.x and ohpc-4.x** (`tm-warewulf-4.7-3.x`, uncommitted):

- Spec rebased on upstream `warewulf.spec.in`; OHPC delta consolidated and commented
- Version bumped 4.6.5 → 4.7.0; `warewulf-4.5.x-sle_ipxe.patch` dropped (dead artifact)
- Added `chrony` and `mig` overlays to `%files`
- `warewulf-install.md.j2`: removed tftpboot creation + semanage/restorecon workarounds
- `hpc-lab/tests/` rebuilt and diff verified clean

**warewulf upstream** (`tm-dsa-8.x`, PR submitted):

- Removed `dsa` from default ssh key types in `warewulf.conf`, `warewulf.conf-suse`, Go default
- Updated `root_test.go`, `debug_test.go`; all tests pass on Lima (Rocky 9)
- CHANGELOG and `userdocs/server/configuration.rst` updated

**Coordinator**:

- `CLAUDE.md`: added rule — never `git checkout` in sub-repos; use `git show <ref>:<path>`
- `hpc-lab/PROCESS.md`: unchanged (rule belongs at coordinator level)

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
