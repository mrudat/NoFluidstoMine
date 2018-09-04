local stone = data.raw.item["stone"]

-- TODO how to determine if resource is intended to be mined with a vanilla mining drill?

for resource_name,resource in pairs(data.raw.resource) do
  local minable = resource.minable
  if minable.required_fluid and minable.result then
    local required_fluid = minable.required_fluid
    local fluid_amount = minable.fluid_amount
    
    minable.required_fluid = nil
    minable.fluid_amount = nil
    
    local resource_name = minable.result
    local resource_rubble = table.deepcopy(data.raw.item[resource_name])
    resource_rubble.name = resource_name .. "-rubble"
    resource_rubble.localised_name = {
      "item-name.NoFluidstoMine-rubble",
      {"item-name." .. resource_name}
    }
    resource_rubble.icons = {
      {
        icon = stone.icon
      },
      {
        icon = resource_rubble.icon,
        scale = 0.75
      },
    }
    resource_rubble.order = resource_rubble.order .. "-rubble"
    resource_rubble.stack_size = math.floor(resource_rubble.stack_size / 2)
    resource_rubble.icon = nil
    data:extend({resource_rubble})
    
    minable.result = resource_rubble.name
    
    local recipe = {
      type = "recipe",
      category = "crafting-with-fluid",
      enabled = true, -- TODO: unlock after required_fluid can be produced?
      name = resource_name .. "-from-" .. resource_rubble.name,
      ingredients = {
        { resource_rubble.name, 10 },
        {
          type = "fluid",
          name = required_fluid,
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
