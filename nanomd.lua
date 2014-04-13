--
-- nanomd - minimal Markdown alternative for docs and such.
--
-- Supports headings, bold, italic, underlined, links, code and 
-- 'TODO:-like labels.
--
-- See example.nmd for usage.
--
--
-- The MIT License (MIT)
-- 
-- Copyright (c) 2014 Espen Kåsa Notodden
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
-- 

local nanomd = {}

local function strsplit(str, sep, max, pattern)
    local record = {}
    if str:len() > 0 then
        local plain = not pattern
        max = max or -1
        local field=1 start=1
        local first, last = str:find(sep, start, plain)
        while first and max ~= 0 do
            record[field] = str:sub(start, first-1)
            field = field+1
            start = last+1
            first, last = str:find(sep, start, plain)
            max = max-1
        end
        record[field] = str:sub(start)
    end
    return record
end

function nanomd.nanomd(source)
    out = {}
    for i=1000,1,-1 do 
        source = source:gsub(string.rep("%>", i) .. "(.-)\n", 
                             "\n" .. string.rep("&nbsp;", i*4) .. "%1\n")
    end
    source = source:gsub("%[(.-)%]%((.-)%)", [[<a href="%2">%1</a>]]) 
    source = source:gsub("%`(.-)%`", "<code>%1</code>")
    source = source:gsub("%*%*(.-)%*%*", "<i>%1</i>")
    source = source:gsub("%_(.-)%_", "<u>%1</u>")
    source = source:gsub("%*(.-)%*", "<strong>%1</strong>")
    source = source:gsub("([A-Z]-)%:", "<strong>%1:</strong>")
    source = source:gsub("%=[a-zA-Z0-9_]+", [[<i id="%1"></i>]])
    source = source:gsub("######(.-)%\n", "<h6>%1</h6>")
    source = source:gsub("#####(.-)%\n", "<h5>%1</h5>")
    source = source:gsub("####(.-)%\n", "<h4>%1</h4>")
    source = source:gsub("###(.-)%\n", "<h3>%1</h3>")
    source = source:gsub("##(.-)%\n", "<h2>%1</h2>")
    source = source:gsub("#(.-)%\n", "<h1>%1</h1>")
    source = source:gsub("%-%-%--\n", "<hr/>\n")
    for i, line in ipairs(strsplit(source, "\n\n")) do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" then
            out[#out+1] =  "<p>" .. line .. "</p>"
        end
    end
    local result = table.concat(out, "\n")
    return result
end

if arg and arg[0]:find("nanomd%.lua$") then
    local io = require("io")
    local os = require("os")

    local USAGE = "\n  lua nanomd.lua INPUTFILE\n"

    local infile = arg[1]
    local source = ""
    for _, v in ipairs(arg) do
        -- If -h/--help is in the argument list
        -- print the usage message and exit
        if v == "--help" or v == "-h" then
            print(USAGE)
            os.exit(1)
        end
    end
    if (infile ~= nil and infile ~= "--") then
        -- User supplied an input file
        local f = io.open(infile)
        if f == nil then
            print(string.format("Could not open file '%s'", infile))
            os.exit(1)
        end
        source = f:read("*all")
    else
        -- No file specified, use stdin
        local f = io.input()
        source = f:read("*all")
    end
    print(nanomd.nanomd(source))
else
    return nanomd.nanomd
end
