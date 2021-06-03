#!/bin/env bash

function exit_required_envvar()
{
    echo "Environment variable $1 is required for the script to work, please set it"
    exit 127
}

cp -f config-template.xml /tmp/config.xml
cp -f ezstream.xml /tmp/ezstream.xml

# REQUIRED ENVVARS
for required in SOURCE_PASSWORD RELAY_PASSWORD ADMIN_USERNAME ADMIN_PASSWORD QUEUE_SERVER PLAY_DEVICE RECORD_DEVICE
do
    if [[ `eval "if [[ -z "'$'"$required ]]; then echo 'no'; else echo 'yes'; fi"` == 'no' ]]
    then
        exit_required_envvar $required
    else
	val=`eval "echo "'$'"$required"`
        sed -i "s/__${required}__/$val/g" /tmp/config.xml    
        sed -i "s/__${required}__/$val/g" /tmp/ezstream.xml
    fi
done

# todo autodetect free devices, maybe use 
# -N, --nonblock
#    Open the audio device in non-blocking mode. 
#    If the device is busy the program will exit immediately. 
#    If this option is not set the program will block until the audio device is available again.

/usr/bin/icecast2 -c /tmp/config.xml&

tail -f /tmp/*.log&
sleep 3
. player.sh
player_start

ffmpeg -f alsa -i $RECORD_DEVICE -f ogg -q:a 6  - |  ezstream -c /tmp/ezstream.xml

