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
    setup_spigot_plugin f5f6e564739031be453d4d9b3e90eb64bef4e403
    # setup_spigot_woz_plugin
    setup_infrastructure 0fa5427db8f507ab9e50fff73388dca02e3c379c
    setup_simple-architect 0cbb5d123392e73ffdc9a459e85f377b16fce745
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
    echo "randomizeWeights: true" >> simple-architect/architect-config.yaml
    touch .setup_complete
fi

mariadb -u minecraft <<EOF
CREATE DATABASE IF NOT EXISTS RANDOMIZEDWEIGHTS;
EOF

# this order is important:
# architect -> broker -> mc server

# start_simple-architect
# start_woz
#start_simple-architect Block "10000"
start_simple-architect Medium "10001"
#start_simple-architect Highlevel "10002"
sleep 5

start_broker
start_mc $MC_VERSION

wait_end
