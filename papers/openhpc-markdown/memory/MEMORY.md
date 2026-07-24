# OpenHPC Project Memory

## Project Overview

OpenHPC documentation system for HPC cluster installation recipes. Migrated from LaTeX to Markdown with Jinja2 templating. Project root: `docs/install/`.

## Key Design Decisions

See [DESIGN.md](../../../docs/install/DESIGN.md) for full details.

### Architecture

- **Recipe = `.conf` + `.yaml` pair**: `.conf` lists config files to merge, `.yaml` holds per-recipe overrides (Confluent only; omitted for others via `.SECONDEXPANSION`)
- **Makefile merges** `.conf` files via `yq eval-all` into `build/*.yaml`, injects `vc_revision`/`vc_date` via `yq`; mkdoc.py reads pre-merged YAML
- **mkdoc.py is pure Python** — no subprocess calls; all external tool invocations are in the Makefile
- **Document entry point**: `templates/chapters/main.md.j2` includes all 12 chapter aggregators (2 use dynamic `~ provisioner ~` includes)
- **Chapter aggregators**: `chapters/` (shared + provisioner-specific, unified from blocks/ + workflows/)
- **Config inheritance**: base → distro → arch → provisioner → scheduler
- **Boolean flags in YAML** - no runtime computation
- **Section comments auto-injected** via `SectionCommentExtension` Jinja2 extension
- **`input.local.template` is static** — NOT Jinja2-rendered; copied as-is into RPM. Cannot use `{{ vars }}` in it. Jinja2 defaults must be baked into templates instead.

### Heading Ownership

- `#` chapters → in chapter aggregators
- `##` sections → in template files (self-contained, self-describing)
- `###` grouping → in aggregators (groups multiple includes)
- `####` leaves → in leaf template files
- No redundant `{# Comment #}` in aggregators (filenames are self-documenting)
- Chapter separators: `{# ===== Chapter: ... ===== #}` for readability

### Directory Layout

```text
docs/install/
├── mkdoc.py                 # Main build tool
├── generate_manifest.py     # Manifest generator
├── input.local.template     # Shell variable template for recipe.sh (STATIC, not Jinja2)
├── pandoc/                  # PDF + HTML support
│   ├── header-includes.tex.j2   # LaTeX header (page headers, code styling)
│   ├── format-filters.lua       # Lua filter (fonts, tip boxes, format-variant images)
│   └── codeblock-styles.css     # CSS for HTML output
├── config/                  # Configuration hierarchy
├── templates/                # Jinja2 templates
│   ├── chapters/            # Chapter aggregators (8 files)
│   └── ...                  # Individual section templates
├── manifests/               # Package manifest data
├── recipes/                 # Recipe .conf + .yaml pairs (source only)
└── build/                   # Generated output (gitignored, includes *.yaml merged configs)
```

### Terminology (all prose updated)

- `head node` (not master, sms) — all prose/headings updated
- `Base OS` in prose, `base-os` in filenames/variables (not BOS/bos)
- `warewulf` (not warewulf4) — install paths use `warewulf/` not `warewulf4/`
- `el` for Enterprise Linux family
- `infiniband`, `omnipath` (no abbreviations)
- `[sms]#` prompts removed from all code blocks
- SMS variables (`sms_ip`, `sms_name`) kept, SMS defined once in requirements.md.j2

### Naming Conventions

- Files: lowercase with hyphens, `.md.j2` extension
- Variables: `snake_case`, prefixed by category (`pkg_`, `distro_`, `enable_`, `is_`)
- Display names: `provisioner_name`, `scheduler_name` (in config, used in titles/headers)

### Output Formats

- **PDF**: pandoc + xelatex, `--fail-if-warnings`
- **HTML**: pandoc + `--embed-resources` (self-contained, images as base64 data URIs)
- **Images**: `.format-variant` class → Lua filter selects .pdf (LaTeX) or .svg (HTML)
- All images have SVG versions (converted from PDF via inkscape)

### RPM Packaging

- Spec: `components/admin/docs/SPECS/docs.spec` (BuildArch: noarch)
- Source: `get_source.sh` creates tarball with `.git/`, `docs/install/`, ChangeLog
- Build: `make PYTHON=python3` (system packages, no venv)
- Install: `/opt/ohpc/pub/doc/recipes/{distro}/{arch}/{provisioner}/{scheduler}/`
- Files: `Install_guide.{pdf,md,html}` + `recipe.sh` + per-distro `input.local`

## Useful Commands

