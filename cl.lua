ESX = exports["es_extended"]:getSharedObject()
local showVehicle = false
local previewVehicle = nil
local menu = false

function ShowVehiclePreview(modelName)
    if showVehicle then return end
    showVehicle = true
    CreateThread(function()
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local model = GetHashKey(modelName)
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(10)
        end
        local spawnCoords = playerCoords - vector3(0.0, 0.0, 10.0)
        previewVehicle = CreateVehicle(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, false, false)
        SetEntityLocallyVisible(previewVehicle)
        NetworkSetEntityInvisibleToNetwork(previewVehicle, true)
        SetEntityAlpha(previewVehicle, 254, false)
        SetEntityCollision(previewVehicle, false, false)
        SetEntityInvincible(previewVehicle, true)
        SetEntityCanBeDamaged(previewVehicle, false)
        SetVehicleDoorsLocked(previewVehicle, 4)
        SetEntityHasGravity(previewVehicle, false)
        SetEntityDynamic(previewVehicle, false)
        while showVehicle do
            local screenX, screenY = 0.7, 0.5
            local world, normal = GetWorldCoordFromScreenCoord(screenX, screenY)
            local targetPos = world + normal * 7.5
            local camRot = GetGameplayCamRot(2)
            SetEntityCoords(previewVehicle, targetPos.x, targetPos.y, targetPos.z, false, false, false, true)
            SetEntityHeading(previewVehicle, camRot.z + 1.0)
            SetEntityRotation(previewVehicle, camRot.x * (-0.10), 0.0, camRot.z + 140.0, 2, false)
            Wait(5)
        end
        DeleteEntity(previewVehicle)
        previewVehicle = nil
    end)
end

function CloseVehiclePreview()
    showVehicle = false
end

RegisterNUICallback("updateCarColor", function(data, cb)
    local r, g, b = data.r, data.g, data.b
    if data.type == "primary" then
        SetVehicleCustomPrimaryColour(previewVehicle, r, g, b)
    elseif data.type == "secondary" then
        SetVehicleCustomSecondaryColour(previewVehicle, r, g, b)
    end
    cb("ok")
end)

RegisterNetEvent("ns-givecar:openmenu", function(avatar, name)
    menu = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "givecar",
        steampp = avatar,
        steamname = name
    })
end)

RegisterNUICallback("closemenu", function(data, cb)
    menu = false
    SetNuiFocus(false, false)
    CloseVehiclePreview()
    cb("ok")
end)

RegisterNUICallback("showCarPreview", function(data, cb)
    CloseVehiclePreview()
    Wait(10)
    ShowVehiclePreview(data.model)
    cb("ok")
end)

RegisterNUICallback("givecar", function(data, cb)
    SetNuiFocus(false, false)
    showVehicle = false 
    menu = false
    TriggerServerEvent("ns-givecar:givecar", data)
    cb("ok")
end)

local performanceModIndices = { 11, 12, 13, 15 }
function PerformanceUpgradeVehicle(vehicle, customWheels)
    customWheels = customWheels or false
    local max
    if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
        SetVehicleModKit(vehicle, 0)
        for _, modType in ipairs(performanceModIndices) do
            max = GetNumVehicleMods(vehicle, tonumber(modType)) - 1
            SetVehicleMod(vehicle, modType, max, customWheels)
        end
        ToggleVehicleMod(vehicle, 18, true)
        SetVehicleFixed(vehicle)
    end
end

RegisterNetEvent("ns-givecar:getvehicle")
AddEventHandler("ns-givecar:getvehicle", function(model, renk1, renk2, fullmod, plate)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    ESX.Game.SpawnVehicle(model, coords, 0.0, function(vehicle)
        SetVehicleNumberPlateText(vehicle, plate)
        
        -- Primary Color
        local renkler1 = { renk1:match("(%d+) (%d+) (%d+)") }
        local renk1_r = tonumber(renkler1[1])
        local renk1_g = tonumber(renkler1[2])
        local renk1_b = tonumber(renkler1[3])
        SetVehicleCustomPrimaryColour(vehicle, renk1_r, renk1_g, renk1_b)
        
        -- Secondary Color (Fixed bug from original)
        local renkler2 = { renk2:match("(%d+) (%d+) (%d+)") }
        local renk2_r = tonumber(renkler2[1])
        local renk2_g = tonumber(renkler2[2])
        local renk2_b = tonumber(renkler2[3])
        SetVehicleCustomSecondaryColour(vehicle, renk2_r, renk2_g, renk2_b)
        
        TaskWarpPedIntoVehicle(ped, vehicle, -1)
        
        -- Vehicle Keys
        if Config.VehicleKeys == "esx_vehiclekeys" then
            TriggerEvent('esx_vehiclekeys:client:SetOwner', plate)
        elseif Config.VehicleKeys == "wasabi_carlock" then
            exports.wasabi_carlock:GiveKey(plate)
        end
        
        Wait(100)
        if fullmod then
            PerformanceUpgradeVehicle(vehicle, true)
        end
    end)
end)

CreateThread(function()
    while true do 
        if menu then
            DisableIdleCamera(true)
        end
        Wait(100)
    end
end)
