/**
 * MediaWiki for Webship Workspace: a platform plugin.
 *
 * What the package carries is placed by the installer from the manifest: the builder and the
 * maintenance tool in the sites folders, their functions and argparse under core/scripts/plugins/mediawiki/,
 * and its AI items (ai/ in this package) in the folder of their kind: the agents in AI Agents, the skill
 * in AI Skills, the command in AI Commands, the prompts in AI Prompts. The dashboard needs nothing drawn
 * for it: the builder is in the Build list because it is a cmd-*-project.sh, the row menus are the
 * core's, the AI items are listed like any other. What register() adds is what the assistant is told.
 *
 * Everything the dashboard is asked for goes through `api`; this package requires nothing from the
 * dashboard's own files, so it can be installed from npm and removed without a trace.
 */

import type { PluginApi } from '@webship.co/workspace-plugin-api';

/** The plugin's name. A wiki is a DDEV project of type php: the plugin knows it by its files. */
export const PLATFORM = 'mediawiki';

/** The commands the installer places in every sites folder. */
export const COMMANDS = ['cmd-mediawiki-project.sh', 'cmd-tools-mediawiki-maintenance.sh'];

/** The agents the installer places in the AI Agents folder. */
export const AGENTS = ['mediawiki-site-builder', 'mediawiki-tester'];

/** The skill the installer places in the AI Skills folder (a folder each, with its SKILL.md). */
export const SKILLS = ['mediawiki-scenarios'];

/** The slash command the installer places in the AI Commands folder. */
export const AI_COMMANDS = ['mediawiki-test'];

/** The prompts the installer places in the AI Prompts folder: each a whole launch command for a new session. */
export const PROMPTS = ['mediawiki-build-and-test', 'mediawiki-scenarios-for-an-area'];

/** What the assistant is told about MediaWiki in this workspace. */
export function assistantContext(): string {
  return [
    'MediaWiki (a plugin, @webship.co/workspace-mediawiki): a wiki is built with',
    '`bash cmd-mediawiki-project.sh <name> --install --add-users --visual-editor` from a sites folder (dev, test, sandboxes, demos),',
    'from the release tarball (the current stable release, or `--mediawiki-version <x>`), installed by its own installer',
    'in a container like every other project (DDEV project type php, the wiki at the docroot), at https://<name>.ddev.site,',
    'with WikiEditor, CategoryTree and Cite (and the visual editor with `--visual-editor`), uploads on and the job queue run by a service of the container.',
    '`bash cmd-tools-mediawiki-maintenance.sh <name>` says what the wiki is; `--run "<script> <args>"` runs a maintenance script in it,',
    '`--update` runs the database updates, `--jobs` runs the waiting jobs,',
    '`--add-users` adds the default accounts (administrator, editor, reader) and `--cancel-users` blocks them (a wiki never deletes an account).',
    'The row\'s Users menu does not apply to a wiki (its project type is php): use the maintenance tool for the accounts.',
    '`bash cmd-tools-testing.sh <name>` sets up webship-js with the MediaWiki step pack; `--run` runs the suite.',
    `For MediaWiki work, hand over to the agents ${AGENTS.map((a) => `\`${a}\``).join(' and ')}.`,
    `The plugin also places the skill ${SKILLS.map((a) => `\`${a}\``).join(', ')} (the step pack's phrases, by area) in ai-skills/,`,
    `the command ${AI_COMMANDS.map((a) => `\`/${a} <wiki>\``).join(', ')} in ai-commands/ and the prompts ${PROMPTS.map((a) => `\`${a}\``).join(' and ')} in ai-prompts/.`,
    'Never run php or the maintenance scripts on the host for a project; the database settings in its LocalSettings.php are the container\'s own (db, db, db).',
  ].join(' ');
}

export function register(api: PluginApi): void {
  api.addAssistantContext(assistantContext);
}
