#! /bin/bash
# author: Arne Köhn <arne@chark.eu>
# License: Apache 2.0

# this setting was run with previous data:
# mysqldump --add-drop-table RANDOMOPTIMAL > random-optimal-2021-06-17.sql
# mariadb -> create database RANDOMOPTIMALBRIDGE;
# mariadb RANDOMOPTIMALBRIDGE < random-optimal-2021-06-17.sql
#
# with house games removed:
#
# MariaDB [RANDOMOPTIMALBRIDGE]> delete from GAME_LOGS where gameid in (select id from GAMES where scenario = "house");
# Query OK, 149172 rows affected (0.591 sec)
#
# MariaDB [RANDOMOPTIMALBRIDGE]> delete from GAMES where scenario = "house";
# Query OK, 59 rows affected (0.001 sec)

set -e
set -u

MC_VERSION=1.18.1
export USE_DEV_SERVER=false
EXPNAME=test-bridge-fancy
SECRETWORD=apple
#IMPORTANT!!! adapt database name in line 84

SCRIPTDIR=$(cd $(dirname $0); pwd)
source $SCRIPTDIR/functions.sh

SETUP_DIR=${1:-$EXPNAME}
mkdir -p $SETUP_DIR
cd $SETUP_DIR


echo "press enter to kill broker, architect and minecraft server."
sleep 1

if [[ ! -f .setup_complete ]]; then
    if [[ -z ${SECRETWORD+x} ]]; then
	echo "You need to declare the secret word before setting up this experiment"
	echo "e.g. SECRETWORD=foo ./2021-rerun-one-ins.sh"
	exit 1
    fi
    echo "running setup before starting the servers"
    rm -rf infrastructure simple-architect spigot-plugin
    setup_spigot_plugin fa09fee090b9f0a9338a500fca7c37b3a242b722
    # setup_spigot_woz_plugin
    setup_infrastructure 8464134138aebfa5e83b8b51394d3274939e69fd
    setup_simple-architect bdfb8dff2d69859c097ac58dbb418c5d06af00ad
    cp ../configs/broker-config-$EXPNAME.yaml infrastructure/broker/broker-config.yaml

    rm simple-architect/configs/*yaml
    #cp -a ../configs/2021-rerun-one-ins/basic-configs/. simple-architect/configs

    for i in $(ls ../configs/$EXPNAME/plans/ | grep 'lisp$'); do
	cfg=simple-architect/configs/${i%lisp}yaml
	weights=$(cd ../configs/$EXPNAME/weights; pwd)/${i%lisp}json
	plan=$(cd ../configs/$EXPNAME/plans/; pwd)/$i
	cp ../configs/architect.yaml $cfg
	sed -i "s/__NAME__/${i%.lisp}/" $cfg
	sed -i "s|__WEIGHTFILE__|${weights}|" $cfg
	sed -i "s|__PLANFILE__|${plan}|" $cfg
    done
    sed -i "s/secretWord:.*/secretWord: $SECRETWORD/" simple-architect/configs/*yaml
    #sed -i "s/MINECRAFTTEST/SPEEDVERBOSITY/" simple-architect/configs/*yaml

    port=10000
    for i in $(ls simple-architect/configs | grep "yaml$"); do
	echo " - hostname: localhost" >> infrastructure/broker/broker-config.yaml
	echo "   port: $port" >> infrastructure/broker/broker-config.yaml
	port=$((port+1))
    done

    #if [[ $(hostname) = "minecraft" ]]; then
	# We use an external questionnaire for these experiments
	echo "useInternalQuestionnaire: false" >> infrastructure/broker/broker-config.yaml
    #fi

    
    touch .setup_complete
fi

mariadb -u minecraft <<EOF
CREATE DATABASE IF NOT EXISTS TEST
EOF

# this order is important:
# architect -> broker -> mc server

# start_simple-architect
# start_woz

port=10000
for i in $(ls simple-architect/configs | grep "yaml$"); do
    start_simple-architect configs/$i "$port"
    port=$((port+1))
done
sleep 0

start_broker
sleep 20
start_mc $MC_VERSION

wait_end
