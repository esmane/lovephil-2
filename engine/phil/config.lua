-- modifies: phil_audio
local globalWindow = require("engine.core.window")
local table_stringify = require("table_stringify")

local CONFIG_SAVE_NAME = "config.lua"

-- fullscreen constants
FULLSCREEN_MODE_WINDOWED = 0
FULLSCREEN_MODE_EXCLUSIVE = 1
FULLSCREEN_MODE_BORDERLESS = 2

-- implements the phil_config module
local config_state = {}


-- save and load settings
config_state.save = function(self)
    -- save the configuration
    local data = {
        video = globalWindow.config_data,
        audio = {
            enabled = phil_audio.enabled,
            vol = phil_audio.vol
        }
    }
    
    local str = table_stringify.save(data)
    love.filesystem.write(CONFIG_SAVE_NAME, str)
end

config_state.load = function(self)
    local str = love.filesystem.read(CONFIG_SAVE_NAME)
    if str then
        -- if the file existed and we were able to successfully load the data,
        --save it to our table
        local data = table_stringify.load(str)
        globalWindow.config_data = data.video
        
        self:set_audio_enable(data.audio.enabled)
        phil_audio.vol = data.audio.vol
    end
    -- and update the window
    globalWindow:update()
    globalWindow:updateScaleType()
    phil_audio:adjustVolumes()
end


-- video settings
-- fullscreen mode is a string. "w", "e", or "b" (windowed, exclusive, or borderless)
config_state.set_fullscreen = function(self, fullscreen_mode)
    if fullscreen_mode == FULLSCREEN_MODE_BORDERLESS then
        globalWindow.config_data.fullscreen = true
        globalWindow.config_data.exclusive_fullscreen = false
    elseif fullscreen_mode == FULLSCREEN_MODE_EXCLUSIVE then
        globalWindow.config_data.fullscreen = true
        globalWindow.config_data.exclusive_fullscreen = true
    else
        globalWindow.config_data.fullscreen = false
    end
    
    globalWindow:update()
end

config_state.get_fullscreen = function(self)
    if globalWindow.config_data.fullscreen then
        if globalWindow.config_data.exclusive_fullscreen then
            return FULLSCREEN_MODE_EXCLUSIVE
        else
            return FULLSCREEN_MODE_BORDERLESS
        end
    end
    return FULLSCREEN_MODE_WINDOWED
end

config_state.set_nn_scale = function(self, v)
    globalWindow.config_data.use_nn_scaling = v
    globalWindow:updateScaleType()
end

config_state.set_int_scale = function(self, v)
    globalWindow.config_data.force_integer_scale = v
    globalWindow:updateScaleFactor()
end

config_state.set_vsync = function(self, v)
    globalWindow.config_data.use_vsync = v
    globalWindow:update()
end

config_state.get_nn_scale = function(self)
    return globalWindow.config_data.use_nn_scaling
end

config_state.get_int_scale = function(self)
    return globalWindow.config_data.force_integer_scale
end

config_state.get_vsync = function(self)
    return globalWindow.config_data.use_vsync
end

-- audio settings
config_state.get_audio_enable = function(self)
    return phil_audio.enabled
end

config_state.get_volume = function(self, ilk)
    return phil_audio.vol[ilk]
end

config_state.set_audio_enable = function(self, enabled)
        if not enabled then
        phil_audio:stop()
    end
    phil_audio.enabled = enabled
end

config_state.set_volume = function(self, ilk, vol)
    vol = math.max(vol, 0)
    vol = math.min(vol, 1)
    phil_audio.vol[ilk] = vol
    phil_audio:adjustVolumes()
end


return config_state
