local isTied = false

RegisterNetEvent('org:tiePlayer', function(state)
    local playerPed = cache.ped
    if state then
        isTied = true
        RequestAnimDict('mp_arresting')
        while not HasAnimDictLoaded('mp_arresting') do Wait(10) end
        TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0, false, false, false)
        CreateThread(function()
            while isTied do
                Wait(0)
                DisableAllControlActions(0)
            end
        end)
    else
        isTied = false
        ClearPedTasks(playerPed)
    end
end)

local function IsBehindTarget(targetPed)
    local targetCoords = GetEntityCoords(targetPed)
    local targetHeading = GetEntityHeading(targetPed)

    local angleToPlayer = math.deg(math.atan2(cache.coords.y - targetCoords.y, cache.coords.x - targetCoords.x))
    local angleDiff = math.abs((angleToPlayer - targetHeading + 360) % 360)

    return angleDiff >= 120 and angleDiff <= 240
end

exports.ox_target:addGlobalPlayer({
    {
        name = 'org_tie',
        icon = 'fa-solid fa-user-lock',
        label = 'Tie',
        distance = 2.0,
        items = Config.RopeItem,
        canInteract = function(entity)
            return IsPedAPlayer(entity) and not isTied and IsBehindTarget(entity)
        end,
        onSelect = function(data)
            local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
            TriggerServerEvent('org:tiePlayerServer', targetServerId)
        end
    },
    {
        name = 'org_untie',
        icon = 'fa-solid fa-user-check',
        label = 'Untie',
        distance = 2.0,
        items = Config.RopeItem,
        canInteract = function(entity)
            return IsPedAPlayer(entity) and not isTied
        end,
        onSelect = function(data)
            local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
            TriggerServerEvent('org:untiePlayerServer', targetServerId)
        end
    }
})