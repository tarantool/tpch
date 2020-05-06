SCALE_FACTOR ?= 1
TPCHD = tpch-dbgen
DBGEN = $(TPCHD)/dbgen
QGEN = $(TPCHD)/qgen
TABLES = customer lineitem nation orders partsupp part region supplier
TABLE_FILES = $(foreach table, $(TABLES), $(TPCHD)/$(table).tbl)
TARANTOOL ?= tarantool
SQLITE_DB = TPC-H.db
TNT_DB = 00000000000000000000.snap

all: bench_sqlite bench_tnt

# TPC-H binaries and seed data
$(TABLE_FILES): $(DBGEN)
	cd $(TPCHD) && ./dbgen -v -f -s $(SCALE_FACTOR)
	chmod +r $(TABLE_FILES)

$(DBGEN) $(QGEN): $(TPCHD)/Makefile
	$(MAKE) -C $(TPCHD) all

# **optional step** regenerate TPC-H queries
# NB! you don't want to run it everytime:
# queries were manually changed to make 
# them SQLite compatible
gen-queries: $(QGEN)
	@mkdir -p queries/ > /dev/null
	./gen_queries.sh	

# SQLite: populate databases
$(SQLITE_DB): $(TABLE_FILES)
	./create_db.sh $(TABLES)

# Tarantool: populate database 
$(TNT_DB): $(TABLE_FILES)
	$(TARANTOOL) create_table.lua

# run benchmarks
bench_sqlite: $(SQLITE_DB)
	./bench_queries.sh

bench_tnt: $(TNT_DB)
	$(TARANTOOL) bench_query.lua -n 3 

# clean everything
clean: clean-tpch clean-sqlite clean-tnt

clean-tpch:
	$(MAKE) -C $(TPCHD) clean

clean-sqlite: clean-tpch
	rm -rf $(SQLITE_DB) $(TABLE_FILES)

clean-tnt:
	rm -f *.xlog *.snap

