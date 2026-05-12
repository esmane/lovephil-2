-- a visible hotspot
local createHotspot = require("engine.components.hotspot")

local createButton = function(texture, crop_x, crop_y, x, y, w, h, hover_action, click_action)
    local new_button = {
        interactive = true,
        hotspot = nil,
        tex = texture,
        quad = nil,
        crop_x = crop_x,
        crop_y = crop_y
    }
    
    new_button.hotspot = createHotspot(x, y, w, h, hover_action, click_action)
    
    local tex_w
    local tex_h
    tex_w, tex_h = texture:getDimensions()
    new_button.quad = love.graphics.newQuad(crop_x, crop_y, w, h, tex_w, tex_h)
    
    -- functions
    new_button.check = function(self, dt)
        local ret = self.hotspot:check()
        if self.hotspot.pressed then
            self.quad:setViewport(self.crop_x + (self.hotspot.w * 2), self.crop_y, self.hotspot.w, self.hotspot.h)
        elseif self.hotspot.hovered then
            self.quad:setViewport(self.crop_x + (self.hotspot.w    ), self.crop_y, self.hotspot.w, self.hotspot.h)
        else
            self.quad:setViewport(self.crop_x               , self.crop_y, self.hotspot.w, self.hotspot.h)
        end
        return ret
    end
    
    new_button.draw = function(self)
        love.graphics.draw(self.tex, self.quad, self.hotspot.x, self.hotspot.y)
        self.hotspot:draw()
    end
    
    return new_button
end

return createButton
