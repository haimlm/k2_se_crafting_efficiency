require("util")
require("mods/base")
if mods["aai-industry"] then require("mods/aai-industry") end
if mods["space-exploration"] then require("mods/space-exploration") end
if mods["Krastorio2"] then require("mods/krastorio2") end


for name, _data in pairs(K2_SE_CE_Recipes_EX) do
    if data.raw.recipe[name] then
        log("Adding crafting effiency for " .. name)
        CE_Add_Recipe(_data, name)
    end
end
