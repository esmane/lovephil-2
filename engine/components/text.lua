local love_compat = require("love_compat")
local globalFont = require("engine.core.font")

TEXT_ALIGN_RIGHT = "r"
TEXT_ALIGN_CENTER = "c"
TEXT_ALIGN_LEFT = "l"

local fancyLength = function(str)
    local len = #str
    local _, count = str:gsub("@", "@")
    local _, unc = str:gsub("@@", "@@")
    count = count - (unc * 2)
    len = len - count * 2
    return len
end
    

local createTextLn = function(x, y, color, text)
    local new_text = {
        text = text,
        x = x,
        y = y
    }

    if color then
        new_text.color = color

        -- different draw fn for colored text
        new_text.draw = function(self)
            love_compat.setColor(new_text.color[1], new_text.color[2], new_text.color[3])
            globalFont:draw(self.text, self.x, self.y)
            love_compat.setColor(255, 255, 255)
        end
    end
    
    new_text.check = function(self, dt)
        return nil
    end
    
    if not new_text.draw then
        new_text.draw = function(self)
            globalFont:draw(self.text, self.x, self.y)
        end
    end
    
    return new_text
end

createTextMulti = function(text, x, y, w, color, align, tbl)
    local line_x = x    -- left align
    local new_string = ""
    local to_append = nil

    local char_w = globalFont.char_w
    local char_h = globalFont.char_h

    local max_len = w / char_w

    for word in string.gmatch(text, "%S+") do
        to_append = word
        if #new_string > 0 then
            to_append = new_string .. " " .. word
        end
        if #to_append <= max_len then
            new_string = to_append
        else
            if align == TEXT_ALIGN_CENTER then
                line_x = x - ((#new_string * char_w) / 2)
            elseif align == TEXT_ALIGN_RIGHT then
                line_x = x - (#new_string * char_w)
            end
            table.insert(tbl, createTextLn(line_x, y, color, new_string))
            new_string = word
            y = y + char_h
        end
    end
    -- after completing the loop, dump the leftovers
    if #new_string > 0 then
        if align == TEXT_ALIGN_CENTER then
            line_x = x - ((#new_string * char_w) / 2)
        elseif align == TEXT_ALIGN_RIGHT then
            line_x = x - (#new_string * char_w)
        end
        table.insert(tbl, createTextLn(line_x, y, color, new_string))
    end
end
        
return createTextMulti
