#/bin/bash -x

log=bench.log

rm -f $log 
touch $log

function check_q {
	local query=queries/$*.sql
	(
		echo $query
		time ( sqlite3 TPC-H.db < $query  > /dev/null )
	) |& tee -a $log
}

# we need to execute all from 1 to 22
# with exception of 17,20
# and of particular interest are: 7, 8, 9, 13
for i in 7 8 9 13; do
	check_q $i
	check_q $i
	check_q $i
	check_q $i
done
exit 0

for i in 1 2 3 4 5 6 10 11 12 14 15 16 18 19 21 22; do
	check_q $i
	check_q $i
	check_q $i
	check_q $i
done

for i in 17 20; do
	check_q $i
	check_q $i
	check_q $i
	check_q $i
done

