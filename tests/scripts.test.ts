import test from 'node:test';
import assert from 'node:assert';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { spawnSync } from 'child_process';

// Compiled, these tests run from dist/tests, so the package root is one folder further up.
const PKG = fs.existsSync(path.join(__dirname, '..', 'package.json')) ? path.join(__dirname, '..') : path.join(__dirname, '..', '..');
const FUNCTIONS = path.join(PKG, 'scripts', 'functions', 'fun-mediawiki.sh');

// The cucumber.js webship-js scaffolds, as far as the testing hook reads it.
const SCAFFOLD = `module.exports = {
  default: {
    requireModule: ['ts-node/register'],
    require: [
      'node_modules/webship-js/tests/step-definitions/**/*.js',          // Webship-js core step definitions.
      'tests/step-definitions/**/*.js',                                  // Your custom step definitions.
    ],
    paths: ['tests/features/**/*.feature'],
    worldParameters: {
      launchUrl: process.env.LAUNCH_URL || 'http://localhost:8080',
    },
  },
};
`;

/**
 * A project folder with the testing stack scaffolded, and the tooling folder the installer would have filled.
 * A wiki has the release's maintenance/run.php and includes/Defines.php; `installed` adds its LocalSettings.php.
 */
function project(kind: 'mediawiki' | 'drupal', { installed = true } = {}) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'mediawiki-plugin-'));
  const dir = path.join(root, 'dev', 'site1');
  fs.mkdirSync(path.join(dir, '.ddev'), { recursive: true });
  fs.writeFileSync(path.join(dir, '.ddev', 'config.yaml'), `name: site1\ntype: ${kind === 'mediawiki' ? 'php' : 'drupal11'}\ndocroot: ${kind === 'mediawiki' ? '""' : 'web'}\n`);
  if (kind === 'mediawiki') {
    fs.mkdirSync(path.join(dir, 'maintenance'), { recursive: true });
    fs.mkdirSync(path.join(dir, 'includes'), { recursive: true });
    fs.writeFileSync(path.join(dir, 'maintenance', 'run.php'), '<?php\n');
    fs.writeFileSync(path.join(dir, 'includes', 'Defines.php'), "<?php\ndefine( 'MW_VERSION', '1.46.2' );\n");
    if (installed) fs.writeFileSync(path.join(dir, 'LocalSettings.php'), "<?php\nwfLoadExtension( 'WikiEditor' );\n");
  }
  fs.writeFileSync(path.join(dir, 'cucumber.js'), SCAFFOLD);
  fs.writeFileSync(path.join(dir, 'package.json'), JSON.stringify({ name: 'site1', devDependencies: { 'webship-js': '^2.0.6' } }, null, 2));
  const scripts = path.join(root, 'core', 'scripts');
  fs.mkdirSync(path.join(scripts, 'plugins', 'mediawiki'), { recursive: true });
  fs.copyFileSync(path.join(PKG, 'testing', 'site.feature'), path.join(scripts, 'plugins', 'mediawiki', 'site.feature'));
  return { root, dir, scripts };
}

/** Run bash with the plugin's functions sourced and `ddev` replaced by a recorder of its calls (and of what it reads on stdin). */
function bash(script: string, env: Record<string, string> = {}) {
  const fake = 'ddev() { echo "ddev $*" >> "${DDEV_LOG:-/dev/null}" ; if [ ! -t 0 ] ; then sed "s/^/  stdin: /" >> "${DDEV_LOG:-/dev/null}" ; fi ; return 0 ; }';
  return spawnSync('bash', ['-c', `${fake}\nsource ${FUNCTIONS}\n${script}`], { encoding: 'utf8', env: { ...process.env, ...env } });
}

test('the default accounts are one per kind of account a wiki tells apart, with example addresses', () => {
  const r = bash('set_mediawiki_users ; for u in "${users[@]}" ; do n="user_${u}_name" ; m="user_${u}_mail" ; p="user_${u}_password" ; g="user_${u}_role" ; echo "${!n}|${!m}|${!p}|${!g}" ; done');
  assert.strictEqual(r.status, 0, r.stderr);
  const rows = r.stdout.trim().split('\n').map((l) => l.split('|'));
  assert.deepStrictEqual(rows.map((x) => x[0]), ['administrator', 'editor', 'reader']);
  assert.deepStrictEqual(rows.map((x) => x[3]), ['sysop,bureaucrat', 'confirmed', '']);
  for (const [name, mail, password] of rows) {
    assert.strictEqual(mail, `${name}@example.com`);
    assert.ok(password.length >= 10, 'long enough for the password policy of a sysop');
  }
});

