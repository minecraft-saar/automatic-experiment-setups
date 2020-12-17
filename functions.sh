#! /bin/bash
# author: Arne Köhn <arne@chark.eu>
# License: Apache 2.0


## All these functions take a version number to checkout as their only
## (but required) argument.

function setup_spigot_woz {
    local SPIGOT_VERSION=${1:-1.15.2}
    # compile and set up the spigot server
    mkdir spigot-woz
    cd spigot-woz
    wget https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar
    java -jar BuildTools.jar --rev $SPIGOT_VERSION
    java -jar spigot-$SPIGOT_VERSION.jar
    sed -i s/false/true/ eula.txt
    sed -i 's/server-port=25565/server-port=25566/' server.properties
    cd ..
}

function setup_spigot_plugin {
    local VERSION=$1
    # spigot version is ignored by all newer setup.sh scripts (mid-2020)
    local SPIGOT_VERSION=${2:-1.15.2}
    # compile and set up the plugin
    git clone git@github.com:minecraft-saar/spigot-plugin.git
    cd spigot-plugin
    git checkout ${VERSION}
    ./setup.sh $SPIGOT_VERSION
    cd ..
}

function setup_spigot_woz_plugin {
    cd spigot-plugin/woz
    ./gradlew shadowJar
    mkdir -p ../../spigot-woz/plugins
    cp build/libs/woz-*-all.jar ../../spigot-woz/plugins
    cd ..
    cp server_files/server.properties ../spigot-woz 
    cp server_files/bukkit.yml ../spigot-woz
    cp server_files/spigot.yml ../spigot-woz
    cd ..
}

function setup_minecraft-nlg {
    local VERSION=$1
    git clone git@github.com:minecraft-saar/minecraft-nlg.git
    cd minecraft-nlg
    git checkout $VERSION
    ./gradlew publishToMavenLocal
    cd ..
}

function setup_infrastructure {
    local VERSION=$1
    local DATABASE=${2:-MINECRAFT}
    git clone git@github.com:minecraft-saar/infrastructure.git
    cd infrastructure
    git checkout $VERSION
    ./gradlew build
    ./gradlew publishToMavenLocal
    cp broker/example-broker-config.yaml broker/broker-config.yaml
    # The default database is MINECRAFT.  Change it to the
    # database we want.
    sed -i s/MINECRAFT/$DATABASE/ broker/broker-config.yaml
    cd ..
}

function setup_simple-architect {
    local VERSION=$1
    git clone git@github.com:minecraft-saar/simple-architect.git
    cd simple-architect
    git checkout $VERSION
    ./gradlew build
    cd ..
}

function start_woz {
    local SPIGOT_VERSION=${1:-1.15.2}
    echo "starting minecraft server ..."
    cd spigot-woz
    java -jar spigot-${SPIGOT_VERSION}.jar 2>&1 | tee -a log &
    cd ..
    sleep 40
}

function start_dummy-architect {
    echo "starting the dummy architect ..."
    cd infrastructure
    ./gradlew architect:run 2>&1 | tee -a log &
    cd ..
    sleep 2
}

function start_simple-architect {
    echo "starting the simple architect ..."
    local TYPE=${1:-""}
    local PORT=${2:-10000}
    cd simple-architect
    ./gradlew run$TYPE --args="$PORT" 2>&1 | tee -a log-$TYPE-$PORT &
    cd ..
    sleep 2
}


function start_broker {
    echo "starting the broker ..."
    cd infrastructure
    ./gradlew broker:run 2>&1 | tee -a log &
    sleep 5
    cd ..
}

function start_mc {
    local SPIGOT_VERSION=$1
    echo "starting minecraft server ..."
    echo $PWD
    cd spigot-plugin
    ./start.sh $SPIGOT_VERSION 2>&1 | tee -a log &
    cd ..
}

function start_replay_mc {
    # version ignored in recent plugin versions
    echo "starting minecraft server ..."
    echo $PWD
    cd spigot-plugin
    ./start_replay_server.sh 2>&1 | tee -a log &
    cd ..
}

# https://stackoverflow.com/a/26966800
function kill_descendant_processes {
    local pid="$1"
    local and_self="${2:-false}"
    if children="$(pgrep -P "$pid")"; then
        for child in $children; do
            kill_descendant_processes "$child" true
        done
    fi
    if [[ "$and_self" == true ]]; then
        kill "$pid"
    fi
}

function wait_end {
    echo "press enter to kill broker, architect and minecraft server."
    read
    kill_descendant_processes $$
}
