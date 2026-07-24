# Proxy Support Patterns

Proxy support uses **site-specific placeholder markers** rather than inline proxy commands.
The recipes are too distro-specific and fragile for generic proxy logic (CA trust paths,
repo file names, metalink vs mirrorlist, etc.) — sites pre-process the generated `recipe.sh`.

**Placeholder format** (always emitted as no-op shell comments, never conditional):

```bash
#<<< ohpc_proxy:TYPE >>>#
```

Three types, each appearing once per recipe:

- `head` — head node setup (before first `dnf`) → `templates/base-os/proxy.md.j2`
- `compute` — compute image/node config (Warewulf chroot, Confluent nodeshell)
- `image` — OpenCHAMI image-build (distinct because of local registry/podman context)

**Template locations:**

- `templates/base-os/proxy.md.j2` — `head` placeholder; included before `repos.md.j2`
- `templates/provisioner/warewulf/compute-create-image.md.j2` — `compute` placeholder
- `templates/provisioner/confluent/compute-setup.md.j2` — `compute` placeholder
- `templates/provisioner/openchami/compute-image-build.md.j2` — `image` placeholder

**Site pre-processing**: `grep -n '^#<<< ohpc_proxy:' recipe.sh` finds placeholders;
sed/python expands them with site-specific commands. Left as-is = no-op.

**`ohpc_reset` placeholders** (runtime-emitted, not pre-processed): when `has_ipmi=0`,
`boot-computes.md.j2` prints `#<<< ohpc_reset:$i,${c_name[$i]},${c_bmc[$i]} >>>#` to
stdout. A monitoring wrapper intercepts these lines and triggers hypervisor VM resets.
Fields are comma-delimited (IPv6-safe). Source: `templates/boot/boot-computes.md.j2`.
