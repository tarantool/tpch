box.cfg{ listen = 3301, memtx_memory = 10 * 1024^3 }

local ffi = require 'ffi'

-- should obey topological sort order
-- to not violate foreign key constraints
tables = {
  'region', 'nation', 'part', 'supplier',
  'partsupp', 'customer', 'orders', 'lineitem'
  }
for _, tblname in ipairs(tables) do
    local f = assert(io.open(string.format("tpch-dbgen/%s.tbl", tblname), 'rb'))
    print (tblname)

    while true do
        local line = f:read('*line')
        if not line then break end

        t = {}
        for s in string.gmatch(line, '[^|]+') do
          local cvt = tonumber(s)
          if cvt ~= nil then
            -- hack to prevent doubleness for normalized numbers, e.g. 901.00
            if string.match(s, '-?%d+%.%d+$') then
              cvt = ffi.cast('double', cvt)
            end
          else
            cvt = s
          end
          table.insert(t, cvt) 
        end
        tuple = box.tuple.new(t)
        -- print(tblname:upper())
        -- print(tuple)

        box.space[tblname:upper()]:insert(tuple)
        -- print(ok)
    end
    f:close()
end