```bash
cd docs/install

# TWO-STEP BUILD — .md and .sh are separate targets:
#   build/%.md:  mkdoc.py build/%.yaml           (no --with-script)
#   build/%.sh:  mkdoc.py build/%.yaml --with-script
# Running without --with-script only updates the .md; the .sh stays STALE.
# ALWAYS use 'make' or target the .sh explicitly to verify recipe script output.

# Build single recipe .md only (does NOT update .sh):
python mkdoc.py build/rocky9-x86_64-warewulf-slurm.yaml
# Build single recipe .sh (and .md):
python mkdoc.py build/rocky9-x86_64-warewulf-slurm.yaml --with-script
# Or use make target (3.x uses .venv):
make build/rocky9-x86_64-warewulf-slurm.sh PYTHON=.venv/bin/python3

# Makefile targets
make                        # Build all .md + .sh (default)
make script                 # Build all .sh only
make build/NAME.sh          # Build single recipe .sh (also rebuilds .md)
make PYTHON=python3         # Use system python (for RPM builds)
make pdf                    # Build all PDFs
make html                   # Build all HTML
make check                  # Run shellcheck on all .sh

# RPM build (macOS/lima — EL9 VM) — prepare env first, then build:
lima sudo ./tests/ci/prepare-ci-environment.sh
lima sudo ./tests/ci/run_build.py $USER ./components/admin/docs/SPECS/docs.spec

# Generate manifests
python generate_manifest.py manifests/el10-x86_64
```

## Local Test Environment

- **Rocky 10 via lima** — use `lima` (or `lima sudo ...`) for a local Rocky 10 shell
  - Inspect RPM spec files/package contents, test commands without a live remote cluster
  - `lima rpm -qpl <package>` — list files a package would install
  - RPM builds: `lima sudo python3 tests/ci/run_build.py $USER <spec>`
- **Jetstream2 cluster**: `~/projects/ohpc-jetstream2/` — OpenTofu deployment for live testing
  - Test input.local: `~/projects/ohpc-jetstream2/scripts/test-recipe-config-10.sh` (source of truth — not head node)
  - SSH: `rocky@ohpc-head.INI200001.projects.jetstream-cloud.org`
  - `slurm_node_config` must include CPU spec matching VM flavor (`slurmd -C` on compute node)
  - **Multi-line remote root commands**: pipe a local heredoc to `sudo bash` — no quoting issues, no `-t` needed:

    ```bash
    ssh rocky@ohpc-head... sudo bash << 'EOF'
    # commands run as root; single-quoted EOF = no local expansion
    EOF
    ```

  - Avoid `ssh ... "sudo cmd > file"` — redirect runs as rocky, not root; use `sudo tee` or the heredoc pattern above
  - Avoid `ssh ... "... '!foo' ..."` — bash history expansion fires on `!` inside double quotes; use `<< 'EOF'` instead

## Confluent Deployment

**Fully validated** on Jetstream2 (2026-02-22). See [confluent-debug.md](confluent-debug.md) for all fixes and diagnostics.

### Confluent-Specific Variables

- `distro_base_url` — distro config var (trailing slash), e.g. `https://dl.rockylinux.org/pub/rocky/`
- `distro_iso_image` — per-recipe var, "latest" ISO filename, e.g. `Rocky-9-latest-aarch64-dvd.iso` (not pinned to point release)
- `distro_id` — **NOT** in recipe YAML for Confluent; set at runtime via `osdeploy importcheck` in `init-os-images.md.j2`
- `iso_path` — set via `:=` default assignment in template: `: "${iso_path:={{ distro_iso_image }}}"` then used as `${iso_path}` throughout
- `iso_url` — runtime override for ISO download base URL (`:=` default baked in from `distro_base_url`):
  `iso_url="${iso_url:={{ distro_base_url }}{{ distro_version }}/isos/{{ arch }}}"`

### Confluent Pre-Provisioning Templates (2026-03-06)

- `templates/base-os/ssh-key.md.j2` — SSH key generation; included for non-Warewulf provisioners;
  has `{% if is_confluent %}` note that it's required for Confluent
- `templates/provisioner/confluent/download-iso.md.j2` — ISO download before `osdeploy import`;
  uses `${iso_url:=...}` with `distro_base_url` baked in as default

## Original TeX Source

Original LaTeX recipe files at `docs/recipes/install/` are **read-only historical reference** — not built, not used, never edited. See [feedback_tex_reference_only.md](feedback_tex_reference_only.md).

## Current State

**3.x backport in progress** (branch `tm-markdown-3.x`, 2026-04-27). See [project_3x_backport.md](project_3x_backport.md) for full status.

