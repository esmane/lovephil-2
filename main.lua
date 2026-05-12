-- love compat should be the very first thing we load
local love_compat = require("love_compat")


-- game constants
-- font is baked into the game
local GAME_WIDTH = 640
local GAME_HEIGHT = 480
local FONT_CHAR_W = 7
local FONT_CHAR_H = 12
local FONT_CHAR_SP = 1
local FONT_PATH = "font.png"

local GAME_FILE = "phil.lua"


-- now create the game objects
-- global state
local globalWindow = require("engine.core.window")
local globalInput = require("engine.core.input")
local globalFont = require("engine.core.font")


-- phil modules
-- scene and ui are the same object basically so they are created like this
local createSceneObject = require("engine.phil.scene")    -- some scene components depend on state
phil_scene = createSceneObject()
phil_ui = createSceneObject()

-- rest of the phil modules
phil_audio = require("engine.phil.audio")
phil_state = require("engine.phil.state")    -- depends scene*, audio (this may be a problem techically)
phil_cursor = require("engine.phil.cursor")
phil_config = require("engine.phil.config")  -- depends audio
phil_warp = require("engine.phil.warp")
phil_timer = require("engine.phil.timer")
phil_inv = require("engine.phil.inventory")  -- depends cursor
phil_console = require("engine.phil.console")



-- custom love crash scene
local bsod = require("crash")



-- helper function for loading frame rate
local function determine_frame_rate(fallback_frame_rate)
    local _, _, win_flags = love.window.getMode()
    if win_flags.refreshrate > 0 then
        return win_flags.refreshrate
    end
    return fallback_frame_rate
end

-- entry point
function love.run()      
    -- set random seed before loading
	love.math.setRandomSeed(os.time())
    math.randomseed(os.time())

    -- disable text input
    love.keyboard.setTextInput(false)
    love.keyboard.setKeyRepeat(false)

    -- frame buffer
    globalWindow:init(GAME_WIDTH, GAME_HEIGHT)
    globalFont:setup(FONT_PATH, FONT_CHAR_W, FONT_CHAR_H, FONT_CHAR_SP)

    -- maintain a steady frame rate
	local dt = 0
    local frame_start_timestamp = 0
    local timestamp_dif = 0
    local min_dt = 1 / determine_frame_rate(60)
    
    -- We don't want the first frame's dt to include time taken by love.load.
    love.load()
	love.timer.step()

	-- Main loop time.
	while true do
        -- reset scroll
        globalInput.scrolled_up = false
        globalInput.scrolled_down = false
        
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
                        return a
					end
				end
                -- only call handlers if we are not blocked
                -- we do however allow quit to be called even if we are blocked
                if not phil_state.is_blocked then
                    love.handlers[name](a,b,c,d,e,f)
                end
			end
		end

		-- Update dt, as we'll be passing it to update
		love.timer.step()
        dt = love.timer.getDelta()
        frame_start_timestamp = love.timer.getTime()

		-- update
		love.update(dt)
        
        -- draw
        globalWindow:draw()
        
        -- if we are not using vsync, sleep to maintain frame rate
        if globalWindow.config_data.use_vsync then
            -- love devs have this for some reason
            -- love.timer.sleep(0.001)
        else
            -- so basically we want to see how long it took us to draw the previous frame
            timestamp_dif = love.timer.getTime() - frame_start_timestamp
            -- if it took us less time to draw the frame than we need to take to preserve our frame rate, sleep
            if timestamp_dif < min_dt then
                love.timer.sleep(min_dt - timestamp_dif)
            end            
        end
	end
end



-- input callbacks
function love.mousemoved(x, y)
    globalInput.mouse_x, globalInput.mouse_y = globalWindow:getCoordinates(x, y)
end

function love.mousepressed(x, y, button)
    if button == 1 then
        globalInput.left_clicked = true
    elseif button == 2 then
        globalInput.right_clicked = true
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        globalInput.left_clicked = false
    elseif button == 2 then
        globalInput.right_clicked = false
    end
end

function love.wheelmoved(x, y)
    if y > 0 then
        globalInput.scrolled_down = false
        globalInput.scrolled_up = true
    elseif y < 0 then
        globalInput.scrolled_down = true
        globalInput.scrolled_up = false
    else
        globalInput.scrolled_down = false
        globalInput.scrolled_up = false
    end
end

