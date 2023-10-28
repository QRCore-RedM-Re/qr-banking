local QRCore = exports['qr-core']:GetCoreObject()
local banks
local showing, playerLoaded = false, false
local BankPed = {}
local BankBlips = {}
InBank = false

-- Remove Peds / Blips / Prompts --
local function BankCleanup()
    for banks, v in pairs(Config.BankLocations) do
        if not Config.UseTarget then exports['qr-core']:deletePrompt(v.name) end
        if BankPed[banks] ~= nil then
            DeletePed(BankPed[banks])
            BankPed[banks] = nil
        end
        if BankBlips[banks] ~= nil then
            RemoveBlip(BankBlips[banks])
            BankBlips[banks] = nil
        end
    end
end

local function _GET_DEFAULT_RELATIONSHIP_GROUP_HASH ( iParam0 )
    return Citizen.InvokeNative( 0x3CC4A718C258BDD0 , iParam0 );
end

local function SET_PED_RELATIONSHIP_GROUP_HASH ( iVar0, iParam0 )
    return Citizen.InvokeNative( 0xC80A74AC829DDD92, iVar0, _GET_DEFAULT_RELATIONSHIP_GROUP_HASH( iParam0 ) )
end

-- Spawn Ped --
local function QRSpawnPed(model, coords)
    local pedmodel = GetHashKey(model)

    lib.requestModel(pedmodel)

    local pedId = CreatePed(pedmodel, coords.x, coords.y, coords.z - 1, coords.w, false, false, 0, 0)
    while not DoesEntityExist(pedId) do Wait(300) end

    Citizen.InvokeNative(0x283978A15512B2FE, pedId, true)
    FreezeEntityPosition(pedId, true)
    SetEntityInvincible(pedId, true)
    TaskStandStill(pedId, -1)
    SetBlockingOfNonTemporaryEvents(pedId, true)
    SET_PED_RELATIONSHIP_GROUP_HASH(pedId, pedmodel)
    SetEntityCanBeDamagedByRelationshipGroup(pedId, false, `PLAYER`)
    SetEntityAsMissionEntity(pedId, true, true)
    SetModelAsNoLongerNeeded(pedmodel)
    return pedId
end

-- Open Bank UI --
local function openAccountScreen()
    local banking = lib.callback.await('qr-banking:getBankingInformation', false)
    if banking then
        InBank = true
        SetNuiFocus(true, true)

        SendNUIMessage({ status = "openbank", information = banking })

        TriggerEvent("debug", 'Banking: Open UI', 2000, 0, 'hud_textures', 'check')
    end
end
exports('openAccountScreen', openAccountScreen)

-- Threads / Startup --
local function CreateBanks()
    for banks, v in pairs(Config.BankLocations) do
        if BankPed[banks] == nil then BankPed[banks] = QRSpawnPed('A_M_M_BiVFancyTravellers_01', v.coords) end
        if not Config.UseTarget then
            local PrompCoords = GetOffsetFromEntityInWorldCoords(BankPed[banks], 0.0, 3.0, 0.0) -- Prompt 3 Units in Front of Ped
            exports['qr-core']:createPrompt(v.name, vector3(PrompCoords.x, PrompCoords.y, PrompCoords.z), 0xF3830D8E, 'Open ' .. v.name, {
                type = 'client',
                event = 'qr-banking:openBankScreen',
                args = { false, true, false },
            })
        else
            exports['qr-target']:AddTargetEntity(BankPed[banks], {
                options = {
                    {
                        type = "client",
                        event = 'qr-banking:openBankScreen',
                        icon = "fas fa-dollar-sign",
                        label = "Open Bank",
                    },
                },
                distance = 3.0,
            })
        end
        if v.showblip == true then
            BankBlips[banks] = N_0x554d9d53f696d002(1664425300, v.coords)
            SetBlipSprite(BankBlips[banks], -2128054417, 52)
            SetBlipScale(BankBlips[banks], 0.2)
        end
    end
end

CreateThread(function()
    for _, v in pairs(Config.BankDoors) do
        Citizen.InvokeNative(0xD99229FE93B46286, v, 1, 1, 0, 0, 0, 0)
        Citizen.InvokeNative(0x6BAB9442830C7F53, v, 0)
    end
end)

-- Events --
RegisterNetEvent('qr-banking:openBankScreen', function()
    openAccountScreen()
end)

RegisterNetEvent('qr-banking:client:syncBanks', function(data)
    banks = data
    if showing then showing = false end
end)

RegisterNetEvent('qr-banking:transferError', function(msg)
    SendNUIMessage({
        status = "transferError",
        error = msg
    })
end)

RegisterNetEvent('qr-banking:successAlert', function(msg)
    SendNUIMessage({
        status = "successMessage",
        message = msg
    })
end)

-- Resource Stop / Cleanup --
AddEventHandler('QRCore:Client:OnPlayerLoaded', function() CreateBanks() end)
AddEventHandler('QRCore:Client:OnPlayerLoaded', function() BankCleanup() end)
AddEventHandler('onResourceStart', function(resource) if resource ~= GetCurrentResourceName() then return end CreateBanks() end)
AddEventHandler('onResourceStop', function(resource) if resource ~= GetCurrentResourceName() then return end BankCleanup() end)