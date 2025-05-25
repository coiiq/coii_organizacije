
local activeVan = nil
local activePed = nil
local activeVanTarget = nil
local spawnedProps = {}
local shopBlip = nil

function spawnSecretVan()
    if activeVan then
        deleteSecretVan()
    end

    local modelVan = Config.VanModel
    local modelPed = Config.PedModel
    local spawnData = Config.VanLocations[math.random(#Config.VanLocations)]

    RequestModel(modelVan)
    while not HasModelLoaded(modelVan) do Wait(0) end

    RequestModel(modelPed)
    while not HasModelLoaded(modelPed) do Wait(0) end

    activeVan = CreateVehicle(Config.VanModel, spawnData.coords.x, spawnData.coords.y, spawnData.coords.z, spawnData.heading, false, false)
    SetEntityAsMissionEntity(activeVan, true, true)
    SetVehicleDoorsLocked(activeVan, 2)
    SetEntityInvincible(activeVan, true)
    SetVehicleUndriveable(activeVan, true)
    
    local pedPos = GetOffsetFromEntityInWorldCoords(activeVan, Config.PedOffset.x, Config.PedOffset.y, Config.PedOffset.z)
    activePed = CreatePed(4, Config.PedModel, pedPos.x, pedPos.y, pedPos.z, Config.PedHeadingOffset, false, true)
    SetEntityInvincible(activePed, true)
    FreezeEntityPosition(activePed, true)
    
    RequestAnimDict(Config.PedAnimation.dict)
    while not HasAnimDictLoaded(Config.PedAnimation.dict) do Wait(0) end
    TaskPlayAnim(activePed, Config.PedAnimation.dict, Config.PedAnimation.anim, 8.0, -8.0, -1, 1, 0, false, false, false)

    activeVanTarget = exports.ox_target:addLocalEntity(activeVan, {
        {
            icon = 'fa-solid fa-box',
            label = 'Access Shop',
            distance = 2.5,
            onSelect = function()
                openSecretShop()
            end
        }
    })

    CreateThread(function()
        while activeVan and DoesEntityExist(activeVan) do
            Wait(500)
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                if veh == activeVan then
                    TaskLeaveVehicle(ped, veh, 16)
                    lib.notify({
                        title = 'Shop',
                        description = 'You cant drive that vehicle!',
                        type = 'error'
                    })
                end
            end
        end
    end)
end

function deleteSecretVan()
    if activeVanTarget then
        exports.ox_target:removeLocalEntity(activeVanTarget)
        activeVanTarget = nil
    end
    if shopBlip then
        RemoveBlip(shopBlip)
        shopBlip = nil
    end
    if activeVan and DoesEntityExist(activeVan) then
        DeleteEntity(activeVan)
        activeVan = nil
    end
    if activePed and DoesEntityExist(activePed) then
        DeleteEntity(activePed)
        activePed = nil
    end
end

function openSecretShop()
    if activeVanTarget then
        exports.ox_target:removeLocalEntity(activeVanTarget)
        activeVanTarget = nil
    end

    local options = {}

    for _, item in ipairs(Config.ShopItems) do
        table.insert(options, {
            title = item.label,
            description = "Price: " .. item.price .. " STAR points",
            icon = 'box',
            iconColor = '#1199b0',
            onSelect = function()
                spawnShopProp(item.prop, item.item, item.price)
            end
        })
    end

    lib.registerContext({
        id = 'secret_org_shop',
        title = 'Secret Organization Shop',
        options = options
    })

    lib.showContext('secret_org_shop')
end

function spawnShopProp(propModel, itemName, itemPrice)
    local playerPed = PlayerPedId()

    SetVehicleDoorOpen(activeVan, 2, false, false)
    SetVehicleDoorOpen(activeVan, 3, false, false)

    PlaySoundFrontend(-1, "Boss_Message_Orange", "GTAO_Boss_Goons_FM_Soundset", true)

    local dict = "core"
    local particle = "exp_grd_grenade_smoke"
    
    RequestNamedPtfxAsset(dict)
    while not HasNamedPtfxAssetLoaded(dict) do
        Wait(0)
    end
    
    UseParticleFxAssetNextCall(dict)
    
    local particleFx = StartParticleFxLoopedAtCoord(
        particle,
        GetEntityCoords(activeVan).x,
        GetEntityCoords(activeVan).y,
        GetEntityCoords(activeVan).z -1,
        0.0, 0.0, 0.0,
        1.0,
        false, false, false, false
    )
    
    CreateThread(function()
        Wait(5000)
        if particleFx then
            StopParticleFxLooped(particleFx, false)
        end
    end)

    CreateThread(function()
        local lightTime = GetGameTimer() + 10000
        while GetGameTimer() < lightTime do
            DrawLightWithRange(GetEntityCoords(activeVan).x, GetEntityCoords(activeVan).y, GetEntityCoords(activeVan).z + 1.5, 140, 60, 170, 4.0, 5.0)
            Wait(0)
        end
    end)

    ShakeGameplayCam('VIBRATE_SHAKE', 0.3)

    Wait(700)

    local spawnCoords = GetOffsetFromEntityInWorldCoords(activeVan, 0.0, -2.0, 0.7)
    RequestModel(propModel)
    while not HasModelLoaded(propModel) do Wait(0) end

    activeProp = CreateObjectNoOffset(propModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, true, true, true)
    FreezeEntityPosition(activeProp, true)
    SetEntityAlpha(activeProp, 255, false)

    activeItem = itemName
    activePrice = itemPrice 
    confirming = true

    FreezeEntityPosition(playerPed, true)
    FreezeEntityPosition(activeVan, true)

    local camCoords = GetOffsetFromEntityInWorldCoords(activeVan, 0.0, -3.0, 0.8)
    shopCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(shopCam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtEntity(shopCam, activeProp, 0.0, 0.0, 0.0, true)
    SetCamActive(shopCam, true)
    RenderScriptCams(true, true, 1000, true, true)

    CreateThread(function()
        while confirming and DoesEntityExist(activeProp) do
            local heading = GetEntityHeading(activeProp)
            SetEntityHeading(activeProp, heading + 1.0)
            Wait(10)
        end
    end)

    lib.showTextUI("[ENTER] - Confirm purchase | [BACKSPACE] - Cancel", {
        position = "right-center",
        icon     = "hand-holding-usd",
        style = {
            backgroundColor = '#141414',
            color           = '#ffffff'
        }
    })

    CreateThread(function()
        while confirming do
            if IsControlJustReleased(0, 18) then
                confirmPurchase()
                break
            elseif IsControlJustReleased(0, 177) then
                cancelPurchase()
                break
            end
            Wait(0)
        end
    end)
end

function confirmPurchase()
    confirming = false

    if activeProp and DoesEntityExist(activeProp) then
        for i = 255, 0, -15 do
            SetEntityAlpha(activeProp, i, false)
            Wait(30)
        end
        DeleteEntity(activeProp)
        activeProp = nil
    end

    lib.hideTextUI()

    if shopCam then
        RenderScriptCams(false, true, true, true, true)
        DestroyCam(shopCam, false)
        shopCam = nil
    end

    FreezeEntityPosition(PlayerPedId(), false)
    FreezeEntityPosition(activeVan, true)

    SetVehicleDoorShut(activeVan, 2, false)
    SetVehicleDoorShut(activeVan, 3, false)

    if activeItem then
        TriggerServerEvent('org_upgrades:purchaseItem', activeItem, activePrice)
    end

end

function cancelPurchase()
    confirming = false

    if activeProp and DoesEntityExist(activeProp) then
        DeleteEntity(activeProp)
        activeProp = nil
    end

    lib.hideTextUI()

    if shopCam then
        RenderScriptCams(false, true, true, true, true)
        DestroyCam(shopCam, false)
        shopCam = nil
    end

    FreezeEntityPosition(PlayerPedId(), false)
    FreezeEntityPosition(activeVan, true)

    SetVehicleDoorShut(activeVan, 2, false)
    SetVehicleDoorShut(activeVan, 3, false)

    lib.notify({title = 'Shop', description = 'You left shop', type = 'inform'})
end

CreateThread(function()
    while confirming do
        DisableControlAction(0, 322, true)
        DisableControlAction(0, 177, true)
        DisableControlAction(0, 245, true)
        DisableControlAction(0, 26, true)
        DisableControlAction(0, 20, true)
        DisableControlAction(0, 288, true)
        DisableControlAction(0, 289, true)
        DisableControlAction(0, 170, true)
        DisableControlAction(0, 166, true)
        DisableControlAction(0, 167, true)
        DisableControlAction(0, 168, true)
        DisableControlAction(0, 56, true)
        DisableControlAction(0, 23, true)

        Wait(0)
    end
end)

CreateThread(function()
    while true do
        spawnSecretVan()
        local coords = GetEntityCoords(activeVan)
        TriggerServerEvent('org_upgrades:logShopLocation', coords)
        Wait(1000 * 60 * 60 * 2)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if confirming then
        if activeProp and DoesEntityExist(activeProp) then
            DeleteEntity(activeProp)
            activeProp = nil
        end

        lib.hideTextUI()

        if shopCam then
            RenderScriptCams(false, true, 1000, true, true)
            DestroyCam(shopCam, false)
            shopCam = nil
        end

        FreezeEntityPosition(PlayerPedId(), false)
        FreezeEntityPosition(activeVan, true)
    end
end)
