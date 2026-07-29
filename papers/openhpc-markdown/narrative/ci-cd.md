# CI/CD — verified notes (for the CI/CD slide)

Researched 2026-07-28 from the actual workflow files + GitHub PRs (not `hpc-lab/Developer.md`,
which is the operator's fallible notes). Slide added as the last slide of the BoF deck.

## OpenHPC 4.x CI (project-level; GitHub Actions in `ohpc-4.x/.github/workflows/`)

A mature pipeline, mostly built out in 2026 (not the operator's work — largely Adrian Reber et al.):

- **`validate.yml`** — the core pipeline, on push/PR to `4.x`. Jobs: `check_spec` (validate changed
  `.spec` files via `tests/ci/check_spec.py`), `build_on_rhel` (matrix build), `test_on_rhel` (matrix
  test with results upload), `integration_test` (matrix, nested containers), more matrix lint/validate
  jobs, `event_file`. Runs in **purpose-built containers** (`ghcr.io/openhpc/ohpc-analysis`,
  `ohpc-validate`, `ohpc-lint`). Matrix across the RHEL family.
- **Container builds:** `build-container.yml`, `build-ohpc-{analysis,lint,validate}-container.yml` —
  build the CI images the validate jobs run in.
- **PR-comment bots:** `build-order-analysis.yml`+`build-order-comment.yml` (RPM build order),
  `package-count-analysis.yml`+`package-count-comment.yml`, `ccache-stats-comment.yml`.
- **Scheduled:** `package-update-checker.yml` — monitors upstream releases, opens/updates/closes a
  "Package Upgrades Necessary" issue (currently manual-dispatch; hourly cron disabled).
- **Misc:** `lint.yml`, `test-analysis.yml`, `cleanup-packages.yml`, `slack-notifications.yml`,
  `stale.yml`.

### The integration test — a real virtual cluster (`validate.yml` → `tests/ci/integration-test.sh`)

`validate.yml`'s `integration_test` job (matrix: **warewulf, openchami**) starts an AlmaLinux 10
container as the head node (`--hostname sms`, privileged, nested containers) and runs
`tests/ci/integration-test.sh -p <provisioner>`. That harness **provisions a Warewulf head + 2
QEMU compute nodes (`c1`, `c2`) over PXE** and runs the **actual generated `recipe.sh`** end to end
(the recipe's `ipmitool` power-reset calls are intercepted by a fake `ipmitool` that launches the
QEMU VMs on TAP interfaces). So CI runs the real install guide against a real (virtual) cluster.

### Operator's placeholder markers (used by the CI — verified)

**The operator authored the markers**: `ohpc-4.x` commit **`78865bdef` "Add proxy and node reset
placeholder markers"** (Timothy Middelkoop, 2026-03-03). They are `#<<< ohpc_TYPE:SUBTYPE >>>#`
lines that sit in `recipe.sh` as **no-op shell comments** and get expanded by a pre-processor —
a site *or* the CI — to inject context-specific commands. Types: `ohpc_proxy:{head,compute,image}`
and node-reset. Documented in `docs/install/DESIGN.md` § "Site Pre-processing Placeholders."
**Still used in the pipeline:** `integration-test.sh` (line ~359) sed-expands
`#<<< ohpc_proxy:compute >>>#` into dnf config before running the recipe. This is the operator's
concrete CI contribution on the OpenHPC side (the Warewulf-side CI is below).

## Operator's Warewulf CI work (verified via PRs — AUTHORED, not just reviewed)

- **warewulf-node-images #95** (merged 2026-06-22) — *"ci: use native arm64 runners and dynamic matrix
  from images.json."* `container-publish.yml` builds the node OCI images (rocky/alma/leap/tumbleweed/
  debian/openeuler/ubuntu × versions) and publishes to GHCR. Per-arch build → push-by-digest → a
  `merge` job assembles the multi-arch manifest and **cosign-signs** (sigstore keyless).
  **Caveat:** the *dynamic matrix from images.json* was later simplified back to a static matrix
  (commit `2aef434` "Simplify image manifest back into container-publish.yml"); the **native arm64
  runners** (`ubuntu-24.04-arm`, alongside `ubuntu-latest` amd64) **remain**. So the slide says
  "native arm64 multi-arch," which is current — it does *not* claim the dynamic matrix.
- **warewulf #1804** (merged 2025-03-11) — *"Build aarch64 packages with GitHub actions"* (added
  aarch64 package builds to the main Warewulf CI).
- Context: the operator is an active Warewulf contributor (EL10, openEuler, IPv6, cpio
  `--renumber-inodes` #2206, etc.); the two above are the CI-specific ones.

## hpc-lab rig (NOT GitHub Actions — a local/cloud test harness)

`hpc-lab/.github/workflows/ci-test.yaml` is a stub (installs openstackclient on push to `ci`). The
real "pipeline" is **`run.py`**: it provisions a cluster and runs OpenHPC install recipes end-to-end.
- **qemu** (local, default) — the everyday rig; stands up head + compute VMs and runs a recipe.
- **Jetstream2** (cloud, `--cloud=jetstream`) — same rig at scale; slide just references it.
- Also used to test Warewulf branches and node-image import/boot/verify.

## The thread back to the talk

**The docs are the test.** `recipe.sh` is *extracted from the markdown* (`mkdoc.py`, the executable-
documentation feature), so whatever CI or the rig runs **is the install guide itself** — the docs
can't silently drift from what actually works. This is the CI/CD payoff of the markdown transition.

## How it works (prose — also the slide's speaker notes)

OpenHPC's CI runs on every pull request via GitHub Actions: a spec change kicks off a container-based
pipeline that validates the spec, then builds and tests the affected components across a matrix of
RHEL-family distros. The headline job is a full integration test — inside the runner it stands up a
Warewulf head node and two QEMU compute nodes over PXE, then runs the actual generated `recipe.sh`
end to end. To let one generic recipe work in that environment, I added placeholder markers — lines
like `#<<< ohpc_proxy:compute >>>#` and node-reset markers — that sit in the recipe as harmless
comments and get expanded by the pipeline (or by a site) to inject the commands that context needs.
On top of that, bots comment build-order, package-count and ccache stats on the PR, a scheduled job
watches upstream for new releases, and results go to Slack.

On the Warewulf side, I added the node-image pipeline: it builds the OS container images natively on
both x86_64 and arm64 runners, signs them with cosign, and publishes multi-arch manifests to the
GitHub container registry — so pulling an image gets you a signed build for whatever architecture
you're on. I also wired aarch64 package builds into Warewulf's own CI.

My hpc-lab rig sits underneath all that: one command stands up a QEMU cluster and runs an install
recipe end to end, and the same rig scales out to Jetstream2 when I want real-hardware behavior.

The nice part — and the thread back to the whole talk — is that `recipe.sh` is extracted straight from
the markdown, so the thing CI runs is the install guide itself. The documentation and the test are the
same artifact, so the docs can't quietly drift from what actually works.

## Slide placement

Placed as slide 8, **before** "Contribute" — so the call-to-action still closes the section, with
CI/CD as the "the project is well-engineered / the docs are the tests" beat that sets up the ask.
(Overrode the original "put it at the end" once Contribute was the deliberate closer; operator said
"put it where you see fit.")