test('the accounts are written with createAndPromote, their address with resetUserEmail, and a block is lifted', () => {
  const p = project('mediawiki');
  const log = path.join(p.root, 'ddev.log');
  const env = { WORKSPACE_ROOT: p.root, WORKSPACE_SCRIPTS: p.scripts, doc_name: 'dev', PROJECT_NAME: 'site1', DDEV_LOG: log };
  const r = bash('set_mediawiki_users ; add_mediawiki_users', env);
  assert.strictEqual(r.status, 0, r.stderr + r.stdout);
  const written = fs.readFileSync(log, 'utf8');
  assert.match(written, /^ddev exec php maintenance\/run\.php createAndPromote --force --sysop --bureaucrat administrator \S+$/m);
  assert.match(written, /^ddev exec php maintenance\/run\.php createAndPromote --force --custom-groups=confirmed editor \S+$/m);
  assert.match(written, /^ddev exec php maintenance\/run\.php createAndPromote --force reader \S+$/m);
  for (const name of ['administrator', 'editor', 'reader']) {
    assert.match(written, new RegExp(`^ddev exec php maintenance/run\\.php resetUserEmail --no-reset-password ${name} ${name}@example\\.com$`, 'm'));
  }
  assert.match(written, /^ddev exec php maintenance\/run\.php blockUsers --unblock /m, 'a block left on an account is lifted');
});

test('cancelling an account blocks it without end and gives it a random password: a wiki keeps every account', () => {
  const p = project('mediawiki');
  const log = path.join(p.root, 'ddev.log');
  const r = bash('set_mediawiki_users ; cancel_mediawiki_users', { WORKSPACE_ROOT: p.root, WORKSPACE_SCRIPTS: p.scripts, doc_name: 'dev', PROJECT_NAME: 'site1', DDEV_LOG: log });
  assert.strictEqual(r.status, 0, r.stderr + r.stdout);
  const written = fs.readFileSync(log, 'utf8');
  for (const name of ['administrator', 'editor', 'reader']) {
    assert.match(written, new RegExp(`^ddev exec php maintenance/run\\.php changePassword --user=${name} --password=\\S{20,}$`, 'm'));
    assert.match(written, new RegExp(`^  stdin: ${name}$`, 'm'), `${name} is in the list of accounts to block`);
  }
  assert.match(written, /^ddev exec php maintenance\/run\.php blockUsers --expiry=infinite /m);
  assert.doesNotMatch(written, /deleteUser|DELETE FROM/i, 'no account is deleted');
});

test('a wiki that is not installed has no accounts to write, and says so', () => {
  const p = project('mediawiki', { installed: false });
  const r = bash('set_mediawiki_users ; add_mediawiki_users', { WORKSPACE_ROOT: p.root, WORKSPACE_SCRIPTS: p.scripts, doc_name: 'dev', PROJECT_NAME: 'site1' });
  assert.notStrictEqual(r.status, 0);
  assert.match(r.stdout, /not installed/);
});

