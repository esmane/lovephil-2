local love_compat = require("love_compat")
local table_stringify = require("table_stringify")

local SAVE_NAMES_FILE = "savenames.sav"
local SAVE_GAME_FILE_START = "s"
local SAVE_GAME_FILE_END = ".sav"


-- implements the phil_warp module
local warp = {
    slots = {}
}


-- functions for managing slots
warp.get_slot_count = function(self)
    return #self.slots
end

warp.get_slot_name = function(self, slot)
    local name = self.slots[slot]
    
    -- a blank line means no save for the slot
    if name == "" then
        name = nil
    end
    
    -- if we read an invalid index name will already equal nil
    return name
end


-- write and save the slot names to a file
-- these two are internal and should not be used by the game
warp.syncSlotNames = function(self)
    local names = ""
    for _, v in ipairs(self.slots) do
        names = names .. v .. "\n"
    end
    love.filesystem.write(SAVE_NAMES_FILE, names)
end

warp.loadSlotNames = function(self)
    for i in ipairs(self.slots) do
        self.slots[i] = nil
    end
    
    if love_compat.fileExists(SAVE_NAMES_FILE) then
        for line in love.filesystem.lines(SAVE_NAMES_FILE) do
            table.insert(self.slots, line)
        end
    end
end


-- save a table on a specific slot
warp.save = function(self, slot, name, save_data)
    -- sanitize name
    -- name must contain at least one printable character
    if string.find(name, "%g") then
        -- replace all nonprintable characters with a space
        name = string.gsub(name, "[^%g ]", "@")
    else
        name = "Untitled Save"
    end
    
    -- sanitize slot input
    if slot < 1 then
        -- invalid index
        -- you are not allowed to save on a slot < 1
        return false
    elseif slot > #self.slots then
        -- if we are appending onto the slots, append blank lines
        -- until we get to the correct slot
        for _ = #self.slots + 1, slot - 1 do
            table.insert(self.slots, "")
        end
        -- then sppend the name
        table.insert(self.slots, name)
    else
        -- if the slot already exists just overwrite the name
        self.slots[slot] = name
    end
    
    love.filesystem.write(SAVE_GAME_FILE_START .. slot .. SAVE_GAME_FILE_END, table_stringify.save(save_data))
    self:syncSlotNames()
    return true
end

-- delete the game saved on a specific slot
warp.delete = function(self, slot)
    if slot > 0 and slot <= #self.slots then
        if self.slots[slot] ~= "" then
            love.filesystem.remove(SAVE_GAME_FILE_START .. slot .. SAVE_GAME_FILE_END)
            self.slots[slot] = ""
            self:syncSlotNames()
            return true
        end
    end
     -- invalid index or already deleted
    return false
end

-- load the table saved on a specific slot
warp.load = function(self, slot)
    local data_str = love.filesystem.read(SAVE_GAME_FILE_START .. slot .. SAVE_GAME_FILE_END)
    if data_str then
        return table_stringify.load(data_str)
    end
    return nil
end

return warp