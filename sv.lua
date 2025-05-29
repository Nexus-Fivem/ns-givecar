ESX = exports["es_extended"]:getSharedObject()

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

ESX.RegisterCommand('givecar', 'admin', function(xPlayer, args, showError)
    local source = xPlayer.source
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
        if profile then
            local avatarURL = profile.avatarfull
            local steamName = profile.personaname
            TriggerClientEvent("ns-givecar:openmenu", source, avatarURL, steamName)
        else
            print("Steam profile UNKNOWN.")
        end
    end)
end, false, {help = 'Give any vehicle to a player'})

local function generatePlate()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local plate = ""
    for i = 1, 8 do
        local rand = math.random(#charset)
        plate = plate .. string.sub(charset, rand, rand)
    end
    local result = MySQL.scalar.await('SELECT plate FROM owned_vehicles WHERE plate = ?', { plate })
    if result then
        return generatePlate()
    else
        return plate
    end
end

RegisterNetEvent("ns-givecar:givecar", function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local id = tonumber(data.oyuncuID)
    local model = tostring(data.aracKodu)
    local plate = (data.plaka and data.plaka ~= "") and string.upper(data.plaka) or string.upper(generatePlate())
    local fullmod = data.fullmod or false
    local renk1 = data.aracRenk1 or "0 0 0"
    local renk2 = data.aracRenk2 or "0 0 0"
    local targetPlayer = ESX.GetPlayerFromId(id)
    
    if not targetPlayer then
        xPlayer.showNotification('Player is Offline!', 'error')
        return
    end
    
    local result = MySQL.scalar.await('SELECT plate FROM owned_vehicles WHERE plate = ?', {plate})
    if result then
        xPlayer.showNotification('This plate already exists!', 'error')
    else
        MySQL.insert('INSERT INTO owned_vehicles (owner, plate, vehicle, type, job, stored) VALUES (?, ?, ?, ?, ?, ?)', {
            targetPlayer.identifier,
            plate,
            json.encode({ model = GetHashKey(model), plate = plate }),
            'car',
            'civ',
            true
        })
        
        xPlayer.showNotification('Vehicle given successfully!', 'success')
        TriggerClientEvent("ns-givecar:getvehicle", id, model, renk1, renk2, fullmod, plate)
    end
end)
