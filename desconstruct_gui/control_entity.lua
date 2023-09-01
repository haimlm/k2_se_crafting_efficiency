function get_xgui_data(player, unique_id)
    global.xgui_data = global.xgui_data or {}
    global.xgui_data[player.index] = global.xgui_data[player.index] or {}
    global.xgui_data[player.index][unique_id] = global.xgui_data[player.index][unique_id] or {}
    return global.xgui_data[player.index][unique_id]
end

function set_xgui_data(player, unique_id, data)
    global.xgui_data = global.xgui_data or {}
    global.xgui_data[player.index] = global.xgui_data[player.index] or {}
    global.xgui_data[player.index][unique_id] = global.xgui_data[player.index][unique_id] or {}
    global.xgui_data[player.index][unique_id] = data
    return global.xgui_data[player.index][unique_id]
end

---Gets PlayerData table for a given player or creates an empty one if it doesn't exist
---@param player LuaPlayer
---@return PlayerData
function get_make_playerdata(player)
    global.playerdata = global.playerdata or {}
    global.playerdata[player.index] = global.playerdata[player.index] or {}
    return global.playerdata[player.index]
end

local function get_valid_alert_icon(entity_name)
    -- If the entity's name exists as an item prototype, use it
    if game.item_prototypes[entity_name] then
        return { type = "item", name = entity_name }
    end
    -- If not, use a fallback like "iron-plate"
    return { type = "item", name = "iron-plate" }
end



-- Utility function to find all unconnected entities.
local function find_unconnected_entities(player)
    local unconnected = {}
    for _, surface in pairs(game.surfaces) do
        for _, entity in pairs(surface.find_entities_filtered { force = player.force }) do
            if not entity.is_connected_to_electric_network() and entity.electric_buffer_size then
                if not unconnected[entity.name] then
                    unconnected[entity.name] = {}
                end
                table.insert(unconnected[entity.name], entity)
            end
        end
    end
    return unconnected
end

-- Utility function to create the main GUI.
local function create_gui(player, unconnected)
    if player.gui.left.deconstruct_gui then
        player.gui.left.deconstruct_gui.destroy()
    end

    local frame = player.gui.left.add { type = "frame", name = "deconstruct_gui", direction = "vertical", caption =
    "Unconnected Entities" }

    for entity_name, entities in pairs(unconnected) do
        local first_valid_entity = nil
        for _, entity in pairs(entities) do
            if entity.valid then     -- Ensure entity is still valid
                first_valid_entity = entity
                break
            end
        end

        if first_valid_entity then
            local surface_name = first_valid_entity.surface.name
            local count = #entities
            local flow = frame.add { type = "flow", direction = "horizontal" }
            local open_group = flow.add({ type = "button", name = "open_group", caption = "Open" })
            open_group.tags = { entities = entities, entity_name = entity_name, surface_name = surface_name }
            set_xgui_data(player, "open_group",
                { entities = entities, entity_name = entity_name, surface_name = surface_name })
            local element = flow.add { type = "button", name = "deconstruct_deconstruct_" .. entity_name .. "_" .. surface_name, caption =
            "Deconstruct All" }
            set_xgui_data(player, element.name, { entities = entities, entity_name = entity_name, surface_name = surface_name })
            element = flow.add { type = "button", name = "deconstruct_alert_" .. entity_name .. "_" .. surface_name, caption =
            "Alert" }
            set_xgui_data(player, element.name, { entities = entities, entity_name = entity_name, surface_name = surface_name })
            flow.add { type = "label", caption = entity_name .. " (" .. surface_name .. ") - Count: " .. count }
        end
    end

    frame.add { type = "button", name = "close_deconstruct_gui", caption = "Close" }
end

