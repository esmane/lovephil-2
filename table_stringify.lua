--[[
	Save Table to File
	Load Table from File
	v 1.0-PHIL
	
	Lua 5.2 compatible
	
	Only Saves Tables, Numbers and Strings
	Insides Table References are saved
	Does not save Userdata, Metatables, Functions and indices of these
	----------------------------------------------------
	table_stringify.save( table )
	
	returns a string containing the table's data
	
	----------------------------------------------------
	table_stringify.load( stringtable )
	
	returns a table from the string that has been saved via the table.save function
	
	on success: returns a previously saved table
	on failure: returns as second argument an error msg
	----------------------------------------------------
	
	Licensed under the same terms as Lua itself.
]]--

-- original source: http://lua-users.org/wiki/SaveTableToFile
-- modified to write strings, not files
-- also modified to be local
-- also modified to support booleans

local table_stringify = {}

-- declare local variables
--// exportstring( string )
--// returns a "Lua" portable version of the string
local function exportstring( s )
	return string.format("%q", s)
end

--// The Save Function
function table_stringify.save(tbl)
	local charS,charE = "   ","\n"
    
    -- initiate variables for save procedure
	local tables,lookup = { tbl },{ [tbl] = 1 }
    local ret_str = "return {"..charE

	for idx,t in ipairs( tables ) do
		ret_str = ret_str.."-- Table: {"..idx.."}"..charE.."{"..charE
            
        for i,v in pairs( t ) do
            local str = ""
            local stype = type( i )
            -- handle index
            if stype == "table" then
                if not lookup[i] then
                    table.insert( tables,i )
                    lookup[i] = #tables
                end
                str = charS.."[{"..lookup[i].."}]="
            elseif stype == "string" then
                str = charS.."["..exportstring( i ).."]="
            elseif stype == "number" then
                str = charS.."["..tostring( i ).."]="
            end
				
            if str ~= "" then
                stype = type( v )
                -- handle value
                if stype == "table" then
                    if not lookup[v] then
                        table.insert( tables,v )
                        lookup[v] = #tables
                    end
                    ret_str = ret_str..str.."{"..lookup[v].."},"..charE
                elseif stype == "string" then
                    ret_str = ret_str..str..exportstring( v )..","..charE
                elseif stype == "number" then
                    ret_str = ret_str..str..tostring( v )..","..charE
                elseif stype == "boolean" then
                    local b_str = "false"
                    if v then b_str = "true" end
                    ret_str = ret_str..str..b_str..","..charE
                end
            end
        end
        ret_str = ret_str.."},"..charE
	end
    ret_str = ret_str.."}"
    return ret_str
end
	
--// The Load Function
function table_stringify.load(string)
	local ftables,err = loadstring(string)
	if err then return _,err end
	local tables = ftables()
	for idx = 1,#tables do
		local tolinki = {}
		for i,v in pairs( tables[idx] ) do
			if type( v ) == "table" then
				tables[idx][i] = tables[v[1]]
			end
			if type( i ) == "table" and tables[i[1]] then
				table.insert( tolinki,{ i,tables[i[1]] } )
			end
		end
		-- link indices
		for _,v in ipairs( tolinki ) do
			tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
		end
	end
	return tables[1]
end

return table_stringify

-- ChillCode