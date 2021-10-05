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

MC_VERSION=1.17
export USE_DEV_SERVER=false

SCRIPTDIR=$(cd $(dirname $0); pwd)
source $SCRIPTDIR/functions.sh

SETUP_DIR=${1:-2021-rerun-one-ins}
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
    setup_spigot_plugin 597f34172adf061d1aa65a2de03f9a517e8a6c4c
    # setup_spigot_woz_plugin
    setup_infrastructure 7c7301c10f9340c317cbdc0885427c233b9848e8
    setup_simple-architect 6da5402388a4656f950ec42f9fb941db787f8974
    cp ../configs/broker-config-2021-rerun-one-ins.yaml infrastructure/broker/broker-config.yaml

    rm simple-architect/configs/*yaml
    #cp -a ../configs/2021-rerun-one-ins/basic-configs/. simple-architect/configs

    for i in $(ls ../configs/2021-rerun-one-ins/plans/ | grep 'lisp$'); do
	cfg=simple-architect/configs/${i%lisp}yaml
	weights=$(cd ../configs/2021-rerun-one-ins/weights; pwd)/${i%lisp}json
	plan=$(cd ../configs/2021-rerun-one-ins/plans/; pwd)/$i
	cp ../configs/2021-rerun-one-ins/architect.yaml $cfg
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
CREATE DATABASE IF NOT EXISTS RERUN
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
