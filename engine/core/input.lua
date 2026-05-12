-- global input state
-- wraps love to guarantee constant size mouse coordinates
-- and allow easy porting to other input modes
-- and allow input to be blocked
local input_state = {
    mouse_x = 0,
    mouse_y = 0,
    left_clicked = false,
    right_clicked = false,
    scrolled_up = false,
    scrolled_down = false,

    -- text input
    text_input_text = "",
    text_input_enabled = false,
    text_input_pos = 0,
    text_input_max_len = 72,
    text_input_is_submitted = false
}

input_state.activateTextInput = function(self, x, y, w, h, text, pos, max_len)
    love.keyboard.setTextInput(true, x, y, w, h)
    love.keyboard.setKeyRepeat(true)
    
    self.text_input_enabled = true
    self.text_input_text = text
    self.text_input_max_len = max_len
    self.text_input_is_submitted = false
    
    -- if the defined pos is somewhere in the range of the text then set pos to the defined pos
    if (pos >= 0) and (pos <= #self.text_input_text) then
        self.text_input_pos = pos
    else
        -- otherwise set it to the end
        self.text_input_pos = #self.text_input_text
    end
end
    
input_state.deactivateTextInput = function(self)
    love.keyboard.setTextInput(false)
    love.keyboard.setKeyRepeat(false)
    self.text_input_enabled = false
end


return input_state
