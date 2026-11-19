#!/usr/bin/env bash

argparse "$@" <<ARGEOF || exit 1
parser.add_argument('PROJECT_NAME',
                    help='The MediaWiki project in this workspace.')
parser.add_argument('-r', '--run',
                    default="_none_",
                    help='A maintenance script to run in the wiki, with its arguments, as maintenance/run.php takes it. Example: --run "showJobs --group"')
parser.add_argument('-u', '--update',
                    action='store_true',
                    default=False,
                    help='Run the database updates of the wiki (update --quick), after a new release or a new extension.')
parser.add_argument('-j', '--jobs',
                    action='store_true',
                    default=False,
                    help='Run the jobs that are waiting in the job queue now.')
parser.add_argument('-a', '--add-users',
                    action='store_true',
                    default=False,
                    help='Add the default accounts. An account that is already there gets its password, groups and address back, and a block on it is lifted.')
parser.add_argument('-c', '--cancel-users',
                    action='store_true',
                    default=False,
                    help='Cancel the default accounts: a wiki keeps every account, so each is blocked without end and gets a random password.')
ARGEOF
