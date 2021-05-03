#!/bin/bash
set -xo pipefail

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

echo "Analyser cli args $analyser_cli_args"

if [[ -z ${AWS_ACCESS_KEY_ID} ]]; then
    echo "AWS_ACCESS_KEY_ID not found, using local queue"
else
    echo "AWS_ACCESS_KEY_ID found"
fi

if [[ -z ${AWS_SECRET_ACCESS_KEY} ]]; then
    echo "AWS_SECRET_ACCESS_KEY not found, using local queue"
else 
    echo "AWS_SECRET_ACCESS_KEY found"
fi

if [[ -z ${AWS_DEFAULT_REGION} ]]; then
    echo "AWS_DEFAULT_REGION='ap-southeast-2' not found, using local queue"
fi

if [[ -z ${SIGNAL_QUEUE} ]]; then
    echo "SIGNAL_QUEUE is required"
fi

ABSPATH=$(readlink -f $0)
ABSDIR=$(dirname $ABSPATH)
#ABSDIR=$(pwd -P)
FILENAME="$ABSDIR/docker-compose.yml"

docker-compose -f $FILENAME down
#Removing images to pull latest images on every deployment
docker image rm cryptobotregistrybsn.azurecr.io/binance-trader:latest
docker image rm cryptobotregistrybsn.azurecr.io/signal-catcher:latest
docker image rm cryptobotregistrybsn.azurecr.io/crypto-bot-ui:latest
docker-compose -f $FILENAME up -d   