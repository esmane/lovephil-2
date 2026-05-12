-- modifies: phil_scene, phil_audio
local globalInput = require("engine.core.input")

local ver_maj
local ver_min
local ver_patch
ver_maj, ver_min, ver_patch, _ = love.getVersion()

-- implements the phil_state module
-- module that control the global state
local state = {
    is_paused = false,
    is_blocked = false,
    is_debug = false,
    engine_name = "LovePhil v0.265.1 / LÖVE " .. ver_maj .. "." .. ver_min .. "." .. ver_patch
}

state.set_pause = function(self, v)
    self.is_paused = v
    if v then
        -- give the videos a chance to pause themselves
        phil_scene:check(0)
        phil_audio:pause()
    else
        phil_audio:resume()
    end
end

state.set_debug = function(self, v)
    self.is_debug = v
end

state.set_blocked = function(self, v)
    self.is_blocked = v
    if v then
        globalInput.mouse_x = -100
        globalInput.mouse_y = -100
        globalInput.left_clicked = false
        globalInput.right_clicked = false
        globalInput:deactivateTextInput()
    else
        local x, y = love.mouse.getPosition()
        love.event.push("mousemoved", x, y)
    end
end

state.get_pause = function(self)
    return self.is_paused
end

state.get_blocked = function(self)
    return self.is_blocked
end

state.get_debug = function(self)
    return self.is_debug
end

state.get_engine_name = function(self)
    return self.engine_name
end


state.get_textinput = function(self)
    return globalInput.text_input_text
end

state.quit = function(self)
    love.event.quit()
end

return state
