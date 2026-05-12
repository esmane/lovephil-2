local components = require("engine.components.components")
local createFade = require("engine.components.fade")

-- the module
local createScene = function()
    local scene = {}

    -- a table of all the textures the scene contains
    -- and videos too
    scene.textures = {}

    -- a table of all the objects (components) the scene contains
    scene.objects = {}

    -- the name of the last loaded scene
    scene.id = nil
    scene.req_break = false

    -- main callbacks
    scene.check = function(self, dt)
        local ret = nil
        self.req_break = false
        for _, v in ipairs(self.objects) do
            ret = v:check(dt)
            if ret ~= nil then
                ret()
                -- must break early if we clear the scene
                if self.req_break then
                    break
                end
            end
        end
    end
    
    scene.draw = function(self)
        for _, v in ipairs(self.objects) do
            v:draw()
        end
    end

    -- functions
    scene.clear = function(self, count)
        self.req_break = true
        if not count then
            for i in ipairs(self.objects) do
                self.objects[i] = nil
            end
        else
            if count > 0 then
                for _ = 1, count do
                    table.remove(self.objects)
                end
            end
        end
    end
    
    scene.clear_interactive = function(self)
        self.req_break = true
        for i in ipairs(self.objects) do
            if self.objects[i].interactive then
                self.objects[i] = components.createEmpty()
            end
        end
    end
    
    scene.get_size = function(self)
        return #self.objects
    end

    scene.go = function(self, scene_id, fade_time)
        if not fade_time then
            self.id = scene_id
            self:clear()
            _G[scene_id]()

            -- collect garabage
            -- after creating the new scene, we clear all of our references to textures
            -- before this call, there are at least two references to each scene texture
            -- one in our textures{} table
            -- and one in the component that is using the texture
            -- since deleting the reference here does not delete the reference in the component
            -- it is okay to delete these references
            -- then when the scene is cleared the other references will be deleted
            -- and the textures will be marked to free
            -- we do not do this until after we have finished loading the new scene
            -- so if two scene elements use the same texture the texture is only loaded once
            -- it may be wise to call this even less frequently
            -- so that way textures used between scenes are only loaded once
            -- but instead i try to keep the memory usage down
            -- scene changes are relatively infrequent anyway
            for k in pairs(self.textures) do
                self.textures[k] = nil
            end
            collectgarbage()
        else
            table.insert(self.objects, createFade.fade_out(fade_time, scene_id, self))
        end
    end

    scene.reload = function(self)
        self:clear()
        _G[self.id]()
    end
    
    scene.get_id = function(self)
        return self.id
    end

    scene.getTexture = function(self, path)
        -- load image
        local tex = self.textures[path]
        if not tex then
            tex = love.graphics.newImage(path)
            self.textures[path] = tex
        end
        return tex
    end

    scene.add_picture = function(self, path, x, y, crop_x, crop_y, crop_w, crop_h)
        -- load image
        local tex = self:getTexture(path)
        
        -- optional crop
        local crop = nil
        if crop_w then
            crop = {
                x = crop_x,
                y = crop_y,
                w = crop_w,
                h = crop_h
            }
        end
            
        -- emplace back
        table.insert(self.objects, components.createPicture(tex, x, y, crop))
    end

    scene.add_hotspot = function(self, x, y, w, h, hover_action, click_action)
        table.insert(self.objects, components.createHotspot(x, y, w, h, hover_action, click_action))
    end
    
    scene.add_scrollspot = function(self, x, y, w, h, up_action, down_action)
        table.insert(self.objects, components.createScrollspot(x, y, w, h, up_action, down_action))
    end

    scene.add_button = function(self, path, crop_x, crop_y, x, y, w, h, hover_action, click_action)
        local tex = self:getTexture(path)
        table.insert(self.objects, components.createButton(tex, crop_x, crop_y, x, y, w, h, hover_action, click_action))
    end
    
    scene.add_text = function(self, text, x, y, w, color, align)
        components.createText(text, x, y, w, color, align, self.objects)
    end
    
    scene.add_textinput = function(self, text, x, y, w, color, clear, action)
        table.insert(self.objects, components.createTextInput(text, x, y, w, color, clear, action))
    end

    scene.add_video = function(self, path, x, y, loop, freeze, action)
        -- load the video
        local video = self.textures[path]
        if not video then
            video = love.graphics.newVideo(path)
            self.textures[path] = video
        end
        
        table.insert(self.objects, components.createVideo(video, x, y, loop, freeze, action))
    end

    scene.add_empty = function(self)
        table.insert(self.objects, components.createEmpty())
    end

    return scene
end

return createScene
