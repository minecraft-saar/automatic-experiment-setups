#! /bin/bash
# author: Arne Köhn <arne@chark.eu>
# License: Apache 2.0


## All these functions take a version number to checkout as their only
## (but required) argument.

function setup_spigot {
    local SPIGOT_VERSION=${1:-1.14.4}
    # compile and set up the spigot server
    mkdir spigot-server
    cd spigot-server
    wget https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar
    java -jar BuildTools.jar --rev $SPIGOT_VERSION
    java -jar spigot-$SPIGOT_VERSION.jar
    sed -i s/false/true/ eula.txt
    cd ..
}

function setup_spigot_woz {
    local SPIGOT_VERSION=${1:-1.14.4}
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
    # compile and set up the plugin
    git clone git@github.com:minecraft-saar/spigot-plugin.git
    cd spigot-plugin/communication
    git checkout ${VERSION}
    ./gradlew shadowJar
    mkdir -p ../../spigot-server/plugins
    # weird path because it is relative to the target, not the current working directory.
    ln -s ../../spigot-plugin/communication/build/libs/communication-*-all.jar ../../spigot-server/plugins
    cd ..
    cp server_files/server.properties ../spigot-server
    cd ..
}

function setup_spigot_woz_plugin {
    cd spigot-plugin/woz
    ./gradlew shadowJar
    mkdir -p ../../spigot-woz/plugins
    cp build/libs/woz-*-all.jar ../../spigot-woz/plugins
    cd ..
    cp server_files/server.properties ../spigot-woz 
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
    git clone git@github.com:minecraft-saar/infrastructure.git
    cd infrastructure
    git checkout $VERSION
    ./gradlew build
    ./gradlew publishToMavenLocal
    cp broker/example-broker-config.yaml broker/broker-config.yaml
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
    local SPIGOT_VERSION=${1:-1.14.4}
    echo "starting minecraft server ..."
    cd spigot-woz
    java -jar spigot-${SPIGOT_VERSION}.jar &
    cd ..
    sleep 40
}

function start_dummy-architect {
    echo "starting the dummy architect ..."
    cd infrastructure
    ./gradlew architect:run &
    cd ..
    sleep 2
}

function start_simple-architect {
    echo "starting the simple architect ..."
    cd simple-architect
    ./gradlew run &
    cd ..
    sleep 20
}


function start_broker {
    echo "starting the broker ..."
    cd infrastructure
    ./gradlew broker:run &
    sleep 5
    cd ..
}

function start_mc {
    local SPIGOT_VERSION=${1:-1.14.4}
    echo "starting minecraft server ..."
    cd spigot-server
    java -jar spigot-${SPIGOT_VERSION}.jar &
    cd ..
}

function wait_end {
    echo "press enter to kill broker, architect and minecraft server."
    read
    pkill -P $$
}
