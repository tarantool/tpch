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

-- FIXME -- Q13 is 4h50mins long, Q17 - 48mins, and Q20 - 1h11mins
local excluded_tests = {} -- {13, 17, 20}

local function config(portN, memSz)
    if not dryrun then
        box.cfg{ listen = portN, memtx_memory = memSz }
    end
end

-- concatenate lines, but split by ';', if there
-- are multiple statements
local function sql_stmts(qname)
    local f = assert(io.open(qname, "rb"))
    return function()
        local query = {}
        local line

        while true do
            line = f:read('*line')
            if not line then return nil end
            line = string.gsub(line, '%s+', ' ')

            -- skip empty lines or comments
            if not string.match(line, '^%s*$') and
               not string.match(line, '^%-%-.*$')
            then
                table.insert(query, line)
            end
            -- FIXME - assumption that ; is trailing at the line
            if string.match(line, ';%s*$') then break end
        end

        return table.concat(query, ' '):gsub('%s+', ' '):gsub(';', '')
    end
end

local function exec_query(qname)
    local res, err = nil, nil
    local lines = sql_stmts(qname)
    for query_line in lines do
        if verbose then
            print(query_line .. ';;')
        end

        if not dryrun then
            res, err = box.execute(query_line)
            if verbose then
                if err ~= nil then
                    print(err)
                    return res
                else
                    print(yaml.encode(res))
                end
            end
        end
    end
    return res
end

local function bench(func)
    -- hopefully socket.gettime will provide us microsecond precision
    local t = clock.monotonic()

    for i=1,repeatN,1 do
        print('.')
        func()
    end
    t = clock.monotonic() - t
    
    -- ignore negligible timings
    if t < (0.002*repeatN) then
        return nil
    end

    return t / repeatN
end

local function single_query(q)
    local qname = string.format("queries/%s.sql", q)
    print(qname)
    t_ = bench(
            function() 
                exec_query(qname)
            end)
    print("Q"..q .. ';' .. (t_ and t_ or -1))
end

local function Set(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

local banned_set = Set(excluded_tests)

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

-- if no query selected - process all queries
if queryN == nil then
    for q = 1,22,1 do
        if banned_set[q] == nil then
            single_query(q)
        else
            print('Q'..q..';-2')
	end
    end
else
    assert(queryN)
    single_query(queryN)
end

os.exit(0)
