box.cfg{ listen = 3301, memtx_memory = 10 * 1024^3 }
local socket = require 'socket'

local function exec_query(cdata)
    print(cdata)
    return box.execute(cdata)
end

local function bench(func, iterations)
    -- hopefully socket.gettime will provide us microsecond precision
    local t = socket.gettime()

    for i=1,iterations,1 do
        func()
    end
    t = socket.gettime() - t
    
    -- ignore negligible timings
    if t < (0.001*iterations) then
        return nil
    end

    return t
end

local function flat_file_string(qname) 
    local f = assert(io.open(qname, "rb"))
    -- print (qname)
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

    return table.concat(query, ' '):gsub('%s+', ' '):gsub(';', '')
end

local repeatitions = 4
for q = 1,22,1 do
    local qname = string.format("queries/%s.sql", q)
    t_ = bench(
            function() 
                local query_line = flat_file_string(qname) -- qname captured
                exec_query(query_line)
            end, repeatitions)
    print("Q"..q .. ';' .. (t_ and t_ / repeatitions or -1))
end


os.exit(0)
