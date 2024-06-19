garage = false

exports("IsInZone", function(pEntity)
    local coords = GetEntityCoords(PlayerPedId())
    local info = false
    for _, v in pairs(config.garages) do
        local distance = GetDistanceBetweenCoords(coords, v.coords, false)
        if distance < 15 and not info then
            garage = v.location
            info = true
        elseif not info then
            garage = false
        end
    end
    return garage
end)


RegisterNetEvent('six_garages:openGarage', function()
    local options = {}
    if garage then
        lib.callback('six_garages:GetPlayerVehicles', false, function(vehicles)
            for i, v in ipairs(vehicles) do
                local fuelc, enginec, bodyc = '5C5F66', '5C5F66', '5C5F66'
                local data = json.decode(v.vehicle)
                if data.fuelLevel < 30 then
                    fuelc = 'F03E3E'
                else
                    fuelc = '5C5F66'
                end
                if data.engineHealth < 500 then
                    enginec = 'F03E3E'
                else
                    enginec = '5C5F66'
                end
                if data.bodyHealth < 500 then
                    bodyc = 'F03E3E'
                else
                    bodyc = '5C5F66'     
                end
                if v.stored == 1 then
                    options[#options + 1] = {
                        id = i,
                        title = v.model_name,
                        description = v.plate,
                        close = true,
                        metadata = {
                            { label = 'Stan paliwa',    progress = data.fuelLevel,         colorScheme = '#' .. fuelc },
                            { label = 'Stan silnika',   progress = data.engineHealth * 0.1, colorScheme = '#' .. enginec },
                            { label = 'Stan karoserii', progress = data.bodyHealth * 0.1,   colorScheme = '#' .. bodyc },
                        },
                        onSelect = function(data)
                            selectVehicle(v)
                        end,
                    }
                else
                    options[#options + 1] = {
                        id = i,
                        title = v.model_name,
                        description = v.plate,
                        close = true,
                        disabled = true,
                        metadata = {
                            { label = 'Stan paliwa',    progress = data.fuelLevel,         colorScheme = '#' .. fuelc },
                            { label = 'Stan silnika',   progress = data.engineHealth * 0.1, colorScheme = '#' .. enginec },
                            { label = 'Stan karoserii', progress = data.bodyHealth * 0.1,   colorScheme = '#' .. bodyc },
                        },
                        onSelect = function(data)
                            selectVehicle(v)
                        end,
                    }
                end
            end
            table.sort(options, function(a, b)
                return a.title < b.title
            end)
            options[#options - #options] = {
                title = 'Przenieś pojazd',
                icon = 'car-on',
                close = false,
                menu = 'garage:moveveh'
            }

            lib.callback('six_garages:GetPlayerAllVehicles', false, function(vehicles2)
                local options2 = {}
                for l, k in ipairs(vehicles2) do
                    if k.garage ~= garage then
                        if k.stored == 1 then
                            options2[#options2 + 1] = {
                                id = l,
                                title = k.model_name,
                                description = k.plate,
                                close = true,
                                onSelect = function(data)
                                    moveVehicle(k.plate, k.model_name, garage)
                                end,
                            }
                        else
                            options2[#options2 + 1] = {
                                id = l,
                                title = k.model_name,
                                description = k.plate,
                                close = true,
                                disabled = true,
                                onSelect = function(data)
                                    moveVehicle(k.plate, k.model_name, garage)
                                end,
                            }
                        end
                    end
                end
                table.sort(options2, function(a, b)
                    return a.title < b.title
                end)
                lib.registerContext({
                    id = 'garage:moveveh',
                    title = 'Przenieś pojazd',
                    options = options2,
                    menu = garage
                })
            end)
            lib.registerContext({
                id = garage,
                title = garage,
                options = options
            })
            lib.showContext(garage)
        end, garage)
    end
end)

RegisterNetEvent('six_garages:parkvehicle', function()
    local options = {}
    if garage then
        local vehicle = GetVehiclePedIsIn(PlayerPedId())
        local plate = GetVehicleNumberPlateText(vehicle)
        lib.callback('six_garages:isOwner', false, function(isOwner)
            if isOwner then
                DoScreenFadeOut(500)
                Wait(500)
                RenderScriptCams(false, true, 1000, true, true)
                local data = lib.getVehicleProperties(vehicle)
                local engine = math.ceil(GetVehicleEngineHealth(vehicle))
                local body = math.ceil(GetVehicleBodyHealth(vehicle))
                local fuel = GetVehicleFuelLevel(vehicle)
                TriggerServerEvent('six_garages:parkvehicle', garage, data, plate, engine, body, fuel)
                ESX.Game.DeleteVehicle(vehicle)
                Wait(50)
                DoScreenFadeIn(500)
            else
                lib.notify({
                    id = 'veh_not_owner',
                    title = 'Błąd',
                    description = 'Ten pojazd nie należy do ciebie!',
                    showDuration = 3000,
                    position = 'top',
                    icon = 'ban',
                    iconColor = '#C53030'
                })
            end
        end, plate)
    end
end)

