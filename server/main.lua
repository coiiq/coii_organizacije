ESX = exports["es_extended"]:getSharedObject()

lib.callback.register('org_upgrades:getPoints', function(source, society)
    local result = MySQL.scalar.await('SELECT points FROM org_upgrades WHERE society = ?', {society})
    return result or 0
end)

exports('addPoints', function(society, amount)
    local current = MySQL.scalar.await('SELECT points FROM org_upgrades WHERE society = ?', {society})
    if current then
        MySQL.update.await('UPDATE org_upgrades SET points = points + ? WHERE society = ?', {amount, society})
    else
        MySQL.insert.await('INSERT INTO org_upgrades (society, points) VALUES (?, ?)', {society, amount})
    end

    local source = source
    if source then
        local ids = getIdentifiers(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        sendDiscordLog("⭐ Added STAR points",
            string.format("**%s** (%s)\n**Organization:** %s\n**Added:** +%d points\n**License:** `%s`\n**Discord:** %s",
            xPlayer and xPlayer.getName() or "N/A", source, society, amount, ids.license, ids.discord),
            16497928
        )
    end
end)

local function removePointsInternal(society, amount)
    MySQL.update('UPDATE org_upgrades SET points = GREATEST(points - ?, 0) WHERE society = ?', {amount, society})
end

exports('removePoints', removePointsInternal)

exports('getUpgradeLevel', function(society, upgradeKey)
    local result = MySQL.single.await('SELECT ?? FROM org_upgrades WHERE society = ?', {upgradeKey, society})
    return result and result[upgradeKey] or 0
end)

lib.callback.register('org_upgrades:getUpgradeLevel', function(source, society, upgradeKey)
    local result = MySQL.single.await('SELECT ?? FROM org_upgrades WHERE society = ?', {upgradeKey, society})
    return result and result[upgradeKey] or 0
end)

lib.callback.register('org_upgrades:getPlatePrefix', function(source, society)
    local result = MySQL.single.await('SELECT plate_prefix FROM org_upgrades WHERE society = ?', {society})
    return result and result.plate_prefix or nil
end)

lib.callback.register('org_upgrades:buyUpgrade', function(source, upgradeKey)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return false, "Player not found."
    end

    local society = 'society_' .. xPlayer.job.name

    local upgrade = nil
    for _, u in ipairs(Config.Upgrades) do
        if u.key == upgradeKey then
            upgrade = u
            break
        end
    end

    if not upgrade then
        return false, "Invalid upgrade."
    end

    local result = MySQL.single.await(
        'SELECT ??, points FROM org_upgrades WHERE society = ?',
        { upgradeKey, society }
    )
    if not result then
        return false, "Organization not found."
    end

    local currentLevel = tonumber(result[upgradeKey]) or 0
    if currentLevel >= upgrade.maxLevel then
        return false, "Upgrade is already at maximum level."
    end

    if result.points < upgrade.cost then
        return false, "Not enough STAR points."
    end

    MySQL.update.await(
        string.format(
            "UPDATE org_upgrades SET `%s` = %s + 1, points = points - %s WHERE society = ?",
            upgradeKey, upgradeKey, upgrade.cost
        ),
        { society }
    )

    local newLevel = currentLevel + 1
    local ids = getIdentifiers(source)
    sendDiscordLog(
        "⭐ Upgrade Purchased",
        string.format(
            "**%s** (%s)\n" ..
            "**License:** `%s`\n" ..
            "**Discord:** %s\n" ..
            "**Organization:** `%s`\n" ..
            "**Upgrade:** `%s`\n" ..
            "**New level:** `%d/%d`\n" ..
            "**Price:** `%d` STAR points",
            xPlayer.getName(),
            source,
            ids.license or "N/A",
            ids.discord or "N/A",
            society,
            upgrade.label,
            newLevel,
            upgrade.maxLevel,
            upgrade.cost
        ),
        3066993
    )

    return true, "Upgrade purchased: " .. upgrade.label
end)

RegisterNetEvent('org_upgrades:applyVehicleMods', function(netId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local society = 'society_' .. xPlayer.job.name
    local result = MySQL.single.await('SELECT vehicle_mods FROM org_upgrades WHERE society = ?', {society})
    local level = result and result.vehicle_mods or 0

    if level < 1 then return end

    TriggerClientEvent('org_upgrades:applyModsToVehicle', src, netId, level)
end)

function sendDiscordLog(title, description, color)
    local embed = {{
        title = title,
        description = description,
        color = color or 16776960,
        footer = { text = os.date('%d.%m.%Y | %X') }
    }}

    PerformHttpRequest(Config.Webhook, function() end, 'POST', json.encode({ embeds = embed }), {
        ['Content-Type'] = 'application/json'
    })
end

function getIdentifiers(src)
    local ids = { discord = "N/A", license = "N/A" }
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:match("discord:") then
            ids.discord = "<@" .. id:gsub("discord:", "") .. ">"
        elseif id:match("license:") then
            ids.license = id:gsub("license:", "")
        end
    end
    return ids
end

RegisterNetEvent('org_upgrades:logVehicleSpawn', function(model, plate)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local ids = getIdentifiers(src)
    local job = xPlayer.job.name

    sendDiscordLog("🚗 Vehicle Taken out",
        string.format("**%s** (%s)\n**Job:** %s\n**Vehicle:** `%s`\n**Plates:** `%s`\n**License:** `%s`\n**Discord:** %s",
        xPlayer.getName(), src, job, model, plate or "N/A", ids.license, ids.discord),
        5763719
    )
end)

RegisterNetEvent('org_upgrades:openStash', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local job = xPlayer.job.name
    local society = 'society_' .. job
    local result = MySQL.single.await('SELECT safe_weight FROM org_upgrades WHERE society = ?', {society})
    local level = result and result.safe_weight or 0

    local baseWeight = 100000
    local bonusPerLevel = 50000
    local maxWeight = baseWeight + (level * bonusPerLevel)

    local stashId = 'org_' .. job
    local org = Config.Organizations[job]
    if not org then return end

    exports.ox_inventory:RegisterStash(stashId, 'Organization Stash - ' .. org.label, 50, maxWeight, false, {[job] = 0}, org.locations.safe.xyz)

    --print("[STASH] Registrujem stash za: " .. stashId)
    --print("[STASH] Koordinata: " .. json.encode(org.locations.safe.xyz))
    --print("[STASH] Max tezina: " .. maxWeight)    

    TriggerClientEvent('org_upgrades:openStashClient', src, stashId, org.locations.safe.xyz)
end)

function sendLeaderboardLog(title, description, color)
    local embed = {{
        title = title,
        description = description,
        color = color or 16753920,
        footer = { text = os.date('%d.%m.%Y | %X') }
    }}

    PerformHttpRequest(Config.LeaderboardWebhook, function() end, 'POST', json.encode({ embeds = embed }), {
        ['Content-Type'] = 'application/json'
    })
end

CreateThread(function()
    while true do
        Wait(1000 * 60 * 60 * 10) 

        local results = MySQL.query.await('SELECT society, points FROM org_upgrades ORDER BY points DESC LIMIT 5')
        if not results or #results == 0 then return end

        local lines = {}
        for i, row in ipairs(results) do
            local orgLabel = getOrgLabelFromSociety(row.society)
            table.insert(lines, string.format("**%d.** %s - **%d ⭐**", i, orgLabel, row.points))
        end

        sendLeaderboardLog("📊 TOP ORGANIZATIONS (STAR POINTS)", table.concat(lines, "\n"), 1752220)
    end
end)

function getOrgLabelFromSociety(society)
    for _, org in pairs(Config.Organizations) do
        if org.society == society then
            return org.label
        end
    end
    return society
end

function isValidSociety(society)
    for _, org in pairs(Config.Organizations) do
        if org.society == society then
            return true
        end
    end
    return false
end

local function hasPermission(xPlayer)
    return Config.StarAdminGroups[xPlayer.getGroup()] == true
end

RegisterCommand(Config.StarCommands.add, function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not hasPermission(xPlayer) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'You dont have access to this command',
            type = 'error'
        })
        return
    end

    local rawName = args[1]
    local amount = tonumber(args[2])

    if not rawName or not amount then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'Usage: /addstar [organization] [number]',
            type = 'error'
        })
        return
    end

    local society = rawName:find('^society_') and rawName or 'society_' .. rawName

    if not isValidSociety(society) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'Organization "' .. rawName .. '" dont exist',
            type = 'error'
        })
        return
    end

    addPointsInternal(society, amount)

    local ids = getIdentifiers(source)
    local label = getOrgLabelFromSociety(society)

    sendDiscordLog("⭐ Adding STAR points (Admin)",
        string.format(
            "**%s** (%s)\n" ..
            "**Organization:** %s\n" ..
            "**Added:** +%d points\n" ..
            "**License:** `%s`\n" ..
            "**Discord:** %s",
            xPlayer.getName(),
            source,
            label,
            amount,
            ids.license,
            ids.discord
        ),
        5763719
    )

    TriggerClientEvent('ox_lib:notify', source, {
        title       = 'STAR Points',
        description = 'Added ' .. amount .. ' ⭐ points to ' .. label,
        type        = 'success'
    })
