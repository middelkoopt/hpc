---
name: 3.x Markdown Backport Status
description: Status and key decisions for backporting the 4.x Markdown/Jinja2 doc system to 3.x (branch tm-markdown-3.x)
type: project
originSessionId: d949ed90-80eb-4b9f-894c-5fa548513988
---

# 3.x Markdown Backport Status

## Status (as of 2026-04-27)

Branch: `tm-markdown-3.x`

- **Phase 1** ✅ Verbatim copy of `docs/install/` from 4.x committed
- **Phase 2** ✅ EL9 core adaptation committed — 12 recipes build clean, shellcheck passes
- **Phase 3+4** ✅ OpenPBS + Warewulf v3 committed — 8 new recipes, 20 total build clean
- **Phase 5** ✅ Leap 15 done — 4 new recipes, 24 total build clean, shellcheck passes
- **Phase 6** ✅ RPM spec — LaTeX deps removed, yq/python3/jinja2/PyYAML added, build/install rewritten for Markdown system
- **Phase 7** ✅ OpenEuler warewulf3 openpbs — 2 new recipes, 28 total build clean, shellcheck passes
- **Manifests** ✅ Regenerated from OpenHPC 3.4 staging repos via lima (EL9 dnf repoquery). leap15 added to baseos_map in manifests/config.yaml (Leap_15 repo is dnf-queryable from EL9).
- **Version** ✅ Bumped to 3.5 in config/base.yaml and docs.spec
- **Confluent ISO + template fixes** ✅ Applied to both 3.x and 4.x (see below)
- **Testing** 🔲 openEuler 22.03 warewulf3 provisioning in progress (2026-05-07)

## Key Decisions Made

- **No generalization**: EL9-specific values hardcoded in templates (e.g. repos.md.j2 says "EL9", not `{{ distro_version }}`). Each branch tracks one EL generation.
- **git mv pattern**: Use `git mv` for all renames (el10→el9, rocky→rocky9, etc.) so VS Code diff shows rename + content change cleanly.
- **Incremental commits**: Small focused commits; user reviews before proceeding.
- **Manifest content deferred**: el9 manifest dirs created (git mv from el10) but content is still EL10 placeholder. Regenerate with `generate_manifest.py` at end.
- **Phases 3+4 combined**: OpenPBS was only paired with Warewulf v3 in 3.x (not v4). So both phases were done together.
- **Single PR**: All 3.x work will be submitted as a single PR after install scripts are tested.
- **openEuler 22.03 uses warewulf3 only**: No warewulf v4 openeuler recipes exist or are planned in 3.x. All 4 openeuler recipes are warewulf3 (x86_64 + aarch64 × slurm + openpbs).
- **Warewulf3 kernel install uses `kernel-$(uname -r)`**: Head node and compute image are assumed to be on the same SP. No `$KVER` decoupling needed — the assumption is a consistent environment.

## Recipe Matrix (as of Phase 7)

| Distro | Arch | Provisioner | Scheduler | Status |
| ------ | ---- | ----------- | --------- | ------ |
| rocky9, almalinux9 | x86_64, aarch64 | warewulf (v4) | slurm | ✅ Phase 2 |
| rocky9, almalinux9 | x86_64, aarch64 | confluent | slurm | ✅ Phase 2 |
| rocky9, almalinux9 | x86_64, aarch64 | openchami | slurm | ✅ Phase 2 |
| rocky9, almalinux9 | x86_64, aarch64 | warewulf3 | slurm | ✅ Phase 3+4 |
| rocky9, almalinux9 | x86_64, aarch64 | warewulf3 | openpbs | ✅ Phase 3+4 |
| leap15 | x86_64, aarch64 | warewulf3 | slurm, openpbs | ✅ Phase 5 |
| openeuler22.03 | x86_64, aarch64 | warewulf3 | slurm, openpbs | 🔲 In progress (2026-05-07) |

## Build Commands (3.x)

```bash
cd docs/install
make PYTHON=.venv/bin/python3                    # build all
make build/rocky9-x86_64-warewulf3-slurm.sh PYTHON=.venv/bin/python3
make check PYTHON=.venv/bin/python3              # shellcheck all .sh
```

## Phase 7 Changes Made (OpenEuler warewulf3 openpbs)

- New: `recipes/openeuler22.03-{x86_64,aarch64}-warewulf3-openpbs.conf`
- OpenPBS support for warewulf3 was already added in Phase 3+4; Phase 7 extended it to openEuler.
- Modified: `components/admin/docs/SPECS/docs.spec` — added openeuler warewulf3 paths

## Escaping Note (warewulf v4 openpbs, EL9 distros)

In `compute-install-openpbs.md.j2`, inside `wwctl image exec <<- EOF`, `\\\$clienthost` is needed:

- Outer shell heredoc: `\\\$` → `\$`
- Inner bash double-quoted string: `\$` → literal `$clienthost`
- Perl regex sees `$clienthost` as perl variable (empty string), so pattern matches ` <word>` anywhere on the line ✓

## Confluent Template Fixes (2026-04-28, both 3.x and 4.x)

Applied to `templates/provisioner/confluent/` and recipe YAMLs:

1. **ISO "latest"**: `distro_iso_image` changed to `Rocky-9-latest-{arch}-dvd.iso` / `AlmaLinux-9-latest-{arch}-dvd.iso` (4.x: Rocky/AlmaLinux 10). `distro_id` removed from all confluent recipe YAMLs.

2. **Runtime `distro_id`** (`init-os-images.md.j2`): Uses `osdeploy importcheck` + `sed` to capture the actual profile name at runtime:

   ```bash
   : "${iso_path:={{ distro_iso_image }}}"
   distro_id=$(osdeploy importcheck "${iso_path}" 2>&1 \
       | sed -En 's/Detected distribution name: (.*)/\1-default/p')
   osdeploy import "${iso_path}"
   ```

3. **`kernelargs +=` not `=`** (`init-os-images.md.j2`): Preserves `inst.stage2` and other args from `osdeploy import`'s default profile.yaml. Also strips `quiet` and adds arch-specific console:

   ```bash
   yq -i '.kernelargs |= sub("quiet ?", "")'  .../profile.yaml
   yq -i ".kernelargs += \" console=tty0 console={% if is_aarch64 %}ttyAMA0{% else %}ttyS0{% endif %},115200 rd.shell\"" .../profile.yaml
   ```

   Console order: `tty0` first, serial last → serial is `/dev/console` (primary).

4. **`${distro_id}` shell var** in `post-add-user.md.j2` and `add-nodes.md.j2`: All `{{ distro_id }}` references in code blocks changed to `${distro_id}`.

## Config File Map (3.x)

```text
config/distro/el9.yaml             EL9 family (Rocky 9, AlmaLinux 9)
config/distro/rocky9.yaml          Rocky 9 specific
config/distro/almalinux9.yaml      AlmaLinux 9 specific
config/distro/openeuler22.03.yaml  openEuler 22.03 SP4
config/distro/leap15.yaml          openSUSE Leap 15 (NEW Phase 5)
config/scheduler/slurm.yaml        existing (from 4.x)
config/scheduler/openpbs.yaml      NEW (Phase 3+4)
config/provisioner/warewulf3.yaml  NEW (Phase 3+4)
```