function moveVehicle(plate, model, where)
    local alert = lib.alertDialog({
        content = 'Czy chcesz przenieść ' .. model .. ' do garażu ' .. where .. ' \n \nKoszt: $' .. config.moveprice,
        centered = true,
        cancel = true
    })

    if alert == 'confirm' then
        TriggerServerEvent('six_garages:moveveh', plate, where)
    end
end

function selectVehicle(data)
    local vehicle = json.decode(data.vehicle)
    DoScreenFadeOut(500)
    Wait(500)
    RenderScriptCams(false, true, 1000, true, true)
    ESX.Game.SpawnVehicle(vehicle.model, GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId()),
        function(callback_vehicle)
            lib.setVehicleProperties(callback_vehicle, vehicle)
            SetVehRadioStation(callback_vehicle, 'OFF')
            SetVehicleUndriveable(callback_vehicle, false)
            SetVehicleEngineOn(callback_vehicle, true, true)
            SetEntityAsMissionEntity(callback_vehicle, true, false)
            local carplate = GetVehicleNumberPlateText(callback_vehicle)
            TaskWarpPedIntoVehicle(GetPlayerPed(-1), callback_vehicle, -1)
            TriggerServerEvent('six_garages:setStored', carplate, 0)
            Wait(50)
            DoScreenFadeIn(500)
        end)


end


function impoundMenu(where)
    local plates = {}
    local models = {}
    local found = {}
    local anycars = false
    lib.callback('six_garages:GetImpound', false, function(vehicles2)
        local options2 = {}
        for l, k in ipairs(vehicles2) do
            if k.blocked == 0 then
                local vehicles = ESX.Game.GetVehicles()
                for i = 1, #vehicles do
                    local vehicle = vehicles[i]
                    if DoesEntityExist(vehicle) and not found[l] then
                        local vehiclePlate = GetVehicleNumberPlateText(vehicle)
                        if string.gsub(vehiclePlate, "%s+", "") == k.plate then
                            found[l] = true
                        else
                            found[l] = false
                        end
                    end
                end
                if not found[l] then
                    anycars = true
                    plates[l] = k.plate
                    models[l] = k.model_name
                options2[#options2 + 1] = {
                    value = l,
                    label = k.model_name..' | '..k.plate,
                }
                table.sort(options2, function(a, b)
                    return a.label < b.label
                end)
            end
            end
    end
    if anycars then 
    local alert =  lib.inputDialog('Odholownik', {
        {type = 'number', label = 'Koszt', default = config.impoundprice, icon = 'dollar', disabled = true},
            {type = 'select', label = 'Wybierz pojazd', required = true, default = 1 ,options = options2},
            {type = 'select', label = 'Płatność', required = true, default = 1 ,options = {
                {value = 1, label = 'Gotówką'},
                {value = 2, label = 'Kartą'}
            }},
          })
          if not alert then return end
          if alert[3] == 1 and alert[2] then
            TriggerServerEvent('six_garages:impound', plates[alert[2]], 'money', models[alert[2]], where)
          elseif alert[3] == 2 and alert[2] then
            TriggerServerEvent('six_garages:impound', plates[alert[2]], 'card', models[alert[2]], where)
          end
        else
            lib.notify({
                id = 'veh_not_owner',
                title = 'Błąd',
                description = 'Brak odholowanych pojazdów!',
                showDuration = 3000,
                position = 'top',
                icon = 'ban',
                iconColor = '#C53030'
            })
        end
    end)
end

Citizen.CreateThread(function()
for _, v in pairs(config.garages) do
    MapBlip(v.coords)
end
for _, k in pairs(config.impounds) do
    ImpoundBlip(k.coords)
end
end)

function MapBlip(coords)
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, 357)
    SetBlipDisplay(blip,2)
    SetBlipScale(blip, 0.5)
    SetBlipColour(blip, 18)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString('Garaź')
    EndTextCommandSetBlipName(blip)
end


function ImpoundBlip(coords)
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, 68)
    SetBlipDisplay(blip, 2)
    SetBlipScale(blip, 0.7)
    SetBlipColour(blip, 5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString('Odholownik')
    EndTextCommandSetBlipName(blip)
end


--[[]
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
	while (true) do
		local playerPed = PlayerPedId()
		if DoesEntityExist(playerPed) then
			TriggerServerEvent("six_garages:syncPlayerPosition", GetEntityCoords(playerPed))
		end

		Citizen.Wait(3000)
	end
end)]]