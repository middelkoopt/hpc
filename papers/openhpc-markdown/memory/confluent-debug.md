# Confluent Deployment Debug Session (Rocky 10 on OpenStack KVM)

## STATUS: Cluster fully validated ✓ (2026-02-22)

## Environment

- Head node: `rocky@ohpc-head.INI200001.projects.jetstream-cloud.org` (SSH as rocky, then `sudo bash --login`)
- Head node IP: 10.5.0.8, interface enp2s0, subnet 10.5.0.0/16
- Compute node: c1, MAC 52:54:00:05:01:01, IP 10.5.1.1/16, gateway 10.5.0.1
- NIC name in initramfs: `ens1`
- OS: Rocky Linux 10.1 x86_64 via Confluent provisioner
- Confluent profile: `rocky-10.1-x86_64-default`
- Confluent docs cloned at: `~/source/confluent-docs`
- Confluent source cloned at: `~/source/confluent`

## All Fixes Applied (all are required)

### 1. `net.bootable` and `net.ipv4_method` not set

```bash
nodeattrib c1 net.bootable=true
nodeattrib c1 net.ipv4_method=static
```

Without these, Confluent's DHCP didn't offer PXE boot to c1.

### 2. `net.ipv4_address` missing CIDR prefix

```bash
nodeattrib c1 net.ipv4_address=10.5.1.1/16
```

Without `/16`, `deploycfg2` returned no `ipv4_netmask`, making the `ip=` param
in `/etc/cmdline.d/01-confluent.conf` malformed and the Anaconda network phase fail.

### 3. SELinux blocking Apache → Confluent proxy (THE key fix)

```bash
setsebool -P httpd_can_network_connect on
```

Apache proxies `/confluent-api/` to Confluent at `127.0.0.1:4005`. SELinux blocked
this, causing all `/confluent-api/self/whoami` calls to return 503 HTML. The node
then used `<!DOCTYPE` as its nodename and looped forever trying to get an API token.

### 4. `confluent=` kernel arg (OpenStack blocks IPv6 link-local / multicast)

Added to profile.yaml `kernelargs`: `confluent=10.5.0.8`

**Root cause**: Confluent's normal deployment flow uses IPv6 link-local (fe80::)
for initramfs → server communication. From `confluent-docs/docs/advanced_topics/confluentosdeploy.md`:
> "Deployment interfaces must have IPv6 enabled, with at least an automatic fe80:: address."

On bare metal, `ip link set ens1 up` auto-assigns fe80::, copernicus discovers
the server via SSDP over IPv6 multicast, and apiclient communicates via link-local.
On OpenStack, IPv6/multicast is blocked by security groups, so copernicus loops
60 times (~5 min) then returns early with nothing written.

`confluent=10.5.0.8` bypasses copernicus and tells the initramfs directly where
the server is. **Proper fix**: enable IPv6 link-local on the OpenStack compute network.

### 5. Static `ip=` kernel arg (Confluent DHCP is PXE-only)

Added to profile.yaml `kernelargs`: `ip=10.5.1.1::10.5.0.1:255.255.0.0:c1:ens1:none`

**Root cause**: The `confluent=` code path uses `NetworkManager --configure-and-quit=initrd`
with DHCP to get a network address before calling `whoami`. But Confluent's DHCP server
(`pxe.py` line 663) ignores non-PXE DHCP requests:

```python
if requestor[0] == '0.0.0.0' and not info.get('uuid', None):
    return  # ignore DHCP from local non-PXE segment
```

NM's DHCP DISCOVER has no UUID/PXEClient vendor class → silently dropped → no IP
→ `whoami` fails. Static `ip=` configures `ens1` at dracut cmdline phase before
the Confluent hook runs, bypassing NM DHCP entirely.

**Note**: On bare metal with IPv6 link-local working, this is not needed — the
copernicus path uses IPv6, not DHCP.

## Current Working State

### profile.yaml kernelargs

```
console=ttyS0,115200 console=tty0 rd.shell confluent=10.5.0.8 ip=10.5.1.1::10.5.0.1:255.255.0.0:c1:ens1:none
```

