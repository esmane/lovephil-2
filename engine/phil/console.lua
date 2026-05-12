local components = require("engine.components.components")

-- implements the phil_console module
local console = {
    text_lns = {},
    x = 0,
    y = 0,
    w = 0,
    time = 0,
    timed = false
}

console.setup = function(self, x, y, w)
    self.x = x
    self.y = y
    self.w = w
    self.text_lns = {}
    self.time = 0
    self.timed = false
end

console.clear = function(self)
    for i in ipairs(self.text_lns) do
        self.text_lns[i] = nil
    end
    self.timed = false
end

console.set = function(self, text, color, align, time)
    for i in ipairs(self.text_lns) do
        self.text_lns[i] = nil
    end
    
    local offset_x = 0
    if align == TEXT_ALIGN_RIGHT then
        offset_x = self.w
    elseif align == TEXT_ALIGN_CENTER then
        offset_x = self.w / 2
    end

    components.createText(text, self.x + offset_x, self.y, self.w, color, align, self.text_lns)
    if time then
        self.time = time
        self.timed = true
    else
        self.timed = false
    end
end

console.check = function(self, dt)
    if self.timed then
        self.time = self.time - dt
        if self.time <= 0 then
            self:clear()
        end
    end
end

console.draw = function(self)
    for _, v in ipairs(self.text_lns) do
        v:draw()
    end
end

return console