**4.x** — PR merged (2026-02-26): LaTeX → Markdown/Jinja2 migration complete and merged to main.

**14 working recipes:** 6 Warewulf (Rocky, AlmaLinux, openEuler × x86_64, aarch64), 4 Confluent (Rocky, AlmaLinux × x86_64, aarch64), 4 OpenCHAMI (Rocky, AlmaLinux × x86_64, aarch64).

All three provisioners fully validated. OpenCHAMI aarch64 validated 2026-03-12 (via lima proxy). See [openchami-debug.md](openchami-debug.md) and [confluent-debug.md](confluent-debug.md) for per-provisioner debugging notes.

**OpenCHAMI aarch64 pending upstream fixes** (recipe patches baked into `install.md.j2`):

- `openchami` RPM needs `opaal:v0.3.12` + `local-ca` with fixed CMD (tracked in `OpenCHAMI/release`)
- `local-ca` CMD exec-form bug (unexpanded `$PWDPATH`/`$CONFIGPATH`) affects v0.2.3–v0.2.5; filed in `OpenCHAMI/local-ca` (2026-03-26); workaround: `Exec=` override in quadlet — keep on ONE line in template (line continuation splits the `a` text, breaking the quadlet generator for ALL services)
- `coresmd-coredns` Corefile `smd_url` unconfigured (both arches, deferred)

**Jetstream2 VM notes** (see [openchami-debug.md](openchami-debug.md) for full detail):

- IPMI commands replaced with `echo` via sed (VM has no real IPMI)
- SSH user: `almalinux@` (not `rocky@`)
- image-builder uses `reposdir=/home/builder/.pkg_repos/yum.repos.d` — RPM-installed repos are invisible to `dnf`; declare all needed repos in the YAML `repos:` section

## Key Patterns & Rules

### Macro-First Rule

Before writing `{% if is_warewulf %}...{% elif is_confluent %}...{% endif %}` conditionals
in templates, **always check `templates/macros.j2` first**. The `compute_echo`, `compute_run`,
`compute_sed`, and `compute_install` macros handle all provisioner differences automatically.
A provisioner conditional in a template almost always means a macro should be used instead.

### Confluent: NFS Must Come After Package Installs

OpenHPC packages (e.g. `lmod-ohpc`) install files to `/opt/ohpc/pub/`. If NFS is already
mounted there when packages are installed, RPM fails with "Directory not empty". Local copies
get buried under NFS at runtime (acceptable for light packages). Chapter ordering enforced in
`provisioner-confluent.md.j2`: `compute-setup` → `compute-ohpc` → `compute-slurm` → `compute-nfs`.

### RPM Test Workflow

See [feedback_rpm_test_workflow.md](feedback_rpm_test_workflow.md) — build via lima, copy to `~/projects/ohpc-jetstream2/data/`.

### LaTeX Reference Only

See [feedback_tex_reference_only.md](feedback_tex_reference_only.md) — `docs/recipes/install/` tex files are read-only, never active source.

### 3.x Backport

See [project_3x_backport.md](project_3x_backport.md) — status, config map, OpenPBS scope.

### Script Extraction Markers

```markdown
<!-- ohpc_begin -->          block start
<!-- ohpc_end -->            block end
<!-- ohpc_command CMD -->    raw shell line
<!-- ohpc_comment TEXT -->   # TEXT in script
<!-- ohpc_if_set VAR -->     if [[ ${VAR} -eq 1 ]];then  (enable_* flags)
<!-- ohpc_if CONDITION -->   if CONDITION;then            (complex cases)
<!-- ohpc_else -->           else
<!-- ohpc_fi -->             fi   ← NOTE: ohpc_fi not ohpc_endif
```

Runtime conditionals use `input.local` variables (sourced at install time).
Build-time conditionals use Jinja2 `{% if ... %}` (recipe YAML flags).

### Proxy Support

See [proxy-patterns.md](proxy-patterns.md) for full details. Summary: placeholder markers
`#<<< ohpc_proxy:TYPE >>>#` (head/compute/image) emitted as no-op comments; sites
pre-process with sed/python. Defined in `base-os/proxy.md.j2` and provisioner compute templates.

**`mkdoc.py` line-length warning fix**: lineno now relative to section start (not absolute
in rendered output), so warning line numbers match source template files.

### Python 3.9 Compatibility (mkdoc.py)

EL9 ships Python 3.9. Avoid: `X | Y` type unions (use `Optional`/`Union` from `typing`),
`match` statements, `tomllib`. Use `from typing import Optional, Union` for type hints.
