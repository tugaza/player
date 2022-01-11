#!/bin/env bash

function exit_required_envvar()
{
    echo "Environment variable $1 is required for the script to work, please set it"
    exit 127
}

cp -f config-template.xml /tmp/config.xml
cp -f ezstream.xml /tmp/ezstream.xml

# REQUIRED ENVVARS
for required in SOURCE_PASSWORD RELAY_PASSWORD ADMIN_USERNAME ADMIN_PASSWORD
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

bash app.sh

