#!/usr/bin/env bash

# workspace-name: MediaWiki (release tarball)

# Installed by the MediaWiki plugin (plugins.sh --install mediawiki); __WORKSPACE__ is the workspace it was installed into.
#
# Build a wiki in a container from the MediaWiki release tarball: on DDEV (the default) at
# https://<name>.ddev.site (project type php, the wiki at the docroot), and with --runtime docker,
# podman or kubernetes on that runtime, at the address the build prints. With --install it is installed by its own installer on
# the container's database, with the extensions a default wiki uses, and the workspace account is its
# first account; with --add-users it also gets the default accounts; with --visual-editor, the visual
# editor.

# Bootstrap.
# Find the workspace tooling from this script, so a fresh clone needs no setup.
WORKSPACE_SCRIPTS="${WORKSPACE_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../core/scripts" && pwd)}";
source ${WORKSPACE_SCRIPTS}/bootstrap.sh || exit 1 ;

# Load workspace settings.
eval $(parse_yaml ${WORKSPACE_CONFIG}/workspace.__WORKSPACE__.settings.yml);

# Distribution.
distribution_name="mediawiki";
distribution_title="MediaWiki";
distribution_webroot="";

ARGPARSE_DESCRIPTION="Build a ${distribution_title} wiki in __WORKSPACE__"
# The args file comes with the plugin: core/scripts/plugins/mediawiki/ is where plugins.sh --install puts it.
source ${WORKSPACE_SCRIPTS}/plugins/mediawiki/args/arg-mediawiki.sh || exit 1 ;

shift $#;

mediawiki_build ;
