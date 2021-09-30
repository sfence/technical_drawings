-------------------
-- Drawing Table --
-------------------
----- Ver 1.0 -----
-----------------------
-- Initial Functions --
-----------------------

local S = technical_drawings.translator;

-- drawing table for identification of drawing

technical_drawings.drawing_table = appliances.appliance:new(
    {
      node_name_inactive = "technical_drawings:drawing_table",
      node_name_active = "technical_drawings:drawing_table_active",
      
      node_description = S("Drawing Table"),
    	node_help = S("Powered by punching.").."\n"..S("Analyze drawed canvas and change them into technical drawing."),
      
      usage_stack_size = 0,
      usage_stack = nil,
      have_usage = false,
      
      sounds = {
        running = {
          sound = "technical_drawings_drawing_table_active",
          sound_param = {max_hear_distance = 8, gain = 0.25},
          repeat_timer = 1,
        },
      },
    })

local drawing_table = technical_drawings.drawing_table

drawing_table:power_data_register(
  {
    ["punch_power"] = {
        run_speed = 1,
        disable = {}
      },
  })

--------------
-- Formspec --
--------------

---------------
-- Callbacks --
---------------

function drawing_table:recipe_aviable_input(inventory)
  local input_stack = inventory:get_stack(self.input_stack, 1)
  local input_name = input_stack:get_name()
  local input_meta = input_stack:get_meta()
  local res = input_meta:get_int("resolution")
  local version = input_meta:get_string("version")
  local grid = input_meta:get_string("grid")
  if (res==0) or (version~="hexcolors") or (grid=="") then
    return nil, nil
  end
  return self.recipes.inputs[input_name], nil
end

----------
-- Node --
----------

local node_def = {
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {cracky = 2},
    legacy_facedir_simple = true,
    is_ground_content = false,
    sounds = default.node_sound_wood_defaults(),
    drawtype = "mesh",
    mesh = "technical_drawings_drawing_table.obj",
    tiles = {
        "default_wood.png",
        "default_junglewood.png",
        "technical_drawings_drawing_table_book_plan.png",
    },
 }

local node_inactive = {
  }

local node_active = {
  }

drawing_table:register_nodes(node_def, node_inactive, node_active)

-------------------------
-- Recipe Registration --
-------------------------

local function technical_drawing_output(self, timer_step)
  if (timer_step.production_time<5) then
    return "technical_drawings:empty_drawing"
  end
  local input_stack = timer_step.inv:get_stack(self.input_stack, 1)
  local input_meta = input_stack:get_meta()
  local canvas = {
    res = input_meta:get_int("resolution"),
    version = input_meta:get_string("version"),
    grid = input_meta:get_string("grid"),
  }
  local orig_grid = minetest.deserialize(painting.decompress(canvas.grid))
  local drawing = {
    res = canvas.res,
    grid = {},
  }
  -- conversion
  for y = 0, canvas.res - 1 do
    local line = {}
    for x = 0, canvas.res - 1 do
      table.insert(line, orig_grid[x][y])
    end
    table.insert(drawing.grid, line)
  end
  drawing = technical_drawings.drawing_to_palette(drawing, 16)
  -- find best math drawing
  local output_stack = technical_drawings.find_best_drawing_math(drawing)
  if not output_stack then
    output_stack = ItemStack("technical_drawings:empty_drawing")
  end
  local output_meta = output_stack:get_meta()
  output_meta:set_int("resolution", canvas.res)
  output_meta:set_string("version", canvas.version)
  output_meta:set_string("grid", canvas.grid)
  return {output_stack}
end

appliances.register_craft_type("technical_drawings_drawing_table", {
    description = S("Analyzing"),
    width = 1,
    height = 1,
  })

drawing_table:recipe_register_input(
	"painting:paintedcanvas",
	{
		inputs = 1,
		outputs = {technical_drawing_output},
		production_time = 5, -- 60
		production_step_size = 1,
	});

-- no recipe registration

