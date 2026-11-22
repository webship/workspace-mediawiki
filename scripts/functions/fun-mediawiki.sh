#!/usr/bin/env bash

# MediaWiki for the Webship Workspace: build a wiki from the release tarball, run its maintenance
# scripts, add its default accounts, and wire its step pack into the testing setup.
#
# Placed by `plugins.sh --install mediawiki` in core/scripts/plugins/mediawiki/functions/, where
# bootstrap sources it after the core's own functions. Everything runs in the project's container
# (DDEV by default: `ddev exec php maintenance/run.php …`), never on the host. DDEV has no project
# type of its own for MediaWiki: a project is of type php with the wiki at the docroot, and the
# plugin knows it by its files (maintenance/run.php and the MW_VERSION of includes/Defines.php).
# The installer writes the wiki's database settings into LocalSettings.php from the container's own
# values (db, db, db on the host db), and nothing personal.
#
# The runtimes: a wiki is built on DDEV, or with --runtime on Docker Compose, Podman or Kubernetes.
# The commands are the same on each: `ddev <verb>` is DDEV itself on a DDEV project, and on another
# runtime the core's layer (fun-runtime.sh) gives the verb its meaning there. What differs is behind
# mediawiki_runtime: the address (mediawiki_url), the claim of the plugin on the project (rt_claim,
# which is how a wiki of another runtime is known), and the two things DDEV carries in .ddev/ that
# the stack of the other runtimes has no place for: the nginx rule of the REST API (Apache, the web
# server there, needs none) and the job queue as a service (the wiki runs its jobs itself there).
#
# Four names are the ones the core's tools look for:
#   set_mediawiki_users          the default accounts            (cmd-tools-add-users.sh <project> mediawiki)
#   add_mediawiki_users          create them in the wiki         (the same tool, and --add-users of the builder)
#   cancel_mediawiki_users       cancel them                     (cmd-tools-cancel-users.sh <project> mediawiki)
#   testing_configure_mediawiki  the step pack in the testing stack (cmd-tools-testing.sh <project>)

# The step pack a wiki is tested with, and the release line it is required at.
readonly MEDIAWIKI_STEPS_PACKAGE='@webship-js/mediawiki-steps';
readonly MEDIAWIKI_STEPS_VERSION='^2.0.0';
# The release the builder installs when --mediawiki-version is not given: the current stable one.
readonly MEDIAWIKI_DEFAULT_RELEASE='1.46.2';

# The default accounts, the ones a scenario logs in as: one per kind of account a wiki tells apart.
# Accounts are configuration, made once on the wiki with the maintenance script createAndPromote; a
# test suite never creates or deletes one.
#   administrator  sysop and bureaucrat: protects, deletes, restores, blocks
#   editor         the "confirmed" group: the rights of an established account at once
#   reader         no group: a new account, refused the pages protected for established accounts
function set_mediawiki_users() {
  users=(administrator editor reader);
  local user ;
  for user in "${users[@]}" ; do
    printf -v "user_${user}_name" '%s' "${user}" ;
    printf -v "user_${user}_mail" '%s' "${user}@example.com" ;
    printf -v "user_${user}_password" '%s' 'dD.123123ddd' ;
  done
  user_administrator_role='sysop,bureaucrat' ;
  user_editor_role='confirmed' ;
  user_reader_role='' ;
}

# The runtime of the project in this folder, or of a new build (--runtime, else the workspace's
# setting, else DDEV). A core without the runtime layer has DDEV only.
function mediawiki_runtime() {
  if declare -f runtime_of > /dev/null ; then runtime_of ; else echo 'ddev' ; fi
}

# The address of the wiki in this folder: https://<name>.ddev.site on DDEV, http://127.0.0.1:<port>
# on Docker Compose and Podman, the node's address and a port on Kubernetes. Asked after `ddev config`.
function mediawiki_url() {
  if declare -f rt_url > /dev/null ; then rt_url ; else echo "https://${PROJECT_NAME}.ddev.site" ; fi
}

