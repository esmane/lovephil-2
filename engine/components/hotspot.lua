local love_compat = require("love_compat")
local globalInput = require("engine.core.input")
-- depends:phil_state

-- an invisible clickable rectangle
local createHotspot = function(x, y, w, h, hover_action, click_action)
    local new_hotspot = {
        interactive = true,
        x = x,
        y = y,
        w = w,
        h = h,
        hover_action = hover_action,
        click_action = click_action,
        pressed = false,
        hovered = false
    }
    
    -- functions
    new_hotspot.check = function(self, dt)
        local ret = nil
        if globalInput.mouse_x >= self.x and
           globalInput.mouse_y >= self.y and
           globalInput.mouse_x <= self.x + self.w and
           globalInput.mouse_y <= self.y + self.h then
            -- mouse is inside
            self.hovered = true
            ret = self.hover_action
            if globalInput.left_clicked then
                self.pressed = true
            elseif self.pressed then
                -- if the pressed flag is true,
                -- the mouse is inside the hotspot,
                -- but the button is no longer being pressed,
                -- that means the button was just released
                -- and the hotspot was checked
                ret = self.click_action
                self.pressed = false
            end
        else
            -- if the cursor is no longer in the hotspot,
            -- the hotspot is no longer being pressed,
            -- even if the button is still being held down
            self.pressed = false
            self.hovered = false
        end
        return ret
    end
    
    new_hotspot.draw = function(self)
        if phil_state.is_debug then
            love_compat.setColor(255, 0, 255)
            love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
            love_compat.setColor(255, 255, 255)
        end
    end
    
    return new_hotspot
end

return createHotspot
