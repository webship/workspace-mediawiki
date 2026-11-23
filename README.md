# @webship.co/workspace-mediawiki

MediaWiki for the [Webship Workspace](https://github.com/webship/workspace) dashboard: a builder
that makes a real wiki in a container from the MediaWiki release tarball, installed by its own
installer, a maintenance tool for the wikis it built, the default accounts, the
[MediaWiki step pack](https://github.com/webship/mediawiki-steps) wired into the workspace's
testing setup, and its AI items — two agents, a skill, a command and two prompts — each listed in
the workspace folder of its kind.

The workspace is container-based (DDEV by default): a wiki is a row like any other, so the row
menus the core draws (start, stop, launch, backup, clone, remove, tests) work on it unchanged. The
row's Users menu does not apply to a wiki: see [The default accounts](#the-default-accounts).

It is made from the reference platform plugin, `@webship.co/workspace-wordpress`.

## Use it

```bash
cd ~/workspace
bash core/scripts/plugins.sh --require @webship.co/workspace-mediawiki --with-needs   # npm install into the dashboard
bash core/scripts/plugins.sh --activate mediawiki --with-needs                         # plugins.mediawiki in settings.yml
bash core/scripts/plugins.sh --install mediawiki                                       # commands, functions, args, AI items
bash core/scripts/plugins.sh --configure mediawiki                                     # nothing to configure: it has no settings file
```

The same four steps are buttons on the dashboard's **Settings → Plugins** page. `--install` is
idempotent. `--uninstall` removes what it placed; an AI item you edited stays.

Everything the plugin carries lands in the folder it belongs to, when that folder is an active
workspace folder:

| What | Lands in |
| --- | --- |
| `cmd-mediawiki-project.sh`, `cmd-tools-mediawiki-maintenance.sh` | every active sites folder: `dev/`, `test/`, `sandboxes/`, `demos/` |
| The agents `mediawiki-site-builder`, `mediawiki-tester` | `ai-agents/` |
| The skill `mediawiki-scenarios` | `ai-skills/` |
| The command `/mediawiki-test` | `ai-commands/` |
| The prompts `mediawiki-build-and-test`, `mediawiki-scenarios-for-an-area` | `ai-prompts/` |

There they are listed like any other item of the folder, and installed into Claude Code from there.

## What it needs

A workspace starts empty, so the manifest says what else this plugin needs (`needs`):

- one sites folder, for the builder and the tool: `dev`, `test`, `sandboxes`, `demos` (`dev` is the one added when none is there). The folder also carries `cmd-tools-testing.sh` and the Users tools this plugin's hooks answer to.
- `ai-agents`, `ai-skills`, `ai-commands` and `ai-prompts`: the AI folders its agents, its skill, its command and its prompts are placed in.

`--require` says so, `--activate` and `--install` stop until the workspace has them, and `--with-needs` adds what is missing first:

```bash
bash core/scripts/plugins.sh --activate mediawiki --with-needs   # dev and the four AI folders are required, activated and installed first
bash core/scripts/plugins.sh --install mediawiki
```

Everything the builder runs for a wiki runs in the wiki's own container, through the container tool the workspace already needs: the release is downloaded and unpacked there, and PHP and the maintenance scripts are the web container's. The plugin asks for no command of its own on the machine.

## What the package holds

| Path | What it is |
| --- | --- |
| `commands/cmd-mediawiki-project.sh` | The builder, in the Build list as **MediaWiki (release tarball)**, installed into every sites folder |
| `commands/cmd-tools-mediawiki-maintenance.sh` | The maintenance scripts of one wiki: what the wiki is, a script, the database updates, the waiting jobs, the default accounts |
| `scripts/functions/fun-mediawiki.sh` | The bash functions behind both, sourced by bootstrap once installed; the names the core's tools look for (`set_mediawiki_users`, `add_mediawiki_users`, `cancel_mediawiki_users`, `testing_configure_mediawiki`) |
| `scripts/args/arg-mediawiki.sh`, `arg-mediawiki-maintenance.sh` | Their argparse; the Build form draws the builder's flags from the first |
| `testing/site.feature` | The first feature a wiki gets when testing is set up |
| `ai/agents/mediawiki-site-builder.md` | The agent that builds and maintains wikis with these commands |
| `ai/agents/mediawiki-tester.md` | The agent that writes and runs scenarios with the MediaWiki step pack |
| `ai/skills/mediawiki-scenarios/` | The skill: the step pack's phrases by area, the traps found on a real wiki, three example features |
| `ai/commands/mediawiki-test.md` | The slash command `/mediawiki-test <wiki>`: set up, match every step, run, report |
| `ai/prompts/mediawiki-build-and-test.md`, `mediawiki-scenarios-for-an-area.md` | Two prompts: whole launch commands for a new session |
| `src/index.ts` | `register(api)`: what the assistant is told about MediaWiki here |
| `features/mediawiki.feature` | Scenarios for the dashboard's own browser suite |
| `features/mediawiki-runtimes.feature` | The row, the test users and the pages of a wiki built on Docker Compose and on Kubernetes |

The `workspacePlugin` block in `package.json` is the manifest the installer reads.

## What is different from a platform with a project type

DDEV has no project type for MediaWiki. The plugin keeps the shape of the reference and changes
only this:

| | WordPress (the reference) | MediaWiki |
| --- | --- | --- |
| Project | `--project-type=wordpress` | `--project-type=php --docroot=""`: the wiki is at the docroot |
| Recognised by | The DDEV project type | Its files: the release's `maintenance/run.php` and the `MW_VERSION` of `includes/Defines.php` |
| Database | The container tool's default, settings written by the tool | The container tool's default (MariaDB); the installer writes the container's own `db` / `db` / `db` on the host `db` into `LocalSettings.php` |
| Getting the code | `wp core download` | The release tarball from releases.wikimedia.org, unpacked in the web container |
| Install | `wp core install` | `maintenance/run.php install` with WikiEditor, CategoryTree and Cite (and VisualEditor with `--visual-editor`); the workspace account is the first account |
| Server | Nothing to add | The rule MediaWiki documents for nginx, so `rest.php/v1/…` reaches the REST API (the search suggestions and the visual editor need it), and the job queue as a service of the web container (`runJobs --wait`) |
| Accounts | WP-CLI | The maintenance scripts `createAndPromote` and `resetUserEmail`; cancelling blocks (`blockUsers`) |
| Users menu of the row | Reads the project type | Does not apply (the type is `php`): `cmd-tools-mediawiki-maintenance.sh --add-users`, or `cmd-tools-add-users.sh <name> mediawiki` |

## The commands

Run them from a sites folder. `--help` is safe on both.

### Build a wiki

```bash
cd ~/workspace/dev
bash cmd-mediawiki-project.sh mywiki --install --add-users --visual-editor
```

| Flag | What it does |
| --- | --- |
| `--install` | Install the wiki with its own installer on the container's database, with WikiEditor, CategoryTree and Cite; the workspace account is its first account (sysop, bureaucrat, interface-admin). Without it the release is unpacked and waits for its installer |
| `--add-users` | With `--install`: add the default accounts |
| `--visual-editor` | Turn the visual editor on (VisualEditor; Parsoid is in core) |
| `--mediawiki-version <x>` | The release to install, for example `1.43.11` (the long-term-support line); empty means the current stable release (1.46.2) |
| `--php-version <x>` | The PHP of the project container (the current release needs 8.3 or later) |
| `--runtime <name>` | The container runtime to build on: `ddev` (the default), `docker`, `kubernetes` or `podman`. See [Runtimes](#runtimes) |
| `--launch` | Open the wiki when it is ready |

On DDEV the wiki answers at `https://mywiki.ddev.site`, its login at `/index.php?title=Special:UserLogin`.
The build adds to `LocalSettings.php`: uploads on, the "confirmed" group (the rights an account
otherwise earns after 4 days and 10 edits, the thresholds it sets as on large public wikis), the job
queue run by the service (`$wgJobRunRate = 0`), and the object cache and the sessions in the
database (the installer picks the PHP process cache, which the maintenance scripts cannot see and a
restart empties). A project of the same name is deleted first.

### Runtimes

```bash
bash cmd-mediawiki-project.sh mywiki --install --add-users                        # DDEV, the default
bash cmd-mediawiki-project.sh mywiki --install --add-users --runtime docker       # Docker Compose
bash cmd-mediawiki-project.sh mywiki --install --add-users --runtime kubernetes   # a Kubernetes cluster
```

Without `--runtime` a build takes `container.runtime` of the workspace's `settings.yml`, then DDEV.
It needs a Webship Workspace with the container runtimes
([webship/workspace#694](https://github.com/webship/workspace/issues/694)); on an older one the
builder refuses `--runtime` and builds on DDEV only.

| | DDEV | Docker Compose | Kubernetes | Podman |
| --- | --- | --- | --- | --- |
| Build and install, with the default accounts (and the visual editor) | Yes | Yes, with webship/workspace#723 | Yes, with webship/workspace#723 | The same code as Docker Compose, not yet run |
| The main page, the login page, the REST API and the action API | Yes | Yes | Yes | Not yet run |
| `cmd-tools-mediawiki-maintenance.sh`: what the wiki is, `--run`, `--jobs` | Yes | Yes | Yes | Not yet run |
| Test users, cancelled and given back (the command line and the row's Tests menu) | Yes | Yes | Yes | Not yet run |
| The testing setup and the suite, with the pack's examples | Yes | Yes | Yes | Not yet run |
| Export and import the database | Yes | Yes | Yes | Not yet run |
| The row in the dashboard, and remove | Yes | Yes | Yes | Not yet run |

"Yes" means it was run on a real wiki of that runtime. On Docker Compose and Kubernetes the installer needs webship/workspace#723: before it, the name of the wiki and the account given to the installer come apart at their spaces there.

| Runtime | The wiki's address | What the project carries |
| --- | --- | --- |
| DDEV | `https://mywiki.ddev.site` | `.ddev/config.yaml` (type `php`), the nginx rule of the REST API, the job service |
| Docker Compose | `http://127.0.0.1:<port>`, printed by the build | `compose.yaml` (with `platform: mediawiki`: the claim), `.webship/runtime/Dockerfile` |
| Kubernetes | `http://<node address>:<port>`, printed by the build | The same, and `k8s/` (the namespace `ws-mywiki`) |

What differs on Docker Compose and Kubernetes:

- **The claim:** the project type is `php` there too, so the builder writes `platform: mediawiki` in
  the `x-webship:` block of `compose.yaml`. The tools and the row's Tests menu read it.
- **The address** the installer is given (`$wgServer`) is the runtime's.
- **The web server** is Apache, which passes `rest.php/v1/…` to the REST API by itself: no rule is
  written. The database is the same: `db` / `db` / `db` on the host `db`.
- **The job queue:** the stack has no service for it, so the wiki runs its jobs itself at the end
  of a request (`$wgJobRunRate = 1`, MediaWiki's default). `--jobs` of the maintenance tool runs the
  waiting ones at once.
- **Not there yet:** HTTPS and a host name are DDEV's. Podman runs the same code as Docker Compose
  and was not run yet.

The same commands work on every runtime: `cmd-tools-mediawiki-maintenance.sh`, `cmd-tools-add-users.sh`,
`cmd-tools-testing.sh`. The pattern is the reference plugin's:
[On Docker Compose and Kubernetes](https://github.com/webship/workspace-wordpress/blob/1.0.x/docs/cms-plugin-pattern.md#on-docker-compose-and-kubernetes).

### Work on a wiki

```bash
bash cmd-tools-mediawiki-maintenance.sh mywiki                              # version, extensions, accounts
bash cmd-tools-mediawiki-maintenance.sh mywiki --run "showJobs --group"     # any maintenance script
bash cmd-tools-mediawiki-maintenance.sh mywiki --update                     # the database updates
bash cmd-tools-mediawiki-maintenance.sh mywiki --jobs                       # the waiting jobs, now
bash cmd-tools-mediawiki-maintenance.sh mywiki --add-users                  # the default accounts
bash cmd-tools-mediawiki-maintenance.sh mywiki --cancel-users               # block them
```

### The default accounts

| Account | Address | Groups | Handle in the tests |
| --- | --- | --- | --- |
| `administrator` | `administrator@example.com` | sysop, bureaucrat | `administrator` |
| `editor` | `editor@example.com` | confirmed (the rights of an established account at once) | `editor` |
| `reader` | `reader@example.com` | none: a new account, refused the pages protected for established accounts | `reader` |

Each account has the password of the workspace's other default lists. They are for local wikis and
for tests; the wiki's first account is the workspace account and is never written into a test.

**Manage them with the maintenance tool, not the row's Users menu.** The dashboard's Users menu
picks its actions by the project type, and a wiki's type is `php`, so the menu offers actions that
do not apply to a wiki. Use:

```bash
bash cmd-tools-mediawiki-maintenance.sh mywiki --add-users     # add them, or give them back their password, groups and address, and lift a block
bash cmd-tools-mediawiki-maintenance.sh mywiki --cancel-users  # cancel them
bash cmd-tools-add-users.sh mywiki mediawiki                   # the core's tool: the same list
bash cmd-tools-cancel-users.sh mywiki mediawiki
```

A wiki never deletes an account (its edits keep their author): cancelling blocks the account
without end, gives it a random password and ends its sessions; adding it again gives it back.

### Test a wiki

```bash
bash cmd-tools-testing.sh mywiki                 # webship-js, the step pack, the users registry, a first feature
bash cmd-tools-testing.sh mywiki --run           # run the suite in the container
bash cmd-tools-testing.sh mywiki --run --path tests/features/site.feature
```

`cmd-tools-testing.sh` is the workspace's own. For a wiki it also adds `@webship-js/mediawiki-steps`
to `package.json`, lists its step definitions in `cucumber.js` after webship-js's own, writes the
users registry (the handles above, overridable with `MEDIAWIKI_<HANDLE>_USERNAME`,
`MEDIAWIKI_<HANDLE>_PASSWORD` and `MEDIAWIKI_<HANDLE>_EMAIL`), `wikiAdmin` (the handle the step
pack makes and deletes its test pages as, through the wiki's API) and the tags that keep the pack's
assertions that must fail out of a normal run, places `tests/features/site.feature` when the
project has none, and makes sure the default accounts are on the wiki. Run it again and it adds what
is missing and keeps what you changed.

The suite runs in the project's container, where the network changes of the host (another container
starting) do not cut the browser's requests.

A scenario of your own reads like this one, from the step pack's phrases (the skill
`mediawiki-scenarios` lists them by area); it makes its test pages and deletes them after it:

```gherkin
Feature: The talk page of a page
  Scenario: The editor asks a question on the talk page
    Given the page "Readme talk page" has the text "A page to talk about."
    And the page "Talk:Readme talk page" does not exist
    And I am a logged in user with the "editor" user
    When I open the page "Readme talk page"
    And I open the talk page
    And I add the topic "A question" with the text "Is this page complete?"
    Then the talk page should have the topic "A question"
```

`tests/features/site.feature` passes on a wiki built with `--install --add-users`. The features of the
step pack pass on a wiki built with `--install --add-users --visual-editor` (the visual editor
feature needs it); each makes its own test pages and deletes them after it.

## The AI items

`ai/` in the package holds one folder per kind, the manifest's `ai` block names each item, and
`--install` places it in the workspace folder of that kind.

| Kind | Item | Use it to |
| --- | --- | --- |
| Agent | `mediawiki-site-builder` | Build, update, maintain or remove a wiki with the commands above, in containers only |
| Agent | `mediawiki-tester` | Set the testing stack up, look at the wiki in the Playwright MCP browser first, write scenarios from the pack's steps and run them; it never creates an account in a suite and never writes a platform name into a step phrase |
| Skill | `mediawiki-scenarios` | Write a scenario from phrases that exist: the pack's steps by area, the handles of the users registry, the test pages, the traps found on a real wiki, and three features that pass on a new wiki |
| Command | `/mediawiki-test <wiki> [feature or @tag]` | Run the suite of a wiki from inside a session: set up when missing, match every step, run, report what failed and why |
| Prompt | `mediawiki-build-and-test` | Start a session that builds a wiki, says what it is, sets the testing stack up and runs the first feature |
| Prompt | `mediawiki-scenarios-for-an-area` | Start a session that writes and runs the scenarios of one area of a wiki |

After `--install` each is in its folder on the dashboard. **Install** there puts an agent, a skill
or a command into Claude Code (`~/.claude/agents`, `~/.claude/skills`, `~/.claude/commands`), or
from the command line:

```bash
cd ~/workspace/ai-agents   && bash cmd-tools-ai-items.sh mediawiki-tester --install
cd ~/workspace/ai-skills   && bash cmd-tools-ai-items.sh mediawiki-scenarios --install
cd ~/workspace/ai-commands && bash cmd-tools-ai-items.sh mediawiki-test --install
```

A prompt is not installed: it is the whole `claude …` launch command of a new session, and the
dashboard's **New screen** form lists it as a template. By hand, fill the placeholders in and run
the command of the file from the folder it names.

The items are written for any AI CLI, with Claude Code as the default shape: the frontmatter and
the file layout are Claude Code's, the body of each item is plain Markdown that names no tool or
feature of one CLI, a command says in words what its arguments are, and the text between the
triple quotes of a prompt can be given to another AI CLI as it is.

Every step phrase the items show is checked against the definitions of the step pack and of
webship-js (`tests/fixtures/step-definitions.txt`), and every command and flag against the
plugin's own.

## Develop it

```bash
npm install     # builds dist/ (TypeScript)
npm run lint
npm test        # the manifest, the commands, the AI items, the functions against a scaffolded project
```

CI runs the same on Node.js 24 and 26, parses every shell script, and runs the plugin's
`features/mediawiki.feature` against a dashboard with this plugin installed
(`webship/workspace/.github/workflows/plugin-browser-suite.yml`).
