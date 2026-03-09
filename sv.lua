local QBCore = exports['qb-core']:GetCoreObject()

function ExtractIdentifiers(src)
    local identifiers = {}
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if string.find(id, "steam") then
            identifiers.steam = id
        end
    end
    return identifiers
end

QBCore.Commands.Add('givecar', 'Give any vehicle to a player', {}, true, function(source, args)
    local source = source
    if Config.UseSteamApi then
        local ids = ExtractIdentifiers(source)
        local steamID = ""
        if ids.steam then
            steamID = ids.steam:gsub("steam:", "")
        else
            steamID = ""
        end
        steamID = tonumber(steamID, 16)
        local steamAPIKey = Config.steamAPIKey
        local steamAPIURL = "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=" .. steamAPIKey .. "&steamids=" .. steamID
        PerformHttpRequest(steamAPIURL, function(err, text, headers)
            local jsonData = json.decode(text)
            local profile = jsonData.response.players[1]
            if profile and Config.UseSteamApi then
                local avatarURL = profile.avatarfull
                local steamName = profile.personaname
                TriggerClientEvent("ns-givecar:openmenu", source, true, avatarURL, steamName)
            else
                print("NO STEAM API FOUND")
            end
        end)
    else 
        TriggerClientEvent("ns-givecar:openmenu", source, false)
    end
end, 'admin')

local function generatePlate()
    local plate = QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(2)
    local result = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE plate = ?', { plate })
    if result then
        return generatePlate()
    else
        return plate:upper()
    end
end

RegisterNetEvent("ns-givecar:givecar", function(data)
    local src = source
    local id = tonumber(data.oyuncuID)
    local model = tostring(data.aracKodu)
    local plate = (data.plaka and data.plaka ~= "") and string.upper(data.plaka) or string.upper(generatePlate())
    local fullmod = data.fullmod or false
    local renk1 = data.aracRenk1 or "0 0 0"
    local renk2 = data.aracRenk2 or "0 0 0"
    local Player = QBCore.Functions.GetPlayer(id)
    if not Player then
        TriggerClientEvent('QBCore:Notify', src, 'Player is Offline!', 'error')
        return
    end
    local cid = Player.PlayerData.citizenid
    local result = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE plate = ?', {plate})
    if result then
        TriggerClientEvent('QBCore:Notify', src, 'This plate is already exist!', 'error')
    else
        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            Player.PlayerData.license,
            cid,
            model,
            GetHashKey(model),
            '{}',
            plate,
            0
        })
        TriggerClientEvent('QBCore:Notify', src, 'Vehicle is given!', 'success')
        TriggerClientEvent("ns-givecar:getvehicle", id, model, renk1, renk2, fullmod, plate)
    end
end)
