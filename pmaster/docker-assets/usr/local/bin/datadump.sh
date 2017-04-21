#!/usr/bin/env bash

while true
do
	sleep 30
	psql -c "INSERT INTO distributors (did, name) VALUES ('120', 'kevyn');"
done