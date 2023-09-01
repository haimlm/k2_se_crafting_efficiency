local space_crafting_categories = {
  "space-accelerator",
  "space-astrometrics",
  "space-biochemical",
  "space-collider",
  "space-crafting", -- same as basic assembling but only in space
  "space-decontamination",
  "space-electromagnetics",
  "space-materialisation",
  "space-genetics",
  "space-gravimetrics",
  "space-growth",
  "space-hypercooling",
  "space-laser",
  "space-lifesupport", -- same as "lifesupport" but can only be in space
  "space-manufacturing",
  "space-mechanical",
  "space-observation-gammaray",
  "space-observation-xray",
  "space-observation-uv",
  "space-observation-visible",
  "space-observation-infrared",
  "space-observation-microwave",
  "space-observation-radio",
  "space-plasma",
  "space-radiation",
  "space-radiator",
  "space-hard-recycling", -- no conflict with "recycling"
  "space-research",
  "space-spectrometry",
  "space-supercomputing-1",
  "space-supercomputing-2",
  "space-supercomputing-3",
  "space-supercomputing-4",
  "space-thermodynamics",
  "spaceship-console",
  "spaceship-antimatter-engine",
  "spaceship-rocket-engine",
  "pressure-washing",
}



function string.starts(String, Start)
  if String == nil or Start == nil then return false end
  return string.sub(String, 1, string.len(Start)) == Start
end

local function find_furnace(name)
  if data.raw.furnace[name] then return data.raw.furnace[name] end
  if data.raw["assembling-machine"][name] then return data.raw["assembling-machine"][name] end
  if data.raw[name] then return data.raw[name] end
end

local function find_belt(name)
  if data.raw["transport-belt"][name] then return data.raw.furnace[name] end
  if data.raw[name] then return data.raw[name] end
end

local function is_space_assembly(value)
  if value.name ~= nil and string.starts(value.name, "furance-pro") then
    return false
  end
  if value ~= nil and value.crafting_categories ~= nil then
    for _, category in pairs(value.crafting_categories) do
      if string.starts(category, "space-") or string.starts(category, "se-space") then
        return true
      end
    end
  end
  return false
end

local function find_all_space_assemblies()
  local space_assemblies = {}
  for _, value in pairs(data.raw["assembling-machine"]) do
    if is_space_assembly(value) then
      table.insert(space_assemblies, value)
    end
  end
  for _, value in pairs(data.raw["furnace"]) do
    if is_space_assembly(value) then
      table.insert(space_assemblies, value)
    end
  end
  for _, value in pairs(data.raw) do
    if is_space_assembly(value) then
      table.insert(space_assemblies, value)
    end
  end
  return space_assemblies
end

local furnaces = {
  furnace_prototype_01 = find_furnace("furnace-pro-01"),
  furnace_prototype_02 = find_furnace("furnace-pro-02"),
  furnace_prototype_03 = find_furnace("furnace-pro-03"),
  furnace_prototype_04 = find_furnace("furnace-pro-04"),
  furnace_prototype_05 = find_furnace("furnace-pro-05")
}

for _, value in pairs(furnaces) do
  table.insert(value.crafting_categories, "kiln")
  table.insert(value.crafting_categories, "casting")
  table.insert(value.crafting_categories, "space-thermodynamics")
  table.insert(value.crafting_categories, "space-growth")
  table.insert(value.crafting_categories, "melting")
end

local pro_machines = {
  machine_prototype_01 = find_furnace("advanced-assembling-machine-returns"),
  machine_prototype_02 = find_furnace("advanced-assembler-rampant-industry"),
}
for _, value in pairs(pro_machines) do
  table.insert(value.crafting_categories, "RPKs-stacked-crafting")
  table.insert(value.crafting_categories, "crafting-with-fluid")
end

local advanced_chemical = {
  advanced_chemical_prototype_01 = find_furnace("kr-advanced-chemical-plant"),
  advanced_chemical_prototype_02 = find_furnace("advanced-chemical-plant-rampant-industry"),
}
for _, value in pairs(advanced_chemical) do
  table.insert(value.crafting_categories, "fuel-refining")
  -- table.insert(se_fuel_refinery.crafting_categories, "fuel-refinery")
end


local growth_facility =
{
  growth_facility_prototype_01 = find_furnace("se-space-growth-facility"),

}

for _, value in pairs(growth_facility) do
  value.crafting_speed = 40
end


local space_assemblies = find_all_space_assemblies()

for _, value in pairs(space_assemblies) do
  value.crafting_speed = value.crafting_speed * 10
end

local space_belts =
{
  belt = find_belt("space-transport-belt"),
  splitter = find_belt("space-splitter"),
  underground = find_belt("space-underground-belt"),
}

for _, value in pairs(space_belts) do
  value.speed = 100 --value.speed * 3
end
