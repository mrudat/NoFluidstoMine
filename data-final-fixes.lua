require("data")

local MOD_NAME = "NoFluidstoMine"
local mod_was_here = MOD_NAME .. "_was_here"
local recipe_exists = MOD_NAME .. "_recipe_exists"

local items = data.raw.item
local recipes = data.raw.recipe

-- disable resource-rubble items that were never used becase they weren't being mined with fluid
local hidden_items = {}

for item_name, item in pairs(items) do
  if item[mod_was_here] then
    if not item[recipe_exists] then
      item.hidden = true
      hidden_items[item_name] = true
    end
  end
end

local function recipe_uses_hidden_items(recipe)
  local result = recipe.result
  if result then
    if hidden_items[result] then return true end
  end
  local item_lists = {}
  if recipe.results then table.insert(item_lists,recipe.results) end
  if recipe.ingredients then table.insert(item_lists,recipe.ingredients) end
  if recipe.normal then table.insert(item_lists,recipe.normal.ingredients) end
  if recipe.hard then table.insert(item_lists,recipe.hard.ingredients) end
  
  for _,item_list in ipairs(item_lists) do
    for _,item in ipairs(item_list) do
      local item_name = item.name
      if item_name then
        if hidden_items[item_name] then return true end
      else
        if hidden_items[item[1]] then return true end
      end
    end
  end
  return false
end

-- disable generated recipes that use the useless resource-rubble item
for recipe_name, recipe in pairs(recipes) do
  if recipe_uses_hidden_items(recipe) then
    log("Disabling derived recipe " .. recipe_name .. " that uses unused rubble item")
    recipe.hidden = true
  end
end
