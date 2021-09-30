
-- empty technical drawing

local S = technical_drawings.translator;

minetest.register_tool("technical_drawings:empty_drawing", {
    description = S("Empty Technical Drawing"),
    inventory_image = "technical_drawings_empty_drawing.png",
    groups = {not_in_creative_inventory = 1},
  })

local drawing_on_place = function(itemstack, player, pointed_thing)
  end
local drawing_on_use = function(itemstack, player, pointed_thing)
    if (pointed_thing.type=="node") then
      local node = minetest.get_node(pointed_thing.under)
      if (node.name=="painting:easel") then
        local node_def = minetest.registered_nodes[node.name]
        node_def.on_punch(pointed_thing.under, node, player, pointed_thing)
        return player:get_wielded_item()
      end
    end
    if player and (player:get_player_name()~="") then
      local meta = itemstack:get_meta()
      local drawing = {
        res = meta:get_int("resolution"),
        version = meta:get_string("version"),
        grid = meta:get_string("grid"),
        drawing = meta:get_string("drawing"),
        quality = meta:get_float("quality"),
      }
      local orig_grid = minetest.deserialize(painting.decompress(drawing.grid))
      if technical_drawings.drawings[drawing.drawing] then
        drawing.drawing = technical_drawings.drawings[drawing.drawing].description
      end
      local formspec = 
        "formspec_version[3]" .. "size[11,14]" ..
        "label[0.5,0.5;Drawing: "..drawing.drawing.."]"..
        "label[0.5,1.5;Quality: "..math.floor(drawing.quality*100).."%]"..
        "image[0.5,2.5;10,10;"..painting.to_imagestring(orig_grid, drawing.res).."]"..
        "button_exit[5,13;2,0.5;exit;Exit]"
      minetest.show_formspec(player:get_player_name(), "technical_drawing", formspec)
    end
  end

function technical_drawings.register_drawing_item(drawing_name, drawing_data)
  minetest.register_tool(":technical_drawings:"..drawing_name, {
      description = S("Technical Drawing").." - "..drawing_data.description,
      inventory_image = drawing_data.inventory_image,
      groups = {technical_drawings = 1, not_in_creative_inventory = 1},
      _technical_drawings_name = drawing_name,
      on_place = drawing_on_place,
      on_use = drawing_on_use,
      --on_receive_fields = drawing_on_receive_fields,
    })
end

