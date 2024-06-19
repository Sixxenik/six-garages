local created = false

function target()
    for i,v in ipairs(config.impounds) do
    exports.qtarget:AddBoxZone("impund"..i,
    v.coords, 3, 3.3, {
        name = 'impound',
        heading = 70,
        debugPoly = config.debug,
        minZ = v.coords.z - 1.5,
        maxZ = v.coords.z + 1.5,
    }, {
        options = {
            {
                action = function()
                    impoundMenu(v.garage)
                end,
                label = 'Odholownik', --langg
                icon = "fa-solid fa-car-burst",
            },
        },
        distance = 3,
    })
end
end


RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer, isNew, skin)
    target()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    target()
end)
