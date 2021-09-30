
local S = technical_drawings.translator

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
  --print(dump(tool))
  if tool then
    local inv = user:get_inventory()
    local drawing_item = inv:get_stack("main", user:get_wield_index()+drawing_index_move);
    local drawing_def = drawing_item:get_definition();
    local node = minetest.get_node(pointed_thing.under);
    --print(drawing_def._technical_drawings_name)
    local recipe_data = technical_drawings.get_recipe(drawing_def._technical_drawings_name, tool.category_name, node.name);
    --print(dump(recipe_data))
    if recipe_data then
      local node_meta = minetest.get_meta(pointed_thing.under);
      local timestamp = node_meta:get_int("timestamp");
      local gametime = minetest:get_gametime();
      --print(gametime);
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
        --print("done: "..done)
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


-- comparing drawings
local function drawings_diff_core(A, B)
  local ratio = A.res/B.res;
  local check = math.modf(ratio);
  
  -- palette conjuction table
  local conjuction = {};
  local valid_points = 0;
  
  -- same size drawing
  --   statistic comparation for palette conjuction point to point
  
  -- different size of drawing
  --   use method point to multiple point
  --   should be done in good way, to prevent background to be identified as line. Is it possible?
  
  -- what about shitch A and B? (multicolored drawing from player match to ideal, no match ideal to player)
  for y=1,A.res do
    local lineA = A.grid[y];
    for x=1,A.res do
      -- use next cycle for different resolution of drawing
      local pA = lineA[x];
      local pB = B.grid[math.ceil(y/ratio)][math.ceil(x/ratio)];
      if (pA~=0) and (pB~=0) then -- ignore DO NOT MATTER palette indexes
        local conjA = conjuction[pA];
        if not conjA then
          conjA = {
              conj = {},
            };
          conjuction[pA] = conjA;
        end
        --[[
        if conjA.conj[pB] then
          conjA.conj[pB] = conjA.conj[pB] + 1;
        else
          conjA.conj[pB] = 1;
        end--]]
        conjA.conj[pB] = (conjA.conj[pB] or 0) + 1;
        valid_points = valid_points + 1;
      end
    end
  end
  
  --print(dump(conjuction))
  -- I have conjuction, so select the best matches
  local convertion = {};
  
  for orig_palette,conj in pairs(conjuction) do
    local vmax = 0;
    local pmax = 0;
    for palette,count in pairs(conj.conj) do
      if (count>vmax) then
        vmax = count;
        pmax = palette;
      end
    end
    convertion[orig_palette] = pmax;
  end
  --print(dump(convertion))
  
  local diff = 0;
  
  for y=1,A.res do
    local lineA = A.grid[y];
    for x=1,A.res do
      local pA = lineA[x];
      local pB = B.grid[math.ceil(y/ratio)][math.ceil(x/ratio)];
      if (pA~=0) and (pB~=0) then -- ignore DO NOT MATTER palette indexes
        if (convertion[pA]~=pB) then
          diff = diff + 1;
        end
      end
    end
  end
  
  --return diff;
  return diff/valid_points;
  --return (diff/valid_points)*(A.res/B.res);
  --return diff/(A.res*A.res);
  --return (((diff/valid_points)+(diff/(A.res*A.res)))/2);
end

function technical_drawings.drawings_diff(A, B)
  if (A.res>=B.res) then
    return drawings_diff_core(A, B);
  else
    return drawings_diff_core(B, A);
  end
end

local function HexToRGB(hex)
  return {
      r = tonumber(string.sub(hex, 1, 2), 16),
      g = tonumber(string.sub(hex, 3, 4), 16),
      b = tonumber(string.sub(hex, 5, 6), 16),
    }
end
local function RGBToHex(color)
  return string.format("%02x%02x%02x", color.r, color.g, color.b);
end
local function DiffRGB(color1, color2)
  return math.abs(color1.r-color2.r)+math.abs(color1.g-color2.g)+math.abs(color1.b-color2.b);
end

function technical_drawings.drawing_to_palette(drawing, max_colors_diff)
  local palette = {};
  
  for _,line_data in pairs(drawing.grid) do
    for _,point_data in pairs(line_data) do
      local new_color = true;
      for _,palette_color in pairs(palette) do
        if (DiffRGB(palette_color.center_color, HexToRGB(point_data))<=max_colors_diff) then
          new_color = false;
          if palette_color.colors[point_data] then
            palette_color.colors[point_data] = palette_color.colors[point_data] + 1;
          else
            palette_color.colors[point_data] = 1;
          end
          break;
        end
      end
      if new_color then
        table.insert(palette, {
            center_color = HexToRGB(point_data),
            colors = {[point_data] = 1}
          });
      end
    end
  end
  
  --print(dump(palette))
  
  -- reduce drawing
  local paletted = {};
  for _,line_data in pairs(drawing.grid) do
    local new_line = {};
    for _,point_data in pairs(line_data) do
      for palette_index,palette_color in pairs(palette) do
        if (DiffRGB(palette_color.center_color, HexToRGB(point_data))<=max_colors_diff) then
          table.insert(new_line, palette_index);
          break;
        end
      end
    end
    table.insert(paletted, new_line);
  end
  
  return {
      res = drawing.res,
      grid = paletted,
    }
end

function technical_drawings.find_best_drawing_math(drawing)
  local best_math = 1
  local best_name = nil
  for drawing_name, drawing_data in pairs(technical_drawings.drawings) do
    local diff = technical_drawings.drawings_diff(drawing, drawing_data.drawing)
    if (diff<best_math) then
      best_math = diff
      best_name = drawing_name
    end
    --print(drawing_name..": "..diff)
  end
  if best_name then
    local stack = ItemStack("technical_drawings:"..best_name)
    local meta = stack:get_meta()
    local def = stack:get_definition()
    local quality = (1/(1+best_math))^4
    meta:set_float("quality", quality)
    meta:set_string("drawing", best_name)
    meta:set_string("description", def.description.."\n"..S("Quality: ")..math.floor(quality*100).."%")
    return stack
  end
  return nil
end

