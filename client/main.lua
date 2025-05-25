ESX = exports["es_extended"]:getSharedObject()

local spawnedProps = {}
local spawnedTargets = {}
local lastJob = nil
local orgBlip = nil

RegisterNetEvent('org_upgrades:applyModsToVehicle', function(netId, level)
    local veh = NetToVeh(netId)
    if not DoesEntityExist(veh) then return end

    SetVehicleModKit(veh, 0)
    if level >= 1 then SetVehicleMod(veh, 11, math.min(level - 1, 3), false) end
    if level >= 1 then SetVehicleMod(veh, 12, math.min(level - 1, 3), false) end
    if level >= 3 then SetVehicleMod(veh, 13, math.min(level - 3, 2), false) end
    if level >= 4 then SetVehicleMod(veh, 15, 1, false) end
    if level >= 5 then ToggleVehicleMod(veh, 18, true) end
end)

function openOrgUpgradeMenu()
    local playerData = ESX.GetPlayerData()

    if not playerData.job or playerData.job.grade_name ~= "boss" then
        lib.notify({
            title       = "Error",
            description = "Only the (BOSS) can access the upgrade menu",
            type        = "error"
        })
        return
    end

    local society = 'society_' .. playerData.job.name
    local options = {{
        title       = "Organization Points",
        description = "Loading...",
        icon        = "star",
        iconColor   = '#954692',
        disabled    = false
    }}

    local upgradeLevels = {}
    local callbackCount = 0
    local totalUpgrades = #Config.Upgrades

    lib.callback('org_upgrades:getPlatePrefix', false, function(prefix)
        upgradeLevels["plate_prefix"] = prefix or "N/A"

        lib.callback('org_upgrades:getPoints', false, function(points)
            options[1].description = "Currently: " .. tostring(points) .. " STAR Points"

            for i, upgradeData in ipairs(Config.Upgrades) do
                local upgradeKey = upgradeData.key

                lib.callback('org_upgrades:getUpgradeLevel', false, function(level)
                    level = tonumber(level) or 0
                    upgradeLevels[upgradeKey] = level

                    local displayTitle
                    if upgradeKey == "custom_plate" then
                        displayTitle = string.format('%s (%s)', upgradeData.label, upgradeLevels["plate_prefix"])
                    else
                        displayTitle = string.format('%s (Level %d/%d)', upgradeData.label, level, upgradeData.maxLevel)
                    end                 

                    table.insert(options, {
                        title = displayTitle,
                        description = upgradeData.description .. "\nPrice: " .. tostring(upgradeData.cost) .. " points",
                        icon = 'wrench',
                        iconColor = '#e7c946',
                        onSelect = function()
                            if upgradeKey == "custom_plate" then
                                local input = lib.inputDialog('Set Plate Prefix', {
                                    {
                                        type = 'input',
                                        label = 'Prefix (max 3 letters)',
                                        placeholder = 'Example: VGS',
                                        required = true
                                    }
                                })

                                if input and input[1] then
                                    local prefix = input[1]:upper()
                                    if not prefix:match("^[A-Z][A-Z]?[A-Z]?$") then
                                        lib.notify({
                                            title = "Error",
                                            description = "Prefix must contain only letters (max 3).",
                                            type = "error"
                                        })
                                        return
                                    end

                                    TriggerServerEvent('org_upgrades:setPlatePrefix', prefix)
                                end
                            else
                                lib.callback('org_upgrades:buyUpgrade', false, function(success, msg)
                                    lib.notify({
                                        title = success and "Success" or "Error",
                                        description = msg or "Unknown error"
                                    })
                                end, upgradeKey)
                            end
                        end
                    })

                    callbackCount += 1
                    if callbackCount == totalUpgrades then
                        table.insert(options, {
                            title = "Current Upgrade Status",
                            description = "Show all current upgrade levels",
                            icon = 'chart-line',
                            iconColor = '#3B82F6',
                            onSelect = function()
                                local info = {}
                                for _, upgrade in ipairs(Config.Upgrades) do
                                    local lvl = upgradeLevels[upgrade.key] or 0
                                    table.insert(info, string.format("- %s: %s", upgrade.label,
                                        upgrade.key == "custom_plate" and ("Prefix: " .. (upgradeLevels["plate_prefix"] or "N/A")) or (lvl .. "/" .. upgrade.maxLevel)))
                                end

                                lib.notify({
                                    title = "Organization Upgrade Status",
                                    description = table.concat(info, "\n"),
                                    type = "inform"
                                })
                            end
                        })

                        lib.registerContext({
                            id = 'org_upgrade_menu',
                            title = 'Organization Upgrades',
                            options = options
                        })

                        lib.showContext('org_upgrade_menu')
                    end
                end, society, upgradeKey)
            end
        end, society)
    end, society)
