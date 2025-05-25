RegisterNetEvent('org:tiePlayerServer', function(targetId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local targetPlayer = ESX.GetPlayerFromId(targetId)

    xPlayer.removeInventoryItem(Config.RopeItem, 1)
    TriggerClientEvent('org:tiePlayer', targetId, true)

    local sourceDiscord = getIdentifiers(source)
    local targetDiscord = getIdentifiers(targetId)

    sendDiscordLog(
        '👮‍♂️ Player Tied',
        ('**%s** (%s) tied **%s** (%s)')
        :format(xPlayer.getName(), sourceDiscord, targetPlayer.getName(), targetDiscord),
        16711680
    )
end)

RegisterNetEvent('org:untiePlayerServer', function(targetId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local targetPlayer = ESX.GetPlayerFromId(targetId)

    xPlayer.addInventoryItem(Config.RopeItem, 1)
    TriggerClientEvent('org:tiePlayer', targetId, false)

    local sourceDiscord = getIdentifiers(source)
    local targetDiscord = getIdentifiers(targetId)

    sendDiscordLog(
        '🤝 Player Untied',
        ('**%s** (%s) untied **%s** (%s)')
        :format(xPlayer.getName(), sourceDiscord, targetPlayer.getName(), targetDiscord),
        65280
    )
end)
