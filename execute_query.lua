-- box.cfg{ listen = 3301, memtx_memory = 10 * 1024^3 }

local function exec_query(cdata)
    print(cdata)
    return box.execute(cdata)
end

--[[ 
ok, error = exec_query [[
        select
	l_returnflag,
	l_linestatus,
	sum(l_quantity) as sum_qty,
	sum(l_extendedprice) as sum_base_price,
	sum(l_extendedprice * (1 - l_discount)) as sum_disc_price,
	sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as sum_charge,
	avg(l_quantity) as avg_qty,
	avg(l_extendedprice) as avg_price,
	avg(l_discount) as avg_disc,
	count(*) as count_order
from
	lineitem
where
	l_shipdate <= date('1998-12-01', '-71 days')
group by
	l_returnflag,
	l_linestatus
order by
	l_returnflag,
        l_linestatus;
]]
--]]

--[[
if ok == nil then
    print(error)
end
--]]

local function flat_file_string(qname) 
        local f = assert(io.open(qname, "rb"))
        print (qname)
        local query = {}
        local line
        while true do
                line = f:read('*line')
                if not line then break end
                line = string.gsub(line, '%s+', ' ')

                -- skip empty lines or comments
                if not string.match(line, '^%s*$') and
                not string.match(line, '^%-%-.*$') then
                
                -- print(line)
                table.insert(query, line)
                end
                if string.match(line, ';$') then break end
        end

        local flatten = table.concat(query, ' '):gsub('%s+', ' '):gsub(';', '')
        return flatten
end

for q = 1,22,1 do
    local qname = string.format("queries/%s.sql", q)
    print(flat_file_string(qname))
end


-- os.exit(0)