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
    setup_spigot_plugin 1560561b9e826f4f47e94db25f5abc1c3d718648
    # setup_spigot_woz_plugin
    setup_infrastructure b55a0d869c226bcaa20d7b626bb91a4252ba543a
    setup_simple-architect a47658febdc124d2168be0ba4951cfc53458a521
    cp ../configs/broker-config-2021-random-optimal.yaml infrastructure/broker/broker-config.yaml
    if [[ $(hostname) = "minecraft" ]]; then
	# We use an external questionnaire for these experiments
	echo "useInternalQuestionnaire: false" >> infrastructure/broker/broker-config.yaml
    fi
    sed -i "s/secretWord:.*/secretWord: $SECRETWORD/" simple-architect/configs/*yaml
    sed -i "s/MINECRAFTTEST/RANDOMOPTIMAL/" simple-architect/configs/*yaml
    # make optimal learn from both optimal and random games to emulate epsilon greedy,
    # reusing the random games for efficiency:
    sed -i "s/weightTrainingArchitectName:.*/weightTrainingArchitectName: \"%\"/" simple-architect/configs/*yaml
    touch .setup_complete
fi

mariadb -u minecraft <<EOF
CREATE DATABASE IF NOT EXISTS RANDOMOPTIMAL;
EOF

# this order is important:
# architect -> broker -> mc server

# start_simple-architect
# start_woz
start_simple-architect configs/block-randomized.yaml "10000"
start_simple-architect configs/teaching-randomized.yaml "10001"
start_simple-architect configs/highlevel-randomized.yaml "10002"
start_simple-architect configs/block-optimal.yaml "10003"
start_simple-architect configs/teaching-optimal.yaml "10004"
start_simple-architect configs/highlevel-optimal.yaml "10005"
sleep 5

start_broker
start_mc $MC_VERSION

wait_end
