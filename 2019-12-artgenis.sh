#! /bin/bash
# author: Arne Köhn <arne@chark.eu>
# License: Apache 2.0

## sets up a demo with the dummy architect.

set -e
set -u

MC_VERSION=1.14.4

SCRIPTDIR=$(cd $(dirname $0); pwd)
source $SCRIPTDIR/functions.sh

SETUP_DIR=${1:-artgenis}
mkdir -p $SETUP_DIR
cd $SETUP_DIR

echo "press enter to kill broker, architect and minecraft server."
sleep 1

if [[ ! -f .setup_complete ]]; then
	echo "running setup before starting the servers"
	if [[ ! -f .spigot_setup ]]; then
		setup_spigot $MC_VERSION
		touch .spigot_setup
	fi
	rm -rf infrastructure simple-architect spigot-plugin
	setup_spigot_plugin d5487ba
	setup_infrastructure release-1.1.4
	setup_simple-architect e4b69ac
    touch .setup_complete
fi

# this order is important:
# architect -> broker -> mc server

start_simple-architect
start_broker
start_mc $MC_VERSION

wait_end