### Node attributes

```bash
nodeattrib c1 net.bootable=true
nodeattrib c1 net.ipv4_method=static
nodeattrib c1 net.ipv4_address=10.5.1.1/16
nodeattrib c1 net.ipv4_gateway=10.5.0.1
nodeattrib c1 deployment.pendingprofile=rocky-10.1-x86_64-default
nodeattrib c1 deployment.apiarmed=once
```

### Key files on head node

- Profile: `/var/lib/confluent/public/os/rocky-10.1-x86_64-default/profile.yaml`
- boot.ipxe: `/var/lib/confluent/public/os/rocky-10.1-x86_64-default/boot.ipxe`
- Distribution: `/var/lib/confluent/distributions/rocky-10.1-x86_64/`
- Kickstart: `https://10.5.0.8/confluent-public/os/rocky-10.1-x86_64-default/kickstart`
- Confluent events log: `/var/log/confluent/events`

## Recipe Fixes Round 2 (2026-02-22 — cluster validation session)

1. **`pam_slurm` applied to head node** — `$CHROOT` unset on Confluent → wrote to head node `/etc/pam.d/sshd`
   - Root cause: `customize.md.j2` included `scheduler/slurm/pam.md.j2` (Warewulf `$CHROOT` version) for all provisioners
   - Fix: merged into single `pam.md.j2` using `compute_echo` macro; deleted `provisioner/confluent/pam.md.j2`

2. **SELinux blocks httpd serving `/var/lib/confluent/`**
   - Fix: `semanage fcontext -a -t httpd_sys_content_t '/var/lib/confluent(/.*)?'` in `confluent-install.md.j2`
   - Fix: `restorecon -Rv /var/lib/confluent/` after `osdeploy import` in `init-os-images.md.j2`
   - Live fix: `sudo semanage fcontext ...` + `restorecon` + `setenforce 1`

3. **NFS not mounted on compute nodes** — fstab entries never added
   - Fix added to `provisioner/confluent/compute-setup.md.j2` after nfs-utils install:

     ```bash
     MOUNT_OPTIONS="nfsvers=3,nodev,nosuid 0 0"
     NFS_PUB="${sms_ip}:/opt/ohpc/pub /opt/ohpc/pub nfs ${MOUNT_OPTIONS}"
     nodeshell compute "echo ${sms_ip}:/home /home nfs ${MOUNT_OPTIONS} >> /etc/fstab"
     nodeshell compute "echo ${NFS_PUB} >> /etc/fstab"
     nodeshell compute "mkdir -p /opt/ohpc/pub"
     nodeshell compute "mount -a"
     ```

4. **Slurm node DOWN — CPU mismatch** — `slurm_node_config="NodeName=c[1-4] State=UNKNOWN"` defaults to CPUs=1
   - Jetstream2 VMs have 2 vCPUs → slurmd reports mismatch → node DOWN
   - Fix in `test-recipe-config-10.sh`: `slurm_node_config="NodeName=c[1-4] CPUs=2 State=UNKNOWN"`
   - Also fixed `input.local.template` default (was missing `NodeName=` prefix)

5. **`slurm.conf` not distributed** — `nodersync` already in `compute-slurm.md.j2` (was working)

## Recipe Script Bugs Fixed (2026-02-22)

Template bugs found during cluster bring-up, all fixed:

1. **`crb enable` misrouted as dnf install** (`compute-setup.md.j2`)
   - Was: `{{ pkg_install_chroot }} compute /usr/bin/crb enable`
   - Fix: `{{ compute_run("/usr/bin/crb enable") }}`

2. **rpmmacros double-echo** (`compute-ohpc.md.j2`)
   - Was: `compute_echo("echo -e %_excludedocs 1", "~/.rpmmacros")`
   - `compute_echo` already wraps in echo — string must be content only
   - Also: `~` doesn't expand in double-quoted strings — use `$HOME`
   - Fix: `compute_echo("%_excludedocs 1", "$HOME/.rpmmacros")`

