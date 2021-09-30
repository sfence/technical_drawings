
technical_drawings = {
  translator = minetest.get_translator("technical_drawings")
}

local modpath = minetest.get_modpath(minetest.get_current_modname());

dofile(modpath.."/functions.lua")
dofile(modpath.."/api.lua")

dofile(modpath.."/drawing.lua")

dofile(modpath.."/drawing_table.lua")