test('the testing hook adds the step pack, the users registry, wikiAdmin, the tags and a first feature to a wiki, once', () => {
  const p = project('mediawiki');
  const log = path.join(p.root, 'ddev.log');
  const run = () => bash(`cd ${p.dir} && testing_configure_mediawiki ${p.dir}`, { WORKSPACE_ROOT: p.root, WORKSPACE_SCRIPTS: p.scripts, doc_name: 'dev', PROJECT_NAME: 'site1', DDEV_LOG: log });
  const r = run();
  assert.strictEqual(r.status, 0, r.stderr + r.stdout);
  const pkg = JSON.parse(fs.readFileSync(path.join(p.dir, 'package.json'), 'utf8'));
  assert.strictEqual(pkg.devDependencies['@webship-js/mediawiki-steps'], '^2.0.0');
  assert.strictEqual(pkg.devDependencies['webship-js'], '^2.0.6', 'what was there stays');
  const cucumber = fs.readFileSync(path.join(p.dir, 'cucumber.js'), 'utf8');
  const lines = cucumber.split('\n');
  const core = lines.findIndex((l) => l.includes('node_modules/webship-js/tests/step-definitions'));
  assert.strictEqual(lines[core + 1], "      'node_modules/@webship-js/mediawiki-steps/tests/step-definitions/**/*.js',", 'the pack is listed right after webship-js');
  assert.match(cucumber, /administrator: \{ username: process\.env\.MEDIAWIKI_ADMINISTRATOR_USERNAME \|\| 'administrator', password: process\.env\.MEDIAWIKI_ADMINISTRATOR_PASSWORD \|\| '[^']+', email: process\.env\.MEDIAWIKI_ADMINISTRATOR_EMAIL \|\| 'administrator@example\.com' \},/);
  assert.match(cucumber, /reader: \{ username: process\.env\.MEDIAWIKI_READER_USERNAME \|\| 'reader'/);
  assert.match(cucumber, /wikiAdmin: process\.env\.WIKI_ADMIN \|\| 'administrator',/);
  assert.match(cucumber, /tags: process\.env\.CUCUMBER_TAGS \|\| 'not @wip and not @must-fail',/);
  // Still a module node can load, with the registry where webship-js reads it.
  const loaded = spawnSync(process.execPath, ['-e', `const c = require(${JSON.stringify(path.join(p.dir, 'cucumber.js'))}).default; console.log(JSON.stringify([c.require, Object.keys(c.worldParameters.users), c.tags, c.worldParameters.wikiAdmin, c.worldParameters.users.editor.username]))`], { encoding: 'utf8', env: { ...process.env, CUCUMBER_TAGS: '' } });
  assert.strictEqual(loaded.status, 0, loaded.stderr);
  const [requires, handles, tags, admin, username] = JSON.parse(loaded.stdout);
  assert.strictEqual(requires.length, 3);
  assert.deepStrictEqual(handles, ['administrator', 'editor', 'reader']);
  assert.match(tags, /not @must-fail/);
  assert.strictEqual(admin, 'administrator');
  assert.strictEqual(username, 'editor');
  assert.ok(fs.existsSync(path.join(p.dir, 'tests', 'features', 'site.feature')));
  assert.match(fs.readFileSync(log, 'utf8'), /createAndPromote --force --custom-groups=confirmed editor/, 'an installed wiki gets the default accounts');
  // Again, after a person changed the feature: nothing is doubled, nothing is reset.
  fs.writeFileSync(path.join(p.dir, 'tests', 'features', 'site.feature'), 'Feature: mine\n');
  assert.strictEqual(run().status, 0);
  assert.strictEqual(fs.readFileSync(path.join(p.dir, 'cucumber.js'), 'utf8'), cucumber);
  assert.strictEqual(fs.readFileSync(path.join(p.dir, 'tests', 'features', 'site.feature'), 'utf8'), 'Feature: mine\n');
});

test('the testing hook leaves a project of another platform alone', () => {
  const p = project('drupal');
  const r = bash(`cd ${p.dir} && testing_configure_mediawiki ${p.dir}`, { WORKSPACE_ROOT: p.root, WORKSPACE_SCRIPTS: p.scripts, doc_name: 'dev', PROJECT_NAME: 'site1' });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stdout, '');
  assert.strictEqual(fs.readFileSync(path.join(p.dir, 'cucumber.js'), 'utf8'), SCAFFOLD);
  assert.ok(!fs.existsSync(path.join(p.dir, 'tests')));
});

test('the maintenance tool refuses a project that is not a wiki', () => {
  const p = project('drupal');
  const r = bash('PROJECT_NAME=site1 ; RUN="showJobs" ; trim_project_name() { :; } ; mediawiki_maintenance_tool', { WORKSPACE_ROOT: p.root, doc_name: 'dev' });
  assert.strictEqual(r.status, 1);
  assert.match(r.stdout, /is not a MediaWiki project/);
});

test('the first feature names no platform in a step, and no password', () => {
  const feature = fs.readFileSync(path.join(PKG, 'testing', 'site.feature'), 'utf8');
  const steps = feature.split('\n').filter((l) => /^\s*(Given|When|Then|And|But) /.test(l));
  assert.ok(steps.length >= 10);
  for (const s of steps) assert.doesNotMatch(s, /mediawiki|wikimedia/i, s);
  assert.doesNotMatch(feature, /dD\.123123ddd/);
  assert.doesNotMatch(feature, /createAndPromote|Create your account/i, 'a suite never creates an account');
});