3. **syslog forward directive incomplete + quoting** (`syslog.md.j2`)
   - Was: `compute_echo("*.* action(type=\"omfwd\"...Port=\"514\" ", ...)`
   - Incomplete (missing `Protocol="udp")`), and inner `"` broke quoting
   - Fix: `compute_run("echo '*.* @${sms_ip}:514' > /etc/rsyslog.d/ohpc-forward.conf")`
   - Uses `compute_run` with single-quoted echo so `${sms_ip}` expands via
     outer `"..."` on head node; also switched to legacy format + drop-in file

4. **Stray `'` in Confluent `compute_sed` macro** (`macros.j2`)
   - Was: `"{{ file }}"'` — unmatched quote caused shell parse error
   - Fix: `"{{ file }}"` (removed stray `'`)

## Recipe Fixes Round 3 (2026-02-22 — NFS ordering)

1. **`lmod-ohpc` fails on compute nodes** — "Directory not empty" on `/opt/ohpc/pub/modulefiles/os`
   - Root cause: NFS was mounted *before* package installs; `lmod-ohpc` writes to `/opt/ohpc/pub/`
     which already exists on the NFS mount from the head node
   - The `%_excludedocs 1` workaround only covers `%doc` files, not module files/binaries
   - Fix: extracted NFS mount to new `provisioner/confluent/compute-nfs.md.j2` included
     *after* all package installs in `chapters/provisioner-confluent.md.j2`
   - Chapter ordering: `compute-setup` → `compute-ohpc` → `compute-slurm` → `compute-nfs`
   - Light duplicated files on local disk (e.g. lmod binaries) are buried under NFS at runtime

## OpenHPC Recipe Fixes

### For all environments (bare metal and VM)

- `net.bootable=true` + `net.ipv4_method=static` — **APPLIED** in `nodedefine` in `sections/provisioner/confluent/add-nodes.md.j2`
- `net.ipv4_address` in CIDR format — **APPLIED** via new `${internal_prefix_length}` variable (default `16`)
  - Added to `input.local.template` Confluent section (with consistency note re: `internal_netmask`)
  - Added to `sections/intro/inputs.md.j2` under `{% if is_confluent %}` guard
  - Applied in `nodedefine`: `net.ipv4_address=${c_ip[$i]}/${internal_prefix_length}`
- `setsebool -P httpd_can_network_connect on` — **APPLIED** in `confluent-install.md.j2` after `systemctl enable --now httpd`

### For OpenStack/KVM environments — SOLVED via OpenTofu

**Root cause**: OpenStack port security (anti-spoofing) blocks all traffic not matching
the port's assigned IPs. Compute ports had no IPv6 address assigned → ALL IPv6 blocked,
including fe80:: link-local → copernicus couldn't discover the head node.

**Fix**: Set `port_security_enabled = false` on compute node ports in OpenTofu
(`jetstream/openstack.tf`). This matches what was already done for the head node's
internal port. With port security off, IPv6 link-local auto-assigns on `ip link set up`
and copernicus discovers the server normally — no `confluent=` or `ip=` kernel args needed.

**`confluent=` + `ip=` workarounds are NOT needed** on OpenStack with this fix applied.
They remain documented below as a fallback for environments where IPv6 cannot be enabled.

**Fallback workaround** (if `port_security_enabled` cannot be set to false) — add to
profile kernelargs after `osdeploy updateboot`:

```bash
yq -i '.kernelargs += " confluent=$sms_ip ip=$node_ip::$gw:$netmask:$hostname:$nic:none"' \
  /var/lib/confluent/public/os/$profile/profile.yaml
osdeploy updateboot $profile
```

## `sms_eth_internal` Detection Note

The IP-based detection works correctly on OpenStack because cloud-init configures
`enp2s0` with the fixed IP from the port definition even when `enable_dhcp = false`.
OpenStack exposes the port's fixed IP via instance metadata; cloud-init reads it and
configures the interface statically. So `ip -j addr show to ${internal_network}/${internal_netmask}`
reliably finds `enp2s0` after cloud-init completes.