# Is this folder a MediaWiki project? On Docker Compose, Podman and Kubernetes the claim of the
# plugin says so (`platform: mediawiki` in the x-webship block of compose.yaml, written by the
# builder: the core's rt_is_platform reads it). On DDEV, whose project type for it is `php`, a
# container project with the maintenance runner of the release and the version it defines, as before.
function mediawiki_is_project() {
  local project_path="$1";
  if declare -f rt_is_platform > /dev/null && rt_is_platform "${project_path}" mediawiki ; then return 0 ; fi
  [ -f "${project_path}/.ddev/config.yaml" ] && [ -f "${project_path}/maintenance/run.php" ] \
    && grep -q "define( 'MW_VERSION'" "${project_path}/includes/Defines.php" 2>/dev/null ;
}

# The release of the wiki in the current folder.
function mediawiki_version() {
  sed -n "s/^define( 'MW_VERSION', '\(.*\)' );/\1/p" includes/Defines.php 2>/dev/null ;
}

# Is the wiki of the current folder installed (it has its LocalSettings.php)?
function mediawiki_installed() {
  [ -f LocalSettings.php ] ;
}

# Go to the project a tool was asked about, or say why not.
function mediawiki_enter_project() {
  local project_path="${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME}";
  if [ ! -d "${project_path}" ] ; then
    echo "No project ${PROJECT_NAME} in ${WORKSPACE_ROOT}/${doc_name}." ;
    return 1 ;
  fi
  if ! mediawiki_is_project "${project_path}" ; then
    echo "${doc_name}/${PROJECT_NAME} is not a MediaWiki project (it has no maintenance/run.php and includes/Defines.php of the release, and no plugin claims it in compose.yaml)." ;
    return 1 ;
  fi
  cd "${project_path}" || return 1 ;
}

# A maintenance script of the wiki, in the container, with stdin closed.
function mediawiki_maintenance() {
  ddev exec php maintenance/run.php "$@" < /dev/null ;
}

# The settings the builder adds to LocalSettings.php after the installer wrote it: uploads, the
# "confirmed" group with the autoconfirm thresholds of large public wikis, the job queue as a
# service, the object cache and the sessions in the database.
function mediawiki_write_settings() {
  cat >> LocalSettings.php <<'PHPEOF'

# Added by the Webship Workspace (cmd-mediawiki-project.sh).
# Uploads, for the upload form (Special:Upload).
$wgEnableUploads = true;
# A new account earns the rights of an established one ("autoconfirmed") after 4 days and
# 10 edits, as on large public wikis; the "confirmed" group gives those rights at once.
$wgAutoConfirmAge = 4 * 86400;
$wgAutoConfirmCount = 10;
$wgGroupPermissions['confirmed']['autoconfirmed'] = true;
$wgGroupPermissions['confirmed']['editsemiprotected'] = true;
PHPEOF
  # On DDEV the job queue runs as a service of the web container. The stack of the other runtimes
  # has no such service: there the wiki runs its jobs itself, at the end of a request, as a wiki
  # does by default.
  if [ "$(mediawiki_runtime)" == 'ddev' ] ; then
    cat >> LocalSettings.php <<'PHPEOF'
# The job queue runs as a service of the container (.ddev/config.mediawiki-jobs.yaml).
$wgJobRunRate = 0;
PHPEOF
  else
    cat >> LocalSettings.php <<'PHPEOF'
# The job queue: the wiki runs its jobs itself, at the end of a request (the container has no
# service for it on this runtime).
$wgJobRunRate = 1;
PHPEOF
  fi
  cat >> LocalSettings.php <<'PHPEOF'
# The object cache and the sessions in the database: the maintenance scripts and the job
# runner share them with the web requests, and a restart keeps the sessions.
$wgMainCacheType = CACHE_DB;
$wgSessionCacheType = CACHE_DB;
PHPEOF
}

