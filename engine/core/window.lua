local love_compat = require("love_compat")

-- the global window, render context, whatever you want to call it
-- basically wraps love to guarantee the window is always the same size
local window = {
    scale_factor = 1,
    offset_x = 0,
    offset_y = 0,
    game_width = 640,
    game_height = 480,
    render_buffer = nil,
    
    config_data = {
        fullscreen = true,
        exclusive_fullscreen = false,
        force_integer_scale = false,
        use_nn_scaling = false,
        use_vsync = false
    }
}

-- create the render buffer
window.init = function(self, width, height)
    self.game_width = width
    self.game_height = height
    self.render_buffer = love.graphics.newCanvas(width, height)
end

-- recreate the window (switch mode)
-- sets fullscreen mode and vsync
window.update = function(self)
    -- set the window flags we would like to change
    local window_flags = {
        fullscreen = self.config_data.fullscreen,
        fullscreentype = "desktop",
        vsync = self.config_data.use_vsync
    }
    
    if self.config_data.exclusive_fullscreen then
        window_flags.fullscreentype = "exclusive"
    end


    -- set the mode
    love_compat.updateMode(self.game_width, self.game_height, window_flags)
    
    -- we need to update the scale factor because the size of the window may have changed
    self:updateScaleFactor()
end

-- update the scale factor
window.updateScaleFactor = function(self)
    -- get the actual size of the window
    local window_w
    local window_h
    window_w, window_h = love.graphics.getDimensions()
    
    -- calculate the scale factor
    local scale_x = window_w / self.game_width
    local scale_y = window_h / self.game_height
    self.scale_factor = math.min(scale_x, scale_y)
    if self.config_data.force_int_scale then
        self.scale_factor = math.floor(self.scale_factor)
    end
    
    local draw_w = self.game_width * self.scale_factor
    local draw_h = self.game_height * self.scale_factor

    self.offset_x = (window_w - draw_w) / 2
    self.offset_y = (window_h - draw_h) / 2
    
    -- since the size of the window has potentially changed, we want to clear it's framebuffer
    local temp_canvas = love.graphics.getCanvas()
    love.graphics.setCanvas()
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setCanvas(temp_canvas)
end

-- update the scale filter mode
window.updateScaleType = function(self)
    local scale_type = "linear"
    if self.config_data.use_nn then
        scale_type = "nearest"
    end
    self.render_buffer:setFilter(scale_type)
end


-- get mouse coordinates in game
window.getCoordinates = function(self, x, y)
    local sx = (x - self.offset_x) / self.scale_factor
    local sy = (y - self.offset_y) / self.scale_factor
    sx = math.floor(sx)
    sy = math.floor(sy)
    return sx, sy
end


-- update the window
window.draw = function(self)
    love.graphics.clear(0, 0, 0, 0) -- clear the buffer
	love.graphics.setCanvas(self.render_buffer) -- set render target to the buffer
    love.graphics.setBlendMode("alpha", "alphamultiply")
    love.graphics.clear(0, 0, 0, 0) -- clear the buffer
	love.draw() -- render game to buffer
    love.graphics.setCanvas() -- set render target to window
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.draw(self.render_buffer, self.offset_x, self.offset_y, 0, self.scale_factor, self.scale_factor) -- render buffer to window, scaling appropriately
    love.graphics.present() -- update window
end


return window