The topology-based fallback (default-route exclusion) is still more robust for
environments where the internal interface is not pre-configured by the cloud platform,
but was not ultimately needed here.

## Local QEMU Test Environment (aarch64, both 3.x and 4.x)

- QEMU processes run inside tmux session `ohpc` (window 0 = head, window 1 = c1)
- Access console: `tmux send-keys -t ohpc:c1 "command" Enter` / `tmux capture-pane -t ohpc:c1 -p`
- Head node SSH: `ssh -p 8022 cloud@localhost` then `sudo`
- `osdeploy` full path: `/opt/confluent/bin/osdeploy`
- Compute node: c1, MAC 52:54:00:05:01:01, IP 10.5.1.1/16, gw 10.5.0.8, interface `enp0s1`
- QEMU command uses `-bios edk2-aarch64-code.fd` — **use `-drive if=pflash` instead** to avoid EDK2 TPL assertion on ExitBootServices (fixed in test harness separately)
- Two virtio disks: `vda` = main disk, `vdb` = iPXE boot disk (read-only); ignore `vdb` activity

## el9 aarch64 addons.cpio Bug — Copernicus Path Missing NetworkManager Call (2026-04-28)

**Symptom**: `inst.stage2` missing from kernel cmdline, installer times out. `/etc/confluent/confluent.info` absent despite hook being present.

**Root cause**: In `/var/lib/dracut/hooks/pre-trigger/01-confluent.sh` (from `el9/initramfs/aarch64/addons.cpio`), the copernicus discovery path generates nmconnection files via `nm_generate_connections` but **never calls `NetworkManager --configure-and-quit=initrd --no-daemon`**. The `CNFLNT_IDNT` identity-disk path does call it. Result: `enp0s1` stays DOWN, installer can't reach the Confluent server.

**Confirmed**: Running `NetworkManager --configure-and-quit=initrd --no-daemon` manually from the dracut shell brings up the interface correctly. The `/etc/cmdline.d/01-confluent.conf` IS written correctly by the hook (copernicus works, `inst.repo=`, `ip=` are correct).

**el9 vs el10 addons.cpio**: Same size (319488 bytes) but differ at byte 13 — el10 may already have this fixed. Need to diff the pre-trigger hooks.

**Fix**: Unpack el9 cpio, add `NetworkManager --configure-and-quit=initrd --no-daemon` after `nm_generate_connections` in the copernicus path, repack:
```bash
mkdir /tmp/el9-addon && cd /tmp/el9-addon
cpio -id < /opt/confluent/lib/osdeploy/el9/initramfs/aarch64/addons.cpio
# edit var/lib/dracut/hooks/pre-trigger/01-confluent.sh
find . | cpio -o -H newc > /opt/confluent/lib/osdeploy/el9/initramfs/aarch64/addons.cpio
/opt/confluent/bin/osdeploy updateboot rocky-9.7-aarch64-default
```

**Note**: The 4.x (el10) version was also tested on local QEMU — if it works without this fix, the el10 cpio has the fix already. Debugging continues in the other project context.

## Diagnostics Cheatsheet (if boot fails again)

```bash
# In emergency shell on compute node:
cat /etc/confluent/confluent.info       # NODENAME + MANAGER = whoami worked
cat /etc/confluent/confluent.deploycfg  # profile/ipv4_method = deploycfg2 worked
ls /etc/confluent/confluent.apikey      # exists = port 13001 auth worked
cat /etc/cmdline.d/01-confluent.conf    # inst.repo + ip= = full flow worked
ip addr show                            # ens1 has 10.5.1.1

# On head node:
tail -f /var/log/confluent/events       # watch for whoami/PXE activity
curl -sk https://10.5.0.8/confluent-api/self/whoami \
  -H "CONFLUENT_IDS: uuid=test/mac=52:54:00:05:01:01"   # should return "c1"
nodeattrib c1 deployment.apiarmed=once  # re-arm if consumed between boots
```
