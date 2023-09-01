
if mods["Load-Furn-2"] then require("other_fixes/af2-stone-fix") end

if mods["bzaluminum"] then
    local util = require("__bzaluminum__.data-util")
    local item = "automation-core"
    for i = 1, 15 do
        util.replace_ingredient("ce-" .. item .. "-" .. i, "copper-plate", "aluminum-plate")
    end
    item = "motor"
    for i = 1, 15 do
        util.replace_ingredient("ce-" .. item .. "-" .. i, "iron-plate", "aluminum-plate")
    end
end