end)

RegisterCommand(Config.StarCommands.remove, function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not hasPermission(xPlayer) then
        TriggerClientEvent('ox_lib:notify', source, {
            title       = 'Error',
            description = 'You do not have permission to use this command.',
            type        = 'error'
        })
        return
    end

    local rawName = args[1]
    local amount  = tonumber(args[2])

    if not rawName or not amount then
        TriggerClientEvent('ox_lib:notify', source, {
            title       = 'Error',
            description = 'Usage: /removestar [organization] [amount]',
            type        = 'error'
        })
        return
    end

    local society = rawName:find('^society_') and rawName or 'society_' .. rawName

    if not isValidSociety(society) then
        TriggerClientEvent('ox_lib:notify', source, {
            title       = 'Error',
            description = 'Organization "' .. rawName .. '" does not exist',
            type        = 'error'
        })
        return
    end

    MySQL.update.await(
        'UPDATE org_upgrades SET points = GREATEST(points - ?, 0) WHERE society = ?',
        { amount, society }
    )

    local ids   = getIdentifiers(source)
    local label = getOrgLabelFromSociety(society)

    sendDiscordLog("⭐ Removing STAR points (Admin)",
        string.format(
            "**%s** (%s)\n" ..
            "**Organization:** %s\n" ..
            "**Removed:** -%d points\n" ..
            "**License:** `%s`\n" ..
            "**Discord:** %s",
            xPlayer.getName(),
            source,
            label,
            amount,
            ids.license,
            ids.discord
        ),
        15548997
    )

    TriggerClientEvent('ox_lib:notify', source, {
        title       = 'STAR Points',
        description = 'Removed ' .. amount .. ' ⭐ points from ' .. label,
        type        = 'inform'
    })
end)