end

function PlaySpawnStyleEffect(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local playerData = ESX.GetPlayerData()
    local org = Config.Organizations[playerData.job.name]
    if not org or not org.color then return end

    local c = org.color

    TriggerScreenblurFadeIn(200)
    DoScreenFadeOut(200)
    Wait(300)
    DoScreenFadeIn(400)
    TriggerScreenblurFadeOut(500)

    local coords = GetEntityCoords(vehicle)
    CreateSpawnLight(coords, c.r, c.g, c.b)
end

function CreateSpawnLight(coords, r, g, b)
    local intensity = 1.0
    local duration = 10000

    CreateThread(function()
        local start = GetGameTimer()
        while GetGameTimer() - start < duration do
            DrawLightWithRange(coords.x, coords.y, coords.z, r, g, b, 8.0, intensity)
            Wait(0)
        end

        for i = 10, 1, -1 do
            intensity = i / 10
            DrawLightWithRange(coords.x, coords.y, coords.z, r, g, b, 8.0, intensity)
            Wait(150)
        end
    end)
end

function CreateLight(coords, r, g, b)
    local obj = CreateObject(`prop_worklight_03b`, coords.x, coords.y, coords.z - 0.5, false, false, false)
    SetEntityAlpha(obj, 0)
    SetEntityCollision(obj, false, false)
    FreezeEntityPosition(obj, true)

    CreateThread(function()
        while DoesEntityExist(obj) do
            DrawLightWithRange(coords.x, coords.y, coords.z, r, g, b, 8.0, 1.0)
            Wait(0)
        end
    end)

    return obj
end

function PlaySpawnCamera(vehicle)
    local ped = PlayerPedId()
    local vehCoords = GetEntityCoords(vehicle)

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    TaskStandStill(ped, 6000)

    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local camCoords = vec3(vehCoords.x, vehCoords.y, vehCoords.z + 20.0)
    SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtCoord(cam, vehCoords.x, vehCoords.y, vehCoords.z + 1.0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, true, true)

    PlaySoundFrontend(-1, "Zoom_In", "DLC_HEIST_PLANNING_BOARD_SOUNDS", true)

    local duration = 5000
    local startTime = GetGameTimer()
    CreateThread(function()
        while GetGameTimer() - startTime < duration do
            local progress = (GetGameTimer() - startTime) / duration
            local z = camCoords.z - (progress * 20.0)
            SetCamCoord(cam, camCoords.x, camCoords.y, z)
            Wait(0)
        end

        RenderScriptCams(false, true, 1000, true, true)
        DestroyCam(cam, false)

        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
    end)
end

function spawnVehicle(model, coords)
    local playerData = ESX.GetPlayerData()
    ESX.Game.SpawnVehicle(model, coords, 0.0, function(vehicle)
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
        PlaySpawnStyleEffect(vehicle)
        SetVehicleFuelLevel(vehicle, 100.0)
        local org = Config.Organizations[playerData.job.name]

        if org and org.color then
            local c = org.color
            SetVehicleCustomPrimaryColour(vehicle, c.r, c.g, c.b)
            SetVehicleCustomSecondaryColour(vehicle, c.r, c.g, c.b)
        end

        local society = 'society_' .. playerData.job.name

        lib.callback('org_upgrades:getPlatePrefix', false, function(prefix)
            local plate
            if prefix and prefix:match("^[A-Z][A-Z]?[A-Z]?$") then
                plate = prefix .. GetRandomString(5)
            else
                plate = GetRandomString(8)
            end
            plate = string.upper(string.sub(plate, 1, 8))
            SetVehicleNumberPlateText(vehicle, plate)

            TriggerServerEvent('org_upgrades:logVehicleSpawn', model, plate)
        end, society)

        TriggerServerEvent('org_upgrades:applyVehicleMods', VehToNet(vehicle))

        lib.notify({
            title = 'Garage',
            description = 'Vehicle spawned successfully',
            type = 'success'
        })

        lib.callback('org_upgrades:getUpgradeLevel', false, function(level)
            if level and level > 0 then
                lib.notify({
                    title = 'Tuning',
                    description = 'Organization tunning is applied to the vehicle',
                    type = 'inform'
                })
            end
        end, society, 'vehicle_mods')
        PlaySpawnCamera(vehicle)
    end)
end

function GetRandomString(length)
    local charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local output = ''
    for i = 1, length do
        local r = math.random(1, #charset)
        output = output .. charset:sub(r, r)
    end
    return output
end


function openGarageMenu(org)
    local options = {}

    for _, v in pairs(org.vehicles) do
        table.insert(options, {
            title = v.label,
            icon = 'car-side',
            onSelect = function()
                spawnVehicle(v.model, org.locations.vehspawn)
            end
        })
    end

    lib.registerContext({
        id = 'org_garage_menu_' .. org.label,
        title = 'Organization Vehicles - ' .. org.label,
        options = options
    })

    lib.showContext('org_garage_menu_' .. org.label)
end

local function spawnOrgProp(model, coords, heading)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local prop = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(prop, heading or 0.0)
    SetEntityAlpha(prop, 0)
    FreezeEntityPosition(prop, true)
    SetEntityCollision(prop, false, false)

    for alpha = 0, 255, 15 do
        Wait(10)
        SetEntityAlpha(prop, alpha)
    end

    SetEntityCollision(prop, true, true)
    SetEntityAsMissionEntity(prop, true, true)

    table.insert(spawnedProps, prop)
end

CreateThread(function()
    while true do
        Wait(3000)

        local playerData = ESX.GetPlayerData()
        local job = playerData.job and playerData.job.name

        if job ~= lastJob then
            lastJob = job

            clearOrgTargets()

            for _, prop in pairs(spawnedProps) do
                if DoesEntityExist(prop) then
                    DeleteEntity(prop)
                end
            end
            spawnedProps = {}

            if orgBlip then
                RemoveBlip(orgBlip)
                orgBlip = nil
            end

            local org = Config.Organizations[job]
            if org then

                spawnOrgTargets(job, org)

                if org.locations.boss then
                    orgBlip = AddBlipForCoord(org.locations.boss)
                    SetBlipSprite(orgBlip, 437)
                    SetBlipDisplay(orgBlip, 4)
                    SetBlipScale(orgBlip, 0.8)
                    SetBlipColour(orgBlip, org.blipColor or 5)
                    SetBlipAsShortRange(orgBlip, true)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString("Baza " .. org.label)
                    EndTextCommandSetBlipName(orgBlip)
                end

                if org.safeprop and org.locations.safe then
                    spawnOrgProp(org.safeprop, org.locations.safe.xyz, org.locations.safe.w)
                end

                if org.bossprop and org.locations.boss then
                    spawnOrgProp(org.bossprop, org.locations.boss.xyz, org.locations.boss.w)
                end

                if org.garageprop and org.locations.garage then
                    spawnOrgProp(org.garageprop, org.locations.garage.xyz, org.locations.garage.w)
                end
            end
        end
    end
end)

RegisterNetEvent('org_upgrades:openStashClient', function(stashId, coords)
    --print("[STASH] Otvaram stash na clientu: " .. stashId)
    exports.ox_inventory:openInventory('stash', {
        id = stashId,
        coords = coords
    })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, prop in pairs(spawnedProps) do
        if DoesEntityExist(prop) then DeleteEntity(prop) end
    end
end)

function spawnOrgTargets(orgName, org)
    if not org then return end

    if org.locations.safe then
        local id = exports.ox_target:addBoxZone({
            coords = org.locations.safe.xyz,
            size = vec3(2, 2, 2),
            rotation = 0,
            options = {{
                name = 'org_safe_' .. orgName,
                icon = 'fas fa-archive',
                label = 'Access Stash',
                distance = 2,
                onSelect = function()
                    TriggerServerEvent('org_upgrades:openStash')
                end
            }}
        })
        table.insert(spawnedTargets, id)
    end

    if org.locations.garage then
        local id = exports.ox_target:addBoxZone({
            coords = org.locations.garage,
            size = vec3(2, 2, 2),
            rotation = 0,
            options = {
                {
                    name = 'org_garage_spawn_' .. orgName,
                    icon = 'fas fa-car',
                    label = 'Garage',
                    distance = 2,
                    canInteract = function()
                        -- using ox_lib cache:
                        return not cache.vehicle
                        -- if you prefer native:
                        -- local ped = PlayerPedId()
                        -- return not IsPedInAnyVehicle(ped, false)
                    end,
                    onSelect = function()
                        openGarageMenu(org)
                    end
                },
                {
                    name = 'org_garage_return_' .. orgName,
                    icon = 'fas fa-redo',
                    label = 'Return Vehicle',
                    distance = 5,
                    canInteract = function()
                        local ped = PlayerPedId()
                        local veh = GetVehiclePedIsIn(ped, false)
                        return cache.vehicle and cache.seat == -1
                    end,
                    onSelect = function()
                        local ped = PlayerPedId()
                        local veh = GetVehiclePedIsIn(ped, false)
                    
                        if veh and GetPedInVehicleSeat(veh, -1) == ped then

                            TaskLeaveVehicle(ped, veh, 0)
                            
                            Wait(1000)
                    
                            CreateThread(function()
                                local alpha = 255
                                local startTime = GetGameTimer()
                                local duration = 3000
                    
                                while GetGameTimer() - startTime < duration do
                                    local elapsed = GetGameTimer() - startTime
                                    alpha = 255 - math.floor((elapsed / duration) * 255)
                                    if alpha < 0 then alpha = 0 end
                    
                                    SetEntityAlpha(veh, alpha)
                                    Wait(50)
                                end
                    
                                if DoesEntityExist(veh) then
                                    DeleteEntity(veh)
                                end
                    
                                lib.notify({title = 'Garage', description = 'Vehicle returned in garage', type = 'success'})
                            end)
                        else
                            lib.notify({title = 'Garage', description = 'You need to be in vehicle', type = 'error'})
                        end
                    end
                }
            }
        })
        table.insert(spawnedTargets, id)
    end

    if org.locations.boss then
        local id = exports.ox_target:addBoxZone({
            coords = org.locations.boss,
            size = vec3(2, 2, 2),
            rotation = 0,
            options = {
                {
                    name = 'org_bossmenu_' .. orgName,
                    icon = 'fas fa-briefcase',
                    label = 'Boss Menu',
                    distance = 2,
                    canInteract = function()
                        local data = ESX.GetPlayerData()
                        return data.job and data.job.grade_name == 'boss'
                    end,
                    onSelect = function()
                        TriggerEvent('esx_society:openBossMenu', orgName, function(data, menu)
                            menu.close()
                        end, { wash = false })
                    end
                },
                {
                    name = 'org_upgrades_' .. orgName,
                    icon = 'fas fa-star',
                    label = 'Organization Upgrades',
                    distance = 2,
                    canInteract = function()
                        local data = ESX.GetPlayerData()
                        return data.job and data.job.grade_name == 'boss'
                    end,
                    onSelect = function()
                        openOrgUpgradeMenu()
                    end
                }
            }
        })
        table.insert(spawnedTargets, id)
    end
end


function clearOrgTargets()
    for _, id in ipairs(spawnedTargets) do
        exports.ox_target:removeZone(id)
    end
    spawnedTargets = {}
end
