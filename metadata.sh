#!/bin/bash

test -z "${1}" && cat /data/cache/`cat /data/current_id`.info.json | jq .title | tr -d '"' 2> /dev/null
exit 0