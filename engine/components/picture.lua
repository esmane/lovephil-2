-- a static visible picture
local createPicture = function(texture, x, y, crop)
    local new_picture = {
        x = x,
        y = y,
        tex = texture,
        quad = nil
    }
    
    if crop then
        local tex_w
        local tex_h
        tex_w, tex_h = texture:getDimensions()
        new_picture.quad = love.graphics.newQuad(crop.x, crop.y, crop.w, crop.h, tex_w, tex_h)
    end
    
    -- functions
    new_picture.check = function(self, dt)
        return nil
    end
    
    new_picture.draw = function(self)
        if self.quad then            
            love.graphics.draw(self.tex, self.quad, self.x, self.y)
        else
            love.graphics.draw(self.tex, self.x, self.y)
        end
    end
    
    return new_picture
end

return createPicture
