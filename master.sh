#! /bin/bash
# author: Arne Köhn <arne@chark.eu>
# License: Apache 2.0

## sets up a demo with the simple architect, everything from master.

set -e
set -u

MC_VERSION=1.15.2

SCRIPTDIR=$(cd $(dirname $0); pwd)
source $SCRIPTDIR/functions.sh

SETUP_DIR=${1:-master}
mkdir -p $SETUP_DIR
cd $SETUP_DIR

echo "press enter to kill broker, architect and minecraft server."
sleep 1

if [[ ! -f .setup_complete ]]; then
	echo "running setup before starting the servers"
	if [[ ! -f .spigot_setup ]]; then
		setup_spigot $MC_VERSION
		# setup_spigot_woz $MC_VERSION
		touch .spigot_setup
	fi
	rm -rf infrastructure simple-architect spigot-plugin
	setup_minecraft-nlg master
	setup_spigot_plugin master
	# setup_spigot_woz_plugin
	setup_infrastructure master
	setup_simple-architect master
    touch .setup_complete
fi

# this order is important:
# architect -> broker -> mc server

# start_simple-architect
# start_woz
start_simple-architect

start_broker
start_mc $MC_VERSION

wait_end
