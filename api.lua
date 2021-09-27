
-- 

technical_drawings.drawings = {}

--[[
drawing_data = {
    drawing = {
      res = 16,
      grid = { -- 16x16
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
      }
    },
    description = S(""),
    inventory_image = "",
    -- will be added by recipe registration
    categories = {
      chisel = {
        recipes = {},
      }
    }
  }
--]]

function technical_drawings.register_drawing(drawing_name, drawing_data)
  if technical_drawings.drawings[drawing_name] then
    minetest.log("error", "[technical_drawings]: ".."Technical drawing with name "..drawing_name.." is already registered.")
    return
  end
  technical_drawings.drawings[drawing_name] = drawing_data;
  -- register drawing item for drawing
  technical_drawings.register_drawing_item(drawing_name, drawing_data);
end

-- input -> item name
--[[ recipe_data
  recipe_data = {
    output = "", -- or {"",""}
    work_points = 20, -- how long it take to be done
    resistance = 2, -- this reduce tool efectivity (minus)
  }
--]]
function technical_drawings.register_recipe(drawing_name, category_name, input, recipe_data)
  if not technical_drawings.drawings[drawing_name] then
    minetest.log("error", "[technical_drawings]: ".."Technical drawing with name "..drawing_name.." is not registered.")
    return
  end
  if not technical_drawings.drawings[drawing_name].categories then
    technical_drawings.drawings[drawing_name].categories = {}
  end
  if not technical_drawings.drawings[drawing_name].categories[category_name] then
    technical_drawings.drawings[drawing_name].categories[category_name] = {
        recipes = {},
      }
  end
  technical_drawings.drawings[drawing_name].categories[category_name].recipes[input] = recipe_data;
end

function technical_drawings.get_recipe(drawing_name, category_name, input_name)
  if not technical_drawings.drawings[drawing_name] then
    return;
  end
  if not technical_drawings.drawings[drawing_name].categories then
    return;
  end
  if not technical_drawings.drawings[drawing_name].categories[category_name] then
    return;
  end
  return technical_drawings.drawings[drawing_name].categories[category_name].recipes[input_name];
end

