# OpenHPC Docs System

Reference for working in `ohpc-3.x/docs/install/` and `ohpc-4.x/docs/install/`.
Both branches use the same Markdown/Jinja2 system; differences are noted where they exist.

## Architecture

- **Recipe** = `.conf` file (lists YAML config files to merge) + optional `.yaml` override (Confluent only)
- **Makefile** merges `.conf` via `yq eval-all` → `build/*.yaml`; injects `vc_revision`/`vc_date`
- **`mkdoc.py`** is pure Python — reads pre-merged YAML, renders Jinja2 templates; no subprocess calls
- **Config inheritance**: `base` → `distro` → `arch` → `provisioner` → `scheduler`
- **Boolean flags in YAML** — no runtime computation; use `is_warewulf`, `is_openeuler`, etc.
- **`input.local.template` is static** — NOT Jinja2-rendered; copied as-is into RPM. Jinja2 defaults must be baked into templates instead.

## Directory Layout

```text
docs/install/
├── mkdoc.py                   # Main build tool
├── generate_manifest.py       # Manifest generator
├── input.local.template       # Shell variable template (STATIC, not Jinja2)
├── config/                    # Config hierarchy (base, distro, arch, provisioner, scheduler)
├── templates/
│   ├── chapters/              # Chapter aggregators (include other templates)
│   └── ...                    # Section templates (.md.j2)
├── manifests/                 # Package manifest data
├── recipes/                   # Recipe .conf files (source only)
└── build/                     # Generated output (gitignored)
```

## Build Commands

```bash
cd docs/install

# 3.x — uses .venv (already set up)
make PYTHON=.venv/bin/python                        # build all .md + .sh
make build/openeuler22.03-aarch64-warewulf3-openpbs.sh PYTHON=.venv/bin/python
make check PYTHON=.venv/bin/python                  # shellcheck all .sh

# 4.x — also uses .venv
make PYTHON=.venv/bin/python

# RPM builds (EL9 VM via lima)
lima sudo ./tests/ci/prepare-ci-environment.sh
lima sudo ./tests/ci/run_build.py $USER ./components/admin/docs/SPECS/docs.spec

# IMPORTANT: .md and .sh are separate targets
# 'make' without --with-script only updates .md; .sh stays stale
# Always use 'make' (not just mkdoc.py directly) or target the .sh explicitly
```

## Deploying to hpc-lab for testing

```bash
# From ohpc-3.x/docs/install/
make PYTHON=.venv/bin/python && cp -v build/*.sh ../../../hpc-lab/tests/
```

`hpc-lab/tests/` is an intentional staging buffer — copy only when intending to run.
The copy decouples the build process from the test process and allows auditing what was run.

## Heading Ownership

- `#` chapters → in chapter aggregators
- `##` sections → in template files (self-contained)
- `###` grouping → in aggregators
- `####` leaves → in leaf template files

## Naming Conventions

- Files: lowercase with hyphens, `.md.j2` extension
- Variables: `snake_case`, prefixed by category (`pkg_`, `distro_`, `enable_`, `is_`)
- Display names: `provisioner_name`, `scheduler_name` (used in titles/headers)
- Terminology: `head node` (not master/sms), `Base OS` in prose / `base-os` in filenames,
  `warewulf` (not warewulf4), `el` for Enterprise Linux family

## Key Patterns

### Macro-First Rule

Before writing `{% if is_warewulf %}...{% elif is_confluent %}...{% endif %}` in templates,
check `templates/macros.j2` first. The `compute_echo`, `compute_run`, `compute_sed`, and
`compute_install` macros handle provisioner differences automatically. A provisioner
conditional almost always means a macro should be used instead.

### Script Extraction Markers

```markdown
<!-- ohpc_begin -->          block start
<!-- ohpc_end -->            block end
<!-- ohpc_command CMD -->    raw shell line
<!-- ohpc_comment TEXT -->   # TEXT in script
<!-- ohpc_if_set VAR -->     if [[ ${VAR} -eq 1 ]];then
<!-- ohpc_if CONDITION -->   if CONDITION;then
<!-- ohpc_else -->           else
<!-- ohpc_fi -->             fi   ← NOTE: ohpc_fi not ohpc_endif
```

Runtime conditionals use `input.local` variables. Build-time conditionals use Jinja2.

### Proxy Placeholders

Proxy support uses placeholder markers (never conditional, always emitted):

```bash
#<<< ohpc_proxy:TYPE >>>#    # head / compute / image
```

Sites pre-process with sed/python. Left as-is = no-op. Defined in:

- `templates/base-os/proxy.md.j2` — `head`
- provisioner compute templates — `compute`
- `templates/provisioner/openchami/compute-image-build.md.j2` — `image`

`ohpc_reset` placeholders (runtime, not pre-processed): when `has_ipmi=0`,
`boot-computes.md.j2` prints `#<<< ohpc_reset:$i,${c_name[$i]},${c_bmc[$i]} >>>#`.
hpc-lab's test-recipe-run.sh intercepts these for qemu VM resets.

### Confluent: NFS After Package Installs

OpenHPC packages install to `/opt/ohpc/pub/`. If NFS is already mounted there,
RPM fails with "Directory not empty". Chapter ordering in `provisioner-confluent.md.j2`:
`compute-setup` → `compute-ohpc` → `compute-slurm` → `compute-nfs`.

### Warewulf3 + OpenPBS Escaping

In `compute-install-openpbs.md.j2`, inside `wwctl image exec <<- EOF`,
`\\\$clienthost` is needed:

- Outer shell heredoc: `\\\$` → `\$`
- Inner bash double-quoted string: `\$` → literal `$clienthost`
- Perl regex sees `$clienthost` as variable (empty string) → pattern matches correctly

### OpenCHAMI: Quadlet One-Line Constraint

In `templates/provisioner/openchami/`, the `local-ca` `Exec=` override line in the quadlet
**must stay on a single line** — line continuation (`\`) splits the `a` text in the quadlet
generator and silently breaks ALL services, not just local-ca. No obvious error is emitted.

## Python 3.9 Compatibility (mkdoc.py)

EL9 ships Python 3.9. Avoid:

- `X | Y` type unions → use `Optional`/`Union` from `typing`
- `match` statements
- `tomllib`

## RPM Packaging

| Field | Value |
| ----- | ----- |
| Spec | `components/admin/docs/SPECS/docs.spec` (BuildArch: noarch) |
| Source | `get_source.sh` creates tarball with `.git/`, `docs/install/`, ChangeLog |
| Build | `make PYTHON=python3` (system packages, no venv) |
| Install | `/opt/ohpc/pub/doc/recipes/{distro}/{arch}/{provisioner}/{scheduler}/` |
| Files | `Install_guide.{pdf,md,html}` + `recipe.sh` + per-distro `input.local` |

## Original LaTeX Sources

`docs/recipes/install/` — read-only historical reference only. Never edit.
All active development is in `docs/install/templates/`.
