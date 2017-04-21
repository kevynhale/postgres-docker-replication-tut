#!/usr/bin/env bash

STATES=(utah virginia california maryland texas indiana washington oregon nevada georgia)

get_random_state() {
	RANDOM=$$$(date +%s)
	echo ${STATES[$RANDOM % ${#STATES[@]} ]}
}

get_random_number() {
	echo $(($$$(date +%s) % 100000))
}

get_random_phrase() {
	ALL_NON_RANDOM_WORDS=/etc/postgresql/9.4/main/postgresql.conf
	non_random_words=`cat $ALL_NON_RANDOM_WORDS | wc -l` 
	random_number=`od -N3 -An -i /dev/urandom | awk -v f=0 -v r="$non_random_words" '{printf "%i\n", f + r * $1 / 16777216}'` 
    RESULT=$(sed `echo $random_number`"q;d" $ALL_NON_RANDOM_WORDS)
	echo $RESULT | tr -s ' '
}

while true
do
	sleep 3
	STATE=$(get_random_state)
	PHRASE=$(get_random_phrase)
	ID=$(get_random_number)
	psql -c "INSERT INTO entries (did, phrase, state) VALUES ('$ID', '$PHRASE', '$STATE');"
done	