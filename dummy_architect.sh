#! /bin/bash
# author: Arne Köhn <arne@chark.eu>
# License: Apache 2.0

## sets up a demo with the dummy architect.

set -e
set -u

MC_VERSION=1.14.4

SCRIPTDIR=$(cd $(dirname $0); pwd)
source $SCRIPTDIR/functions.sh

SETUP_DIR=${1:-experiment-setup}
mkdir -p $SETUP_DIR
cd $SETUP_DIR

echo "press enter to kill broker, architect and minecraft server."
sleep 1

if [[ ! -f .setup_complete ]]; then
	echo "running setup before starting the servers"
	setup_spigot $MC_VERSION
	setup_spigot_plugin 1.1.3
	setup_infrastructure release-1.1.3
    touch .setup_complete
fi

# this order is important:
# architect -> broker -> mc server

start_dummy-architect
start_broker
start_mc $MC_VERSION

wait_end