# The rule MediaWiki documents for nginx, so that rest.php/v1/... reaches the REST API (the search
# suggestions and the visual editor use it), and the job queue as a service of the web container.
function mediawiki_write_container_config() {
  mkdir -p .ddev/nginx ;
  cat > .ddev/nginx/mediawiki-rest.conf <<'NGINXEOF'
# The REST API of the wiki (rest.php/v1/...): the rule MediaWiki documents for nginx.
location /rest.php/ {
    try_files $uri $uri/ /rest.php?$query_string;
}
NGINXEOF
}

function mediawiki_write_jobs_service() {
  cat > .ddev/config.mediawiki-jobs.yaml <<'JOBSEOF'
# The job queue of the wiki as a service of the web container (added by the Webship Workspace).
web_extra_daemons:
  - name: "mediawiki-jobs"
    command: "php maintenance/run.php runJobs --wait --maxtime=3600 --memory-limit=256M"
    directory: /var/www/html
JOBSEOF
}

# Write one account: create it, or give it back its password; add its groups; set its address;
# lift a block on it. createAndPromote --force cannot set the address of an account that is there,
# so resetUserEmail does.
function mediawiki_write_account() {
  local name="$1" mail="$2" password="$3" groups="$4" ;
  local flags=() group ;
  for group in ${groups//,/ } ; do
    case "${group}" in
      sysop) flags+=(--sysop) ;;
      bureaucrat) flags+=(--bureaucrat) ;;
      interface-admin) flags+=(--interface-admin) ;;
      bot) flags+=(--bot) ;;
      *) flags+=(--custom-groups="${group}") ;;
    esac
  done
  mediawiki_maintenance createAndPromote --force "${flags[@]}" "${name}" "${password}" > /dev/null || return 1 ;
  [ -n "${mail}" ] && { mediawiki_maintenance resetUserEmail --no-reset-password "${name}" "${mail}" > /dev/null || return 1 ; } ;
  printf '%s\n' "${name}" | ddev exec php maintenance/run.php blockUsers --unblock --performer="Maintenance script" --reason="Account given back by the Webship Workspace" > /dev/null 2>&1 ;
  return 0 ;
}

# The accounts of the wiki: name, address, groups, and whether a block is on it.
function mediawiki_list_accounts() {
  mediawiki_maintenance sql --json --query "SELECT u.user_name AS name, u.user_email AS mail, (SELECT GROUP_CONCAT(ug_group) FROM user_groups WHERE ug_user = u.user_id) AS user_group_list, (SELECT COUNT(*) FROM block_target bt WHERE bt.bt_user = u.user_id) AS blocked FROM user u WHERE u.user_name NOT IN ('MediaWiki default', 'Maintenance script') ORDER BY u.user_id" 2>/dev/null \
    | python3 -c '
import json, sys
try:
    rows = json.load(sys.stdin)
except ValueError:
    rows = []
for r in rows:
    print("  %s <%s> %s%s" % (r.get("name"), r.get("mail") or "no address", r.get("user_group_list") or "no group", " (blocked)" if str(r.get("blocked")) not in ("0", "None") else ""))
' ;
}

