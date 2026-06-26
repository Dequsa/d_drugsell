local QBCore = exports['qb-core']:GetCoreObject()
local blacklistedPeds = {}

local function SellDrugs()
    QBCore.Functions.TriggerCallback('d_drugsell:server:checkPlayerDrugs', function(hasDrugs, drugName)
        if hasDrugs then
            TriggerServerEvent('d_drugsell:server:sellDrugs', drugName)
        else
            QBCore.Functions.Notify(Lang.pl_pl.no_drugs, 'error')
        end
    end)
end

local function CheckBlacklist(entity)
    local model = GetEntityModel(entity)
    return blacklistedPeds[model]
end

local function CheckTargeting(entity)
    if (CheckBlacklist(entity)) then
        return false
    end

    if entity == cache.ped then
        return false
    end

    local playerPed = PlayerPedId()
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
    HashBlacklistedPeds()
    MakePedsTargetable()
end)
