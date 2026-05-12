-- okay, so the font is loaded as an image
-- each glyph is defined as a quad in that image
-- so to render a glyph we just look up what quad it is
-- and render that quad
-- the space character is not rendered
-- but is used to render any unknown characters
-- so is defined as a question mark in a box on the sprite sheet
-- the first glyph in the image is the space
-- all control codes are not rendered
-- the font assumes text is encoded in a one byte per character format
-- we ship the windows-1252 character set in our font
-- to port the game to a language that requires a different character encoding you will need the font spritesheet changed to match the encoding used
-- so that the glyphs match the encoding format used by your language
-- for example to port to russian you would need to make sure the string table file is encoded as iso 8859-5
-- and that the font spritesheet matches the 8859-5 codepage
-- everything else *should* work automatically
-- if the string table file is encoded in utf-8 or some other format where there is more than one byte per character
-- the font will not render correctly
-- and both the sprite sheet and the font implementation will need to be changed
-- oh, and one more thing
-- the font sprite sheet actually encodes four fonts
-- the top left is the regular font
-- the top right is the bold font
-- the bottom left is the italic font
-- and the bottom right is bold-italic
-- when setting up the quads for the characters
-- the font only looks at the top left quarter of the grid
-- changing the font adds an offset to either the x or the y of the glyph's quad
-- control sequences starting with @ change the font
-- @i toggles italic, shifting the y
-- @h toggles bold (heavy), shifting the x
-- to print a @ type @@
-- ex: "@iemail@i@@example.com" -> "<i>email</i>@example.com

-- special characters
-- @ is used to toggle a control sequence
-- @ is not printed normally
-- currently there are four special control sequences:
-- @i turns italics on or off
-- @h turns bold on or off (h for heavy, b is reserved in case i later decide to add control sequences to change the color using hex color codes
-- @r turns both bold and italic off
-- @@ prints an @


local CHAR_SP  = string.byte(" ")
local CHAR_LF  = string.byte("\n")
local CHAR_ESC = string.byte("@")
local CHAR_IT  = string.byte("i")
local CHAR_BD  = string.byte("h")
local CHAR_RG  = string.byte("r")
local CHAR_MAX = 255

local font = {
    chars = {},
    tex = nil,
    char_w = 0,
    char_h = 0,
    x_shift = 0,    -- shift to the bold font
    y_shift = 0,    -- shift to the italic font
    render_quad = nil,
    offset_x = 0,
    offset_y = 0
}

font.setup = function(self, path, char_w, char_h, char_sp)
    self.char_w = char_w + char_sp
    self.char_h = char_h
    
    self.tex = love.graphics.newImage(path)
    local tex_w
    local tex_h
    tex_w, tex_h = self.tex:getDimensions()
    
    self.x_shift = tex_w / 2
    self.y_shift = tex_h / 2
    self.render_quad = love.graphics.newQuad(0, 0, char_w, char_h, tex_w, tex_h)
    
    local x = 0
    local y = 0
    
    for i = CHAR_SP, CHAR_MAX do
        self.chars[i] = love.graphics.newQuad(x, y, char_w, char_h, tex_w, tex_h)
        x = x + char_w
        if x + char_w > self.x_shift then
            x = 0
            y = y + char_h
            if y + char_h > self.y_shift then
                return
            end
        end
    end
    
    -- reset
    self.offset_x = 0
    self.offset_y = 0
end

font.draw = function(self, text, x, y)
    local og_x = x
    local x2
    local y2
    local w
    local h
    
    local i = 1
    local char
    local draw
    while i <= #text do
        draw = true
        char = text:byte(i)
        -- check if the character is an escape character
        if char == CHAR_ESC then
            -- if it is, check the next character
            draw = false
            char = text:byte(i + 1)
            if char == CHAR_BD then
                if self.offset_x > 0 then
                    self.offset_x = 0
                else
                    self.offset_x = self.x_shift
                end
            elseif char == CHAR_IT then
                if self.offset_y > 0 then
                    self.offset_y = 0
                else
                    self.offset_y = self.y_shift
                end
            elseif char == CHAR_RG then
                self.offset_x = 0
                self.offset_y = 0
            elseif char == CHAR_ESC then
                draw = true
            end
            -- increment i to skip the second part of the control code
            i = i + 1
        -- check if the character is a linefeed
        elseif char == CHAR_LF then
            y = y + self.char_h
            x = og_x
            draw = false
        end
        
        if draw then
            -- spaces are not drawn but they do advance the x value by the width of a character
            if char ~= CHAR_SP then
                -- all other characters are drawn. if a character is not in the font we draw the space character
                if not self.chars[char] then
                    char = CHAR_SP
                end
                x2, y2, w, h = self.chars[char]:getViewport()
                self.render_quad:setViewport(x2 + self.offset_x, y2 + self.offset_y, w, h)
                love.graphics.draw(self.tex, self.render_quad, x, y)
            end
            x = x + self.char_w
        end
        
        i = i + 1
    end
end

return font