# Build a wiki from nothing: the container, the release tarball, and with --install the wiki
# installed by its own installer, the workspace account as its first account.
function mediawiki_build() {
  trim_project_name ;
  local base_url runtime ;
  runtime="$(mediawiki_runtime)" ;
  if [ "${RUNTIME:-_none_}" != '_none_' ] && [ "${RUNTIME}" != "${runtime}" ] ; then
    echo "--runtime ${RUNTIME} needs a Webship Workspace with the container runtimes (webship/workspace#694): update the workspace, or build on DDEV." ;
    exit 1 ;
  fi
  local release="${MEDIAWIKI_VERSION:-${site_mediawiki_version:-${MEDIAWIKI_DEFAULT_RELEASE}}}" ;
  local major ;
  major="$(echo "${release}" | cut -d. -f1,2)" ;
  local php_version="${PHP_VERSION:-${site_php_version:-}}" ;
  local extensions='WikiEditor,CategoryTree,Cite' ;
  [ "${VISUAL_EDITOR}" == 'yes' ] && extensions="WikiEditor,VisualEditor,CategoryTree,Cite" ;

  cd ${WORKSPACE_ROOT}/${doc_name} || exit 1 ;

  drop_database ;
  rm -rf "${PROJECT_NAME}" ;
  mkdir -p "${PROJECT_NAME}" ;
  cd ${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME} || exit 1 ;

  # DDEV has no project type for the wiki: php, the wiki at the docroot.
  ddev config --project-type=php --docroot="" --project-name=${PROJECT_NAME} \
    --nodejs-version=$(ddev_nodejs_version) ${php_version:+--php-version=${php_version}} --auto || exit 1 ;
  if [ "${runtime}" == 'ddev' ] ; then
    mediawiki_write_container_config ;
  else
    # The project type is `php` on every runtime: on another runtime than DDEV the plugin claims the
    # project, so the tools and the dashboard know it is a wiki. Apache needs no rule for rest.php.
    rt_claim mediawiki || exit 1 ;
  fi
  ddev_up start -y || exit 1 ;
  # The address is the runtime's to say, once the project is configured: never a written ddev.site.
  base_url="$(mediawiki_url)" ;

  # The release tarball from the release server, unpacked at the docroot in the container.
  ddev exec "curl -sSfL https://releases.wikimedia.org/mediawiki/${major}/mediawiki-${release}.tar.gz | tar -xz --strip-components=1" < /dev/null \
    || { echo "The release ${release} could not be downloaded from releases.wikimedia.org." ; exit 1 ; } ;

  if [ "${INSTALL}" == 'yes' ] ; then
    # The installer of the release on the container's database; the workspace account is the
    # wiki's first account (sysop, bureaucrat, interface-admin).
    mediawiki_maintenance install --server="${base_url}" --scriptpath= \
      --dbtype=mysql --dbserver=db --dbname=db --dbuser=db --dbpass=db --installdbuser=db --installdbpass=db \
      --lang=en --pass="${account_pass}" --extensions="${extensions}" \
      "${doc_name} ${PROJECT_NAME}" "${account_name}" || { echo "The installer of the wiki failed." ; exit 1 ; } ;
    mediawiki_write_settings ;
    mediawiki_maintenance resetUserEmail --no-reset-password "${account_name}" "${account_mail}" > /dev/null ;
    printf 'Confirmed users' | ddev exec php maintenance/run.php edit --user="${account_name}" --summary="The name of the confirmed group" "MediaWiki:Group-confirmed" > /dev/null ;
    printf 'confirmed user' | ddev exec php maintenance/run.php edit --user="${account_name}" --summary="The name of a member of the confirmed group" "MediaWiki:Group-confirmed-member" > /dev/null ;
    if [ "${ADD_USERS}" == 'yes' ] ; then
      set_mediawiki_users ;
      add_mediawiki_users ;
      cd ${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME} || exit 1 ;
    fi
    # The job queue as a service: it needs the installed wiki, and starts with this restart. A
    # service of DDEV's web container: on another runtime the wiki runs its jobs itself.
    if [ "${runtime}" == 'ddev' ] ; then
      mediawiki_write_jobs_service ;
      ddev restart || exit 1 ;
    fi
  elif [ "${ADD_USERS}" == 'yes' ] ; then
    echo "--add-users needs --install: there is no wiki to add accounts to yet." ;
  fi

  local version ;
  version="$(mediawiki_version)" ;
  if [ "${INSTALL}" == 'yes' ] ; then
    local with='' ;
    [ "${VISUAL_EDITOR}" == 'yes' ] && with=' with the visual editor' ;
    echo "${doc_name} ${PROJECT_NAME} has been installed: MediaWiki ${version}${with}.";
    echo "Go to ${base_url}/index.php?title=Special:UserLogin and log in as ${account_name}";
  else
    echo "${doc_name} ${PROJECT_NAME} is ready: MediaWiki ${version}, not installed. Install it with its installer at ${base_url}/mw-config/ or build again with --install.";
    echo "Go to ${base_url}";
  fi

  if [ "${LAUNCH}" == 'yes' ] ; then
    ddev launch ;
  fi

  cd ${WORKSPACE_ROOT}/${doc_name};
}

