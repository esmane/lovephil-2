local globalFont = require("engine.core.font")

local CHANNEL_COUNT = 8

SOUND_TYPE_SPEECH = 0
SOUND_TYPE_EFFECT = 1
SOUND_TYPE_MUSIC = 2
SOUND_TYPE_AMBIENT = 3

local audioPlayer = {
    enabled = true, -- the audio player is enabled
    vol = {},
    
    channels = {},
    pos = {0, 0, 0},
    t_pos = {0, 0, 0},
    ang = {0, 1},
    t_ang = {0, 1}
}

audioPlayer.vol[SOUND_TYPE_SPEECH] = 1
audioPlayer.vol[SOUND_TYPE_EFFECT] = 1
audioPlayer.vol[SOUND_TYPE_MUSIC] = 1
audioPlayer.vol[SOUND_TYPE_AMBIENT] = 1

local CHANNEL_EMPTY = 0 -- an empty channel
local CHANNEL_SOUND = 1 -- a channel that is playing a sound
local CHANNEL_DELAY = 2 -- a channel that is not currently playing a sound, but is delaying and will play one shortly

-- internal helper function to see if a channel has a sound loaded on it or not
audioPlayer.channelType = function(self, channel)
    if channel < 1 or channel > CHANNEL_COUNT then
        return CHANNEL_EMPTY
    end
    
    if self.channels[channel] then
        if self.channels[channel].source then
            return CHANNEL_SOUND
        else
            return CHANNEL_DELAY
        end
        
    end
    return CHANNEL_EMPTY
end

-- readjust volumes of all playing sounds
audioPlayer.adjustVolumes = function(self)
    if self.enabled then
        for i = 1, CHANNEL_COUNT do
            if self:channelType(i) == CHANNEL_SOUND then
                self.channels[i].source:setVolume(self.channels[i].base_vol * self.vol[self.channels[i].ilk])
            end
        end
    end
end


-- pause playback of a channel or the entire audio player
audioPlayer.pause = function(self, channel)
    local t
    if channel then
        t = self:channelType(channel)
        if t == CHANNEL_SOUND then
            self.channels[channel].source:pause()
            self.channels[channel].paused = true
        elseif t == CHANNEL_DELAY then
            self.channels[channel].paused = true
        end
    else
        for i = 1, CHANNEL_COUNT do
            t = self:channelType(i)
            if t == CHANNEL_SOUND then
                self.channels[i].source:pause()
                self.channels[i].paused = true
            elseif t == CHANNEL_DELAY then
                self.channels[i].paused = true
            end
        end
    end
end

-- stop playback of a channel or the entire audio player
audioPlayer.stop = function(self, channel)
    if channel then
        if self:channelType(channel) == CHANNEL_SOUND then
            self.channels[channel].source:stop()
        end
        self.channels[channel] = nil
    else
        for i = 1, CHANNEL_COUNT do
            if self:channelType(i) == CHANNEL_SOUND then
                self.channels[i].source:stop()
            end
            self.channels[i] = nil
        end
    end
end

-- resume playback of a channel or the entire audio player
audioPlayer.resume = function(self, channel)
    local t
    if channel then
        t = self:channelType(channel)
        if t == CHANNEL_SOUND then
            self.channels[channel].source:play()
            self.channels[channel].paused = false
        elseif t == CHANNEL_DELAY then
            self.channels[channel].paused = false
        end
    else
        for i = 1, CHANNEL_COUNT do
            t = self:channelType(i)
            if t == CHANNEL_SOUND then
                self.channels[i].source:play()
                self.channels[i].paused = false
            elseif t == CHANNEL_DELAY then
                self.channels[i].paused = false
            end
        end
    end
end


-- change the volume and/or position of a channel. you cannot change the type of sound or the action of a sound
audioPlayer.edit = function(self, channel, vol, location)
    local t = self:channelType(channel)
    -- adjust volume and location of timers too
    if t ~= CHANNEL_EMPTY then
        if vol then
            self.channels[channel].base_vol = vol
        end
        if location and self.channels[channel].paths then
            -- only layer sounds actually need base_loc set
            self.channels[channel].base_loc = location
        end
    end
    
    if t == CHANNEL_SOUND then
        if vol then
            self.channels[channel].source:setVolume(vol * self.vol[self.channels[channel].ilk])
        end
        if location then
            self.channels[channel].source:setPosition(location[1], location[2], location[3])
        end
    end
end


-- play a sound
audioPlayer.play = function(self, path, channel, ilk, vol, action, location, unimportant)
    if self.enabled then
        -- make sure channel is valid
        if channel < 1 or channel > CHANNEL_COUNT then
            return
        end
        
        -- kill existing sound if it exists
        if self:channelType(channel) == CHANNEL_SOUND then
            self.channels[channel].source:stop()
        end
        
        if not vol then
            vol = 1
        end
        
        self.channels[channel] = {
            source = love.audio.newSource(path, "stream"),
            ilk = ilk,
            paused = false,
            action = action,
            
            base_vol = vol,
            base_loc = nil,  -- used only for multi sounds
            delay = nil,     -- used only for multi sounds
            paths = nil,     -- used only for multi sounds
            max_delay = nil, -- used only for multi sounds
            min_delay = nil, -- used only for multi sounds
            
            path = path
        }

        self.channels[channel].source:setVolume(vol * self.vol[ilk])

        if location then
            self.channels[channel].source:setPosition(location[1], location[2], location[3])
        end
        
        self.channels[channel].source:play()
    else
        -- still perform actions if audio is disabled
        if action and not unimportant then
            action()
        end
    end
