#!/bin/bash

DIR=$(dirname "${BASH_SOURCE[0]}")
if [[ -f $DIR/bootstrap.sh ]]
then
    . "$DIR"/bootstrap.sh
else
    echo "bootstrap not found"
    exit 256
fi

if [[ -f /pki/certificate.pem && -f /pki/privatekey.pem ]]
then
    cat /pki/certificate.pem /pki/privatekey.pem > /tmp/everything.pem
fi

bootstrap_load_module "$INPUT_INTERFACE"
bootstrap_load_module "$OUTPUT_INTERFACE"
bootstrap_load_module util/ytdl
bootstrap_load_module player/player
bootstrap_load_module stream/stream

util_ytdl::start_autoupdate

stream::start

player::main_loop