# Create the default accounts in the wiki. An account that is already there gets its password,
# groups and address back, and a block on it is lifted. The list is loaded by the caller
# (set_mediawiki_users): the core's add_users, the builder, the maintenance tool.
function add_mediawiki_users() {
  mediawiki_enter_project || return 1 ;
  if ! mediawiki_installed ; then
    echo "  The wiki is not installed yet: build it with --install first." ;
    cd ${WORKSPACE_ROOT}/${doc_name}; return 1 ;
  fi
  local user user_name user_mail user_password user_role rc=0 ;
  for user in "${users[@]}" ; do
    user_name="user_${user}_name"; user_mail="user_${user}_mail";
    user_password="user_${user}_password"; user_role="user_${user}_role";

    echo " ---------------------------------------------------------------- ";
    echo "      User name: ${!user_name}";
    echo "      User mail: ${!user_mail}";
    echo "  User password: ${!user_password}";
    echo "    User groups: ${!user_role:-(none)}";
    echo " ================================================================= ";

    mediawiki_write_account "${!user_name}" "${!user_mail}" "${!user_password}" "${!user_role}" || rc=1 ;
  done
  cd ${WORKSPACE_ROOT}/${doc_name};
  return ${rc} ;
}

# Cancel the default accounts. A wiki never deletes an account (its edits keep their author): a
# cancelled account is blocked without end and gets a random password, so nobody logs in with it;
# add_mediawiki_users gives it back.
function cancel_mediawiki_users() {
  mediawiki_enter_project || return 1 ;
  local user user_name names="" ;
  for user in "${users[@]}" ; do
    user_name="user_${user}_name";
    echo " ---------------------------------------------------------------- ";
    echo "      User name: ${!user_name}";
    echo " ================================================================= ";
    names="${names}${!user_name}"$'\n' ;
    mediawiki_maintenance changePassword --user="${!user_name}" --password="$(head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 24)Aa1!" > /dev/null ;
    mediawiki_maintenance invalidateUserSessions --user="${!user_name}" > /dev/null 2>&1 ;
  done
  printf '%s' "${names}" | ddev exec php maintenance/run.php blockUsers --expiry=infinite --performer="Maintenance script" --reason="Account cancelled by the Webship Workspace" ;
  local rc=$? ;
  cd ${WORKSPACE_ROOT}/${doc_name};
  return ${rc} ;
}

