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
    git clone https://github.com/minecraft-saar/shared-resources.git
    echo "running setup before starting the servers"
    rm -rf infrastructure simple-architect spigot-plugin
    setup_minecraft-nlg master
    setup_spigot_plugin master
    # setup_spigot_woz_plugin
    setup_infrastructure master
    setup_simple-architect master
    touch .setup_complete
    for target in minecraft-nlg infrastructure/broker spigot-plugin/communication simple-architect; do
	echo "includeBuild '$PWD/shared-resources'" >> settings.gradle
    done
fi

# this order is important:
# architect -> broker -> mc server

# start_simple-architect
# start_woz
start_simple-architect configs/teaching.yaml "10000"

start_broker
start_mc $MC_VERSION

wait_end