RegisterCommand(Config.StarCommands.check, function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not hasPermission(xPlayer) then
        TriggerClientEvent('ox_lib:notify', source, {
            title       = 'Error',
            description = 'You do not have permission to use this command',
            type        = 'error'
        })
        return
    end

    local rawName = args[1]
    if not rawName then
        TriggerClientEvent('ox_lib:notify', source, {
            title       = 'Error',
            description = 'Usage: /' .. Config.StarCommands.check .. ' [organization]',
            type        = 'error'
        })
        return
    end

    local society = rawName:find('^society_') and rawName or 'society_' .. rawName

    if not isValidSociety(society) then
        TriggerClientEvent('ox_lib:notify', source, {
            title       = 'Error',
            description = 'Organization "' .. rawName .. '" does not exist',
            type        = 'error'
        })
        return
    end

    local points = MySQL.scalar.await('SELECT points FROM org_upgrades WHERE society = ?', { society }) or 0
    local label  = getOrgLabelFromSociety(society)

    TriggerClientEvent('ox_lib:notify', source, {
        title       = 'STAR Points',
        description = label .. ' currently has ' .. points .. ' ⭐ points',
        type        = 'info'
    })
end)

function addPointsInternal(society, amount)
    local current = MySQL.scalar.await('SELECT points FROM org_upgrades WHERE society = ?', { society })
    if current then
        MySQL.update.await(
            'UPDATE org_upgrades SET points = points + ? WHERE society = ?',
            { amount, society }
        )
    else
        MySQL.insert.await(
            'INSERT INTO org_upgrades (society, points) VALUES (?, ?)',
            { society, amount }
        )
    end
