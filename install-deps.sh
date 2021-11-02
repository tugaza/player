#!/bin/bash

DIR=`dirname "${BASH_SOURCE[0]}"`
if [[ -f $DIR/bootstrap.sh ]]
then
    . $DIR/bootstrap.sh
else
    echo "bootstrap not found"
    exit 256
fi
rm -rf cache/*
rm -rf modules/logs
dependencies::depends "logs/logger"
rm -rf modules/queue
dependencies::depends "queue/client"
rm -rf modules/timeslots
dependencies::depends "timeslots/timeslots"
rm -rf modules/player/playlister
dependencies::depends "player/playlister"