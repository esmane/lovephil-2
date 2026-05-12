-- implements the phil_cursor module
local cursor_manager = {
    atlas_tex = nil,
    cursor_w = 0,
    cursor_h = 0,
    current_cursor = nil,
    default_cursor = nil,
    just_set = false
}

-- sets up the cursor manager
cursor_manager.setup = function(self, path_to_atlas, cursor_w, cursor_h)
    self.atlas_tex = love.graphics.newImage(path_to_atlas)
    self.cursor_w = cursor_w
    self.cursor_h = cursor_h
    self.current_cursor = nil
    self.default_cursor = nil
    self.just_set = false
end


-- okay, so the x and y are just the index of the cursor, not the coordinates
-- so the 3rd cursor in the row has an x of 2 regardless of the size of each cursor. (arrays start at 0)
-- the hot_x and hot_y coordinates are absolute relative to the atlas's origin
cursor_manager.create = function(self, x, y, hot_x, hot_y)
    local tex_w
    local tex_h
    tex_w, tex_h = self.atlas_tex:getDimensions()
    
    local off_x = x * self.cursor_w
    local off_y = y * self.cursor_h
    
    local cursor = {
        quad = love.graphics.newQuad(off_x, off_y, self.cursor_w, self.cursor_h, tex_w, tex_h),
        hot_x = hot_x - off_x,
        hot_y = hot_y - off_y
    }
    
    self.current_cursor = cursor
    self.default_cursor = cursor
    self.just_set = true
    
    return cursor
end

cursor_manager.draw = function(self, x, y)
    if self.current_cursor then
        love.graphics.draw(self.atlas_tex, self.current_cursor.quad, x, y, 0, 1, 1, self.current_cursor.hot_x, self.current_cursor.hot_y)
    end
    if not self.just_set then
        self.current_cursor = self.default_cursor
    end
    self.just_set = false
end

cursor_manager.set = function(self, cursor)
    if not self.just_set then
        self.current_cursor = cursor
        self.just_set = true
    end
end

cursor_manager.default = function(self, cursor)
    self.default_cursor = cursor
    self.current_cursor = cursor
end

return cursor_manager
