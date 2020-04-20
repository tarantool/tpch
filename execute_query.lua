local clock = require 'clock'
local getopt = require 'getopt'
local yaml = require 'yaml'

local repeatN = 4
local queryN = nil
local nonoptions = {}
local verbose = false
local dryrun = false

local port = 3301
local mem_size = 10 * 1024^3

local function config(portN, memSz)
    if not dryrun then
        box.cfg{ listen = portN, memtx_memory = memSz }
    end
end
local function exec_query(cdata)
    if verbose then
        print(cdata)
    end
    local res, err = nil, nil
    if not dryrun then
        res, err = box.execute(cdata)
        if verbose then
            if err ~= nil then
                print(err)
            else
                print(yaml.encode(res))
            end
        end
    end
    return res
end

local function bench(func)
    -- hopefully socket.gettime will provide us microsecond precision
    local t = clock.monotonic()

    for i=1,repeatN,1 do
        func()
    end
    t = clock.monotonic() - t
    
    -- ignore negligible timings
    if t < (0.002*repeatN) then
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
           not string.match(line, '^%-%-.*$')
        then
            -- print(line)
            table.insert(query, line)
        end
        if string.match(line, ';$') then break end
    end

    return table.concat(query, ' '):gsub('%s+', ' '):gsub(';', '')
end

local function single_query(q)
    local qname = string.format("queries/%s.sql", q)
    t_ = bench(
            function() 
                local query_line = flat_file_string(qname) -- qname captured
                exec_query(query_line)
            end)
    print("Q"..q .. ';' .. (t_ and t_ / repeatN or -1))
end

local function show_usage()
    print(arg[-1] .. ' ' .. arg[0],
        [[

            Usage: q:n:p:m:tv

            -q N .. execute query `queries/N.sql`
            -n N .. repeat N times
            -p N .. listen port N
            -m N .. memtix memory size
            -v   .. verbose (show results)
            -y   .. dry-run
        ]]
    )
end

-- if no arguments provided - process all queries
if #arg == 0 then
    for q = 1,22,1 do
        single_query(q)
    end
else
    for opt, arg in getopt(arg, 'q:n:p:m:yv', nonoptions) do
        if opt == 'q' then
            queryN = arg
        elseif opt == 'n' then
            repeatN = arg
        elseif opt == 'p' then
            portN = arg
        elseif opt == 'm' then
            mem_size = arg
        elseif opt == 'y' then
            dryrun = true
        elseif opt == 'v' then
            verbose = true
        elseif opt == '?' then
            show_usage()
            os.exit(1)
        end
    end

    config(portN, mem_size)

    assert(queryN)
    single_query(queryN)

    --[[

    print(repeatN, queryN, verbose)


    if #nonoptions >= 1 then
        print('error: wrong number of arguments: ' .. #nonoptions)
        os.exit(1)
    end

    ]]
end

os.exit(0)
