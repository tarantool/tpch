#!/usr/bin/env bash

function check_q {
	local query=queries/$*.sql
	(
		echo $query
		time ( sqlite3 TPC-H.db < $query  > /dev/null )
	)
}

# we need to execute all from 1 to 22 (except 13, 17 and 20 in CI)
for i in 1 2 3 4 5 6 7 8 9 10 11 12 14 15 16 18 19 21 22; do
	check_q $i
	check_q $i
	check_q $i
done
