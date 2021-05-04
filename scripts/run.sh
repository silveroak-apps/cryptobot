#!/bin/bash
set -o pipefail

if [[ `uname` == "Darwin" ]]; then
    ABSDIR=$(pwd -P)
else
    ABSPATH=$(readlink -f $0)
    ABSDIR=$(dirname $ABSPATH)
fi
echo $ABSDIR
if [[ -z bsnbot.env ]]; then
    echo 'Env file not found'
    echo export trader_version=$(curl -s https://api.github.com/repos/bsn-group/trader/commits |grep -oP '(?<=(\"sha\"\: \"))[^\"]*' |head -1) >> $ABSDIR/bsnbot.txt
    echo export analyzer_version=$(curl -s https://api.github.com/repos/bsn-group/analyzer/commits |grep -oP '(?<=(\"sha\"\: \"))[^\"]*' |head -1) >> $ABSDIR/bsnbot.txt
    echo POSTGRES_PASSWORD=$1 >> $ABSDIR/bsnbot.txt
    echo export _connectionString="Host=db;Port=5432;Username=postgres;Password=${POSTGRES_PASSWORD};Database=cryptodb;Pooling=true;Timeout=30;" >> $ABSDIR/bsnbot.txt
    echo export DbAdminConnection=${_connectionString} >> $ABSDIR/bsnbot.txt
    echo export ConnectionStrings__cryptodbConnection=${_connectionString} >> $ABSDIR/bsnbot.txt
    echo export ConnectionStrings__PostgresConnection=${_connectionString} >> $ABSDIR/bsnbot.txt
    cp bsnbot.txt bsnbot.env
fi
    
source bsnbot.env


if [[ -z ${POSTGRES_PASSWORD} ]]; then
    echo "db password not found"
    exit 1
else
    echo "db password found"
fi

if [[ -z ${_connectionString} ]]; then
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

if [[ `uname` == "Darwin" ]]; then
    ABSDIR=$(pwd -P)
else
    ABSPATH=$(readlink -f $0)
    ABSDIR=$(dirname $ABSPATH)
fi
FILENAME="$ABSDIR/docker-compose.yml"
env
docker-compose -f $FILENAME down
#Removing images to pull latest images on every deployment
# docker image rm bsngroup/trader:latest
# docker image rm bsngroup/analyzer:latest
# docker image rm bsngroup/cryptobot-ui:latest
docker-compose -f $FILENAME up -d   