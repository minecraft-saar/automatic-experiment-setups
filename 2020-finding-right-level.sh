#! /bin/bash
# author: Arne Köhn <arne@chark.eu>
# License: Apache 2.0

## sets up a demo with the simple architect, everything from master.
## TODO: Use fixed versions once we know them

set -e
set -u

MC_VERSION=1.15.2

SCRIPTDIR=$(cd $(dirname $0); pwd)
source $SCRIPTDIR/functions.sh

SETUP_DIR=${1:-inlg-experiments}
mkdir -p $SETUP_DIR
cd $SETUP_DIR

echo "press enter to kill broker, architect and minecraft server."
sleep 1

if [[ ! -f .setup_complete ]]; then
    echo "running setup before starting the servers"
    rm -rf infrastructure simple-architect spigot-plugin
    setup_minecraft-nlg master
    setup_spigot_plugin master
    # setup_spigot_woz_plugin
    setup_infrastructure master
    setup_simple-architect master
    cp ../configs/broker-config-2020-finding-right-level.yaml infrastructure/broker/broker-config.yaml
    touch .setup_complete
fi

# this order is important:
# architect -> broker -> mc server

# start_simple-architect
# start_woz
start_simple-architect Block "10000"
start_simple-architect Highlevel "10001"
sleep 5

start_broker
start_mc $MC_VERSION

wait_end
