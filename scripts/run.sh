#!/bin/bash
set -o pipefail

if [[ `uname` == "Darwin" ]]; then
    ABSDIR=$(pwd -P)
else
    ABSPATH=$(readlink -f $0)
    ABSDIR=$(dirname $ABSPATH)
fi
echo $ABSDIR
echo $1
if [[ ! -f bsnbot.env ]]; then
    echo 'Env file not found'
    export trader_version="$(curl -s https://api.github.com/repos/bsn-group/trader/commits |grep -oP '(?<=(\"sha\"\: \"))[^\"]*' |head -1)"
    export analyzer_version="$(curl -s https://api.github.com/repos/bsn-group/analyzer/commits |grep -oP '(?<=(\"sha\"\: \"))[^\"]*' |head -1)"
    export DbAdminConnection="${connectionString}"
    export ConnectionStrings__cryptodbConnection="${connectionString}"
    export ConnectionStrings__PostgresConnection="${connectionString}"
    env > $ABSDIR/bsnbot.env
else
   source $ABSDIR/bsnbot.env
   export trader_version="$(curl -s https://api.github.com/repos/bsn-group/trader/commits |grep -oP '(?<=(\"sha\"\: \"))[^\"]*' |head -1)"
   export analyzer_version="$(curl -s https://api.github.com/repos/bsn-group/analyzer/commits |grep -oP '(?<=(\"sha\"\: \"))[^\"]*' |head -1)"
   export DbAdminConnection="${connectionString}"
   export ConnectionStrings__cryptodbConnection="${connectionString}"
   export ConnectionStrings__PostgresConnection="${connectionString}"
fi
echo ${connectionString}

if [[ -z ${POSTGRES_PASSWORD} ]]; then
    echo "db password not found"
    exit 1
else
    echo "db password found"
fi

if [[ -z $connectionString ]]; then
    echo "db connection string not found"
    exit 1
else
    echo "db connection string found"
fi

if  [[ $2 == "--live" ]]; then
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

if [ -z ${AWS_ACCESS_KEY_ID} ] && [ -z ${AWS_SECRET_ACCESS_KEY} ] && [ -z ${AWS_DEFAULT_REGION} ]; then
    echo "AWS_SECRET_ACCESS_KEY not found, using local queue"
else 
    echo "AWS_ACCESS_KEYS found"
fi

FILENAME="$ABSDIR/docker-compose.yml"
env
docker-compose -f $FILENAME down
#Removing images to pull latest images on every deployment
# docker image rm bsngroup/trader:latest
# docker image rm bsngroup/analyzer:latest
# docker image rm bsngroup/cryptobot-ui:latest
docker-compose -f $FILENAME up -d   