# LaTeX is no more: refactoring the OpenHPC docs with Claude

*Long-form draft — the whole story, before cutting to the PEARC OpenHPC BoF (a 10-minute
update + a call to contribute). First person, Tim's voice. Everything here is git/PR-verified;
see `../STATS.md` and `../narrative/` for sources.*

---

## The itch

The OpenHPC installation recipes are the front door to the project. They are how a site stands up
a cluster: pick your distro, your provisioner, your scheduler, and follow the guide. They are also,
for fifteen years, the part of the project almost nobody outside a couple of maintainers could touch.

The recipes were LaTeX. Not just LaTeX — LaTeX with a Perl script that parsed the document to
*extract the shell commands* into a runnable `recipe.sh`, wired together with gargantuan Makefiles,
per-recipe directories connected by symlinks, and a pile of files with cryptic names sitting in one
directory. If you wanted to fix a typo in the Rocky/Warewulf/Slurm guide, you first had to
understand `../../../../common/parse_doc.pl`. If you wanted to add a distro, you were copying and
hand-editing enormous near-duplicate `.tex` trees. The content across provisioners had drifted —
each recipe had grown its own flow. Fifteen years of tech debt, and every year the barrier to
contributing got a little higher.

That barrier is the whole point of this story. My work in this community is about lowering the cost
of participation — getting more people able to do the work. The OpenHPC docs were a small, sharp
example of the opposite: a body of shared knowledge that had become effectively read-only to the
community that depended on it.

## The why

I did not set out to do this. I had a cold. It was the kind of week where I wanted to do something
absorbing that was not my actual job. So I started poking at the docs.

The goal, once it took shape, was simple to say and hard to do: **make it possible for the community
to contribute to the documentation.** Adrian Reber — the other person who works on this — would
rather work on the technical guts of OpenHPC, and that is exactly where his time should go. If the
docs could be made approachable, the pool of people who could improve them would grow well beyond
the two of us. That is the return: not a prettier PDF, but a doc system a newcomer can open, find
their way around, and change without fear.

## The prior art: Adrian's POC

I want to be clear about the foundation, because it matters both for credit and for how this worked.

Adrian had already done the hard proof. Back in November he let Claude run at the problem and,
in his words, *"around 300K tokens later I have a new version of the OpenHPC pdf. Still a bit rough
around the edges, but generally it seems to be a direction that could work."* That proof-of-concept —
LaTeX to Markdown plus Jinja2 — landed as a real commit in February (the POC system, Warewulf and
Confluent ported). It was rough, but it answered the only question that mattered: *is this even
possible?* Yes.

And here is the part that turned out to be the key technical insight of the whole effort: **the POC
was not just a head start, it was context.** It gave the LLM a worked example of the target — what a
recipe looks like as Markdown, how a provisioner maps across, what "done" looks like. That context
is what made it possible for Claude to automate the tedious middle of the refactor. Without the POC,
I would have been asking the model to invent the destination and travel to it at the same time. With
it, I could point and say: more of this, applied everywhere, cleaned up.

## The refactor (OpenHPC 4.x)

This took about two solid weeks, between me and Claude, mostly while I was supposed to be resting.

**I spent the first couple of days on design.** That is where nearly all the pain was — and, it turned
out, nearly all the value. Design is where I was constantly running out of context and compacting the
conversation, over and over. What is the directory structure? How does configuration compose across
the dimensions — distro, architecture, provisioner, scheduler — without duplication? How do you keep
the Markdown close enough to stock that you could walk away from the tooling later if you wanted to?
Where do the shared pieces live, and where do the provisioner-specific pieces live?

Out of that came a small tool. It started as nothing more than a replacement for `jinja-cli` — which
I could not easily install, and that annoyance is, honestly, the seed of the entire project. The tool
grew: it merged a stack of configuration YAML files (base → distro → arch → provisioner → scheduler,
each layer overriding the last), rendered the Markdown, generated the `recipe.sh`, and warned about
line lengths. `mkdoc.py`. Pure Python. Two dependencies: `jinja2` and `pyyaml`.

Then the actual refactor, which was mechanical and enormous and exactly the kind of thing an LLM is
good at when you hold the reins: bring the POC content over, reshape it into a consistent file layout,
then reshape it *again* so every recipe followed the same flow. Once the flow was consistent, I could
pull the provisioners in one at a time and start deleting duplication — Warewulf, then Confluent, then
OpenCHAMI — introducing Jinja2 macros so a single description of "install these packages on the compute
nodes" could expand correctly whether the provisioner used containers and chroots (Warewulf), running
nodes (Confluent), or YAML (OpenCHAMI). By the end I had re-merged something like **95% of the
duplicated files**, and every recipe shared a common spine.

