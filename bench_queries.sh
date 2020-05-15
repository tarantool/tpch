#!/usr/bin/env bash

function check_q {
	local query=queries/$*.sql
	(
		echo $query
		time ( sqlite3 TPC-H.db < $query  > /dev/null )
	)
}

# we need to execute all from 1 to 22
for i in `seq 1 22`; do
	check_q $i
	check_q $i
	check_q $i
	check_q $i
done
