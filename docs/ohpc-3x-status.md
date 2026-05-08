# OpenHPC 3.x Branch Status

Branch: `tm-openeuler-openpbs-3.x` (active)
Predecessor: `tm-markdown-3.x` (PR pending merge to upstream 3.x)

## Current Work

Testing openEuler 22.03 / warewulf3 / aarch64 / openpbs on local qemu.
Run: `./run.py --target=openeuler-22.03 --provisioner=warewulf3` from `hpc-lab/`.

## Branch Lineage

- `tm-markdown-3.x` — full LaTeX→Markdown backport, 28 recipes, PR pending upstream
- `tm-openeuler-openpbs-3.x` — openEuler warewulf3 slurm+openpbs work, branched from above

When `tm-markdown-3.x` merges upstream, rebase/cherry-pick `tm-openeuler-openpbs-3.x` onto it.

## Recipe Matrix

| Distro | Arch | Provisioner | Scheduler | Status |
|--------|------|-------------|-----------|--------|
| rocky9, almalinux9 | x86_64, aarch64 | warewulf (v4) | slurm | ✅ done |
| rocky9, almalinux9 | x86_64, aarch64 | confluent | slurm | ✅ done |
| rocky9, almalinux9 | x86_64, aarch64 | openchami | slurm | ✅ done |
| rocky9, almalinux9 | x86_64, aarch64 | warewulf3 | slurm | ✅ done |
| rocky9, almalinux9 | x86_64, aarch64 | warewulf3 | openpbs | ✅ done |
| leap15 | x86_64, aarch64 | warewulf3 | slurm, openpbs | ✅ done |
| openeuler22.03 | x86_64, aarch64 | warewulf3 | slurm | ✅ done |
| openeuler22.03 | x86_64, aarch64 | warewulf3 | openpbs | 🔲 testing |

openEuler 22.03 uses warewulf3 only — no warewulf v4, openchami, or confluent recipes planned.

## Key Decisions

- **No generalization**: EL9-specific values hardcoded in templates. Each branch tracks one EL generation.
- **Single PR**: All 3.x work submitted as one PR after install scripts pass testing.
- **Warewulf3 kernel install**: Uses `kernel-$(uname -r)` — head node and compute image assumed on the same SP.
- **OpenPBS only with warewulf3** in 3.x — not paired with warewulf v4.

## Config File Map (3.x)

```
config/distro/el9.yaml             EL9 family (Rocky 9, AlmaLinux 9)
config/distro/rocky9.yaml          Rocky 9 specific
config/distro/almalinux9.yaml      AlmaLinux 9 specific
config/distro/openeuler22.03.yaml  openEuler 22.03 SP4
config/distro/leap15.yaml          openSUSE Leap 15
config/scheduler/slurm.yaml        Slurm
config/scheduler/openpbs.yaml      OpenPBS
config/provisioner/warewulf3.yaml  Warewulf v3 (wwsh/wwmkchroot/wwbootstrap/wwvnfs)
```

## Confluent Template Fixes (applied to both 3.x and 4.x, 2026-04-28)

1. `distro_iso_image` → `Rocky-9-latest-{arch}-dvd.iso` / `AlmaLinux-9-latest-{arch}-dvd.iso`
2. `distro_id` captured at runtime via `osdeploy importcheck` + `sed` (not in recipe YAML)
3. `kernelargs +=` (not `=`) in `init-os-images.md.j2` — preserves existing args from `osdeploy import`
4. `${distro_id}` shell var in `post-add-user.md.j2` and `add-nodes.md.j2`