-- Event Handler for GUI interactions.
function Deconstruct_event(event)
    local player = game.players[event.player_index]
    local element = event.element
    local unconnected = find_unconnected_entities(player)
    local global_tags = get_xgui_data(player, element.name)
    if element.name == "close_deconstruct_gui" then
        if player.gui.left.deconstruct_gui then
            player.gui.left.deconstruct_gui.destroy()
        end
        
    elseif string.find(element.name, "deconstruct_deconstruct_") then
        local entity_name, surface_name = global_tags.entity_name, global_tags.surface_name
        local valid_entities = {}     -- We will store valid entities here after checking

        for _, entity in pairs(unconnected[entity_name] or {}) do
            if entity.valid and entity.surface.name == surface_name then
                entity.order_deconstruction(player.force)
                table.insert(valid_entities, entity)
            end
        end

        -- Update the global table to only keep valid entities
        global.unconnected[entity_name] = valid_entities

        -- Refresh the GUI
        create_gui(player, unconnected)
    elseif string.find(element.name, "deconstruct_alert_") then
        local entity_name, surface_name = global_tags.entity_name, global_tags.surface_name

        if entity_name and surface_name and unconnected[entity_name] then
            for _, entity in pairs(unconnected[entity_name] or {}) do
                if entity.valid and entity.surface.name == surface_name then
                    -- Raise an alert for each unconnected entity in the group
                    player.add_custom_alert(entity, get_valid_alert_icon(entity.name),
                        "Unconnected Entity" .. " - " .. entity.name, true)
                end
            end
        else
            -- This can be removed after debugging is done.
            game.print("Failed to find unconnected entities for: " .. tostring(entity_name))
        end
    end
end

-- Command registration.
commands.add_command('deconstruct_gui', 'Show GUI for unconnected entities', function()
    local player = game.player
    global.unconnected = find_unconnected_entities(player)
    create_gui(player, global.unconnected)
end)


commands.add_command("find_small_networks", "Finds all small electric networks in the game.", function(command)
    local player = game.players[command.player_index]
    local networks = {}

    for _, surface in pairs(game.surfaces) do
        for _, electric_pole in pairs(surface.find_entities_filtered { type = "electric-pole" }) do
            local network_id = electric_pole.electric_network_id
            if not networks[network_id] then
                networks[network_id] = { poles = {}, surface = surface }
            end
            table.insert(networks[network_id].poles, electric_pole)
        end
    end

    local small_networks = {}
    for network_id, data in pairs(networks) do
        if #data.poles < 10 then
            small_networks[network_id] = data
        end
    end

    create_gui_for_small_networks(player, small_networks)
end)


function create_gui_for_small_networks(player, small_networks)
    if player.gui.left.small_networks_gui then
        player.gui.left.small_networks_gui.destroy()
    end

    local frame = player.gui.left.add { type = "frame", name = "small_networks_gui", direction = "vertical", caption =
    "Small Electric Networks" }

    for network_id, data in pairs(small_networks) do
        local surface_name = data.surface.name
        local count = #data.poles
        local first_pole = data.poles[1]
        local flow = frame.add { type = "flow", direction = "horizontal" }
        local open_group = flow.add({ type = "button", name = "open_group", caption = "Open" })
        open_group.tags = { entities = data.poles, entity_name = network_id, surface_name = surface_name }
        set_xgui_data(player, open_group,
            { entities = data.poles, entity_name = network_id, surface_name = surface_name })
        local alert_button = flow.add { type = "button", name = "alert_network", caption = "Alert" }
        alert_button.tags = {
            network_id = network_id,
            representative_pole = first_pole.unit_number,
            surface_name = data.surface.name
        }
        local deconstruct_button = flow.add { type = "button", name = "deconstruct_network", caption = "Deconstruct All" }
        flow.add { type = "label", caption = "Network on " .. surface_name .. " - Count: " .. count }
        deconstruct_button.tags = { network_id = network_id }
    end

    frame.add { type = "button", name = "close_small_networks_gui", caption = "Close" }
end

function Netwrok_event(event)
    local player = game.players[event.player_index]
    local element = event.element

    if element.name == "close_small_networks_gui" then
        if player.gui.left.small_networks_gui then
            player.gui.left.small_networks_gui.destroy()
        end
    end

    if element.name == "alert_network" then
        local network_id = element.tags.network_id
        local pole_unit_number = element.tags.representative_pole
        local surface_name = element.tags.surface_name
        local representative_pole = nil

        for _, entity in pairs(game.surfaces[surface_name].find_entities()) do
            if entity.unit_number == pole_unit_number then
                representative_pole = entity
                break
            end
        end


        if representative_pole and representative_pole.valid and representative_pole.electric_network_id == network_id then
            -- local item_name = "ub-ultimate-miniloader-inserter"
            player.add_custom_alert(representative_pole, get_valid_alert_icon(representative_pole.name),
                "Unconnected Entity", true)
        end
    end


    if element.name == "deconstruct_network" then
        local network_id = element.tags.network_id
        for _, surface in pairs(game.surfaces) do
            for _, electric_pole in pairs(surface.find_entities_filtered { type = "electric-pole" }) do
                if electric_pole.valid and electric_pole.electric_network_id == network_id then
                    electric_pole.order_deconstruction(player.force)
                end
            end
        end
    end
