local love_compat = require("love_compat")
local globalWindow = require("engine.core.window")
-- depends:phil_state

-- fade to black and back
-- time is how long it should take to fade
-- scene_id is the scene we want to fade to
-- obj is the object that is doing the fading
-- can either be the scene or the ui
local fade_fns = {}

fade_fns.fade_in = function(time)
    local newFade = {
        time = time,
        w = globalWindow.game_width,
        h = globalWindow.game_height,
        blackness = 255
    }
    
    if time <= 0 then
        return nil
    end
    
    newFade.check = function(self, dt)
        -- fade in
        self.blackness = self.blackness - ((dt * 255) / self.time)
        if self.blackness <= 0 then
            -- the fade is invisible. so make it disappear
            self = nil
            phil_state:set_blocked(false)
        end
    end
    
    newFade.draw = function(self)
        love_compat.setColor(0, 0, 0, self.blackness)
        love.graphics.rectangle("fill", 0, 0, self.w, self.h)
        love_compat.setColor(255, 255, 255)
    end
    
    return newFade
end
    
fade_fns.fade_out = function(time, scene_id, obj)
    local newFade = {
        time = time,
        w = globalWindow.game_width,
        h = globalWindow.game_height,
        obj = obj,
        scene_id = scene_id,
        blackness = 0
    }
    
    if time <= 0 then
        return nil
    end
    
    -- set the game state to blocked
    phil_state:set_blocked(true)
    
    newFade.check = function(self, dt)
        -- fade out
        self.blackness = self.blackness + ((dt * 255) / self.time)
        if self.blackness >= 255 then
            self.blackness = 255
            self.obj:go(self.scene_id)
            table.insert(self.obj.objects, fade_fns.fade_in(self.time))
        end
    end
    
    newFade.draw = function(self)
        love_compat.setColor(0, 0, 0, self.blackness)
        love.graphics.rectangle("fill", 0, 0, self.w, self.h)
        love_compat.setColor(255, 255, 255)
    end
    
    return newFade
end

return fade_fns