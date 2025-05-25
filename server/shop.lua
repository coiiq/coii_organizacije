local function sendShopDiscordLog(title, description, color)
    if not Config.ShopWebhook or Config.ShopWebhook == "" then return end

    local embed = {{
        title = title,
        description = description,
        color = color or 16776960,
        footer = { text = os.date('%d.%m.%Y | %X') }
    }}

    PerformHttpRequest(Config.ShopWebhook, function() end, 'POST', json.encode({ embeds = embed }), {
        ['Content-Type'] = 'application/json'
    })
end

RegisterNetEvent('org_upgrades:purchaseItem', function(itemName, itemPrice)
    local src     = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if not itemName or not itemPrice then
        DropPlayer(src, "Attempt to purchase a non-existent item!")
        return
    end

    if not xPlayer.job or xPlayer.job.grade_name ~= 'boss' then
        TriggerClientEvent('ox_lib:notify', src, {
            title       = "Shop",
            description = "Only the (BOSS) can access the shop!",
            type        = "error"
        })
        return
    end

    local society = 'society_' .. xPlayer.job.name
    local result  = MySQL.single.await('SELECT points FROM org_upgrades WHERE society = ?', { society })

    if not result or result.points < tonumber(itemPrice) then
        TriggerClientEvent('ox_lib:notify', src, {
            title       = "Shop",
            description = "You don't have enough STAR points!",
            type        = "error"
        })
        TriggerClientEvent('org_upgrades:noPointsScreenShake', src)
        return
    end

    MySQL.update.await('UPDATE org_upgrades SET points = points - ? WHERE society = ?', { itemPrice, society })
    xPlayer.addInventoryItem(itemName, 1)

    local ids = getIdentifiers(src)
    sendShopDiscordLog("🛒 Shop Purchase",
        string.format(
            "**%s** (%s)\n" ..
            "**License:** `%s`\n" ..
            "**Discord:** %s\n" ..
            "**Purchased item:** `%s`\n" ..
            "**Price:** `%d` STAR points",
            xPlayer.getName(),
            src,
            ids.license or "N/A",
            ids.discord or "N/A",
            itemName,
            tonumber(itemPrice)
        ),
        15844367
    )

    TriggerClientEvent('ox_lib:notify', src, {
        title       = "Shop",
        description = "You purchased: " .. itemName,
        type        = "success"
    })
end)

RegisterNetEvent('org_upgrades:logShopLocation', function(coords)
    sendShopDiscordLog("ORGANIZATION SHOP",
        string.format(
            "The shop appeared at coordinates: **X:** %.2f **Y:** %.2f **Z:** %.2f",
            coords.x, coords.y, coords.z
        ),
        8311585
    )
end)