function love.keypressed(key)
    if key == "escape" then
        if game_pause then
            game_pause()
        end
    end

    if globalInput.text_input_enabled then
        if key == "left" then
            if globalInput.text_input_pos > 0 then
                globalInput.text_input_pos = globalInput.text_input_pos - 1
            end
        elseif key == "right" then
            if globalInput.text_input_pos < #globalInput.text_input_text then
                globalInput.text_input_pos = globalInput.text_input_pos + 1
            end
        elseif key == "backspace" then
            if globalInput.text_input_pos > 0 then
                globalInput.text_input_text = globalInput.text_input_text:sub(1, globalInput.text_input_pos - 1) .. globalInput.text_input_text:sub(globalInput.text_input_pos + 1)
                globalInput.text_input_pos = globalInput.text_input_pos - 1
            end
        elseif key == "delete" then
            globalInput.text_input_text = globalInput.text_input_text:sub(1, globalInput.text_input_pos) .. globalInput.text_input_text:sub(globalInput.text_input_pos + 2)
        elseif key == "return" then
            globalInput.text_input_is_submitted = true
            globalInput:deactivateTextInput()
        end
    -- d only toggles debug when not in text input mode
    elseif key == "d" then
        phil_state.is_debug = not phil_state.is_debug
    end
end

function love.textinput(t)
    -- don't allow control codes to be entered
    if t == "@" then
        return
    end
    
    if globalInput.text_input_enabled and #globalInput.text_input_text < globalInput.text_input_max_len then
        globalInput.text_input_text = globalInput.text_input_text:sub(1, globalInput.text_input_pos) .. t .. globalInput.text_input_text:sub(globalInput.text_input_pos + 1)
        globalInput.text_input_pos = globalInput.text_input_pos + 1
    end
end



function love.load()   
    if globalFont.tex and phil_scene and globalWindow.render_buffer and love_compat then
        -- if we have these subsystems loaded we can run our own bsod
        love.errorhandler = bsod.new
        love.errhand = bsod.old
    end
    
    phil_config:load()
    phil_warp:loadSlotNames()
    love.mouse.setVisible(false)
    
    -- fuse the system
    if love.filesystem.isFused() then
        print("(phil boot) running in fused mode.")
        local success = love.filesystem.mount(love.filesystem.getSourceBaseDirectory(), "")
        if success then
            print("(phil boot) mounted base path for reading.")
        else
            print("(phil boot) could not mount base path for reading.")
        end
    end

    -- load the game file. this should return a table of all the game scripts
    local chunk
    local err
    local ok = false
    local game_scripts = nil
    
    chunk, err = love.filesystem.load(GAME_FILE)
	if chunk then
        game_scripts = chunk()
	else
        print("(phil boot) error loading " .. GAME_FILE .. " file. could not load game!")
        print(err)
    end
    
    if game_scripts then
        for _, v in ipairs(game_scripts) do
            chunk, err = love.filesystem.load(v)
            if chunk then
                ok, err = pcall(chunk)
                if not ok then
                    print("(phil boot) error executing " .. v .. ":")
                    print(err)
                end
            else
                print("(phil boot) error loading " .. v .. ":")
                print(err)
            end
        end
    end
    
    if game_start then
        ok, err = pcall(game_start)
        if not ok then
            print("(phil boot) error executing 'game_start' function!")
            print(err)
            love.event.quit(1)
        end
    else
        print("(phil boot) could not find game_start function!")
        love.event.quit(1)
    end
end


function love.update(dt)
    if not phil_state.is_paused then
        phil_timer:check(dt)
        phil_console:check(dt)
        phil_inv:check(dt)
        phil_scene:check(dt)
    end
    -- always check ui and audioplayer
    phil_ui:check(dt)
    phil_audio:check(dt)
end

function love.draw()
    phil_scene:draw()
    phil_console:draw()
    phil_inv:draw()
    phil_ui:draw()

    if phil_state.is_debug then
        globalFont:draw("Current scene: @h".. phil_scene.id .. "@h / Current ui: @h".. phil_ui.id.."@h", 16, 16)
        globalFont:draw(globalInput.mouse_x .. ", " .. globalInput.mouse_y, 16, 16 + 12)
        globalFont:draw("FPS: " .. love.timer.getFPS(), 16, 16 + 24)
        phil_audio:draw()
    end
    
    phil_cursor:draw(globalInput.mouse_x, globalInput.mouse_y)
end
