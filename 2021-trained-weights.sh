#! /bin/bash
# author: Arne Köhn <arne@chark.eu>
# License: Apache 2.0

set -e
set -u

MC_VERSION=1.16.4

SCRIPTDIR=$(cd $(dirname $0); pwd)
source $SCRIPTDIR/functions.sh

SETUP_DIR=${1:-2021-trained-weights}
mkdir -p $SETUP_DIR
cd $SETUP_DIR

echo "press enter to kill broker, architect and minecraft server."
sleep 1

if [[ ! -f .setup_complete ]]; then
    if [[ -z ${SECRETWORD+x} ]]; then
	echo "You need to declare the secret word before setting up this experiment"
	echo "e.g. SECRETWORD=foo ./2021-trained-weights.sh"
	exit 1
    fi
    echo "running setup before starting the servers"
    rm -rf infrastructure simple-architect spigot-plugin
    setup_spigot_plugin f5f6e564739031be453d4d9b3e90eb64bef4e403
    # setup_spigot_woz_plugin
    setup_infrastructure 42894960f7080bd8ad0d4de7582d422c0a6934b4
    setup_simple-architect 6d3c02d3ddb716ad326ed81602650480f289d535
    cp ../configs/broker-config-2021-trained-weights.yaml infrastructure/broker/broker-config.yaml
    if [[ $(hostname) = "minecraft" ]]; then
	# We use an external questionnaire for these experiments
	echo "useInternalQuestionnaire: false" >> infrastructure/broker/broker-config.yaml
    fi
    sed -i "s/secretWord:.*/secretWord: $SECRETWORD/" simple-architect/configs/*yaml
    sed -i "s/MINECRAFTTEST/TRAINEDWEIGHTS/" simple-architect/configs/*yaml
    touch .setup_complete
fi

mariadb -u minecraft <<EOF
CREATE DATABASE IF NOT EXISTS TRAINEDWEIGHTS;
EOF

# this order is important:
# architect -> broker -> mc server

# start_simple-architect
# start_woz
start_simple-architect configs/adaptive-bootstrapped.yaml "10000"
start_simple-architect configs/adaptive-optimal.yaml "10001"
start_simple-architect configs/adaptive-randomized.yaml "10002"
sleep 5

start_broker
start_mc $MC_VERSION

wait_end
