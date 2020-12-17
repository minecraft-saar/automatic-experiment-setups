#! /bin/bash
# author: Arne Köhn <arne@chark.eu>
# License: Apache 2.0

set -e
set -u

MC_VERSION=1.16.4

SCRIPTDIR=$(cd $(dirname $0); pwd)
source $SCRIPTDIR/functions.sh

SETUP_DIR=${1:-2020-randomized-experiments}
mkdir -p $SETUP_DIR
cd $SETUP_DIR

echo "press enter to kill broker, architect and minecraft server."
sleep 1

if [[ ! -f .setup_complete ]]; then
    echo "running setup before starting the servers"
    rm -rf infrastructure simple-architect spigot-plugin
    setup_spigot_plugin e5a43da062539d08019a7455fbcdb7e636ce77e5
    # setup_spigot_woz_plugin
    setup_infrastructure 0b279d9860b2f39cbf73926be9e56fbea93b7f18
    setup_simple-architect 96f2c49cb22b249dbbd4e720475ea1959ee8f2b2
    cp ../configs/broker-config-2020-randomized-weights.yaml infrastructure/broker/broker-config.yaml
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