# What cmd-tools-mediawiki-maintenance.sh does: the first of --run, --update, --jobs, --add-users,
# --cancel-users that was asked for; with none of them, what the wiki is.
function mediawiki_maintenance_tool() {
  trim_project_name ;
  mediawiki_enter_project || exit 1 ;

  if ! ddev describe -j 2>/dev/null | grep -q '"status":"running"' ; then
    ddev start -y || exit 1 ;
  fi

  if [ ! "${RUN}" == '_none_' ] ; then
    # Unquoted on purpose: --run "showJobs --group" is a script and its arguments.
    ddev exec php maintenance/run.php ${RUN} < /dev/null ;
    exit $? ;
  fi

  if [ "${UPDATE}" == 'yes' ] ; then
    mediawiki_maintenance update --quick ;
  elif [ "${JOBS}" == 'yes' ] ; then
    mediawiki_maintenance runJobs ;
  elif [ "${ADD_USERS}" == 'yes' ] ; then
    set_mediawiki_users ;
    add_mediawiki_users ;
  elif [ "${CANCEL_USERS}" == 'yes' ] ; then
    set_mediawiki_users ;
    cancel_mediawiki_users ;
  else
    echo "${doc_name}/${PROJECT_NAME}: MediaWiki $(mediawiki_version) at $(mediawiki_url)" ;
    if mediawiki_installed ; then
      echo "  Extensions: $(sed -nE "s/^wfLoadExtension\( '([^']+)'.*/\1/p" LocalSettings.php | tr '\n' ' ')" ;
      echo "" ; echo "Accounts:" ;
      mediawiki_list_accounts ;
    else
      echo "  Not installed: build it again with --install." ;
    fi
  fi
  cd ${WORKSPACE_ROOT}/${doc_name};
}

