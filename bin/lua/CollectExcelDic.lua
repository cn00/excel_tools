local CS = CS
local System = CS.System

local util = require "util"


function CollectExcelDic(path, db, language, version)
    if(path:sub(-5) == ".xlsx" and nil == path:match("~") )then return end

    language = language or "zh"
    version  = version or "default"

    print("CollectOne",path)
    local wb = Workbook(path)
    local sheet = wb:GetSheet('jp')
    local values = {
        "INSERT OR IGNORE INTO dic (s," .. language .. ",src) VALUES "
    }
    local currentRow
    for i = 1, math.min(sheet.LastRowNum, 10000) do
        local row = sheet:GetRow(i)
        if row ~= nil then
            -- for j = 0, row.LastCellNum - 1 do
            --     local cell = row:GetCell(j)
            --     if cell ~= nil then 
            --         print(i, j, row:GetCell(j).SValue)
            --     end
            -- end
            local cjp = row:GetCell(0)
            if cjp == nil then goto continue end
            local jp = cjp.SValue
            jp=jp:gsub("'", "''")

            local czh = row:GetCell(1)
            if czh == nil then goto continue end
            local zh = czh.SValue
            zh=zh:gsub("'", "''")
            if zh ~= '译文' and zh ~= '' then
                currentRow= "(" 
                    .. "'".. jp .."'," -- jp
                    .. "'".. zh .."'," -- zh
                    .. "'".. path .. ":" ..row:GetCell(5).SValue.."'" -- src
                    ..")"
                values[1+#values] = currentRow .. ","
            else
                print(jp:gsub("\n", "\\n"), zh)
            end
        end
        ::continue::
    end
    values[#values] = currentRow
        .. " ON CONFLICT(s) DO UPDATE SET "
        ..language.." = CASE WHEN "..language.." ISNULL OR "..language.." = '' THEN excluded."..language.. " ELSE " .. language .. " END"
        ..", src = '{"..language.."=\"'||excluded."..language.."||'\",src=\"'||excluded.src||\'\",v=\""..version.."\"},'||char(13)||src"
        .." WHERE "..language.." <> excluded."..language
        .. ";"
    -- values[1+#values] = "COMMIT;"

    local sql = table.concat(values, "\n")
    local cmd = db:CreateCommand();
    cmd.CommandText = sql;
    local reader = cmd:ExecuteReader();
    reader:Dispose()


    local f = io.open(path .. ".sql", "w")
    f:write(sql)
    f:close()
end


return CollectExcelDic