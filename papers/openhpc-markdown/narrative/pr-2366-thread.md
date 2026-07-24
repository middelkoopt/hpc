# PR openhpc/ohpc#2366 — "New Markdown Docs" (the cutover PR)

Created 2026-02-20 · Merged 2026-02-26 · @middelkoopt · +11,549 / −158 · 208 files · 32 comments · 2 reviews
Link: https://github.com/openhpc/ohpc/pull/2366

## PR description
```
New Markdown docs tree
* Install recipes reorganized and ported to Markdown+Jinja2+pandoc
* Rewritten tools, only depends on pyyaml and jinja2 python packages (`mkdoc.py`).
* Refactored from poc-markdown and remaining original tex versions
* Combined duplicated sections/material.
* New directory and configuration structure.
* Refactored document layout and structure.
* New Jinja2 macros to support multiple provisioner commands. 
* Reworked validation comments.
* All variants ported and hand validated against recipe and pdf documents
* Warewulf provisioner works (lightly tested)
* Currently testing Confluent (some issues with VM)
* OpenCHAMI is untested
* Rocky lightly tested
* OpenEuler and AlmaLinux untested
* Moved to docs/install,  previous code left in place.
* Updated ohpc-docs rpm package - need additional testing.
* See docs/install/DESIGN.md for design details

All recipes have been ported to new documentation. 

Ready for broader review and input.  Help is needed for testing as well.

Could be merged as old code is in place (not sure of the role of `ohpc-docs` in the testing infrastructure).

Enjoy!
```

## Thread (chronological, human comments only — CI bot omitted)

**@middelkoopt** (2026-02-22):

Confluent now builds on my test env on Jetstream2 for Rocky and x86_64.

---

**@middelkoopt** (2026-02-23):

OpenCHAMI now working.  Some issues testing on VM's with hanging nodes, just reboot and they should come up. Some work needed on this and a few other minor things.  Tested on Rocky10 on x86_64 with Jetstream2.

---

**@adrianreber** (2026-02-23):

Thanks. But this is too big to review. GitHub cannot handle it correctly. I have problems seeing all the changes.

It this based on the existing markdown work or is this something completely new?

---

**@middelkoopt** (2026-02-23):

It's a complete refactor and rework.  It is based on the poc-markdow, built a tool similar to jenja-cli (it was not easily installable) and then built up the config+chapter+recipe.  The poc-markdown content was then brought over and refactored into a different structure (file layout), then refactored again to update the flow of the content to allow reuse of materials and similar structure across all three provisioners.  The content was then refactored to update variable names, introduce jinja macros to allow recipes to be shared across provisioners as I pulled them in one by one removing duplicated content.  After they layout and flow was settled and the content combined, the pdf recipes where then compared between the original latex and the new versions to ensure all the content was there .  I then updated the ohpc-docs package, makefile, and validation comments system and validated the recipes against my cluster one by one.   This took about two solid weeks between myself and Claud.   You can find the design document under DESIGN.md.  Perhaps we should setup a zoom and I can go over the structure.  I have the early step-by-step commits somewhere I think (they may be lost now) if you are interested, but decided to squash them as there was just way too much churn to follow (I think 30 or so large-ish commits).  The POC markdown was the foundation on which this was built,  provided the LLM the context to automate most of the tedious refactoring.   

TL;DR it's a massive rewrite based off the poc,  github will only be able to show the new content. 

---

**@middelkoopt** (2026-02-23):

Working on OpenCHAMI again to fix some rough edges, upgrading OpenCHAMI and cleaning up some of the docs and recipe.

---

**@adrianreber** (2026-02-23):

To me it seems there is lot of generated code in this PR. It seems there are recipe.sh files and also generated markdown files. Can this be removed?

Also, why the virtualenv? We do not really need that from my point of view. The requirements are all available on our target distributions, so no need to install things via pip. From how I see it all the pip parts, venv parts and also requirements.txt is not necessary.

Also mkdoc.py calls a lot of external tools. That should happen in the Makefile I would say.

---

**@adrianreber** (2026-02-23):

What I also do not understand why is there a top level yaml file defining the document and then it is also using includes? Why are there two mechanisms of creating the document? I like the include part because this is using jinja2 features. The yaml file seems to be something non standard which depends on another tool. Why not just includes?

---

**@middelkoopt** (2026-02-23):

OpenCHAMI fully working now on AlmaLinux x86_64 with Jetstream2.  Working on addressing your comments now.

Did you get a chance to read DESIGN.md - it contains many of the design choices.

* The generated files were committed to make it easier to validate changes and ongoing work.  I'm going to filter them out of the commits.  
* I'll try to refactor out the pandoc into the makefile
* The tool originally was a just a replacement for jinja-cli and "grew".  It manages merging the config yaml files and merging them for the tool (no makefile magic needed).  It also currently also takes care of the shell script generation and has some tools to warn for line length. I'll see what it would take to pull this all apart. One of the goals was to keep the markdown as close to stock as possible in case we wanted to move to another system, I'll see what it would take to build from just the docs.
* .venv was there in the early times so I could easily build on my mac, I'll pull that out.  I would leave requirements to make it easy for folks to contribute.
* the top level yaml file is used to allow adding config variables to the specific recipe and to easily have different structures per arch/provisioner (confluent has a different structure).  It seemed cleaner at the time.  Should we pull out all the configuration stuff into a top level jenja file?  I'll think on this some more (I've been meaning to revisit it as there is a lot of duplication now).

---

**@middelkoopt** (2026-02-24):

Ok, that went smoother than expected.  Ready for another round of comments/review

