-- implements the phil_timer module
local timer_manager = {
    timers = {}
}


timer_manager.reset = function(self)
    for i in ipairs(self.timers) do
        self.timers[i] = nil
    end
end

timer_manager.create = function(self, time, action)
    -- new timer object
    local new_timer = {
        time = time,
        action = action
    }
    
    -- iterate over table, find first empty spot
    local first_empty_slot = nil
    for _, v in ipairs(self.timers) do
        if v == nil then
            first_empty_slot = v
            break
        end
    end
    
    -- if we found an empty slot, use it
    if first_empty_slot then
        self.timers[first_empty_slot] = new_timer
        return first_empty_slot
    end
        
    -- otherwise we need to emplace back
    table.insert(self.timers, new_timer)
    return #self.timers
end


timer_manager.stop = function(self, timer_index)
    self.timers[timer_index] = nil
end


timer_manager.check = function(self, dt)
    for i, v in ipairs(self.timers) do
        if v ~= nil then
            v.time = v.time - dt
            if v.time <= 0 then
                local action = v.action
                self.timers[i] = nil    -- in lua, v is a copy
                if action then
                    action()
                end
            end
        end
    end
end

return timer_manager