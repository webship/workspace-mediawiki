Write and run webship-js scenarios for one area of a MediaWiki wiki, from the step pack's own phrases.

The launch command below is for Claude Code, the default; the text between the triple quotes can be given to another AI CLI as it is.

```
claude --permission-mode bypassPermissions """
Write scenarios for the <reading|search|editing|history|talk pages|categories|watchlist|uploads|administration> area of this wiki, and run them
# ~/workspace/<folder>/<wiki> · https://<wiki>.ddev.site · container-based (DDEV by default)
# the phrases are in the mediawiki-scenarios skill; the mediawiki-tester agent is the one to hand this work over to
# look at the wiki first: in the Playwright MCP browser, in a tab of your own, open each screen of the area as the account the scenario uses, once, before writing its scenario
# the book Automated Functional Testing Recipes first (its README.md, then the matching chapter), from .claude/automated-functional-testing-recipes/ in the project, ~/.claude/automated-functional-testing-recipes/ or https://github.com/webship/webship-js-ai-agent/tree/2.0.x/automated-functional-testing-recipes

1. bash cmd-tools-testing.sh <wiki>
   (when the project has no cucumber.js yet)
2. write tests/features/<area>.feature from the skill's phrases:
   the accounts by their handles (administrator, editor, reader), never a password;
   the pages it needs made with Given the page "…" has the text "…", which the steps delete again;
   no account created, no platform name in a step
3. bash cmd-tools-testing.sh <wiki> --dry-run --path tests/features/<area>.feature
4. bash cmd-tools-testing.sh <wiki> --run --path tests/features/<area>.feature

When it is green: the scenarios and what each one proves. When it is not: the failing step, its
message, and whether the wiki or the scenario is wrong.
"""
```