* build/* has been stripped out of the commits
* pandoc pulled out of mkdoc.py and put in the Makefile, cleaner now and bonus we can do `make -j`
* .venv removed but requirements.txt left
* pulled out the chapters from the recipe yaml files, they all now live in `sections/chapters/main.md.j2`, was able to remove the chapter duplication since they have been refactored to have the same flow.  Bonus: refactored out almost all of the per-recipe variables into config/main.yaml

Remaining:
* original poc-markdown and latex files remain. 
* The manifest files need to be generated for some arch/platform containers.
* openeurler recipie.sh has not been tested along with a lot of other combinations of arch/provisioner/os.

---

**@middelkoopt** (2026-02-24):

Renamed sections to templates to better match conventions.

---

**@adrianreber** (2026-02-24):

Please also remove the .vscode changes from the PR. So far we don't have any editor or IDE specific changes in the repository.

---

**@middelkoopt** (2026-02-24):

Thanks, .vscode occurrences have been removed by filtering them out of the commits.

---

**@adrianreber** (2026-02-25):

At this point I am most sceptical about the need for a special tool to create the documentation. The top level yaml files. I guess I understand the motivation, but requiring a non standard tool and needing our own DSL does not (yet) seem right.

Is there a way to get what you were hoping for without the top level yaml file? I am not sure that introducing something non standard reduces complexity overall.

Also, what is the reason for the LICENSE you included? So far everything OpenHPC did was Apache 2.0 licensed.

---

**@middelkoopt** (2026-02-25):

> At this point I am most sceptical about the need for a special tool to create the documentation. The top level yaml files. I guess I understand the motivation, but requiring a non standard tool and needing our own DSL does not (yet) seem right.

Do you mean the `inherit` in the following (`rocky10-x86_64-warewulf-slurm.yaml`)?

```yaml
inherit:
  - base.yaml
  - distro/el10.yaml
  - distro/rocky.yaml
  - arch/x86_64.yaml
  - provisioner/warewulf.yaml
  - scheduler/slurm.yaml
```  

> Is there a way to get what you were hoping for without the top level yaml file? I am not sure that introducing something non standard reduces complexity overall.

The top level yaml file just merges the config yaml files, later definitions overwrite the previous definition.  I did it this way remove duplication across different dimensions (arch, provisioner, dist, etc.).  A simple cat would not work as there would be duplicate keys, which is non-standard.  We could pull that part out of the mkdocs and write the merged config file with a Makefile and the source would be a file with a list of includes.  We could probably merge them with `yq` but I need to look into this further.  

> Also, what is the reason for the LICENSE you included? So far everything OpenHPC did was Apache 2.0 licensed.

I usually just drop a document license file for documentation. I removed it by filtering it out of the commits and pushed it.


---

**@adrianreber** (2026-02-25):

> We could pull that part out of the mkdocs and write the merged config file with a Makefile and the source would be a file with a list of includes. We could probably merge them with yq but I need to look into this further.

I would be interested in seeing how this looks.

---

**@middelkoopt** (2026-02-25):

> I would be interested in seeing how this looks.

Done.  It ended up being pretty clean.  I also refactored the call to git for vc out as well.  The only down side now is that make is mostly required to run mkdocs.py as the config merging and vc insertion is done in the Makefile.

---

**@middelkoopt** (2026-02-26):

Rebased.

Did some general fixes to remove local script modifications (sed) for testing on a VM. (Finally solved the NHC issues that were haunting me)

Feel good about where the PR is now, all my local todo's are done.  

The only thing left to do is regenerate the manifests .all files and check them sometime before the next release.

---

**@adrianreber** (2026-02-26):

> The only thing left to do is regenerate the manifests .all files and check them sometime before the next release.

Don't worry, this is part of the release process anyway.

There are still a couple of recipe.sh files in the PR, is this intentional? Besides that, this looks good. Ready from my side. Thanks for reworking it.

For the CI failure, please exclude docs.spec for openEuler. What I would like to do, is switch the package to noarch at some point and copy the noarch package from EL_10 to the openEuler repository. If it is just PDFs and shellscripts no need to build it twice and pandoc is anyway missing on openEuler.

---

**@middelkoopt** (2026-02-26):

Removed the remaining `recipe.sh` files from the history.  I already switched it to noarch at some point.  

---

**@middelkoopt** (2026-02-26):

Fixing DCO

---

**@adrianreber** (2026-02-26):

Now squash it. No need for the intermediate commits.

---

**@adrianreber** (2026-02-26):

Maybe let claude write a fancy commit message, some condensed version of the DESIGN.md. That way it is clear in the git history what and why happened here.

---

**@middelkoopt** (2026-02-26):

> Maybe let claude write a fancy commit message, some condensed version of the DESIGN.md. That way it is clear in the git history what and why happened here.

Just saw that now. Will do.

---

**@adrianreber** (2026-02-26):

I see you no longer require mdtoc, right? How do you generate the table of contents?

---

**@middelkoopt** (2026-02-26):

> I see you no longer require mdtoc, right? How do you generate the table of contents?

It's a pandoc switch for pdf and html.  At one point the mkdoc.py also did it.

---

**@adrianreber** (2026-02-26):

> > I see you no longer require mdtoc, right? How do you generate the table of contents?
> 
> It's a pandoc switch for pdf and html. At one point the mkdoc.py also did it.

Great, so I can remove the package again. Perfect.

---

**@adrianreber** (2026-02-26):

Should we merge it?

---

**@middelkoopt** (2026-02-26):

> Should we merge it?

Yup

---