end

script.on_event(defines.events.on_gui_click, function(event)
    -- Indvidual_gui_event(event)
    -- Netwrok_event(event)
    -- Deconstruct_event(event)
end)



local function teleport_to_entity(player, entity)
    if not entity or not entity.valid then
        return
    end
    player.teleport(entity.position, entity.surface)
end

local previous_positions = {}
local function teleport_back(player)
    if previous_positions[player.index] then
        player.teleport(previous_positions[player.index], player.surface)
        previous_positions[player.index] = nil
    end
end

local function open_individual_gui(player)
    if player.gui.screen.group_entities_gui_flow then
        player.gui.screen.group_entities_gui_flow.destroy()
    end
    if get_xgui_data(player, "open_group") and get_xgui_data(player, "open_group").entities then
        entities = get_xgui_data(player, "open_group").entities
    else
        entities = {}
    end
    local root = player.gui.screen.add {
        type = "frame",
        name = "group_entities_gui_flow",
        direction = "vertical",
    }

    local frame = root
    local close_button = frame.add({
        type = "sprite-button",
        name = "close_individual_gui",
        sprite = "utility/close_white",
        style = "close_button",
        tooltip = "Close"
    })
    close_button.style.size = 28
    -- let's add a title, so we will be able to drag it
    -- let's give the entity name,  surface name and location to the title
    local title = frame.add { type = "label", caption = "Inspector" }
    title.style.font = "default-bold"
    if not entities or not entities[1] then return end
    frame.add({ type = "button", name = "indvidual_previous_entity", caption = "Previous" }).tags = {
        entities = entities,
        current_index = 1
    }
    frame.add({ type = "button", name = "indvidual_next_entity", caption = "Next" }).tags = {
        entities = entities,
        current_index = 2
    }
    frame.add({ type = "button", name = "indvidual_deconstruct_entity", caption = "Deconstruct" }).tags = {
        entities = entities,
        current_index = 1
    }
    title.drag_target = frame
    Update_title_label(frame, entities[1])
    teleport_to_entity(player, entities[1])
end


function Update_title_label(frame, entity)
    if frame["entity_title_label"] then
        frame["entity_title_label"].caption = entity.name ..
            " - " .. entity.surface.name .. " - " .. entity.position.x .. ", " .. entity.position.y
    end
end

function Indvidual_gui_event(event)
    if not event or not event.element then return end
    local player = game.players[event.player_index]
    local element = event.element
    if not element or not element.valid then return end
    local name = element.name
    if (not name or name == "") or (name ~= "open_group" and name ~= "close_individual_gui" and name ~= "indvidual_next_entity" and name ~= "indvidual_previous_entity") then return end
    local tags = element.tags
    local frame = player.gui.screen.group_entities_gui_flow

    if name == "open_group" then
        open_individual_gui(player)
    elseif name == "close_individual_gui" then
        local frame = element.parent
        -- teleport_to_entity(player, frame.tags.previous_positions)
        set_xgui_data(player, "open_group", {})
        frame.destroy()
    elseif name == "indvidual_next_entity" or name == "indvidual_previous_entity" or name == "indvidual_deconstruct_entity" then
        local entities = tags.entities
        if not entities then return end
        local current_index = tags.current_index
        if name == "indvidual_next_entity" and current_index < #entities then
            current_index = current_index + 1
        elseif name == "indvidual_previous_entity" and current_index > 1 then
            current_index = current_index - 1
        end

        -- Update title label to reflect current entity
        Update_title_label(frame, entities[current_index])

        -- Ensure all buttons have the same current_index in their tags
        if frame["indvidual_next_entity"] then
            frame["indvidual_next_entity"].tags.current_index = current_index
        end
        if frame["indvidual_previous_entity"] then
            frame["indvidual_previous_entity"].tags.current_index = current_index
        end
        if frame["indvidual_deconstruct_entity"] then
            frame["indvidual_deconstruct_entity"].tags.current_index = current_index
        end

        if name == "indvidual_deconstruct_entity" and entities[current_index] then
            if entities[current_index] then
                entities[current_index].order_deconstruction(player.force)
            end
        else
            teleport_to_entity(player, entities[current_index])
        end
    end
end

-- script.on_event(defines.events.on_gui_closed, function(event)
--     if event.element and event.element.name == "my_custom_individual_gui" then
--         teleport_back(game.players[event.player_index])
--     end
-- end)