end


audioPlayer.play_layer = function(self, path_list, min_silence, max_silence, channel, ilk, vol, location)
    if self.enabled then
        -- make sure channel is valid
        if channel < 1 or channel > CHANNEL_COUNT then
            return
        end
        
        -- kill existing sound if it exists
        if self:channelType(channel) == CHANNEL_SOUND then
            self.channels[channel].source:stop()
        end
        
        if not vol then
            vol = 1
        end
        
        self.channels[channel] = {
            source = nil,     -- create this later
            ilk = ilk,
            paused = false,
            action = nil,     -- layers do not support actions
            
            base_vol = vol,
            base_loc = location,
            delay = min_silence,
            paths = path_list,
            max_delay = max_silence,
            min_delay = min_silence,
            
            path = nil
        }
        
        
        
        self:determineDelay(self.channels[channel])
    end
end

audioPlayer.determineDelay = function(self, sound)
    -- determine delay
    if sound.max_delay ~= sound.min_delay then
        sound.delay = math.random(sound.min_delay, sound.max_delay)
    else
        sound.delay = sound.min_delay
    end
    if sound.delay <= 0 then
        self:playRandom(sound)
    end
end


audioPlayer.playRandom = function(self, sound)
    local to_play = sound.paths[math.random(1, #sound.paths)]
    if sound.source then
        sound.source:stop()
    end
    sound.source = love.audio.newSource(to_play, "stream")
    sound.source:setVolume(sound.base_vol * self.vol[sound.ilk])
    if sound.base_loc then
        sound.source:setPosition(sound.base_loc[1], sound.base_loc[2], sound.base_loc[3])
    end
    sound.source:play()
    sound.path = to_play
end



local lerp = function(v0, v1, t)
    return v0 + t * (v1 - v0)
end

audioPlayer.check = function(self, dt)
    if self.enabled then
        self.pos[1] = lerp(self.pos[1], self.t_pos[1], 0.1)
        self.pos[2] = lerp(self.pos[2], self.t_pos[2], 0.1)
        self.pos[3] = lerp(self.pos[3], self.t_pos[3], 0.1)
        self.ang[1] = lerp(self.ang[1], self.t_ang[1], 0.1)
        self.ang[2] = lerp(self.ang[2], self.t_ang[2], 0.1)
        
        love.audio.setPosition(self.pos[1], self.pos[2], self.pos[3])
        love.audio.setOrientation(self.pos[1] + self.ang[1], self.pos[2] + self.ang[2], self.pos[3], 0, 0, -1)
        
        for i = 1, CHANNEL_COUNT do
            if self.channels[i] then
                if not self.channels[i].paused then
                    if self.channels[i].source then
                        if not self.channels[i].source:isPlaying() then
                            -- if a channel is not paused, has a sound, and the sound is not playing,
                            -- that means that the sound has reached its end
                            -- if the channels has a list of paths,
                            -- it is a layer and we do the play random thing
                            if self.channels[i].paths then
                                self.channels[i].source = nil
                                self:determineDelay(self.channels[i])
                            else
                                -- if it does not have paths we simply execute its action
                                local action = self.channels[i].action
                                self:stop(i)
                                if action then
                                    action()
                                end
                            end
                        end
                    else
                        -- if it does not have a source and is not playing, do the count thing
                        self.channels[i].delay = self.channels[i].delay - dt
                        if self.channels[i].delay <= 0 then
                            if self.channels[i].paths then
                                self:playRandom(self.channels[i])
                            end
                        end
                    end
                end
            end
        end
    end
end

audioPlayer.set_player_position = function(self, location, dir)
    if location then
        self.t_pos = location
    end
    
    if dir then
        if dir == "n" then
            self.t_ang[1] = 0
            self.t_ang[2] = 1
        elseif dir == "s" then
            self.t_ang[1] = 0
            self.t_ang[2] = -1
        elseif dir == "e" then
            self.t_ang[1] = 1
            self.t_ang[2] = 0
        elseif dir == "w" then
            self.t_ang[1] = -1
            self.t_ang[2] = 0
        elseif dir == "ne" then
            self.t_ang[1] = 1
            self.t_ang[2] = 1
        elseif dir == "se" then
            self.t_ang[1] = 1
            self.t_ang[2] = -1
        elseif dir == "nw" then
            self.t_ang[1] = -1
            self.t_ang[2] = 1
        elseif dir == "sw" then
            self.t_ang[1] = -1
            self.t_ang[2] = -1
        end
    end
end

audioPlayer.draw = function(self)
    local x = 16
    local y = 64
    globalFont:draw("Audio Player State:", x, y)
    y = y + 16
    local text = ""
    for i = 1, CHANNEL_COUNT do
        if self.channels[i] then
            if self.channels[i].source then
                text = "channel " .. i .. " - " .. self.channels[i].path .. " (" .. self.channels[i].ilk .. ") - " .. math.floor(self.channels[i].source:getVolume() * 100) .. "%"
                if self.channels[i].paused then
                    text = "@i"..text.."@i"
                end
            else
                text = "channel " .. i .. " - " .. "@iWAITING...@i " .. self.channels[i].delay
            end
        else
            text = "channel " .. i .. " - @iEMPTY@i"
        end
        globalFont:draw(text, x, y)
        y = y + 16
end
end
return audioPlayer