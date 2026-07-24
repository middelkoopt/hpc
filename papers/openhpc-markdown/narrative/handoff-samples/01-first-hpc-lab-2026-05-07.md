# Session Handoff

To resume: open this file and tell Claude `continue with handoff-prompt.md`.

---

## Active Work

**Testing**: openEuler 22.03 / warewulf3 / slurm / aarch64 / qemu

- `data/warewulf-vnfs-ohpc-3.10.0-19999.ci.ohpc.noarch.rpm` — CI build under test
- `scripts/test-recipe-patch.sed` — installs it after `ohpc-warewulf`
- Mirror: Berkeley (`mirrors.ocf.berkeley.edu/openeuler`), 22.03=SP4
- Run: `./run.py --target=openeuler-22.03 --provisioner=warewulf3`

**Test status**: not yet run this session — next step is to execute the run above.

---

## Last Session Summary (2026-05-07)

- Fixed `test-recipe-run.sh` to guard `data/` copy against empty directory
- Backported mirror setup to `test-recipe-config-3.sh` (Berkeley mirror, openEuler repo override, proxy URL fix)
- Added `warewulf-vnfs-ohpc` local install to `test-recipe-patch.sed`
- Docs overhaul: 7 new docs files, 4 extended, CLAUDE.md rewritten
- Committed: `72ff884`

---

## Pending Work

- [ ] Run openEuler 22.03 / warewulf3 test and verify `warewulf-vnfs-ohpc` CI RPM
- [ ] Upstream `warewulf-bios-dhcp-bug` fix to Warewulf (see `docs/warewulf-bios-dhcp-bug.md`)
- [ ] Refactor `test-recipe-run.sh` — extract per-distro head setup into separate script
- [ ] Move `obs_family`/`OHPC_OBS_FAMILY` into `[target.*]` in run.ini (second consumer needed first)
- [ ] Split `clouds/jetstream/openstack.tf` → network.tf + compute.tf
- [ ] openEuler SP3: Warewulf base image rebuild + OpenHPC COPR publish
- [ ] Create `handoff-prompt.md` for the session handoff pattern (done — this file)

---

## Infrastructure State

- Platform: qemu (local, aarch64)
- Proxy: check `proxy/proxy.pid` — if present, proxy is active
- No cloud infra running (qemu VMs are ephemeral per-run)

---

## Key Rules (easy to forget)

- Only fix the `tests/` script matching the current run — never bulk-patch
- Confirm before running `create.sh`, `delete.sh`, `create-net.sh`, `delete-net.sh`
- `config/run.ini` is TOML not INI
- dnf5/AlmaLinux 10: lowercase `http_proxy` only

---

## Quick Reference

```bash
# Verify / dry-run
./run.py --list
./run.py --target=openeuler-22.03 --provisioner=warewulf3 --dry-run

# Current test run
./run.py --target=openeuler-22.03 --provisioner=warewulf3

# Check proxy
ls proxy/proxy.pid && cat proxy/local.env
```