I did not trust any of it on faith. I compared the generated PDF of each recipe against the original
LaTeX version, one by one, to make sure no content had silently vanished in the reshaping. Then I
updated the `ohpc-docs` RPM package and the build, rebuilt the validation-comment system that marks
which lines become shell commands, and validated the recipes against my own cluster — provisioner by
provisioner, distro by distro.

I will be honest about the tradeoffs, because this audience can smell a sales pitch. **Claude's first
pass was a good first pass, not a finished one.** It got messy at times, and I had to clean up after
it. The Confluent port, in particular, was a horrible first pass — that one took real human time to get
right. The pattern that emerged was consistent: the model was excellent at the wide, tedious,
well-specified transformations, and needed me for judgment, for the parts where the "right" structure
was a matter of taste, and for the places where a plausible-looking change was subtly wrong.

## The review: PR #2366

I opened the pull request on February 20th. It merged on the 26th. In between is one of the more
useful records of what human/LLM collaboration on a real project actually looks like, and it is worth
walking through because it is not the tidy story the marketing implies.

Adrian's first response: **"this is too big to review. GitHub cannot handle it correctly. I have
problems seeing all the changes."** The PR was +11,549 / −158 across 208 files. He wanted to know:
is this the existing Markdown work, or something new? (It was a complete rework built on top of his
POC.)

Then came the real review — and it was skeptical in exactly the right ways. He pushed on three things:

- **Generated files in the tree.** I had committed the rendered Markdown and `recipe.sh` files to make
  it easy to see changes while working. He wanted them gone. Fair — I filtered them out.
- **The virtualenv and pip.** Why a venv, why `requirements.txt`, when the target distributions already
  ship the packages? The venv was a Mac-build convenience from early on. I pulled it.
- **The custom tool doing too much.** `mkdoc.py` was shelling out to external tools; that belonged in
  the Makefile. And, most pointedly: *"I am most sceptical about the need for a special tool to create
  the documentation… requiring a non-standard tool and needing our own DSL does not seem right."*

That last one was the important disagreement, and he was right to press it. My instinct had been to
solve the config-composition problem inside my tool. His instinct was that the project should not
depend on a bespoke tool and a homegrown DSL if it could be avoided. So I pulled the configuration
merge out of `mkdoc.py` and did it with `yq` in the Makefile; pulled `pandoc` out into the Makefile
(bonus: now `make -j` works); pulled the version-control insertion out too. The tool got smaller. The
dependency surface got smaller. The result was genuinely better than my first design, and it was
better *because* a skeptical reviewer refused to accept complexity he did not think was necessary.

The end of the thread is almost a period piece for 2026. *"Now squash it. No need for the intermediate
commits."* And then: *"Maybe let claude write a fancy commit message, some condensed version of the
DESIGN.md. That way it is clear in the git history what and why happened here."* We squashed roughly
thirty large-ish, churn-heavy commits into one — I had considered keeping the step-by-step history, but
there was simply too much thrash to be worth following. Then: *"Should we merge it?"* *"Yup."*

## The backport (OpenHPC 3.x)

4.x is the modern branch — EL10, the current provisioners, Slurm. But OpenHPC also supports an older,
wider world: EL9, openSUSE Leap 15, openEuler, the legacy Warewulf 3 provisioner, the OpenPBS
scheduler. All of that lives in 3.x, and all of it needed the new doc system too.

The 3.x backport was a completely different kind of work, and the contrast is the interesting part.
Where 4.x was exploratory and messy — figuring out what "good" even looked like — 3.x was disciplined
and phased, because the system already existed. The recipe for the backport was: copy the 4.x
`docs/install` verbatim, then adapt configuration for the older targets. Seven phases: EL9 core (12
recipes), add OpenPBS and Warewulf 3 (20), add Leap 15 (24), rework the RPM spec, add openEuler on
Warewulf 3 (28). Twenty-eight recipes, each building clean, shellcheck passing, committed in small
reviewable steps.

Two things are worth naming. First, **the tooling refactor is what made the backport tractable.** The
old world would have meant hand-editing another enormous LaTeX tree. The new world meant copying a
system and turning configuration knobs. That is the entire argument for the refactor in one sentence.

Second — and this is the thread I most want to pull on — **the backport is where my *process* matured,
not the code.**

## The process story: compacting → handoff

Here is the part I did not expect to be the takeaway, and now think might be the most transferable
thing I learned.

For the first stretch — the design-heavy 4.x work — I lived inside the conversation. When the context
window filled, I compacted and kept going. Across the design phase I compacted something like **44
times over five sessions.** Compaction is lossy: every time, some of the state of "what we are doing
and why" got squeezed, and I would find myself re-establishing ground we had already covered.

