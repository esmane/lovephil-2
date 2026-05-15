# lovephil
"Did Someone Kill Phil?" implemented in Love2D

## about
This is a prerendered 1st person point and click adventure game. The main branch contains the engine code that you can copy if you want to make your own adventure game using my engine. For more information about how to do this you will have to study the code as there is no documentation currently. At some point I will document the engine functions and how they work.

## running the game
The game is built in Love2D and can run on any system that supports Love2D, although the game does not support touchscreen input currently and probably will not run correctly on smartphones. In addition to this the game scripts are written in such that they use special phil_xxx functions and no love functions, so the game could easily be ported to pretty much any system that can run a lua interpreter and implements the phil_xxx functions.

## credits
The fonts contained in the file font.png are based on Pixolde by fontenddev.com. Pixolde is released under the [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) license and if you make a game using this font you must give appropriate credit.

The file table_stringify.lua contains code modified from [here](http://lua-users.org/files/wiki_insecure/users/chill/table.save-1.0.lua).