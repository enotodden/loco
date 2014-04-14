-- Loco
-- ====

-- Port of [Docco](http://jashkenas.github.io/docco/):
-- The original quick-and-dirty, hundred-line-long,
-- literate-programming-style documentation generator.
--
-- Loco outputs HTML alongside code for simple and easy documentation.
-- No javadoc or other crap, just markdown and code.
--
-- Comments are passed through Niklas Frykholm's Markdown module.
--
--
-- If you're reading this in a browser, this page is generated using loco.
--

local markdown = require("markdown")
local templates = {}

--## Utilities

-- String split function from Turbo.lua
function strsplit(str, sep, max, pattern)
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

-- Encodes a string to html entities..
-- This is used to avoid problems when html occurs inside
-- the source code.
function htmlentities(s)
    return string.gsub(s, "([^A-Za-z0-9_])", function (c)
        return string.format("&#%d;", string.byte(c))
    end)
end

--## Comment/Code splitter

-- `parse()`: Splits sourcecode into a list of {doc, code} pairs
function parse(code)
    local lines = strsplit(code, "\n")
    local sections = {}
    local has_code = false
    local docs_text = ""
    local code_text = ""
    if lines[1]:sub(1, 2) == "#!" then
        table.remove(lines, 1)
    end
    for i, line in ipairs(lines) do
        if line:match("^%s*%-%-.*$") and not line:match("^%s*%-%-|.*$") then
            -- If the line 'starts with' a comment and not with --|
            -- We use --| to avoid inclusion.
            -- This is useful in some cases where code is supposed to be
            -- commented out.
            if has_code then
                sections[#sections+1] = {
                    docs_text=docs_text,
                    code_text=code_text
                }
                has_code = false
                docs_text = ""
                code_text = ""
            end
            -- Remove the comment marker (--)
            docs_text = docs_text .. line:gsub("^%s*%-%-", "") .. "\n"
        else
            -- Not a comment
            has_code = true
            code_text = code_text .. line .. "\n"
        end
    end
    sections[#sections+1] = {
        docs_text=docs_text,
        code_text=code_text
    }
    return sections
end

--## HTML Generator

-- Make the html..
--
function generate_html(sections)
    local out = templates.header
    for i, section in ipairs(sections) do
        local docs_text = section.docs_text
        out = out .. string.format(templates.section,
                                   i,
                                   i,
                                   markdown(docs_text),
                                   htmlentities(section.code_text))
    end
    out = out .. templates.footer
    return out
end

function loco(source)
    return generate_html(parse(source))
end


--## HTML Templates

templates.header = [[
<!doctype html>
<html>
    <head>
        <link rel="stylesheet" href="http://cdnjs.cloudflare.com/ajax/libs/highlight.js/8.0/styles/tomorrow.min.css">
        <script src="http://cdnjs.cloudflare.com/ajax/libs/highlight.js/8.0/highlight.min.js"></script>
        <script src="http://cdnjs.cloudflare.com/ajax/libs/highlight.js/8.0/languages/lua.min.js"></script>
        <meta charset="utf-8"/>
        <style>
            body {
                font-family: 'Palatino Linotype', 'Book Antiqua', Palatino, FreeSerif, serif;
                font-size: 15px;
                line-height: 22px;
                color: #2B2B2B;
                margin: 0; padding: 0;
            }
            table td { border: 0; outline: 0; }
            td.docs {
                max-widht: 30rem;
                min-width: 30rem;
                min-height: 1rem;
                padding: 10px 25px 1px 50px;
                vertical-align: top;
                text-align: left;
            }
            td.code {
                padding: 30px 15px 16px 50px;
                width: 100%;
                vertical-align: top;
                border-left: 1px solid #e5e5ee;
            }
            pre, code {
                font-size: 14px;
                line-height: 22px;
                margin: 0; padding: 0;
            }
            .section-link {
                display: inline;
                text-decoration: none;
                color: rgba(0,0,0,0.1);
            }
            .section-link:hover {
                color: #2b2b2b;
                text-decoration: none;
            }
        </style>
    </head>
    <body>
        <div id="container">
            <table cellspacing=0 cellpadding=0>
                <tbody>
]]

templates.footer = [[
                </tbody>
            </table>
        </div>
        <script>
            hljs.initHighlightingOnLoad();
        </script>
    </body>
</html>
]]

templates.section = [[
<tr id="section-%d">
    <td class="docs"><a class="section-link" href="#section-%d">#</a>%s</td>
    <td class="code">
        <pre><code>%s</code></pre>
    </td>
</tr>
]]


--## Command line part

if arg and arg[0]:find("loco%.lua$") then
    local io = require("io")
    local os = require("os")

    local USAGE = [[
        lua loco.lua INPUTFILE
    or
        cat INPUTFILE | lua loco.lua
    ]]

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
    print(loco(source))
else
    return loco
end
