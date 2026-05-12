-- a video
-- depends:phil_state

local createVideo = function(video, x, y, loop, freeze, action)
    local new_video = {
        x = x,
        y = y,
        video = video,
        loop = loop,
        freeze = freeze,
        action = action,
        is_shown = true,
        paused = false
    }
        
    -- functions
    new_video.check = function(self, dt)
        local ret = nil
        -- if we've requested pause, pause the video
        if phil_state.is_paused then
            self.video:pause()
            self.paused = true
        else
            if not self.video:isPlaying() then
                if self.paused then
                    self.video:play()
                    self.paused = false
                else
                    -- if it's not playing and not paused, it means we are at the end of the video
                    if loop then
                        self.video:rewind()
                        self.video:play()
                    else
                        -- if the video freezes at the end, it stays visible but does not loop
                        -- if the video does not freeze or loop, it disappears
                        if not freeze then
                            self.is_shown = false
                        end
                    end
                    ret = self.action
                end
            end
        end
        return ret
    end
        
    new_video.draw = function(self)
        if self.is_shown then
            love.graphics.draw(self.video, self.x, self.y)
        end
    end
    
    new_video.video:play()
    return new_video
end

return createVideo