end

RegisterNetEvent('org_upgrades:setPlatePrefix', function(prefix)
    local src     = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if type(prefix) ~= "string" then return end
    prefix = prefix:upper()

    if not prefix:match("^[A-Z][A-Z]?[A-Z]?$") then
        TriggerClientEvent('ox_lib:notify', src, {
            title       = 'Error',
            description = 'Prefix must contain only letters (max 3)',
            type        = 'error'
        })
        return
    end

    local society = 'society_' .. xPlayer.job.name

    local cost = 0
    for _, upgrade in ipairs(Config.Upgrades) do
        if upgrade.key == "custom_plate" then
            cost = upgrade.cost
            break
        end
    end

    local result = MySQL.single.await(
        'SELECT points FROM org_upgrades WHERE society = ?',
        { society }
    )
    if not result or result.points < cost then
        TriggerClientEvent('ox_lib:notify', src, {
            title       = 'Error',
            description = 'Organization does not have enough STAR points to set a custom plate',
            type        = 'error'
        })
        return
    end

    MySQL.update.await(
        'UPDATE org_upgrades SET plate_prefix = ? WHERE society = ?',
        { prefix, society }
    )

    removePointsInternal(society, cost)

    sendDiscordLog("Custom License Plate Set",
        string.format(
            "**%s** (%s) set plate prefix: `%sXXX` for `%s`",
            xPlayer.getName(),
            src,
            prefix,
            society
        ),
        3447003
    )

    TriggerClientEvent('ox_lib:notify', src, {
        title       = 'License Plate',
        description = 'Plate prefix set to: ' .. prefix,
        type        = 'success'
    })
end)

RegisterCommand(Config.StarCommands.resetplates, function(source, args)
    local src     = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if src ~= 0 and not Config.StarAdminGroups[xPlayer.group] then
        TriggerClientEvent('ox_lib:notify', src, {
            title       = 'Error',
            description = 'You do not have permission to use this command.',
            type        = 'error'
        })
        return
    end

    local org = args[1]
    if not org then
        if src ~= 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title       = 'Error',
                description = 'Please enter an organization name.',
                type        = 'error'
            })
        else
            print("Please enter an organization name.")
        end
        return
    end

    local society = "society_" .. org
    local result  = MySQL.update.await(
        'UPDATE org_upgrades SET plate_prefix = NULL WHERE society = ?',
        { society }
    )

    if src ~= 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title       = 'Plate Prefix Reset',
            description = result > 0
                and ('Prefix reset for: ' .. society)
                or 'Organization not found.',
            type        = result > 0 and 'success' or 'error'
        })

        if result > 0 then
            local ids = getIdentifiers(src)
            sendDiscordLog("🔁 License Plate Prefix Reset",
                string.format(
                    "**%s** (%s) has reset the plate prefix for `%s`\n" ..
                    "**License:** `%s`\n" ..
                    "**Discord:** %s",
                    xPlayer.getName(),
                    src,
                    society,
                    ids.license,
                    ids.discord
                ),
                16760576
            )
        end
    else
        print(
            result > 0
            and ('[SUCCESS] Prefix reset for: ' .. society)
            or '[ERROR] Organization not found.'
        )
    end
end, true)


