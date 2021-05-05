#!/bin/bash
set -o pipefail

if [[ `uname` == "Darwin" ]]; then
    ABSDIR=$(pwd -P)
else
    ABSPATH=$(readlink -f $0)
    ABSDIR=$(dirname $ABSPATH)
fi

export trader_version="$(curl -s https://api.github.com/repos/bsn-group/trader/commits |grep -oP '(?<=(\"sha\"\: \"))[^\"]*' |head -1)"
export analyzer_version="$(curl -s https://api.github.com/repos/bsn-group/analyzer/commits |grep -oP '(?<=(\"sha\"\: \"))[^\"]*' |head -1)"
export ui_version="latest"

if [[ -z ${POSTGRES_DB} ]]; then
    echo "db name not found"
    exit 1
else
    echo "db name found"
fi

if [[ -z ${POSTGRES_USER} ]]; then
    echo "db user not found"
    exit 1
else
    echo "db user found"
fi

if [[ -z ${POSTGRES_PASSWORD} ]]; then
    echo "db password not found"
    exit 1
else
    echo "db password found"
fi

if  [[ $1 == "--live" ]]; then
    export analyser_cli_args="--takeovertrade" # live 
    export trader_cli_args="--realorders" # live
    if [[ -z ${Binance__FuturesKey} ]]; then
        echo "Binance__FuturesKey is required"
        exit 1
    else 
        echo "Binance__FuturesKey found"
    fi
    if [[ -z ${Binance__FuturesSecret} ]]; then
        echo "Binance__FuturesSecret is required"
        exit 1
    else 
        echo "Binance__FuturesSecret found"
    fi
else
    echo "Not running live"
fi

echo "Analyser cli args ${analyser_cli_args}"

if [ -z ${AWS_ACCESS_KEY_ID} ] && [ -z ${AWS_SECRET_ACCESS_KEY} ] && [ -z ${AWS_DEFAULT_REGION} ]; then
    echo "AWS_SECRET_ACCESS_KEY not found, using local queue"
else 
    echo "AWS_ACCESS_KEYS found"
fi

if [[ -z ${SIGNAL_QUEUE} ]]; then
    echo " SIGNAL_QUEUE not found"
    exit 1
else
    echo "SIGNAL_QUEUE found"
fi

FILENAME="${ABSDIR}/docker-compose.yml"
docker-compose -f ${FILENAME} down
env
#Removing images to pull latest images on every deployment
docker image rm bsngroup/trader:latest
docker image rm bsngroup/analyzer:latest
docker image rm bsngroup/cryptobot-ui:latest
docker-compose -f ${FILENAME} up -d   