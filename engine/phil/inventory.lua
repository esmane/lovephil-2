-- modifies: phil_cursor

local globalInput = require("engine.core.input")

-- implements the phil_inventory module
-- responsible for drawing the inventory window
-- and managing the inventory items
local inventory = {
    items = {},
    active_item = nil,
    
    atlas_tex = nil,
    visible = false,
    x = 0,
    y = 0,
    w = 0,
    h = 0,
    item_w = 0,
    item_h = 0,
    
    draw_offset = 1,  -- the item to start drawing on
    visible_items = {},
    req_visible_item_update = false,
    
    inspect_cursor = nil,
    noitem_cursor = nil,
    left_clicked = false,
    right_clicked = false
}


inventory.setup = function(self, path_to_atlas, item_w, item_h, x, y, w, h, inspect_cursor, noitem_cursor)
    self.items = {}
    self.active_item = nil
    phil_cursor:default(noitem_cursor)
        
    self.atlas_tex = love.graphics.newImage(path_to_atlas)
    self.visible = true
    
    self.item_w = item_w
    self.item_h = item_h
    self.x = x
    self.y = y
    self.w = w
    self.h = h

    self.draw_offset = 1
    
    self.inspect_cursor = inspect_cursor
    self.noitem_cursor = noitem_cursor
    
    self.visible_items = {}
    self.req_visible_item_update = true
    self.left_clicked = false
    self.right_clicked = false
end


inventory.create_item = function(self, x, y, action, cursor, obtained)
    local tex_w
    local tex_h
    tex_w, tex_h = self.atlas_tex:getDimensions()
    
    local new_item = {
        quad = love.graphics.newQuad(x * self.item_w, y * self.item_h, self.item_w, self.item_h, tex_w, tex_h),
        action = action,
        cursor = cursor,
        obtained = obtained
    }
    
    -- if the newly created item is obtained by default we must update the list of visible items to include it
    -- if the newly created item is not obtained by default, there's no need to update the list because nothing about it has changed
    -- because the new item is emplaced on the back and the index of no existing (visible) item will be changed
    if obtained then
        self.req_visible_item_update = true
    end
    
    table.insert(self.items, new_item)
    return #self.items
end


-- deal with items
inventory.has_item = function(self, item_index)
    return self.items[item_index].obtained
end

inventory.set_item = function(self, item_index, val)
    self.items[item_index].obtained = val
    self.req_visible_item_update = true
end

inventory.get_active_item = function(self)
    return self.active_item
end

inventory.set_active_item = function(self, item_index)
    if item_index then
        if self.items[item_index].cursor then
            self.active_item = item_index
            phil_cursor:default(self.items[item_index].cursor)
        end
    else
        self.active_item = nil
        phil_cursor:default(self.noitem_cursor)
    end
end


-- deal with the inventory window
inventory.scroll_up = function(self)
    if self.draw_offset > 1 then
        self.draw_offset = self.draw_offset - 1
    end
end

inventory.scroll_down = function(self)
    if self.draw_offset < #self.visible_items then
        self.draw_offset = self.draw_offset + 1
    end
end

inventory.toggle_visible = function(self, v)
    self.visible = v
end

inventory.check = function(self, dt)
    if self.req_visible_item_update then
        self:updateItems()
    end
    
    -- first, see if the mouse is within the boundaries of the inventory
    if globalInput.mouse_x >= self.x and
       globalInput.mouse_y >= self.y and
       globalInput.mouse_x <= self.x + (self.w * self.item_w) and
       globalInput.mouse_y <= self.y + (self.h * self.item_h) then
        -- see where the mouse is
        local row = math.floor((globalInput.mouse_y - self.y) / self.item_h)
        local col = math.floor((globalInput.mouse_x - self.x) / self.item_w)
        local sel_item = self.visible_items[col + (row * self.w) + self.draw_offset]
        if sel_item then
            -- see if a mouse button is being pressed
            if globalInput.left_clicked then
                self.left_clicked = true
            elseif self.left_clicked then
                -- process left click
                if self.active_item ~= sel_item then
                    if self.items[sel_item].cursor then
                        self.active_item = sel_item
                        phil_cursor:default(self.items[sel_item].cursor)
                    -- if the item does not have a cursor, it is an only inspectable item, and we will perform it's action when left clicked
                    elseif self.items[sel_item].action then
                        self.items[sel_item].action()
                    end
                else
                    self.active_item = nil
                    phil_cursor:default(self.noitem_cursor)
                end
                self.left_clicked = false
                
            elseif globalInput.right_clicked then
                self.active_item = nil
                phil_cursor:default(self.noitem_cursor)
                phil_cursor:set(self.inspect_cursor)
                
                self.right_clicked = true
            elseif self.right_clicked then
                -- process right click
                if self.items[sel_item].action then
                    self.items[sel_item].action()
                end
                self.right_clicked = false
            end
        else
            self.left_clicked = false
            self.right_clicked = false
        end
    else
        self.left_clicked = false
        self.right_clicked = false
        
        if globalInput.right_clicked then
            self.active_item = nil
            phil_cursor:default(self.noitem_cursor)
        end
    end
end

inventory.draw = function(self)
    local offset_x = self.x
    local offset_y = self.y
    for i = self.draw_offset, #self.visible_items do
        love.graphics.draw(self.atlas_tex, self.items[self.visible_items[i]].quad, offset_x, offset_y)
        offset_x = offset_x + self.item_w
        if offset_x >= self.x + (self.w * self.item_w) then
            offset_x = self.x
            offset_y = offset_y + self.item_h
            if offset_y >= self.y + (self.h * self.item_h) then
                break
            end
        end
    end
end


-- internal helper fn
inventory.updateItems = function(self)
    for i in ipairs(self.visible_items) do
        self.visible_items[i] = nil
    end
    
    for i, v in ipairs(self.items) do
        if v.obtained then
            table.insert(self.visible_items, i)
        end
    end
    self.req_visible_item_update = false
end

-- save/load fns
inventory.dump = function(self)
    local inv_state = {}
    for _, v in ipairs(self.items) do
        table.insert(inv_state, v.obtained)
    end
    return inv_state
end

inventory.load = function(self, state)
    for i, v in ipairs(state) do
        if i > #self.items then
            break
        end
        self.items[i].obtained = v
    end
    self.req_visible_item_update = true
end

return inventory
    