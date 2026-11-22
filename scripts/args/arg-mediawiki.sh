#!/usr/bin/env bash

argparse "$@" <<ARGEOF || exit 1
parser.add_argument('PROJECT_NAME',
                    help='The name of the project: its folder, and its name on the container runtime (on DDEV its host name too).')
parser.add_argument('--runtime',
                    dest='RUNTIME',
                    default="_none_",
                    choices=['ddev', 'docker', 'podman', 'kubernetes'],
                    help='The container runtime to build on: ddev (the default, or container.runtime of settings.yml), docker (Docker Compose), podman or kubernetes.')
parser.add_argument('-i', '--install',
                    action='store_true',
                    default=False,
                    help='Install the wiki with its own installer on the container database; the workspace account is its first account.')
parser.add_argument('-a', '--add-users',
                    action='store_true',
                    default=False,
                    help='With --install, add the default accounts (administrator, editor, reader): the ones the test scenarios log in as.')
parser.add_argument('-v', '--visual-editor',
                    action='store_true',
                    default=False,
                    help='Turn the visual editor on (VisualEditor, with Parsoid from core), beside WikiEditor, CategoryTree and Cite.')
parser.add_argument('-m', '--mediawiki-version',
                    default="",
                    help='The release to install, from releases.wikimedia.org; empty means the current stable release. Example: --mediawiki-version 1.43.11')
parser.add_argument('-l', '--launch',
                    action='store_true',
                    default=False,
                    help='Open the wiki in a browser when it is ready.')
parser.add_argument('--php-version',
                    default="",
                    choices=['8.4', '8.3'],
                    help='PHP version for the project container; empty means the default of the container tool. Example: --php-version 8.4')
ARGEOF
