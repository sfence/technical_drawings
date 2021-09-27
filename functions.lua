
local S = technical_drawings.translator

local drawing_on_place = nil;
local drawing_on_use = nil;

if minetest.get_modpath("painting") then
  drawing_on_place = function(itemstack, player, pointed_thing)
    end
  drawing_on_use = function(itemstack, player, pointed_thing)
    end
end

function technical_drawings.register_drawing_item(drawing_name, drawing_data)
  minetest.register_tool(":technical_drawings:"..drawing_name, {
      description = S("Technical Drawing").." - "..drawing_data.description,
      inventory_image = drawing_data.inventory_image,
      groups = {technical_drawings = 1},
      _technical_drawings_name = drawing_name,
    })
end

local drawing_index_move = 8;
if minetest.get_modpath("hades_core") then
  drawing_index_move = 10;
end

function technical_drawings.tool_on_use(itemstack, user, pointed_thing)
  if not user then
    return itemstack;
  end
  local item_def = itemstack:get_definition();
  local tool = item_def._technical_drawings_tool;
  print(dump(tool))
  if tool then
    local inv = user:get_inventory()
    local drawing_item = inv:get_stack("main", user:get_wield_index()+drawing_index_move);
    local drawing_def = drawing_item:get_definition();
    local node = minetest.get_node(pointed_thing.under);
    print(drawing_def._technical_drawings_name)
    local recipe_data = technical_drawings.get_recipe(drawing_def._technical_drawings_name, tool.category_name, node.name);
    print(dump(recipe_data))
    if recipe_data then
      local node_meta = minetest.get_meta(pointed_thing.under);
      local timestamp = node_meta:get_int("timestamp");
      local gametime = minetest:get_gametime();
      print(gametime);
      if ((gametime-timestamp)<tool.interval) then
        return itemstack;
      end
      local points = tool.power/recipe_data.resistance;
      if points<1 then
        itemstack:add_wear(tool.wear);
        return itemstack;
      end
      itemstack:add_wear(math.ceil(tool.wear/points));
      local done = node_meta:get_int("points_done")+points;
      if (done>=recipe_data.work_points) then
        node.name = recipe_data.output;
        minetest.set_node(pointed_thing.under, node);
      else
        node_meta:set_int("timestamp", gametime);
        node_meta:set_int("points_done", done);
        print("done: "..done)
        local percent = math.floor((100*done)/recipe_data.work_points);
        local hud_image = "technical_drawings_progress_bar.png^[lowpart:"..percent..":technical_drawings_progress_bar_full.png^[transformR270]]"
        local hud = user:hud_add({
            hud_elem_type = "image",
            scale = {x = 80, y = 2},
            text = hud_image,
            position = {x=0.5, y=0.5},
            alignment = {x = 0, y = 0},

          })
        minetest.after(tool.interval*1.1, function() user:hud_remove(hud) end)
      end
      return itemstack;
    end
  end
  return itemstack;
end

