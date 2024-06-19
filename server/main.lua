local spawnedVehicles = {}
local allvehicles = {}


lib.callback.register('six_garages:GetPlayerVehicles', function(source, garage)
    local xPlayer = ESX.GetPlayerFromId(source)
    local vehicles = MySQL.query.await('SELECT * FROM `owned_vehicles` WHERE owner = ? AND garage = ?',
        { xPlayer.identifier, garage })
    return vehicles
end)

lib.callback.register('six_garages:GetPlayerAllVehicles', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local vehicles = MySQL.query.await('SELECT * FROM `owned_vehicles` WHERE owner = ?', { xPlayer.identifier })
    return vehicles
end)


lib.callback.register('six_garages:GetImpound', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local vehicles = MySQL.query.await('SELECT * FROM `owned_vehicles` WHERE `owner` = ? AND `stored` = ?',
    { xPlayer.identifier, 0 })
    return vehicles
end)



lib.callback.register('six_garages:isOwner', function(source, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    local vehicles = MySQL.query.await('SELECT `owner` FROM `owned_vehicles` WHERE plate = ?', { plate })
    if vehicles[1] then
        if vehicles[1].owner == xPlayer.identifier then
            return true
        else
            return false
        end
    else
        return false
    end
end)

RegisterNetEvent('six_garages:moveveh', function(plate, garage)
    local count = exports.ox_inventory:GetItemCount(source, 'cash')
    if count >= config.moveprice then
        exports.ox_inventory:RemoveItem(source, 'cash', config.moveprice)
        MySQL.update('UPDATE owned_vehicles SET garage = ? WHERE plate = ?', {
            garage, plate
        })
    else
        TriggerClientEvent('ox_lib:notify', source, {
            id = 'garagemovenomoney',
            title = 'Błąd',
            description = 'Nie posiadasz wystarczająco gotówki',
            showDuration = 3000,
            position = 'top',
            icon = 'ban',
            iconColor = '#C53030'
        })
    end
end)

RegisterNetEvent('six_garages:parkvehicle', function(garage, data, plate, engine, body, fuel)
    local affectedRows = MySQL.update.await(
    'UPDATE owned_vehicles SET `garage` = ?, `vehicle` = ?, `stored` = 1 WHERE plate = ?',
        {
            garage, json.encode(data), plate
        })
end)

RegisterNetEvent('six_garages:setStored', function(plate, stored)
    local affectedRows = MySQL.update.await('UPDATE owned_vehicles SET `stored` = ? WHERE plate = ?', {
        stored, plate
    })
end)


RegisterNetEvent('six_garages:impound', function(plate, payment, model, where)
    local xPlayer = ESX.GetPlayerFromId(source)
    if payment == 'money' then
        local count = exports.ox_inventory:GetItemCount(source, 'cash')
        if count >= config.impoundprice then
            exports.ox_inventory:RemoveItem(source, 'cash', config.impoundprice)
            TriggerClientEvent('ox_lib:notify', source, {
                id = 'impounded',
                title = 'Informacja',
                description = 'Przeniesiono '..model..' do garażu '..where,
                showDuration = 3000,
                position = 'top',
            })
            local sql = MySQL.update.await('UPDATE owned_vehicles SET `stored` = 1, `garage` = ? WHERE plate = ?', {
                where, plate
               })
        else
            TriggerClientEvent('ox_lib:notify', source, {
                id = 'garagemovenomoney',
                title = 'Błąd',
                description = 'Nie posiadasz wystarczająco gotówki',
                showDuration = 3000,
                position = 'top',
                icon = 'ban',
                iconColor = '#C53030'
            })
        end
    elseif payment == 'card' then
        local accountplayer = xPlayer.getAccount('bank').money
		if accountplayer >= config.impoundprice then
        xPlayer.removeAccountMoney('bank', config.impoundprice)

        TriggerClientEvent('ox_lib:notify', source, {
            id = 'impounded',
            title = 'Informacja',
            description = 'Przeniesiono '..model..' do garażu '..where,
            showDuration = 3000,
            position = 'top',
        })
        local sql = MySQL.update.await('UPDATE owned_vehicles SET `stored` = 1, `garage` = ? WHERE plate = ?', {
            where, plate
           })
        else
            TriggerClientEvent('ox_lib:notify', source, {
                id = 'garagemovenomoney',
                title = 'Błąd',
                description = 'Nie posiadasz wystarczająco pieniędzy na koncie',
                showDuration = 3000,
                position = 'top',
                icon = 'ban',
                iconColor = '#C53030'
            })
        end
    end

end)
--[[
function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)

        if GetActivePlayerCount() > 0 then
            TrySpawnVehicles()
        end
    end
end)

RegisterServerEvent("six_garages:syncPlayerPosition")
AddEventHandler("six_garages:syncPlayerPosition", function(position)
    activePlayerPositions[source] = position
end)

-- player disconnected
AddEventHandler("playerDropped", function(disconnectReason)
    activePlayerPositions[source] = nil
end)

MySQL.ready(function()
    -- fetch all database results
    MySQL.Async.fetchAll(
        "SELECT * FROM owned_vehicles", {},
        function(results)

            for i = 1, #results do
                allvehicles[results[i].plate] = {
                    handle         = nil,
                    position       = vector3(results[i].posX, results[i].posY, results[i].posZ),
                    rotation       = vector3(results[i].rotX, results[i].rotY, results[i].rotZ),
                    vehicle  = json.decode(results[i].vehicle),
                    lastUpdate     = results[i].lastUpdate,
                    spawning       = false,
                    spawningPlayer = nil
                }
            end

            CleanUp()
        end)
end)

function TrySpawnVehicles()
    local loadedVehicles = GetAllVehicles()
    local playerVehiclePlates = {}
    for id, position in pairs(activePlayerPositions) do
        local ped = GetPlayerPed(id)
        local veh = GetVehiclePedIsIn(ped, false)
        if (DoesEntityExist(veh)) then
            local tab = GetVehicleNumberPlateText(veh)
            tab = string.gsub(tab, "^%s*(.-)%s*$", "%1")
            table.insert(playerVehiclePlates, tab)
        end
    end

    -- check, if vehicles need to be spawned
    for plate, vehicleData in pairs(allvehicles) do
        if (not vehicleData.spawning) then
            local closestPlayer, dist = GetClosestPlayerId(vehicleData.position)
            if (closestPlayer ~= nil and dist < Config.spawnDistance and not ContainsPlate(plate, playerVehiclePlates)) then
                if (vehicleData.handle ~= nil and DoesEntityExist(vehicleData.handle)) then
                    -- vehicle found on server side
                else
                    -- vehicle not found on server side
                    -- check, if it is loaded differently
                    --if result ~=  then
                    local loadedVehicle = TryGetLoadedVehicle(plate, loadedVehicles)
                    if (loadedVehicle ~= nil) then
                        -- vehicle found
                        vehicleData.handle = loadedVehicle
                    else
                        -- vehicle not found
                        -- try and spawn it, posY, posZ
                        -- MySQL.Async.fetchAll(
                        --     'SELECT * FROM owned_vehicles WHERE `plate` = @plate OR `fakeplate` = @plate',
                        --     { ["@plate"] = plate },
                        --     function(result)
                        --         -- przetworzenie wyniku zapytania
                        --         if result[1] == nil then
                        local playerId, distance = GetClosestPlayerId(vehicleData.position)
                        if (playerId and distance < Config.spawnDistance) then
                            vehicleData.spawning = true
                            Citizen.CreateThread(function()
                                local vec4 = vector4(vehicleData.position.x, vehicleData.position.y,
                                    vehicleData.position.z, vehicleData.rotation.z)
                                local vehicle = Citizen.InvokeNative(GetHashKey("CREATE_AUTOMOBILE"),
                                    vehicleData.vehicle.model, vec4.xyzw)
                                while (not DoesEntityExist(vehicle)) do
                                    Citizen.Wait(0)
                                end
                                SetEntityCoords(vehicle, vehicleData.position.x, vehicleData.position.y,
                                    vehicleData.position.z)
                                SetEntityRotation(vehicle, vehicleData.rotation.x, vehicleData.rotation.y,
                                    vehicleData.rotation.z)
                                vehicleData.handle = vehicle
                                local networkOwner = -1
                                while (networkOwner == -1) do
                                    Citizen.Wait(0)
                                    networkOwner = NetworkGetEntityOwner(vehicleData.handle)
                                end
                                vehicleData.spawningPlayer = GetPlayerIdentifiersSorted(networkOwner)
                                TriggerClientEvent("six_parking:setVehicleMods", networkOwner,
                                    NetworkGetNetworkIdFromEntity(vehicleData.handle), plate,
                                    vehicleData.vehicle)
                            end)
                        end
                        -- end
                        -- end)
                    end
                end
            end
        elseif (vehicleData.spawningPlayer) then
            -- if vehicle is currently spawning check if responsible player is still connected
            if (not IsPlayerWithLicenseActive(vehicleData.spawningPlayer)) then
                TriggerEvent("six_garages:setVehicleModsFailed", plate)
            end
        end
    end
end

function TryGetLoadedVehicle(plate, loadedVehicles)
    for i = 1, #loadedVehicles, 1 do
        if (plate == GetVehicleNumberPlateText(loadedVehicles[i]) and DoesEntityExist(loadedVehicles[i])) then
            return loadedVehicles[i]
        end
    end

    return nil
end

RegisterServerEvent("six_garages:enteredVehicle")
AddEventHandler("six_garages:enteredVehicle", function(networkId, modifications)
    local vehicle = NetworkGetEntityFromNetworkId(networkId)

    if (DoesEntityExist(vehicle)) then
        local currentTime = os.time()

        local plate = GetVehicleNumberPlateText(vehicle)
        plate = string.gsub(plate, "^%s*(.-)%s*$", "%1")

        local position = GetEntityCoords(vehicle)
        position = vector3(math.floor(position.x * 100.0) / 100.0, math.floor(position.y * 100.0) / 100.0,
            math.floor(position.z * 100.0) / 100.0)
        local rotation = GetEntityRotation(vehicle)
        rotation = vector3(math.floor(rotation.x * 100.0) / 100.0, math.floor(rotation.y * 100.0) / 100.0,
            math.floor(rotation.z * 100.0) / 100.0)

        if (allvehicles[plate]) then
            -- already on server list



            if (allvehicles[plate].handle ~= vehicle) then
                if (DoesEntityExist(allvehicles[plate].handle)) then
                    DeleteEntity(allvehicles[plate].handle)
                end

                allvehicles[plate].handle = vehicle
            end

            allvehicles[plate].position = position
            allvehicles[plate].rotation = rotation
            allvehicles[plate].vehicle = modifications
            allvehicles[plate].lastUpdate = currentTime

            MySQL.Async.execute(
                "UPDATE owned_vehicles SET posX = @posX, posY = @posY, posZ = @posZ, rotX = @rotX, rotY = @rotY, rotZ = @rotZ, vehicle = @vehicle, lastUpdate = @lastUpdate WHERE plate = @plate",
                {
                    ["@plate"]         = plate,
                    ["@posX"]          = allvehicles[plate].position.x,
                    ["@posY"]          = allvehicles[plate].position.y,
                    ["@posZ"]          = allvehicles[plate].position.z,
                    ["@rotX"]          = allvehicles[plate].rotation.x,
                    ["@rotY"]          = allvehicles[plate].rotation.y,
                    ["@rotZ"]          = allvehicles[plate].rotation.z,
                    ["@vehicle"] = json.encode(allvehicles[plate].vehicle),
                    ["@lastUpdate"]    = allvehicles[plate].lastUpdate
                })
        else
            -- insert in db



            allvehicles[plate] = {
                handle         = vehicle,
                position       = position,
                rotation       = rotation,
                vehicle  = vehicle,
                lastUpdate     = currentTime,
                spawning       = false,
                spawningPlayer = nil
            }

            MySQL.Async.execute(
                "INSERT INTO owned_vehicles (plate, posX, posY, posZ, rotX, rotY, rotZ, vehicle, lastUpdate) VALUES (@plate, @posX, @posY, @posZ, @rotX, @rotY, @rotZ, @vehicle, @lastUpdate)",
                {
                    ["@plate"]         = plate,
                    ["@posX"]          = allvehicles[plate].position.x,
                    ["@posY"]          = allvehicles[plate].position.y,
                    ["@posZ"]          = allvehicles[plate].position.z,
                    ["@rotX"]          = allvehicles[plate].rotation.x,
                    ["@rotY"]          = allvehicles[plate].rotation.y,
                    ["@rotZ"]          = allvehicles[plate].rotation.z,
                    ["@vehicle"] = json.encode(allvehicles[plate].vehicle),
                    ["@lastUpdate"]    = allvehicles[plate].lastUpdate
                })
        end
    else
        print("WTF IS HAPPENING")
    end
end)

function ContainsPlate(plate, vehiclePlates)
    for i = 1, #vehiclePlates, 1 do
        if (plate == vehiclePlates[i]) then
            return true
        end
    end

    return false
end

-- prints text to the server console
function Log(text)
    if (Config.isDebug) then
        print(GetCurrentResourceName() .. ": " .. text)
    end
end

-- return the distance between two positions (Vector3)
function Vector3Dist(v1, v2)
	return math.sqrt( (v2.x - v1.x) * (v2.x - v1.x) + (v2.y - v1.y) * (v2.y - v1.y) + (v2.z - v1.z) * (v2.z - v1.z) )
end

-- return the distance between two positions without sqrt (Vector3)
function Vector3DistFast(v1, v2)
	return (v2.x - v1.x) * (v2.x - v1.x) + (v2.y - v1.y) * (v2.y - v1.y) + (v2.z - v1.z) * (v2.z - v1.z)
end

-- returns the difference in degrees from the axis with the highest difference
function GetRotationDifference(r1, r2)
    local x = math.abs(r1.x - r2.x)
    local y = math.abs(r1.y - r2.y)
    local z = math.abs(r1.z - r2.z)

    if (x > y and x > z) then
        return x
    elseif (y > z) then
        return y
    else
        return z
    end
end

-- get the amount of currently active players
function GetActivePlayerCount()
    local playerCount = 0
    for k, v in pairs(activePlayerPositions) do
        playerCount = playerCount + 1
    end
    return playerCount
end

-- return the ID of the closest player
function GetClosestPlayerId(position)
	local closestDistance = 1000000.0
	local closestPlayerID = nil
    local closestPos = nil
	
    for playerID, pos in pairs(activePlayerPositions) do
        local distance = Vector3DistFast(position, pos)
        
        if (distance < closestDistance) then
            closestDistance = distance
            closestPlayerID = playerID
            closestPos = pos
        end
	end
	
    local distance = nil
    if (closestPlayerID ~= nil) then
        distance = Vector3Dist(position, closestPos)
    end
    
	return closestPlayerID, distance
end

function IsAnyPlayerInsideVehicle(vehicle, playerPeds)
    for i = 1, #playerPeds, 1 do
        local veh = GetVehiclePedIsIn(playerPeds[i], false)

        if (DoesEntityExist(veh) and veh == vehicle) then
            return true
        end
    end

    return false
end

-- return the ped of the closest player
function GetClosestPlayerPed(position, playerPeds)
	local closestDistance = 1000000.0
	local closestPlayerPed = nil
    local closestPos = nil
	
    for k, playerPed in pairs(playerPeds) do
        local pos = GetEntityCoords(playerPed)
        local distance = Vector3DistFast(position, pos)
        
        if (distance < closestDistance) then
            closestDistance = distance
            closestPlayerPed = playerPed
            closestPos = pos
        end
	end
	
    local distance = 0.0
    if (closestPlayerPed ~= nil) then
        distance = Vector3Dist(position, closestPos)
    end
    
	return closestPlayerPed, distance
end


-- Return an array with all identifiers - e.g. ids["license"] = license:xxxxxxxxxxxxxxxx
function GetPlayerIdentifiersSorted(playerServerId)
	local ids = {}

	local identifiers = GetPlayerIdentifiers(playerServerId)

	for k, identifier in pairs (identifiers) do
		local i, j = string.find(identifier, ":")
		local idType = string.sub(identifier, 1, i-1)

		ids[idType] = identifier
	end

	return ids
end
]]