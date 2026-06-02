# Coordinator Tooling

Tools available in the `hpc/` coordinator workspace.

## Python venv

A coordinator-level venv lives at `.venv/` (git-ignored).

```bash
# Create / reinstall
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt

# Use
.venv/bin/python3 script.py
```

`requirements.txt` at the coordinator root tracks the packages. Current deps:

| Package | Use |
|---------|-----|
| `pyyaml` | Parse/validate YAML (GitHub Actions workflows, warewulf configs) |

The OpenHPC docs build (`ohpc-4.x/docs/install/`) has its own `requirements.txt`
(`pyyaml`, `jinja2`) and its own venv — set that up separately inside that directory.

## System CLI Tools

These are installed system-wide (Homebrew / macOS):

| Tool | Use |
|------|-----|
| `jq`  | JSON querying — image digests, GitHub API output, container metadata |
| `yq`  | YAML querying — OpenHPC manifests, warewulf config, GitHub Actions matrix inspection |

Quick reference:

```bash
# Extract a field from a YAML file
yq '.matrix.include[] | select(.os == "almalinux") | .version' workflow.yml

# Parse JSON digest list
jq -r '.[] | .digest' digests.json

# Combine: query a YAML file and emit JSON
yq -o=json '.jobs.build.strategy.matrix.include' container-publish.yml | jq 'length'
```
