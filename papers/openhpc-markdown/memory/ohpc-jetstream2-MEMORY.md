# ohpc-jetstream2 Project Memory

## Feedback

- `memory/feedback_patch_only_current_file.md` — fix only the one `tests/` script for the current run; user backports upstream separately

## Active Work

- Testing openEuler 22.03 on qemu/aarch64 with warewulf3+slurm (3.x branch)
- `data/warewulf-vnfs-ohpc-3.10.0-19999.ci.ohpc.noarch.rpm` — CI build under test; `test-recipe-patch.sed` installs it after `ohpc-warewulf`
- **openEuler 22.03 / warewulf3 / aarch64 / qemu: WORKING** as of 2026-05-07
- `data/warewulf-vnfs-ohpc-3.10.0-19999.ci.ohpc.noarch.rpm` — CI build confirmed working

## Warewulf BIOS DHCP Bug (upstream fix needed)

See `docs/warewulf-bios-dhcp-bug.md`. Workaround in `tests/rocky10-x86_64-warewulf-slurm.sh`.
User is Warewulf/OpenHPC developer and will upstream the fix.

## HTTP Proxy (mitmproxy)

See `docs/proxy.md` for full reference.

Key notes:

- `proxy/start-proxy.sh` / `proxy/stop-proxy.sh` — writes/removes `proxy/local.env`
- **CRITICAL**: dnf5/libcurl on AlmaLinux 10 only reads LOWERCASE `http_proxy`/`https_proxy`

## Infrastructure

- **Local (macOS aarch64)**: qemu via `clouds/qemu/` — primary test platform for aarch64
- **Remote x86_64 qemu**: `jetstream.ini200001.projects.jetstream-cloud.org` — separate repo, used for x86_64 qemu tests
  - iPXE ROM path: `/usr/lib/ipxe/qemu/efi-virtio.rom` (Ubuntu/Debian, not `/usr/share/`)

## Things to Avoid

- Do NOT run create.sh, create-net.sh, delete.sh, delete-net.sh without user confirmation
- Do NOT push Terraform state files or local.tfvars
- `config/run.ini` is TOML not INI — tomllib parses it

## Pending / Future Work

- Split `clouds/jetstream/openstack.tf` → network.tf + compute.tf
- Add sles target when ready
- Remove test-recipe-patch.sed entries as upstream gains has_* guards
- openEuler: Warewulf base image needs SP3 rebuild; OpenHPC COPR needs SP3 publish — see `docs/openeuler.md`
- openEuler + wwmkchroot: `YUM_MIRROR_BASE=$MIRROR` now set in `scripts/head/test-recipe-mirrors.sh` (sourced by head-setup and config files)
- **PRIORITY**: Move `obs_family`/`OHPC_OBS_FAMILY` upstream into `[target.*]` in run.ini once a second consumer exists (TODO at scripts/test-recipe-config-4.sh:58)
- `virtio_pci` fix in both `tests/rocky9-aarch64-warewulf3-slurm.sh` and `tests/openeuler22.03-aarch64-warewulf3-slurm.sh` (`modprobe += virtio_pci, virtio_net`)
