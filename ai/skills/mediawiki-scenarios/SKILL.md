---
name: mediawiki-scenarios
description: Write webship-js scenarios for a MediaWiki wiki of the Webship Workspace from phrases that exist — the MediaWiki step pack's steps by area (reading, search, the editors, history, talk pages, categories, watchlist, preferences, uploads, administration, the session), the handles of the users registry, the test pages a scenario makes and the steps delete, the traps found on a real wiki, and three features that pass on a new wiki. Use when writing or fixing a scenario for a wiki, choosing a step for a wiki screen, or turning a manual check of a wiki into a feature.
---

# mediawiki-scenarios

Scenarios for a wiki built with the MediaWiki plugin (`bash cmd-mediawiki-project.sh <wiki> --install
--add-users --visual-editor`) in a container-based workspace (DDEV by default), tested with webship-js
and `@webship-js/mediawiki-steps` once `bash cmd-tools-testing.sh <wiki>` set the project up. Every
phrase below exists in the pack or in webship-js; a scenario names no platform.

## Accounts and test pages

- `Given I am a logged in user with the "editor" user`: `administrator` (sysop, bureaucrat),
  `editor` (confirmed), `reader` (a new account). `Given I am an anonymous user` for a visitor.
- `Given the page "…" has the text "…"` (one line, `\n` for a new line, `with the summary "…"` for
  the history), or `has the text:` with a doc string: a test page, made through the wiki's API as
  `wikiAdmin` and deleted after the scenario. A page a person made is never overwritten.
- `Given the page "…" does not exist`: for the page the scenario makes itself (it is deleted after it).
- `Given the page "…" is protected so that only autoconfirmed users can edit it` (or `administrators`).
- `Given the file "Name.png" is uploaded from "tests/fixtures/blue-square.png"` and `Given the account
  "reader" is not blocked`.

## Phrases by area

| Area | Steps |
| --- | --- |
| Reading | `I open the page "…"`, `I should see the page "…"`, `the page text should contain "…"`, `the page should have the section "…"`, `the page should have these sections in order:`, `the contents list should list "…"`, `I follow "…" in the contents list`, `I should be at the section "…"`, `the page should link to the page "…"` (or `the missing page`), `the page should link to the external site "…"`, `I follow the link to the page "…"`, `the reference "1" should read "…"`, `the scripts of the page should all load` |
| Categories | `the page should be in the category "…"`, `I follow the category "…"`, `the category should list the page "…"` (or `the subcategory`), `I expand the category "…" in the category tree`, `the category tree should show "…" under "…"` |
| Search | `I type "…" in the search box`, `the search suggestions should list "…"`, `I choose the suggestion "…"`, `I search for "…"`, `the search results should list the page "…"`, `the search result "…" should mention "…"`, `the search should find 1 page` (or `no page`) |
| Source editor | `I edit the page "…"`, `I set the wikitext to "…"` (or `to:`), `I add the wikitext "…"`, `I preview the page`, `the preview should show "…"`, `I show my changes`, `the changes should show "…" added` (or `removed`), `I save the page as a minor edit with the summary "…"`, `the edit should be saved`, `the page should be created` |
| Visual editor | `I edit the page "…" in the visual editor`, `I type "…" in the visual editor`, `I save the page with the summary "…"`, `the visual editor should not be open` |
| Conflicts and refusals | `another account saves the page "…" with the text "…"`, `I should see an edit conflict`, `the edit conflict should keep my text "…"`, `editing the page "…" should be refused with "…"` |
| History and talk | `I open the history of the page "…"`, `the history should list the revision "…" by "editor"`, `I compare the revisions "…" and "…"`, `I undo the revision "…"`, `I open the talk page`, `I add the topic "…" with the text "…"`, `the talk page should have the topic "…"` |
| Watchlist and preferences | `I watch the page`, `I stop watching the page`, `my watchlist should list the page "…"`, `the recent changes should show a change to "…" with the summary "…"`, `I open my preferences`, `I tick the preference "…"`, `I save my preferences` |
| Files | `I upload the file "tests/fixtures/blue-square.png" as "Name.png" ignoring warnings`, `I should see the file "Name.png"`, `the upload should be held back with the warning "…"` |
| Administration | `I protect the page "…" so that only administrators can edit it`, `I remove the protection of the page "…"`, `I delete the page "…" with the reason "…"`, `I restore the page "…" with the reason "…"`, `I block the account "reader" for "1 day" with the reason "…"`, `I unblock the account "reader" with the reason "…"`, `the account "reader" should be blocked`, `the page "…" should not exist` |
| Session | `I log in as "editor" with the login form`, `I log in with the user name "…" and the password "…"`, `the login should be refused with "…"`, `I log out`, `I should be logged in as "editor"`, `nobody should be logged in`, `I try to create the account "…" with the password "…" and the confirmation "…"`, `the account creation should be refused with "…"` |

## Traps found on a real wiki

- A link in the categories box to a category without a page is a red link that opens the editor:
  make the category's page first.
- The search finds a page by a word of its text; a title typed exactly opens that page instead of the
  results: search for a word, not a title.
- Five failed logins of one account from one address in five minutes lock it for five minutes: try
  wrong passwords with a name no other scenario uses.
- The visual editor's welcome dialog and the watchlist popover are closed by the steps; a plain
  `I press "…"` behind them does nothing.
- A history row is found by its summary: give the setup revisions summaries of their own.
- Make the pages a page links to before the page itself: a link to a page made later stays red until a
  job of the wiki draws the page again.
- An undo's summary differs between releases ("Undid revision …", "Undo revision …"): save the undo with a
  summary of your own when a scenario looks for it in the history.

## Examples

- [`examples/reading-and-search.feature`](examples/reading-and-search.feature): a page, its links, the search box and a full search.
- [`examples/editing.feature`](examples/editing.feature): the source editor with its changes, the history, the visual editor.
- [`examples/administration.feature`](examples/administration.feature): a protected page refused, a page deleted and restored.

Copy them into `tests/features/` of the project and run them:

```bash
bash cmd-tools-testing.sh <wiki> --run --path tests/features/editing.feature
```

## The book

For any automated functional testing in this work (a Gherkin feature, a step definition, choosing a
step, a test run and its failures), read the book *Automated Functional Testing Recipes* first.

- **Where.** Use the first that exists: `.claude/automated-functional-testing-recipes/` in the project,
  `~/.claude/automated-functional-testing-recipes/` (installed by webship/webship-js-ai-agent,
  webship/webship-js-skills or webship/ai-agents), or
  https://github.com/webship/webship-js-ai-agent/tree/2.0.x/automated-functional-testing-recipes
- **How.** Its `README.md` first, then the chapter that matches the task (one file per chapter,
  named by its subject), not the single complete file.
- **Which wins.** The installed webship-js package and the step pack are the source of truth for
  step phrasing. When they differ from the book, follow them and say so.
- **For MediaWiki.** Start with `ch26-testing-cms-applications.md` (content, publishing, media and
  roles), `ch07-waiting-dynamic-content.md` (waiting on the page's own signals),
  `ch10-authentication-authorization.md` (logins, sessions and refusals) and
  `ch21-when-tests-go-bad.md` (flaky, brittle and slow scenarios).