# The step pack in the testing stack of a MediaWiki project. The core's testing_configure calls this
# in the project folder once webship-js is scaffolded and before the dependencies are installed;
# for a project that is not a wiki it changes nothing.
#
# It adds the pack to package.json, lists its step definitions in cucumber.js after webship-js's
# own, gives cucumber.js the users registry of the default accounts (a handle a scenario reads,
# mapped to an account; never the workspace account), the handle the test-page steps work as
# (wikiAdmin) and the tags that keep the pack's assertions that must fail out of a normal run, and
# writes a first feature when the project has none of its own. Every part is skipped when it is
# already there, so a second run adds what the first missed and never resets a suite.
function testing_configure_mediawiki() {
  local project_path="$1";
  mediawiki_is_project "${project_path}" || return 0 ;
  if [ ! -f "${project_path}/cucumber.js" ] || [ ! -f "${project_path}/package.json" ] ; then
    echo "  MediaWiki: cucumber.js is not here yet — run the testing setup again once webship-js is scaffolded." ;
    return 1 ;
  fi

  echo "Adding the MediaWiki step pack (${MEDIAWIKI_STEPS_PACKAGE} ${MEDIAWIKI_STEPS_VERSION}).";
  set_mediawiki_users ;
  local registry="" user user_name user_mail user_password ;
  for user in "${users[@]}" ; do
    user_name="user_${user}_name"; user_mail="user_${user}_mail"; user_password="user_${user}_password";
    registry="${registry}${user}|${!user_mail}|${!user_password}|${!user_name}"$'\n' ;
  done

  python3 - "${project_path}" "${MEDIAWIKI_STEPS_PACKAGE}" "${MEDIAWIKI_STEPS_VERSION}" 'MEDIAWIKI' "${registry}" <<'PYEOF' || return 1
import json, re, sys

project, pack, version, prefix, registry = sys.argv[1:6]

# package.json: the pack as a dev dependency, at the release line this plugin was proven on.
pkg_file = project + '/package.json'
pkg = json.load(open(pkg_file))
if pack not in pkg.get('dependencies', {}) and pack not in pkg.get('devDependencies', {}):
    pkg.setdefault('devDependencies', {})[pack] = version
    open(pkg_file, 'w').write(json.dumps(pkg, indent=4) + '\n')
    print('  package.json: %s %s' % (pack, version))

# cucumber.js: the pack's step definitions after webship-js's own, the users registry, the handle the
# test-page steps work as, and the tags of the pack's lane.
cucumber_file = project + '/cucumber.js'
src = open(cucumber_file).read()
before = src

if ('node_modules/%s/' % pack) not in src:
    line = "'node_modules/%s/tests/step-definitions/**/*.js'," % pack
    core = re.search(r"^([ \t]*)'node_modules/webship-js/tests/step-definitions/[^']*',.*$", src, re.M)
    opening = re.search(r"^([ \t]*)require:[ \t]*\[[ \t]*$", src, re.M)
    if core:
        src = src[:core.end()] + '\n' + core.group(1) + line + src[core.end():]
    elif opening:
        src = src[:opening.end()] + '\n' + opening.group(1) + '  ' + line + src[opening.end():]
    else:
        sys.exit("  cucumber.js has no require list this can add to. Add this line to it:\n    " + line)
    print('  cucumber.js: the step definitions of %s' % pack)

if not re.search(r"^[ \t]*tags:", src, re.M):
    default = re.search(r"^([ \t]*)default:[ \t]*\{[ \t]*$", src, re.M)
    if default:
        pad = default.group(1) + '  '
        block = [
            pad + "// The pack's assertions that must fail are no part of a normal run.",
            pad + "tags: process.env.CUCUMBER_TAGS || 'not @wip and not @must-fail',",
        ]
        src = src[:default.end()] + '\n' + '\n'.join(block) + src[default.end():]
        print('  cucumber.js: the tags that keep the assertions that must fail out of a normal run')

world = re.search(r"^([ \t]*)worldParameters:[ \t]*\{[ \t]*$", src, re.M)
if not world:
    sys.exit("  cucumber.js has no worldParameters block to add the users registry to.")
pad = world.group(1) + '  '
additions = []
if not re.search(r"^[ \t]*wikiAdmin:", src, re.M):
    additions += [
        pad + "// The account the test-page steps make and delete the test pages as, through the wiki's API.",
        pad + "wikiAdmin: process.env.WIKI_ADMIN || 'administrator',",
    ]
if not re.search(r"^[ \t]*users:[ \t]*\{", src, re.M):
    rows = [r.split('|') for r in registry.splitlines() if r.strip()]
    additions += [
        pad + "// The users registry: a handle a scenario reads, mapped to an account of this wiki (the default",
        pad + "// accounts: cmd-tools-mediawiki-maintenance.sh --add-users). Override one with %s_<HANDLE>_USERNAME," % prefix,
        pad + "// %s_<HANDLE>_PASSWORD and %s_<HANDLE>_EMAIL." % (prefix, prefix),
        pad + "users: {",
    ]
    for handle, email, password, name in rows:
        env = '%s_%s' % (prefix, handle.upper())
        additions.append(pad + "  %s: { username: process.env.%s_USERNAME || '%s', password: process.env.%s_PASSWORD || '%s', email: process.env.%s_EMAIL || '%s' }," % (handle, env, name, env, password, env, email))
    additions.append(pad + "},")
    print('  cucumber.js: the users registry (%s)' % ', '.join(r[0] for r in rows))
if additions:
    src = src[:world.end()] + '\n' + '\n'.join(additions) + src[world.end():]

if src != before:
    open(cucumber_file, 'w').write(src)
PYEOF

  # A first feature, when the project has none for the wiki yet: the main page, the login page,
  # each default account, a refused login, the refusal of a protected page.
  local feature="${WORKSPACE_SCRIPTS}/plugins/mediawiki/site.feature" ;
  if [ -f "${feature}" ] && [ ! -f "${project_path}/tests/features/site.feature" ] ; then
    mkdir -p "${project_path}/tests/features" && cp "${feature}" "${project_path}/tests/features/site.feature" \
      && echo "  tests/features/site.feature: a first feature for the wiki" ;
  fi

  # The scenarios log in as the default accounts: make sure an installed wiki has them.
  if ( cd "${project_path}" && mediawiki_installed ) ; then
    if ( add_mediawiki_users > /dev/null 2>&1 ) ; then
      echo "  the default accounts are on the wiki (${users[*]})" ;
    else
      echo "  The default accounts could not be written: is the wiki installed (bash cmd-mediawiki-project.sh ${PROJECT_NAME} --install)?" ;
    fi
  else
    echo "  The wiki is not installed: the scenarios that log in need a wiki built with --install." ;
  fi
}
