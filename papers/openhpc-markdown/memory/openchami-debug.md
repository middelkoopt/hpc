# OpenCHAMI Deployment Debug Session (Rocky 10 on OpenStack KVM)

## STATUS: SSH + Slurm WORKING (2026-02-23) — 3 more template fixes needed (see below)

## Environment

- Head node: `rocky@ohpc-head.INI200001.projects.jetstream-cloud.org` (recipe runs as root via `sudo bash -x -e ./recipe.sh`)
- Head node IP: 10.5.0.8 (`sms_ip`), hostname `head.novalocal` (`sms_name`)
- Compute node: c1, MAC 52:54:00:05:01:01, IP 10.5.1.1, BMC placeholder 10.5.100.1
- OS: Rocky Linux 10.1 x86_64
- Recipe run: `sudo OHPC_INPUT_LOCAL=./test-recipe-config-10.sh bash -x -e ./recipe.sh`
- OpenCHAMI services: rootful podman (root's podman, not rocky's)
- `gen_access_token` requires root (uses root's podman to reach hydra container)

## Fixes Applied

### 1. Missing `/opt/ohpc/admin/images/` directory (`s3-setup.md.j2`)

`cat > /opt/ohpc/admin/images/public-read-boot.json` failed because the directory
didn't exist. Fixed by adding `mkdir -p /opt/ohpc/admin/images` before the `cat`.

### 2. `ochami config cluster set` interactive prompt (`client-install.md.j2`)

`/etc/ochami/config.yaml does not exist. Create it? [yN]:`
Fixed by pre-creating the file: `mkdir -p /etc/ochami && touch /etc/ochami/config.yaml`
before the `ochami config cluster set` call. Removed the unreliable `yes |` pipe.

### 3. `c_bmc` not defined in test config — wrong args to `ohpc-nodes.sh`

`ohpc-nodes.sh` signature: `NAME NID_OFFSET BMC_IP MAC IP_ADDR`
Without `c_bmc`, empty arg was dropped by bash word-splitting, shifting MAC into
BMC_IP position → SMD got MAC as IP address → "IPAddress is not a valid IP address".
Fixed by adding placeholder BMC IPs to `test-recipe-config-10.sh`:
```bash
c_bmc[0]=10.5.100.1
c_bmc[1]=10.5.100.2
c_bmc[2]=10.5.100.3
c_bmc[3]=10.5.100.4
```
Note: `c_bmc` has defaults in `input.local.template` but test config bypasses the
template (it IS the input.local via `OHPC_INPUT_LOCAL`).

### 4. `rocky10-nodocs` image has no bash/dnf (`compute-image-build.md.j2`)

`image-build` uses two code paths in `installer.py`:
- `install_scratch_repos/packages` — for `parent: scratch`, uses `dnf --installroot`
  (no bash needed in container)
- `install_repos/packages` — for all other parents, uses `buildah run -- bash -c ...`
  (bash + dnf must exist in the container)

`nodocs.yaml` started from `scratch` with no packages → empty container → no bash/dnf.
Building `rocky10-base` on top of it called `install_repos` → bash not found.

Fix: added repos + packages to `nodocs.yaml` definition in `compute-image-build.md.j2`:
```yaml
repos:
  - alias: '{{ baseosshort }}_BaseOS'
    url: '{{ distro_base_url }}{{ distro_version }}/BaseOS/{{ arch }}/os/'
    gpg: '{{ distro_base_url }}RPM-GPG-KEY-{{ distro_name }}-{{ distro_version }}'
  - alias: '{{ baseosshort }}_AppStream'
    url: '{{ distro_base_url }}{{ distro_version }}/AppStream/{{ arch }}/os/'
    gpg: '{{ distro_base_url }}RPM-GPG-KEY-{{ distro_name }}-{{ distro_version }}'
packages:
  - bash
  - dnf
  - dnf-plugins-core
```
This was a **pre-existing bug** from the original TeX (not a refactor regression).
The original TeX also had no repos/packages in nodocs.yaml.

### 5. `dnf config-manager --set-enabled crb` fails in compute-base layer (`compute-image-build.md.j2`)

`compute-base.yaml` had `cmds: - cmd: dnf config-manager --set-enabled crb` but `crb` repo
is not defined in the container. `image-builder` configures repos from the YAML — the host's
`/etc/yum.repos.d/` is not visible inside the buildah container.

Fix: added CRB as an explicit `repos` entry and removed the `cmds` section entirely:
```yaml
repos:
  - alias: '{{ baseosshort }}_CRB'
    url: '{{ distro_base_url }}{{ distro_version }}/CRB/{{ arch }}/os/'
    gpg: '{{ distro_base_url }}RPM-GPG-KEY-{{ distro_name }}-{{ distro_version }}'
  - alias: 'Epel{{ distro_version }}'
    ...
```
**Root cause**: pre-existing bug from original TeX (same pattern — relied on `crb` being
present in the running system's dnf config, which doesn't apply inside the buildah container).

### 6. `compute-prod.yaml` SELinux `user_tmp_t` blocks container read (`rebuild-image.md.j2`)

`yq -i` creates a temp file and renames it, leaving the file with `user_tmp_t` SELinux context.
The `builder` user inside the podman container can't read `user_tmp_t` files → `Permission denied: 'config.yaml'`.

Fix: add `:z` to the volume mount in `rebuild-image.md.j2`:
```
-v /opt/ohpc/admin/images/compute-prod.yaml:/home/builder/config.yaml:z
```
`:z` tells podman to relabel the mounted file for container access.

**Key insight**: other yaml files (nodocs, base, compute-base) work without `:z` because they're
created by `cat >` (proper SELinux context). Only compute-prod.yaml is modified by `yq -i`.

### 7. `compute_sed` macro missing closing quote (`macros.j2`)

OpenCHAMI `compute_sed` macro had:
```
C="sed -i '{{ regex }} {{ file }}"
```
Missing `'` after regex. Fix:
```
C="sed -i '{{ regex }}' {{ file }}"
```
Pure refactor bug (macro was newly written for OpenCHAMI).

### 8. OpenHPC packages not found in compute-prod (`compute-image-build.md.j2`)

`image-builder` sets `reposdir=/home/builder/.pkg_repos/yum.repos.d` in `/etc/dnf/dnf.conf`.
This custom directory only contains repos explicitly defined in the layer's YAML — the standard
`/etc/yum.repos.d/` (where `ohpc-release` installs `OpenHPC.repo`) is completely ignored by `dnf`.

Result: even though `ohpc-release` is installed and `/etc/yum.repos.d/OpenHPC.repo` exists,
`dnf repolist --all` doesn't show OpenHPC, and `dnf install ohpc-base-compute` fails.

Fix: add OpenHPC repo explicitly to `compute-prod.yaml` repos section:
```yaml
repos:
  - alias: 'OpenHPC'
    url: '{{ ohpc_repo_server }}/OpenHPC/{{ ohpc_version_tree }}/{{ ostree }}'
    gpg: 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OpenHPC-{{ ohpc_version_tree }}'
```
The `file://` GPG reference works because `ohpc-release` (installed in compute-base) puts the
key at `/etc/pki/rpm-gpg/RPM-GPG-KEY-OpenHPC-4`, which is inherited by compute-prod.

**Rule**: any package that requires an RPM-installed repo (like `ohpc-release`) MUST also
have the repo explicitly defined in the YAML's `repos:` section for packages to be found.

### 9. `boot-params` ran before `rebuild-image` published to S3

`boot-params.md.j2` queries S3 for kernel/initrd/squashfs paths. Was in `provisioner-openchami.md.j2` before `rebuild-image.md.j2` (in `deploy-openchami.md.j2`). S3 was empty → all paths empty → BSS got `http://sms_ip:9000/` with no file path.

Fix: moved `boot-params.md.j2` and `cloud-init.md.j2` from `provisioner-openchami.md.j2` to `deploy-openchami.md.j2`, immediately after `rebuild-image.md.j2`.

Hand-fix on live cluster: re-ran `ochami bss boot params set` manually with correct S3 paths (confirmed working bootscript).

### 10. Compute nodes not in `/etc/hosts`

OpenCHAMI has no equivalent of `confluent2hosts`. Fix: added `echo "${c_ip[$i]} ${c_name[$i]}" >> /etc/hosts` in `node-discovery.md.j2`'s loop. Runs before `cp /etc/hosts` in `compute-image-build.md.j2`, so image also gets correct hosts.

### 11. Missing trailing slash on cloud-init seedfrom URL (`boot-params.md.j2`)

`ds=nocloud-net;s=http://${sms_ip}:8081/cloud-init` (no trailing slash) caused cloud-init to
request `http://…/cloud-inituser-data` (404) instead of `http://…/cloud-init/user-data` (200).
Result: cloud-init silently failed, no SSH key or munge key distributed to compute nodes.

Fix: added trailing `/` → `ds=nocloud-net;s=http://${sms_ip}:8081/cloud-init/`

Confirmed: cloud-init server logs showed no requests from 10.5.1.1 before fix, then
`xname x1000c0s0b1 with ip 10.5.1.1 found` + all endpoints 200 after fix.

### 12. Munge/slurmd not restarted after cloud-init key distribution (`cloud-init.md.j2`)

Cloud-init writes the munge key but munge was already running with a default key.
Without restarting, slurmd auth failed and `pam_slurm` blocked SSH even after key injection.

Fix: added `runcmd` section to the cloud-init compute group template:
```yaml
runcmd:
  - systemctl restart munge
  - systemctl restart slurmd
```

### 13. pdsh uses wrong SSH key / host key rejection (`cloud-init.md.j2`)

`pdsh` uses default SSH keys, not `id_openchami`. LiveOS regenerates SSH host keys on each boot,
causing `known_hosts` conflicts. Fix: add SSH client config after key generation:
```bash
cat >> "$HOME/.ssh/config" <<EOF
Host ${compute_prefix}*
    IdentityFile $HOME/.ssh/id_openchami
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
```

### 14. No wait for nodes after boot (`deploy-openchami.md.j2`, new `wait-nodes.md.j2`)

recipe proceeded to slurm startup before compute nodes were SSH-accessible.
Fix: new `wait-nodes.md.j2` polls `pdsh` until all nodes respond:
```bash
until pdsh -w "${compute_prefix}[1-${num_computes}]" true >/dev/null 2>&1; do
    echo "Waiting for compute nodes..."
    sleep 10
done
```
Included in `deploy-openchami.md.j2` after `boot/wait.md.j2`.

### 15. iPXE EFI crash on boot retry due to unset `${SYSTEM_URL}` — REVERTED

**Symptom**: `https:///apis/bss/boot/v1/bootscript` (empty hostname) → EFI General Protection Fault.
Root cause: BSS bootscript retry path uses `${SYSTEM_URL}` iPXE variable which `config.ipxe` never sets.

**Fix attempted**: new `ipxe-config.md.j2` that writes custom `config.ipxe` and adds
a file-level volume mount to `coresmd.container`. Reverted after testing for two reasons:

1. This is a VM UEFI bug — on real hardware with IPMI the node would reboot automatically
2. The EFI crash only affected boot-loop recovery (first successful boot worked fine)

The recipe should not add complexity to work around a VM-only issue.

**Bugs still filed** in `docs/install/openchami-bugs.md` for upstream reference:

1. `config.ipxe` not setting `SYSTEM_URL` (coresmd upstream issue)
2. `coresmd.container` missing `/tftpboot` volume mount (deployment-recipes upstream issue)

**Lessons from the attempt**:

- GNU sed requires `\|pattern|` not `|pattern|` for alternate address delimiters
- Mounting a whole directory volume (`:/tftpboot:Z`) shadows ALL container contents —
  always mount specific files (`:/tftpboot/config.ipxe:Z`) to avoid hiding other files
- Use `vol="..."` variable for long sed lines to stay under mkdoc.py's 87-char limit

### Cloud-init Architecture (OpenCHAMI)

- Server identifies nodes by requesting IP → SMD EthernetInterfaces → ComponentID → group membership
- Both interfaces (BMC + node) use `ComponentID: x1000c0s0bXn0`'s parent xname `x1000c0s0bX`
- Compute group in SMD must contain `x1000c0s0bX` (ohpc-nodes.sh creates this automatically)
- Cloud-init fetches: `user-data` (13B empty), `meta-data` (583B), `vendor-data`, `compute.yaml` (1784B)
- `user-data` is minimal/empty; `compute.yaml` is the group template fetched separately
- `## template: jinja` + `{%raw%}{{ ... }}{%endraw%}` in Jinja2 context for cloud-init Jinja passthrough

## Current State (2026-02-23)

14 fixes in templates. Fix 15 reverted. Full clean rebuild in progress.

- ✓ fixes 1-10: template + hand-validated
- ✓ fixes 11-14: template + hand-validated on live cluster (c1 boots, munge/slurmd active, sinfo idle, pdsh works)
- ✗ fix 15 reverted (EFI crash is VM UEFI bug, not recipe issue)
- ✗ full clean rebuild with fixes 1-14 not yet confirmed end-to-end

**Next**: wait for clean rebuild to complete, then verify SSH to c1, `sinfo` shows idle, `pdsh` works.
If cloud-init fails: check `curl http://10.5.0.8:8081/cloud-init/c1/user-data` and
`journalctl -u cloud-init-server` — the BSS `ds=nocloud-net;s=localhost/` override is a suspected issue.

---

## aarch64 Validation (2026-03-12)

**Result: `rocky10-aarch64-openchami-slurm` recipe fully validated end-to-end.**

Tested via lima proxy (`ssh -p 8022 cloud@localhost`). Recipe ran to completion after applying
upstream container version patches.

### Upstream Bugs Found and Filed

**1. `openchami` RPM v0.1.2 references amd64-only images**

- `opaal.container` + `opaal-idp.container`: `ghcr.io/openchami/opaal:v0.3.10` (amd64-only)
- `step-ca.container`: `ghcr.io/openchami/local-ca:v0.2.2` (amd64-only)
- Fix: bump to `opaal:v0.3.12` (arm64 added) and `local-ca:v0.2.3` (arm64 added)
- Filed in: `OpenCHAMI/release` — PR #41 (`OpenCHAMI/release#41`) bumps opaal; local-ca needs separate bump

**2. `local-ca:v0.2.2` missing arm64 manifest**

- Filed as `[BUG]` in `OpenCHAMI/release` issues
- `local-ca:v0.2.3` adds arm64 but introduces new CMD bug (see below)

**3. `local-ca` CMD variables never shell-expanded (v0.2.3 through v0.2.5)**

- v0.2.3 symptom: `/entrypoint.sh: exec: exec: not found` (literal `exec` in CMD array)
- v0.2.5 symptom: `step-ca can't find or open the configuration file` (literal `$PWDPATH`/`$CONFIGPATH` in CMD array)
- Root cause: Dockerfile CMD is exec-form `["/usr/bin/step-ca", "--password-file", "$PWDPATH", "$CONFIGPATH"]`; `entrypoint.sh` does `exec "${@}"` which passes them as literal strings — no shell expansion
- Fix needed upstream: use shell-form CMD or replace `exec "${@}"` with `exec /usr/bin/step-ca --password-file "$PWDPATH" "$CONFIGPATH"` in entrypoint.sh
- Filed in `OpenCHAMI/local-ca` (2026-03-26); v0.2.5 still broken
- Workaround: `sed` an `Exec=` line into `step-ca.container` with literal paths (see recipe.sh patch below)

**4. `coresmd-coredns` Corefile missing `smd_url` (both arches)**

- Shipped Corefile has `smd_url` commented out — `coresmd-coredns` fails immediately
- `PartOf=openchami.target` so failure cascades; workaround: remove from target or configure it
- Not filed yet — pre-existing issue, affects x86_64 too; deferred for now

### Recipe.sh aarch64 Patch (in template, `install.md.j2`)

Now baked into the recipe template under `{% if is_aarch64 %}`. Patch bumps image versions
and adds `Exec=` override to bypass the CMD variable-expansion bug:

```bash
sed -i 's|ghcr.io/openchami/opaal:v0.3.10|ghcr.io/openchami/opaal:v0.3.12|g' \
    /etc/containers/systemd/opaal.container \
    /etc/containers/systemd/opaal-idp.container
sed -i 's|ghcr.io/openchami/local-ca:v0.2.2|ghcr.io/openchami/local-ca:v0.2.5|g' \
    /etc/containers/systemd/step-ca.container
# FIXME: local-ca CMD uses unexpanded $PWDPATH/$CONFIGPATH; override with literal paths
sed -i '/^PodmanArgs=--no-hosts$/a Exec=/usr/bin/step-ca --password-file /home/step/secrets/password /home/step/config/ca.json' \
    /etc/containers/systemd/step-ca.container
```

**Important**: keep the `Exec=` sed on a single line in the template — line continuation (`\`) inside
the sed `a` text splits the appended value across two lines, creating an invalid quadlet unit that
breaks the entire quadlet generator (all services fail to load, not just step-ca).

Once upstream releases a fixed RPM (opaal:v0.3.12 + local-ca with shell-expanded CMD), this patch can be removed.

### arch-confirmed working on aarch64

- `image-build:latest` — has proper arm64 manifest, builds Rocky 10 aarch64 layers correctly
- `opaal:v0.3.12` — arm64 manifest works
- `local-ca:v0.2.3` — arm64 manifest works, but CMD bug needs `Exec=` workaround

## Debugging Tools & Workflow

### Cluster lifecycle

- Rebuild: run `test-recipe-run.sh` from `~/projects/ohpc-jetstream2/` (don't edit this file)
- Recipe command: `sudo OHPC_INPUT_LOCAL=./test-recipe-config-10.sh bash -x -e ./recipe.sh`
- Recipe runs as root (`gen_access_token` needs root's podman)
- Cluster is fully disposable — always prefer rebuild over hand-patching when in doubt

### Monitoring image builds

The `image-build` podman runs are long (5–10 min). Redirect output on the head node:

```bash
# Start build in background and redirect output
sudo podman run --rm --device /dev/fuse --network host \
    -v /opt/ohpc/admin/images/FOO.yaml:/home/builder/config.yaml \
    ghcr.io/openchami/image-build:latest image-build \
        --config config.yaml --log-level DEBUG \
    2>&1 | tee /tmp/image-build.log

# Watch from another terminal (or Claude reads it via SSH)
tail -f /tmp/image-build.log
```

### SSH access

```bash
ssh rocky@ohpc-head.INI200001.projects.jetstream-cloud.org
sudo bash   # or: sudo OHPC_INPUT_LOCAL=... bash -x -e ./recipe.sh
```

### Checking image layers in local registry

```bash
sudo podman images                          # list all
sudo podman images | grep compute-base      # specific layer
```

### When to hand-test vs. rebuild

- **Hand-test** for isolated, obvious fixes where the yaml/command is already on the head node
  and upstream layers are intact. Update the yaml file via SSH (use Python, not bash heredoc
  — bash quoting mangles YAML quotes), then run the podman command directly.
- **Rebuild** when: multiple layers need rebuilding, yaml quoting issues arose from hand-patching,
  or the fix is in an early recipe section. Rebuilds take ~20–30 min total.

### Hand-patching YAML on head node

**Use Python, not bash heredoc** — bash heredoc quoting strips YAML string quotes:
```bash
sudo python3 -c "open('/opt/ohpc/admin/images/FOO.yaml','w').write('''..content..''')"
```
Or copy the recipe.sh section and run just that block.

---

## Fixes 16–18: cloud-init / SSH not working (2026-02-23)

These three bugs caused cloud-init to fail → SSH key not installed → "Permission denied (publickey)".
Fixed live; templates need to be updated.

### Fix 16: BSS appends duplicate `ds=` (tab in params string)

**Root cause**: BSS's `paramExists()` splits params by space only (`strings.Split(params, " ")`).
The recipe params use bash line-continuation tabs (`\<newline>\t`), so `\tds=...` doesn't match
prefix `"ds="`. BSS always appends `ds=nocloud-net;s=localhost/` (from `BSS_ADVERTISE_ADDRESS=localhost`
in `openchami.env`), overriding our cloud-init URL.

**Symptom**: kernel cmdline has `ds=nocloud-net;s=http://sms_ip:8081/cloud-init/ ... ds=nocloud-net;s=localhost/` (two `ds=`). Cloud-init uses the last one (`localhost/`) and warns it's invalid.

**Fix**: In `boot-params.md.j2`, put `ds=` **first** in the params string with no leading tab. Then
`paramExists` finds it and BSS skips its append.

```bash
# WRONG (tab before ds=):
export params="nomodeset ro \
    root=... \
    ds=nocloud-net;s=http://${sms_ip}:8081/cloud-init/"

# CORRECT (ds= first, space-separated, no tabs):
export params="ds=nocloud-net;s=http://${sms_ip}:8081/cloud-init/ nomodeset ro root=... ip=dhcp overlayroot=tmpfs overlayroot_cfgdisk=disabled apparmor=0 selinux=0 console=ttyS0,115200 ip6=off cloud-init=enabled"
```

**BSS source**: `bss/cmd/boot-script-service/default_api.go:592` (`paramExists`) and `:696` (`checkParam` for `ds=`).
**`BSS_ADVERTISE_ADDRESS=localhost`** is in `/etc/openchami/configs/openchami.env` — this is the deployed value.

### Fix 17: EthernetInterface has BMC xname for compute NIC

**Root cause**: `ochami discover static` registers the compute NIC's EthernetInterface with
`ComponentID: "x1000c0s0b1"` (NodeBMC) instead of `"x1000c0s0b1n0"` (Node).
The cloud-init-server maps source IPs via SMD EthernetInterfaces — if the compute NIC is
registered under the BMC xname, the server can't find the node and returns 404.

**Symptom**: cloud-init-server logs `Adding new node x1000c0s0b1 with MAC 02:0e:0f:e4:37:b0`
(only the BMC MAC/IP, not the compute NIC). `curl http://10.5.0.8:8081/cloud-init/user-data`
from the compute node returns 404.

**Fix**: After `ochami discover static`, patch each compute NIC's EthernetInterface ComponentID
to the node xname in `node-discovery.md.j2`. The MAC IDs (without colons, lowercase) are the
EthernetInterface IDs in SMD.

```bash
for((i=0; i < $num_computes; i++)); do
    mac_id=$(echo "${c_mac[$i]}" | tr -d ':' | tr '[:upper:]' '[:lower:]')
    xname="x1000c0s0b$((i+1))n0"
    curl -sk -X PATCH \
        -H "Authorization: Bearer $(gen_access_token)" \
        -H "Content-Type: application/json" \
        -d "{\"ComponentID\":\"$xname\"}" \
        "https://${sms_name}:8443/hsm/v2/Inventory/EthernetInterfaces/$mac_id"
done
```

**Live fix applied**: `curl -sk -X PATCH ... -d '{"ComponentID":"x1000c0s0b1n0"}' "https://head.novalocal:8443/hsm/v2/Inventory/EthernetInterfaces/525400050101"`

Also needed: enable node and add to SMD group:
- `ochami -k smd group member add compute x1000c0s0b1n0`
- Enable via `curl -sk -X PATCH ... -d '{"Enabled":true}' ".../hsm/v2/State/Components/x1000c0s0b1n0/Enabled"`

**Note**: `ochami discover static` creates `x1000c0s0b${NID}n0` as a Node component (disabled by default)
and `x1000c0s0b${NID}` as NodeBMC. The compute MAC gets registered under BMC — this is a bug in
`ochami discover static` or in the `ohpc-nodes.sh` YAML format it generates.

### Fix 18: cloud-init defaults/group not uploaded during recipe run

**Root cause**: TBD — the `/opt/ohpc/admin/cloud-init/*.yaml` files are created but
`ochami cloud-init defaults set` and `ochami cloud-init group set` didn't upload the data.
Possible causes: recipe failed before these steps due to an earlier error, or `C_ACCESS_TOKEN`
was not exported at that point.

**Workaround applied live**:
```bash
source /etc/profile.d/openchami.sh
export C_ACCESS_TOKEN=$(gen_access_token)
ochami -k cloud-init defaults set -f yaml -d @/opt/ohpc/admin/cloud-init/defaults.yaml
ochami -k cloud-init group set -f yaml -d @/opt/ohpc/admin/cloud-init/compute.yaml
```

**Recipe fix needed**: Ensure `C_ACCESS_TOKEN` is exported (already done in node-discovery for
`${prefix^^}_ACCESS_TOKEN`). Check the recipe for any early exit that would skip cloud-init upload.
Add `ochami -k` (insecure) flag to all ochami calls if they're using self-signed TLS.

**Additional bug found**: `defaults.yaml` has the SSH public key duplicated with a trailing `\n`
(the `yq` loop re-adds the key from `id_openchami.pub` which was already added inline). Harmless
for SSH but should be fixed.

### Fix 19: `ochami cloud-init` calls missing `-k` flag (`cloud-init.md.j2`)

**Symptom**: `ochami cloud-init defaults set` and `ochami cloud-init group set` fail during
recipe run (TLS certificate verification error — self-signed cert).

**Root cause**: Both calls in `cloud-init.md.j2` lacked the `-k` (insecure TLS) flag that
all other `ochami` calls in the recipe use.

**Fix**: Added `-k` to both calls:

```bash
ochami -k cloud-init defaults set \
    -f yaml -d @/opt/ohpc/admin/cloud-init/defaults.yaml
ochami -k cloud-init group set \
    -f yaml -d @/opt/ohpc/admin/cloud-init/compute.yaml
```

**Template**: `sections/provisioner/openchami/cloud-init.md.j2`

**Also fixed in this session**: `params=` line in `boot-params.md.j2` was 243 chars (limit 87).
Split into `p1`–`p4` temp variables, assembled into `params`. `ds=` still first.

## cloud-init-server Architecture (KEY)

- **IP-based identification**: Server maps source IP → xname via SMD EthernetInterfaces
- **No node ID in URL**: Compute node requests `http://sms_ip:8081/cloud-init/user-data` (no `/c1/` in path)
- **Group mapping**: SMD group membership drives cloud-init group serving (SMD group `compute` → cloud-init group `compute`)
- **vendor-data**: Returns `#include http://sms_ip:8081/cloud-init/compute.yaml` for the group
- **compute.yaml URL**: Also IP-identified; the include fetch comes from the compute node's IP
- **Refresh**: SMD cache refreshes every 60 seconds (`Ticker triggered`)
- **API paths**: Admin API at `https://sms_name:8443/cloud-init/admin/...` (haproxy routes `/cloud-init/` → cloud-init-server:27777)

## BSS Architecture (KEY)

- **Source**: `~/source/openchami/bss/` (v1.31.3)
- **`paramExists(params, "ds=")`**: Splits by space only — tabs break detection
- **`checkParam(params, "ds=", "nocloud-net;s="+advertiseAddress+"/")`**: Only adds if `ds=` not found
- **`BSS_ADVERTISE_ADDRESS=localhost`**: Set in `openchami.env` — this is the deployed value
- **Fix**: Put `ds=` first in recipe params (no tab prefix)

## Image Build Architecture (`installer.py`)

Key file: `~/source/openchami/image-builder/src/installer.py`
- `install_scratch_*` methods: use `dnf --installroot` (for `parent: scratch`)
- `install_repos/packages/cmds`: use `buildah run [cname] -- bash -c ...`
- Consequence: any layer with `parent: scratch` must install bash+dnf if subsequent
  layers need to run commands inside the container

---

## Session: 2026-02-23 (openchami 0.1.2, ochami 0.6.1 upgrade)

### ochami 0.6.1 V2 Discovery Format

Source: `~/source/openchami/ochami/cmd/discover/static/static.go`

Old format detected by presence of `bmc_ip`/`bmc_mac` keys in YAML — triggers deprecation warnings:
- `bmc_ip found, using old discovery format`
- `using deprecated discovery format`
- `'group' is deprecated; use 'groups' instead`

New V2 format (`pkg/discover/struct.go`):
```yaml
bmcs:
- xname: x1000c0s0b1
  ip: 10.5.2.1
nodes:
- name: c1
  nid: 1
  xname: x1000c0s0b1n0
  bmc: x1000c0s0b1
  groups:
  - compute
  interfaces:
  - mac_addr: 52:54:00:05:01:01
    ip_addrs:
    - name: internal
      ip_addr: 10.5.1.1
```

`node-discovery.md.j2` updated to generate this format directly using inline heredoc loops.
Plain `<< EOF` (flush left, not `<<-EOF`) — avoids tab/space ambiguity.

### V2 discover static does NOT register EthernetInterfaces

Key finding from source (static.go line ~337):
```go
if discoveryVersion == discover.DiscoveryMethodV1 {
    // register EthernetInterfaces
}
```
V2 path: creates components + SMD groups, skips EthernetInterfaces entirely.
`--discovery-version` flag defaults to V2 regardless of YAML format.

Fix: add explicit `ochami -k smd iface add` loop after discover:
```bash
ochami -k smd iface add x1000c0s0b${nid}n0 ${c_mac[$i]} internal,${c_ip[$i]}
```
This replaces the old PATCH-based Fix 17 (PATCH EthernetInterface ComponentID).

### SMD has FOUR tables — all must be cleared for full reset

```bash
ochami -k smd component delete --all   # nodes and BMCs
ochami -k smd iface delete --all       # ethernet interfaces (MAC→xname map)
ochami -k smd rfe delete --all         # redfish endpoints (BMC hardware objects)
ochami -k smd compep delete --all      # component endpoints (EthernetNICInfo etc.)
```

`component delete` + `iface delete` alone leaves `rfe` and `compep` populated.
EthernetNICInfo in compep is a remnant from redfish discovery; must clear `rfe` first.

### EthernetInterfaces: dual purpose

1. **BSS at PXE boot**: MAC → xname → fetch boot params
2. **cloud-init at OS boot**: source IP → xname → group membership → serve config

`ochami discover static` (V2) does NOT populate these. Must use:
```bash
ochami -k smd iface add <xname> <mac> <netname>,<ip>
```

### EFI GPF crash — not a recipe issue

- Happens after N iPXE retry cycles when `${SYSTEM_URL}` is unset in some iPXE context
- Observed to coincide with timing of `ochami discover static` but not caused by it
- Root cause: VM UEFI / iPXE issue after multiple retries
- Fix 15 (ipxe-config.md.j2 change) was attempted and reverted — confirmed VM issue

### Current blocking issue: S3 empty, no BSS boot params

Recipe failed before reaching image build step:
- `ochami -k bss boot params get` → `null`
- `s3cmd ls -r s3://boot-images/` → empty
- `/opt/ohpc/admin/nodes/compute-boot.yaml` doesn't exist

Suspected cause: `gen_access_token` not available when needed in recipe
(requires `source /etc/profile.d/openchami.sh`; only available after openchami installs it).

Also: `ochami bss boot params set` in `boot-params.md.j2` may be missing `-k` flag.
And: `cat >>` in `boot-params.md.j2` should be `cat >` (first run should not append).

### Fixes applied this session (all confirmed)

1. `boot-params.md.j2`: `cat >>` → `cat >` ✓
2. `boot-params.md.j2`: added `-k` flag to `ochami bss boot params set` ✓
3. `node-discovery.md.j2`: removed opaal restart (caused haproxy cascade crash) ✓
4. `node-discovery.md.j2`: V2 format with `bmcs:`/`nodes:`, synthetic BMC MACs ✓
5. `node-discovery.md.j2`: removed iface add loop — V2 discover handles it correctly ✓
6. `node-discovery.md.j2`: removed PATCH ComponentID loop — no longer needed ✓
7. `cloud-init.md.j2`: removed `root_key` export (duplicate), `public-keys: []`, `$()` loop ✓
8. `clustershell.md.j2`: trailing space after `\` line continuation ✓
9. `client-install.md.j2`: hardcoded `cluster` name (was using `${compute_prefix}`) ✓
10. `install.md.j2` (renamed from `enable-repo.md.j2`): added `source /etc/profile.d/openchami.sh` ✓
11. `token.md.j2` (new): sets `CLUSTER_ACCESS_TOKEN` at top of deploy chapter ✓
12. `deploy-openchami.md.j2`: moved node-discovery to end (after cloud-init), added token.md.j2 ✓

### V2 discover static — CORRECTED understanding

V2 discover static DOES register EthernetInterfaces under the **node** xname (from
`interfaces:` section of nodes.yaml). No post-discovery patching needed. Previous
analysis from source code was wrong — iface add loop was added and then removed.

### opaal restart → haproxy cascade

`systemctl restart opaal-idp opaal` causes haproxy to restart (dependency).
Takes ~2 minutes to recover. If `ochami discover static` runs during that window:
"connection refused" on port 8443. Fix: removed opaal restart entirely.

### cloud-init-server memstore — KEY FINDING

State stored in memory only. Lost on container restart. Symptoms:
- `ochami -k cloud-init defaults get` returns `{}`
- `ochami -k cloud-init group get raw compute` returns 404
- Node gets vendor-data with `#include http://cloud-init:27777/compute.yaml` (internal URL)
- cloud-init init stage fails, sshd fails to start, SSH connection refused

Fix: upload defaults + group again. pre-boot-verify.md.j2 catches this before node boot.

### Token TTL and auth failure behavior

- Token TTL: 1 hour (`iat`/`exp` delta = 3600s)
- `ochami -k` returns exit code 1 on bad/expired token
- Silent upload failures are NOT from auth — look for container restarts instead

### Result: Node SSH working on openchami 0.1.2

After manually uploading defaults + compute group, node booted with correct cloud-init
config and became SSH-accessible. Full recipe rebuild in progress.
