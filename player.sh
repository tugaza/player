#!/bin/bash
function autoupdate() {
	while true; do ./youtube-dl -U; sleep 500; done
}

function download()
{
        if [[ ! -f /data/cache/$1 ]]
	then
    	    ./youtube-dl https://www.youtube.com/watch?v=$1 -x --audio-format "vorbis" --no-playlist --write-thumbnail --write-info-json -o "/data/cache/$1.%(ext)s"
	    mv /data/cache/$1.ogg /data/cache/$1
        fi
}

function peek_and_cache() {
    while true; do
        peekNext=`curl -d '{"vhost":"/","name":"youtube-playlist-queue","truncate":"50000","ackmode":"ack_requeue_true","encoding":"auto","count":"1"}' -q http://rabbits:rabbits@rabbits:15672/api/queues/%2f/youtube-playlist-queue/get 2>/dev/null | jq .[].payload | head | tr -d '"'`
	if [[ $peekNext == "" ]]
	then
	    peekNext=`curl -d '{"vhost":"/","name":"idle-queue","truncate":"50000","ackmode":"ack_requeue_true","encoding":"auto","count":"1"}' -q http://rabbits:rabbits@rabbits:15672/api/queues/%2f/idle-queue/get 2>/dev/null | jq .[].payload | head | tr -d '"'`
	
	fi
	if [[ $peekNext != "" ]]
	then
	    if [[ `echo $peekNext | egrep -v '^cust' -c` -gt 0 ]]
	    then
		download $peekNext
	    else
		echo "$peekNext is custom file"
	    fi
	fi
	sleep 10
    done
}

function skip_token_generate {
    while true; do redis-cli -h redis incr skipcounter; sleep 3600; done;
}

function player_start() {
    autoupdate&
    skip_token_generate&
    main&
    peek_and_cache&
}

function play() {
    cat /data/current_id > /data/previous_id
    echo $1 > /data/current_id
    if [[ -f /data/cache/$1 ]]
    then
	echo "Cache exists"
    else
	echo -e "\033[31;1mNo cache, downloading\033[37;1m"
	download $1
    fi
    killall -12 ezstream
    ffmpeg -i /data/cache/$1 2>&1 | grep "Duration" > /data/current_meta
    ffmpeg -i /data/cache/$1 -ar 48000 -ac 2 -f alsa $PLAY_DEVICE -vn 2>/volatile/ffout
    ret=$?
    if [[ $ret -eq 0 ]]
    then
	echo -e "\033[32mffmpeg clean exit\033[37;1m"    
    else
	cat /volatile/ffout >> /volatile/fffailures
        echo -e "\033[33;1mffmpeg exit status $ret\033[37;1m"
    fi
    return $ret
}    

function player_control() {
    pid=$1
    while kill -0 $pid; do
        command=`amqp-get -u $QUEUE_SERVER -q command-queue`
	ffpid=`ps ax | grep ffmpeg | grep /data/cache | sed -e 's/  //g' | sed -e 's/^ //g' | cut -d\  -f1`

        if [[ $command == "skip-remove" ]]
        then
            if [[ `redis-cli -h redis --raw get skipcounter` -gt 5 ]]
            then
		rm `ps ax | grep ffmpeg| grep /data/cache | rev | cut -d\  -f7 | rev`
                kill -9 $ffpid
                kill -9 $pid
                redis-cli -h redis decrby skipcounter 5
		redis-cli -h redis decr songcounter
		sleep 1
	        return 1
            fi
        fi
        if [[ $command == "skip" ]]
        then
            if [[ `redis-cli -h redis --raw get skipcounter` -gt 0 ]]
            then
                kill -9 $ffpid
                kill -9 $pid
		sleep 1
                redis-cli -h redis decr skipcounter
		return 0
            fi
        fi
        sleep 0.5
    done
    return 0
}

function main() {
    sleep 5
    while true
    do
        video=`amqp-get -u $QUEUE_SERVER -q youtube-playlist-queue`
	if [[ $? -gt 0 || $video == "" ]]
	then
		echo -e "\033[31;1mFailed to get video from queue, falling back to idle queue\033[37;1m"
		video=`amqp-get -u $QUEUE_SERVER -q idle-queue`
	else
		redis-cli -h redis decr inqueue
	fi
	if [[ $video != "" ]]
	then
	    echo -e "\033[32mPlaying video $video\033[37;1m"
	    play $video&
    	    player_pid=$!
    	    player_control $player_pid&
    	    player_control_pid=$!
    	    wait $player_pid
		if wait $player_control_pid
		then
			echo -e "\033[32mAdding video to idle queue\033[37;1m"
			amqp-publish -u $QUEUE_SERVER -e idle-queue -r idle-queue -p -b $video
		fi
	else
		echo -e "\033[32mPlayback failed\033[37;1m"
	fi
	sleep 2
	video=""
    done
}