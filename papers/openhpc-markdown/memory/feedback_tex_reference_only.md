---
name: LaTeX sources are reference-only
description: The tex files under docs/recipes/install/ are read-only historical reference — never treat them as active source or suggest editing them
type: feedback
originSessionId: 7f5e6731-e1c0-4657-a19f-edae4a0dcc34
---
The LaTeX recipe files under `docs/recipes/install/` are the original pre-migration sources kept for historical comparison only. They are **not** built, not used, and should not be edited.

**Why:** The project completed a full LaTeX → Markdown/Jinja2 migration. All active development happens in `docs/install/templates/`. Referencing the tex files is only valid when comparing a pre-existing behavior vs. a regression introduced during the migration.

**How to apply:** Never suggest editing tex files. Never treat a pattern found only in tex as the authoritative source. When the user asks "is X from the tex files?" and the answer is no, that means X was added during migration and may be a candidate for cleanup.
