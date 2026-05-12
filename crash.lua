local love_compat = require("love_compat")

local globalFont = require("engine.core.font")
local globalWindow = require("engine.core.window")

-- phil_bsod
local bsod = {}

bsod.fn = function()
    love.event.pump()
        
    for e, a in love.event.poll() do
        if e == "quit" then
            return 1
        elseif e == "keypressed" and a == "escape" then
            return 1
        end
    end
        
    love.graphics.clear(0, 0, 0, 0) -- clear the buffer
    love.graphics.setCanvas(globalWindow.render_buffer) -- set render target to the buffer
    love.graphics.clear(0, 0, 0, 0) -- clear the buffer
    love_compat.setColor(0, 0, 255)
    love.graphics.rectangle("fill", 0, 0, globalWindow.game_width, globalWindow.game_height)
    love_compat.setColor(255, 255, 255)
    phil_scene:draw()

    love.graphics.setCanvas() -- set render target to window
    love.graphics.draw(globalWindow.render_buffer, globalWindow.offset_x, globalWindow.offset_y, 0, globalWindow.scale_factor, globalWindow.scale_factor) -- render buffer to window, scaling appropriately
    love.graphics.present() -- update window
        
    if love.timer then
        love.timer.sleep(0.1)
    end
end

bsod.prep = function(msg)
    msg = tostring(msg)
    if love.audio then love.audio.stop() end
    phil_scene:clear()
    phil_scene:add_text("@hFATAL ERROR!@h", globalWindow.game_width / 2 + 1, 2, globalWindow.game_width - 2, {0, 0, 0}, TEXT_ALIGN_CENTER)
    phil_scene:add_text(msg, 8, globalFont.char_h * 2 + 2, globalWindow.game_width - 10, {0, 0, 0}, TEXT_ALIGN_LEFT)
    phil_scene:add_text("@hFATAL ERROR!@h", globalWindow.game_width / 2, 1, globalWindow.game_width - 2, nil, TEXT_ALIGN_CENTER)
    phil_scene:add_text(msg, 7, globalFont.char_h * 2 + 1, globalWindow.game_width - 10, nil, TEXT_ALIGN_LEFT)
    
    local trace = debug.traceback()
    local y = (((#phil_scene.objects - 2) / 2) * globalFont.char_h) + (globalFont.char_h * 3)
    for l in trace:gmatch("(.-)\n") do
		if not l:match("boot.lua") then
			l = l:gsub("stack traceback:", "@hstack traceback@h")
            phil_scene:add_text(l, 8, y + 2, globalWindow.game_width - 10, {0, 0, 0}, TEXT_ALIGN_LEFT)
			phil_scene:add_text(l, 7, y + 1, globalWindow.game_width - 10, nil, TEXT_ALIGN_LEFT)
            y = y + globalFont.char_h
		end
	end
end

bsod.new = function(msg)
    bsod.prep(msg)
    return bsod.fn
end

bsod.old = function(msg)
    bsod.prep(msg)
    while true do
        if bsod.fn() then
            return
        end
    end
end

return bsod
