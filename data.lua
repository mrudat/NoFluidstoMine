local DEBUG = false

local stone = data.raw.item["stone"]

local MOD_NAME = "NoFluidstoMine"
local mod_was_here = MOD_NAME .. "_was_here"
local recipe_exists = MOD_NAME .. "_recipe_exists"

-- TODO how to determine if resource is intended to be mined with a vanilla mining drill?

local function mangle_icons(resource)
  if resource.icon then
    resource.icons = {
      {
        icon = stone.icon
      },
      {
        icon = resource.icon,
        scale = 0.75
      },
    }
    resource.icon = nil
  elseif resource.icons then
    for i,icon in ipairs(resource.icons) do
      icon.scale = (icon.scale or 1) * 0.75
    end
    table.insert(resource.icons,1, { icon = stone.icon })
  else
    error("?!")
  end
end

local items = data.raw.item
local fluids = data.raw.fluid
local recipes = data.raw.recipe
local resources = data.raw.resource

local function build_rubble(resource_name)
  local rubble_name = resource_name .. "-rubble"
  if not items[rubble_name] then
    local resource_rubble = table.deepcopy(items[resource_name])
    resource_rubble.name = rubble_name
    resource_rubble.localised_name = {
      "item-name.NoFluidstoMine-rubble",
      {"item-name." .. resource_name}
    }
    resource_rubble.order = resource_rubble.order .. "-rubble"
    resource_rubble.stack_size = math.floor(resource_rubble.stack_size / 2)
    mangle_icons(resource_rubble)
    resource_rubble[mod_was_here] = true
    data:extend({resource_rubble})
  end
  return rubble_name
end

local function build_recipe(resource_name, fluid_name, fluid_amount)
  local recipe_name = resource_name .. "-from-rubble-with-" .. fluid_name
  local rubble_name = resource_name .. "-rubble"
  if not recipes[recipe_name] then
    items[rubble_name][recipe_exists] = true
    local recipe = {
      type = "recipe",
      category = "crafting-with-fluid",
      enabled = true, -- TODO: unlock after fluid_name can be produced?
      name = recipe_name,
      ingredients = {
        { rubble_name, 10 },
        {
          type = "fluid",
          name = fluid_name,
          amount = fluid_amount * 10
        }
      },
      results = {
        { resource_name, 10 }
      }
    }
    data:extend({recipe})
  end
end

for resource_name,resource in pairs(resources) do
  if resource[mod_was_here] then goto next_resource end
  
  local minable = resource.minable
  local resource_name  = minable.result
  local results = minable.results
  
  local required_fluid = minable.required_fluid
  local fluid_amount = minable.fluid_amount
  
  if required_fluid then
    minable.required_fluid = nil
    minable.fluid_amount = nil
    resource[mod_was_here] = true
  end
  
  if resource_name then
    local rubble_name = build_rubble(resource_name)

    if required_fluid then
      minable.result = rubble_name
      build_recipe(resource_name, required_fluid, fluid_amount)
    end
  elseif results then
    local result_count = #results
    if required_fluid then
      fluid_amount = fluid_amount / result_count
    end
    for _,result in ipairs(results) do
      local resource_name = result.name
      local resource_type = result.type
      if resource_type == "item" then
        local rubble_name = build_rubble(resource_name)
        if required_fluid then
          result.name = rubble_name
          build_recipe(resource_name, required_fluid, fluid_amount)
        end
      else
        -- TODO fluid? probably not; if you're going to pipe the fluid you're mining, you might as well pipe in the fluid to mine it as well.
      end
    end
  else
    log("Shouldn't happen!")
  end
  ::next_resource::
end
