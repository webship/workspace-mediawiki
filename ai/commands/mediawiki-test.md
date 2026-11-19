---
description: Test a MediaWiki wiki of the Webship Workspace with webship-js and the MediaWiki step pack — set the testing stack up when it is missing, match every step, run the suite (or one feature, or one tag) in the wiki's container, and report what failed and why.
argument-hint: '<wiki> [tests/features/<name>.feature | @tag]'
---

# /mediawiki-test

Test the MediaWiki wiki named in: `$ARGUMENTS`

`$ARGUMENTS` stands for what was typed after the command. An AI CLI that does not fill it in
reads the same from the request: the name of the wiki, then, if anything, one feature path or one
tag.

The first word is the wiki (its folder name in a sites folder of the workspace). What follows, if
anything, narrows the run: a path that starts with `tests/features/` is one feature (or one folder
of features), a word that starts with `@` is a tag expression. With nothing after the wiki, the whole
suite runs. With no wiki at all, stop and ask for one: list the candidates with
`grep -l "MW_VERSION" ~/workspace/*/*/includes/Defines.php`.

The workspace is container-based (DDEV by default) and everything below runs in the wiki's container
through the workspace's own command. Never run `npx cucumber-js`, `npx playwright`, `php` or the
maintenance scripts on the host for a wiki.

## 1. Find the wiki

```bash
ls -d ~/workspace/*/<wiki>/.ddev/config.yaml
grep -l "MW_VERSION" ~/workspace/<folder>/<wiki>/includes/Defines.php
```

Work from that sites folder (`cd ~/workspace/<folder>`). A wiki that is not installed (no
`LocalSettings.php`) has nothing to test: say so, and name `bash cmd-mediawiki-project.sh <wiki>
--install --add-users --visual-editor` (it rebuilds the wiki from nothing).

## 2. Set the testing stack up, when it is missing

```bash
bash cmd-tools-testing.sh <wiki>
```

It adds webship-js, the MediaWiki step pack, the users registry (`administrator`, `editor`,
`reader`), the handle the test-page steps work as, and `tests/features/site.feature`. A project that
has `cucumber.js` already keeps it; the setup adds only what is missing.

## 3. Match every step

```bash
bash cmd-tools-testing.sh <wiki> --dry-run
```

Every step must match exactly one definition. An undefined step is a phrase that does not exist: find
the real one in the pack's README or in the `mediawiki-scenarios` skill, never invent a step.

## 4. Run

```bash
bash cmd-tools-testing.sh <wiki> --run                                     # the whole suite
bash cmd-tools-testing.sh <wiki> --run --path tests/features/site.feature  # one feature
bash cmd-tools-testing.sh <wiki> --run --tags @critical                    # one tag
```

## 5. Report

The scenarios and steps that passed and failed, then for each failure: the step, its message and
hint, the screenshot the run kept, and what it means (a defect of the wiki, a scenario to fix, or a
request the browser cut, which a second run clears). A suite never creates an account, never writes
a password into a feature file, and never writes a platform name into a step phrase. For writing or
fixing scenarios, use the `mediawiki-scenarios` skill or hand over to the `mediawiki-tester` agent;
for changing the wiki, to `mediawiki-site-builder`.

Before you write or change a scenario, or read a failed run, read the book *Automated Functional
Testing Recipes* (its `README.md`, then the matching chapter):
`.claude/automated-functional-testing-recipes/` in the project,
`~/.claude/automated-functional-testing-recipes/`, or
https://github.com/webship/webship-js-ai-agent/tree/2.0.x/automated-functional-testing-recipes
