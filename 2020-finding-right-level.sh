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
    setup_minecraft-nlg 4da39a42cdfbf84f1c835e074fb0d99facbf67ec
    setup_spigot_plugin 710753efdc28d39adbe5891db7d3a5c39e5aea00
    # setup_spigot_woz_plugin
    setup_infrastructure 570bfcaca696b0573890efed370fbea2a6f183ab
    setup_simple-architect b91b4c73f6642a111bd6748f04378d5098048166
    cp ../configs/broker-config-2020-finding-right-level.yaml infrastructure/broker/broker-config.yaml
    if [[ $(hostname) = "minecraft" ]]; then
	if [[ -z ${SECRETWORD+x} ]]; then
	    echo "You need to declare the secret word before setting up this experiment"
	    echo "e.g. SECRETWORD=foo ./2020-finding-right-level.sh"
	    exit 1
	fi
	# We use an external questionnaire for these experiments
	echo "useInternalQuestionnaire: false" >> infrastructure/broker/broker-config.yaml
	echo "secretWord: $SECRETWORD" >> simple-architect/architect-config.yaml
    else
	# nobody on our test server is getting paid
	echo "showSecret: false" >> simple-architect/architect-config.yaml
    fi
    touch .setup_complete
fi

# this order is important:
# architect -> broker -> mc server

# start_simple-architect
# start_woz
start_simple-architect Block "10000"
start_simple-architect Medium "10001"
start_simple-architect Highlevel "10002"
sleep 5

start_broker
start_mc $MC_VERSION

wait_end
