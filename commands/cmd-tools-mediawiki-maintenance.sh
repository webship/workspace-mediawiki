#!/usr/bin/env bash

# Installed by the MediaWiki plugin (plugins.sh --install mediawiki); __WORKSPACE__ is the workspace it was installed into.
#
# The maintenance scripts of one wiki of this workspace, in its container (maintenance/run.php): say
# what the wiki is, run a script, run the database updates, run the waiting jobs, add or cancel the
# default accounts. Nothing here runs on the host.

# Bootstrap.
# Find the workspace tooling from this script, so a fresh clone needs no setup.
WORKSPACE_SCRIPTS="${WORKSPACE_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../core/scripts" && pwd)}";
source ${WORKSPACE_SCRIPTS}/bootstrap.sh || exit 1 ;

# Load workspace settings.
eval $(parse_yaml ${WORKSPACE_CONFIG}/workspace.__WORKSPACE__.settings.yml);

# Distribution.
distribution_name="mediawiki";

ARGPARSE_DESCRIPTION="Run the maintenance scripts of a MediaWiki wiki of __WORKSPACE__: status, a script, updates, jobs, the default accounts"
# The args file comes with the plugin: core/scripts/plugins/mediawiki/ is where plugins.sh --install puts it.
source ${WORKSPACE_SCRIPTS}/plugins/mediawiki/args/arg-mediawiki-maintenance.sh || exit 1 ;

shift $#;

mediawiki_maintenance_tool ;
