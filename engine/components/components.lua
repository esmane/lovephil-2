-- wrapper for all the game object components
local components = {}
components.createVideo = require("engine.components.video")
components.createPicture = require("engine.components.picture")
components.createButton = require("engine.components.button")
components.createHotspot = require("engine.components.hotspot")
components.createText = require("engine.components.text")
components.createTextInput = require("engine.components.textinput")
components.createScrollspot = require("engine.components.scrollspot")

components.createEmpty = function()
    local new_empty = {}
    
    new_empty.check = function(self, dt)
        return nil
    end
    
    new_empty.draw = function(self)
        return nil
    end
    
    return new_empty
end

return components