On May 7th — right as the migration was wrapping — I did something about it, and the git history
captures the exact afternoon. Four commits: I rewrote the project's `CLAUDE.md`, then added two new
files, `PROCESS.md` and `handoff-prompt.md`, and then — the tell — a commit literally titled *"Clean
up handoff-prompt.md for session close."* I had invented a ritual: at the end of a session, write down
the present state; at the start of the next, read it back.

`PROCESS.md` wrote down the rule that made it work: **`docs/` is the source of truth. Anything worth
keeping goes into git. Machine-local memory is only pointers and active state. Loss of the machine is
acceptable if you commit regularly.** That sounds obvious written down. It was not obvious in the
moment; it was earned by losing context to compaction enough times to stop trusting the conversation
as a place to keep knowledge.

The pattern kept maturing after that, and again the commits are precise about it:

- **June 1st — slim the handoff.** One commit cut the handoff file by 55 lines and moved the durable
  reference *out* to `CLAUDE.md` and `docs/`. The insight: the handoff is present-state *only*. The
  moment something durable lands in it, it belongs somewhere more permanent. Different knowledge has
  different volatility, and each kind wants a different home — the handoff churns every session, the
  rules change slowly, the reference barely moves.
- **June 5th — automate it.** I turned *off* Claude's automatic memory (its content was redundant with
  the always-loaded `CLAUDE.md` and `docs/`) and added a **SessionStart hook** that reads the handoff
  and the doc indexes at the top of every session and forces a pause: state what you read, then ask me
  for new context before doing anything. The ritual I had been performing by hand became something the
  system does for me — and it resists the model's strong bias to charge ahead before it understands the
  situation.

There is a recursive irony here that I think is the real lesson. **The raw transcripts of this entire
migration are gone** — Claude Code keeps them for thirty days by default, the work was months ago, and
the directories moved. What survived is exactly what I had committed to git: the `CLAUDE.md`, the
`PROCESS.md`, the design docs, the memory files with the design decisions. The migration lost its own
conversation history and kept its knowledge, which is precisely the outcome `PROCESS.md` was written to
guarantee. The rule proved itself by being the reason this talk has sources at all.

## What I learned

- **Using an LLM well is a skill,** and I do not see that changing soon. The gap between a good session
  and a bad one was almost entirely me, not the model.
- **Design first.** The two days I spent on structure paid for the two weeks that followed. The messy,
  compaction-heavy design phase was not wasted motion — it was the work.
- **Documentation, and tools for validation and verification, are part of the workflow, not
  afterthoughts.** The PDF-to-PDF comparisons and the shellcheck/line-length checks are what let me
  trust a change I did not hand-write.
- **Managing context and attention is the core discipline.** That includes the compaction process, the
  memory/state files, and knowing when to watch the model's "thinking" and when to let it run.
- **Where the time actually goes is not where you would guess.** By the usage numbers, local tool
  execution — the agent running builds, tests, greps — took more wall-clock than the model's own
  generation. Refactoring with an LLM is mostly the machine doing your legwork, not the machine
  thinking.
- **The honest tradeoff:** first passes are messy, some first passes (hello, Confluent) are bad, and a
  plausible diff can be quietly wrong. You do not get to stop reviewing. What you get is leverage — I
  would not have had the time to do this at all otherwise.

And the bigger point, for this community specifically: this is a genuine shift in what one person can
take on, and it is going to land on research the same way it landed on my documentation. That is worth
our attention, not our hype.

## The magnitude

For a sense of scale, all verifiable in the git history:

- **44 working recipes** across the two branches (16 in 4.x, 28 in 3.x); four distros, two
  architectures, four provisioners, two schedulers.
- Recipe source **collapsed** rather than merely converted: in 4.x, 316 `.tex` files became 151
  Markdown/Jinja2 templates; the duplication is gone.
- **24 pull requests** merged from February through June — the cutover, then aarch64 support for
  Confluent and OpenCHAMI, dnf, openEuler, the 3.x port, OpenPBS, Leap 15, Warewulf 3, and the Warewulf
  4.7.0 updates.
- By Claude Code's own accounting of the effort: **34 sessions, ~818 prompts, ~5,300 tool calls,
  ~16,000 messages, about 9.75 hours of active time** — spread across a couple of weeks of coding
  between naps.

## The call to contribute

Here is the ask, and it is the reason this is a story worth telling at a BoF rather than a changelog.

The OpenHPC install docs are now Markdown. You can find things. You do not have to understand a Perl
parser or a symlink maze to change a recipe. There are macros so a fix to "how we install on compute
nodes" happens in one place across three provisioners. Every recipe follows the same flow, so once you
know one, you know them all. The dependency to build them is two Python packages.

The barrier that kept this to two people is gone. That was the entire goal. So: come contribute. Fix
the guide for the distro you run. Add the provisioner you use. Improve the recipe you wish had existed
when you were standing up your cluster. The docs are, for the first time in fifteen years, a place the
community can actually work.

LaTeX is no more. Your turn.
