#!/bin/bash

DIR=`dirname "${BASH_SOURCE[1]}"`
SCRIPT_DIR=$DIR
GLOBAL_REPOSITORY_ADDRESS="https://raw.githubusercontent.com/tugaza/lib/master/repofile"
GLOBAL_CACHE_DIR="$DIR/cache"
MODULE_DIR="modules"
if [[ -f /sbin/md5 ]]
then
    MD5='/sbin/md5'
else
    MD5='/usr/bin/md5sum'
fi
# ERROR DEFINITIONS

ERROR_NOT_FOUND=101
ERROR_BAD_PROGRAMMER=1
ERROR_BAD_USER=2

IDLE_QUEUE="idle-queue"
REQUEST_QUEUE="youtube-playlist-queue"
COMMAND_QUEUE="command-queue"

INPUT_INTERFACE="inputs/ffmpeg-alsa"
OUTPUT_INTERFACE="outputs/ffmpeg-alsa"


STREAM_LOGFILE=/volatile/ffout
YTDL_CACHE_DIR=/data/cache
DEBUG_ENABLED=1