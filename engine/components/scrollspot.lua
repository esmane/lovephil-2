local love_compat = require("love_compat")
local globalInput = require("engine.core.input")
-- depends:phil_state

-- an invisible mouse-wheelable rectangle
local createScrollspot = function(x, y, w, h, up_action, down_action)
    local new_scrollspot = {
        interactive = true,
        x = x,
        y = y,
        w = w,
        h = h,
        up_action = up_action,
        down_action = down_action
    }
    
    -- functions
    new_scrollspot.check = function(self, dt)
        local ret = nil
        if globalInput.mouse_x >= self.x and
           globalInput.mouse_y >= self.y and
           globalInput.mouse_x <= self.x + self.w and
           globalInput.mouse_y <= self.y + self.h then
            -- mouse is inside
            if globalInput.scrolled_up then
                ret = self.up_action
            elseif globalInput.scrolled_down then
                ret = self.down_action
            end
        end
        return ret
    end
    
    new_scrollspot.draw = function(self)
        if phil_state.is_debug then
            love_compat.setColor(0, 255, 255)
            love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
            love_compat.setColor(255, 255, 255)
        end
    end
    
    return new_scrollspot
end

return createScrollspot
