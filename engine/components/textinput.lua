local love_compat = require("love_compat")
local globalFont = require("engine.core.font")
local globalInput = require("engine.core.input")

local BLINK_DELAY = 0.3

local createTextInput = function(text, x, y, w, color, clear, action)
    local new_text_input = {
        interactive = true,
        text = text,
        x = x,
        y = y,
        color = nil,
        clear = clear,
        action = action,
        active = false,
        w = w,
        click = false,
        blink = true,
        blink_tks = 0
    }
    
    if color then
        new_text_input.color = color
    end
    
    new_text_input.check = function(self, dt)
        local ret = nil
        local just_clicked = globalInput.left_clicked
        -- process a click
        if (just_clicked) and (not self.click) then
            if globalInput.mouse_x >= self.x and
               globalInput.mouse_y >= self.y and
               globalInput.mouse_x <= self.x + self.w and
               globalInput.mouse_y <= self.y + globalFont.char_h then
                -- mouse is inside
                local mouse_pos = math.floor(((globalInput.mouse_x - self.x) / globalFont.char_w) + 0.5)
                
                if self.active then
                    -- if we were clicked inside ourselves, and we were active, we want to set the cursor
                    globalInput.text_input_pos = math.max(0, mouse_pos)
                    globalInput.text_input_pos = math.min(globalInput.text_input_pos, #globalInput.text_input_text)
                    self.blink = true
                    self.blink_tks = 0
                else
                    if self.clear then
                        self.text = ""
                    end
                    globalInput:activateTextInput(self.x, self.y, self.w, globalFont.char_h, self.text, mouse_pos, self.w / globalFont.char_w)
                    self.active = true
                    self.blink = true
                    self.blink_tks = 0
                end
            elseif self.active then
                -- only deactivate on click outside if we were activated
                -- mouse is not inside
                globalInput:deactivateTextInput()
                self.active = false
                ret = action
            end
        end
        
        if self.active then
            if self.text ~= globalInput.text_input_text then
                self.text = globalInput.text_input_text
                self.blink = true
                self.blink_tks = 0
            end
            
            -- enter was pressed
            if globalInput.text_input_is_submitted then
                self.active = false
                ret = action
            end
            
            self.blink_tks = self.blink_tks + dt
            if self.blink_tks > BLINK_DELAY then
                self.blink_tks = 0
                self.blink = not self.blink
            end                
        end
        
        self.click = just_clicked
        return ret
    end
    
    new_text_input.draw = function(self)
        if self.color then
            love_compat.setColor(self.color[1], self.color[2], self.color[3])
        end
        
        globalFont:draw(self.text, self.x, self.y)
        
        if self.active and self.blink then
            globalFont:draw("|", (self.x - (globalFont.char_w / 2)) + (globalInput.text_input_pos * globalFont.char_w), self.y)
        end
        
        if self.color then
            love_compat.setColor(255, 255, 255)
        end
    end
    
    -- if preset text is empty we should make the text input active by default
    if text == "" then
        globalInput:activateTextInput(x, y, w, globalFont.char_h, "", 1, w / globalFont.char_w)
        new_text_input.active = true
        new_text_input.blink = true
        new_text_input.blink_tks = 0
    end

    return new_text_input
end

return createTextInput
