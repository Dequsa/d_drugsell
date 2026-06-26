local QBCore = exports['qb-core']:GetCoreObject()
local blacklistedPeds = {}


local function CheckIfPlayerHasTargetActive()
    return exports.ox_target:isActive()
end

local function SellDrugs()
    local playerPed = PlayerPedId()
    local playerId = PlayerId()
    local playerServerId = GetPlayerServerId(playerId)
    if CheckIfPlayerHasTargetActive() then
        -- print('target')
        QBCore.Functions.TriggerCallback('d_drugsell:server:checkPlayerDrugs',
            function(hasDrugs, drugName, drugAmount, drugPrice)
                if hasDrugs then
                    TriggerServerEvent('d_drugsell:server:sellDrugs', drugName, drugAmount, drugPrice)
                else
                    QBCore.Functions.Notify(Lang.pl_pl.no_drugs, 'error')
                end
            end, playerServerId)
    end
end

local function CheckBlacklist(entity)
    local model = GetEntityModel(entity)
    if blacklistedPeds[model] then
        return true
    end
    return false
end

local function CheckTargeting(entity)
    local playerPed = PlayerPedId()

    if (CheckBlacklist(entity)) then
        return false
    end

    if entity == cache.ped then
        return false
    end

    if IsPedDeadOrDying(playerPed, 1) or IsPedDeadOrDying(entity, 1) then
        return false
    end

    if IsPedAPlayer(entity) and isPedHuman(entity) then
        return false
    end

    return true
end

local function MakePedsTargetable()
    local options = {
        label = Lang.pl_pl.press_to_sell,
        name = 'd_drugsell_target',
        icon = 'fas fa-hand-holding-usd',
        distance = Config.SellDistance,
        canInteract = function(entity, distance, coords, name, bone)
            return CheckTargeting(entity)
        end,

        onSelect = function(data)
            SellDrugs()
        end
    }
    exports.ox_target:addGlobalPed(options)
end

local function HashBlacklistedPeds()
    for _, ped in ipairs(Config.BlacklistedPeds) do
        blacklistedPeds[GetHashKey(ped)] = true
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() 
        HashBlacklistedPeds()
        MakePedsTargetable()
end)

AddEventHandler('onClientResourceStart', function()
    local resourceName = 'd_drugsell'
    if  resourceName == GetCurrentResourceName() then
        HashBlacklistedPeds()
        MakePedsTargetable()
    end
end)