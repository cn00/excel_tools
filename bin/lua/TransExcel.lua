
local CS = CS
local System = CS.System
local NPOI = CS.NPOI
local Mono = CS.Mono
local HWorkbook = NPOI.HSSF.UserModel.HSSFWorkbook
local XWorkbook = NPOI.XSSF.UserModel.XSSFWorkbook

local util = require "util"


local function TransOneExcel(path, dicdb)
    if  true
    	and path:sub(-5) ~= ".xlsx" 
    	and path:sub(-4) ~= ".xls" 
    	or nil ~= path:match("~") 
    	or dicdb == nil 
    then return end

    print("TransOne",path)
    local wb
    if      path:sub(-5) == ".xlsx" then
    	wb = XWorkbook(path)
    elseif path:sub(-4) == ".xls" then
    	local inStream = System.IO.FileStream(path, System.IO.FileMode.Open);
    	wb = HWorkbook(inStream)
    	inStream:Close()
    end

    local count = 0
    local cmd = dicdb:CreateCommand();
    local values = {[[SELECT s, zh FROM dic WHERE s in (]]}
    local lastJpStr
    local cellCach = {
    	--[[
	    	[s] = {cell, ...},
    	]]
    }
    for i=0,wb.NumberOfSheets - 1 do
	    local sheet = wb:GetSheetAt(i)
	    for ii = sheet.FirstRowNum, math.min(sheet.LastRowNum, sheet.FirstRowNum+10000) do
	        local row = sheet:GetRow(ii)
	        if row ~= nil then
	            for jjj = row.FirstCellNum, math.min(row.LastCellNum - 1, row.FirstCellNum+256) do
	                local cell = row:GetCell(jjj)
	                if cell ~= nil then 
	                    local str = cell.SValue:gsub("'", "''")
	                    if util.JpMatch(str).Count > 0 then
	                    	lastJpStr = str
		                    -- print(ii, jjj, lastJpStr)
	                    	values[1+#values] = "'" .. lastJpStr .. "',"
	                    	local cache = cellCach[lastJpStr] or {}
	                    	cache[1+#cache] = cell
	                    	cellCach[lastJpStr] = cache
					   end
	                end
	            end
	        end
	    end -- sheet

    end

    local jpTable = {"INSERT INTO alljp (s, src) VALUES "}
    local currentRow
    for k,v in pairs(cellCach) do
    	-- print(k,v)
        currentRow= "(" 
            .. "'"  .. k .. "'"
            .. ",'" .. path .. ":" .. v.Sheet.SheetName .. "'"
            ..")"
        jpTable[1+#jpTable] = currentRow .. ","
    end
    jpTable[#jpTable] = currentRow .. " ON CONFLICT(s) DO UPDATE SET src = src || '#' || excluded.src;"
	local sql = table.concat(jpTable, "\n")
    local reader = cmd:ExecuteReader();
    reader:Dispose()


    if #values > 1 then 
    	values[#values] = "'" .. lastJpStr .. "')" 
    else
    	return
    end

	sql = table.concat(values, "\n")
    local f = io.open("tmp.sql", "w")
    f:write(sql)
    f:close()
    local fsql = "sql/".. path:gsub("/", "_") ..".sql"
    if(not System.IO.File.Exists(fsql))then 
    	System.IO.File.Copy("tmp.sql", fsql, false)
    end
	-- print(sql)

    cmd.CommandText = sql;
    local reader = cmd:ExecuteReader();
    while (reader:Read()) do
    	local jp = reader:GetTextReader(0):ReadToEnd()
        local zh = reader:GetTextReader(1):ReadToEnd()
    	-- print(jp, "->", zh)
    	local cache = cellCach[jp]
    	if cache ~= nil then
    		for i,v in ipairs(cache) do
    			-- print(i,v)
		        v:SetCellValue(zh)
		        count = 1+count
    		end
	    end
    end
    reader:Dispose()

    print("translate", count)

    System.IO.File.Delete(path)
    local outStream = System.IO.FileStream(path, System.IO.FileMode.CreateNew);
    outStream.Position = 0;
    wb:Write(outStream);
    outStream:Close();
end

return TransOneExcel
