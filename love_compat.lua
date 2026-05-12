-- compatibility functions so game runs on different love versions
-- currently we support all versions > 0.10.0 (gotta have that video module)
local love_compat = {}

-- our game always uses 0-255 colors
-- so if we are running on love 11 or greater we need to convert from 255 to 0-1
local ver = 0
local min = 9
local rev = 0

ver, min, rev, _ = love.getVersion()


if ver > 10 then
    -- VERSION 11+ COMPAT FUNCTIONS
    -- if on version 11.0 or greater we need to convert color to bytes
    love_compat.colorToBytes = love.math.colorToBytes
    love_compat.colorFromBytes = love.math.colorFromBytes
    -- if on version 11.3 or greater these helper functions are provided for us
    -- if not then we implement them here
    if (type(love_compat.colorToBytes) ~= "function") or (type(love_compat.colorFromBytes) ~= "function") then
        love_compat.clamp01 = function(x)
            return math.min(math.max(x, 0), 1)
        end
        
        love_compat.colorToBytes = function(r, g, b, a)
            r = math.floor(love_compat.clamp01(r) * 255 + 0.5)
            g = math.floor(love_compat.clamp01(g) * 255 + 0.5)
            b = math.floor(love_compat.clamp01(b) * 255 + 0.5)
            a = a ~= nil and math.floor(love_compat.clamp01(a) * 255 + 0.5) or nil
            return r, g, b, a
        end
        love_compat.colorFromBytes = function(r, g, b, a)
            r = love_compat.clamp01(math.floor(r + 0.5) / 255)
            g = love_compat.clamp01(math.floor(g + 0.5) / 255)
            b = love_compat.clamp01(math.floor(b + 0.5) / 255)
            a = a ~= nil and love_compat.clamp01(math.floor(a + 0.5) / 255) or nil
            return r, g, b, a
        end
    end
            
    love_compat.getColor = function()
        local r
        local g
        local b
        local a
        r, g, b, a = love.graphics.getColor()
        r, g, b, a = love_compat.colorToBytes(r, g, b, a)
        return r, g, b, a
    end
    
    love_compat.setColor = function(r, g, b, a)
        love.graphics.setColor(love.math.colorFromBytes(r, g, b, a))
    end
    
    -- on version 11, there is an update mode function that we should use
    love_compat.updateMode = love.window.updateMode
    
else
    -- VERSION 10 COMPAT FUNCTIONS
    -- on version 0.10, these functions are fine as is
    love_compat.getColor = love.graphics.getColor
    love_compat.setColor = love.graphics.setColor
    
    -- on version 0.10, there is no update mode function
    -- so we have to implement one ourselves
    love_compat.updateMode = function(w, h, flags)
        -- get old flags
        local old_flags = nil
        _, _, old_flags = love.window.getMode()
        
        -- reuse already specified flags
        flags.msaa = old_flags.msaa
        flags.resizable = old_flags.resizable
        flags.borderless = old_flags.borderless
        flags.centered = old_flags.centered
        flags.display = old_flags.display
        flags.highdpi = old_flags.highdpi
        
        love.window.setMode(w, h, flags)
    end
end

-- VERSION 11 ONLY FUNCTION
if ver == 11 then
    -- on version 11 only, filesystem.exists is depreciated
    -- it is not on 0.10 and 12.0
    -- although the function still exists in version 11 it does cause a depreciated message to appear on the screen which we do not want
    love_compat.fileExists = function(file)
        local t = love.filesystem.getInfo(file)
        if t then
            return true
        end
        return false
    end
else
    love_compat.fileExists = love.filesystem.exists
end


return love_compat