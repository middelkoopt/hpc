<!--
Provenance: verbatim paste from Tim in chat, 2026-07-25 (typos/emoji/Slack
formatting preserved exactly). This is the raw source; the organized/edited
version lives in talk-scraps.md, claude-usage-stats.md, and links.md.
Everything below the line is the unedited original.
-->

---

so back-story.  In my brain-dead and want to do something else time last week I started working on refactoring the documentation for OpenHPC, it was near impossible for someone to just go in and make some simple changes.  We (Adrian, not I) migrated it to markdown as a POC and I'm refactoring it so it sheds 15 years of tech debt.  The ultimate goal is to facilitate the community to participate in writing the docs (Adrian, the other person workin on it would rather work on the technical stuff).  It's also been a wonderful way to learn the power of coding with LLM's (it's wow, it's a game changer, and will have impact on research as well).  I've wanted to push this out so the base docs don't change much between when I start and when I commit, I've got most if it done now.  So sorry for the long story, but thought the context would help.

Just finished the OpenHPC work to convert 15 years of LaTex, perl (that parses shell scripts as well), and gargantuan makefiles built with symlink hell and all the files in one directory with random names into Markdown+Jinja+Python where you can find stuff and don't have to type ../../../../common/parse_doc.pl :wink:.  Now people can actually contribute to the docs :grin:
https://github.com/openhpc/ohpc/pull/2366

### That does not include the 539 files that will be deleted in some commit soon.  I asked Claud to summarize it's use.

### 

| Metric  | Value |
| ----- | ----- |
| Sessions | 34 |
| Real user prompts | 818 |
| Assistant messages | 9,953 |
| Tool calls | 5,297 |
| Total messages (all roles) | \~16,000 |
| API: token generation | 166 min (2.8 hrs) |
| API: time-to-first-token | 104 min (1.7 hrs) |
| Local: tool execution | 315 min (5.3 hrs) |
| Total active time | 585 min (9.75 hrs) |


I learned a LOT... using an LLM effectively is definitely a skill and I don't see that changing any time soon.  The biggest takeaways I took is the importance of good design, good documentation, tools for validation and verification, and that that managing context/attention is very important, along with managing the context window/compacting process and internal memory state files. You also need to figure out when (and when not to) watch the "thinking" process.

44 compactions across 5 sessions.

refactoring is pretty straight forward. I spent the first couple days on design, that's where i was compacting all the time, after that it was just refactoring and refinement.  I did have to clean up after it though, it got messy at times

Mike, thanks for the inspiration, but LaTeX is no more!  Checkout https://github.com/openhpc/ohpc/tree/4.x/docs/install - it's a new markdown+Jina2+pandoc documentation system. Thanks to Adrian for huge PR review.  The layout/structure has been completely reworked and hopefully makes more sense and will make it easier to find things and to contribute.  I was able to re-merge about 95% of the duplicated files and all the recipes now follow the same basic flow.  Added bonus is that there are now macros for installing packages and updating configurations on the compute nodes (Warewulf uses containers/chroots, Confluent running nodes, and OpenCHAMI yaml).  Adrian really kicked this all off with a cool POC that showed that it was possible and getting Warewulf and Confluent ported over. This showed the way for Claud to help out a lot (I would not have had the time to do it otherwise).   Here are some interesting stats from Claude Code.

So an update - I've got a cold and I've been chill'n and coding with Claud (first time on a larger project) between naps, and got some significant progress. The refactor also went deep into the tooling as well, so I've ended up with a flatter directory structure.  A build.py that generates a recipe based on a yaml file (no jinga-cli needed - not having an easy install of this started the whole thing). I also can generate the manifests as well from the repo's.  We only need jinga and yaml as python dependency.  I've spent most of the time working on cleaning up the tooling and the structure to a way I like before working more on content.  Claude did a good first pass on the refactoring.  For the most part the recipes (.md and .sh) are the same.  I'm at a point now that I'm going to put some more human time into how the docs should be laid out and port confluent (Claud did a horrible first-pass on this).  I'll probably build a few more validation tools before I progress.  Although this looks very different deeply based on your first POC.  You can find my work here if you are interested - https://github.com/middelkoopt/ohpc/tree/tm-refactor-md .  TL;DR - big changes to the markdown, including tooling - hope to be ready soon. (edited)

From Adrian - (nov 21, 2025) - @Timothy Middelkoop As we talked about going from latex to markdown plus jinja2, I let claude run for some time and around 300K tokens later I have a new version of the OpenHPC pdf. Still a bit rough around the edges, but generally it seems to be a direction that could work.

There also may be comments on the PR's (you have access to the gh tool).
