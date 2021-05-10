#!/bin/bash
set -o pipefail

if [[ `uname` == "Darwin" ]]; then
    ABSDIR=$( cd "$(dirname "$0")" ; pwd -P )
else
    ABSPATH=$(readlink -f $0)
    ABSDIR=$(dirname $ABSPATH)
fi

echo $ABSDIR
echo "Sourcing bsnbot.env $ABSDIR/bsnbot.env"
source "$ABSDIR/bsnbot.env"

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

if  [[ "${1}" == "--live" ]]; then
    echo "Running Live"
else
    echo "Not running live"
    if [[ -z ${Binance__FuturesUsdtBaseUrl} ]] || [[ -z ${Binance__FuturesCoinMBaseUrl} ]] || [[ -z ${Binance__FuturesWSSUrl} ]]; then
        echo "Binance testnet details not found"
        echo 'To run live cmd  "run.sh --live '
        exit 1
    else
        echo  " Binance testnet details found"
        echo "running in test mode"
    fi
fi

if [ -z ${AWS_ACCESS_KEY_ID} ] || [ -z ${AWS_SECRET_ACCESS_KEY} ] || [ -z ${AWS_DEFAULT_REGION} ]; then
    echo "AWS Listener details not found, using ngrok local queue"
else 
    echo "AWS Listener found"
fi

if [[ -z ${SIGNAL_QUEUE} ]]; then
    echo " SIGNAL_QUEUE not found"
    exit 1
else
    echo "SIGNAL_QUEUE found"
fi

if [[ -z ${IMAGE_VERSION} ]]; then
    export trader_version="$(curl -s https://api.github.com/repos/bsn-group/trader/branches/main |grep -oP '(?<=(\"sha\"\: \"))[^\"]*' |head -1)"
    export analyzer_version="$(curl -s https://api.github.com/repos/bsn-group/analyzer/branches/main |grep -oP '(?<=(\"sha\"\: \"))[^\"]*' |head -1)"
    export ui_version="$(curl -s https://api.github.com/repos/bsn-group/cryptobot-ui/branches/main |grep -oP '(?<=(\"sha\"\: \"))[^\"]*' |head -1)"
else
    export trader_version=${IMAGE_VERSION}
    export analyzer_version=${IMAGE_VERSION}
    export ui_version=${IMAGE_VERSION}
fi

FILENAME="${ABSDIR}/docker-compose.yml"
docker-compose -f ${FILENAME} down
#Removing images to pull latest images on every deployment
docker image rm bsngroup/trader:latest
docker image rm bsngroup/analyzer:latest
docker image rm bsngroup/cryptobot-ui:latest
docker-compose -f ${FILENAME} up -d