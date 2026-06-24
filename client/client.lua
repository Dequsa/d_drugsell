local Config = require '../config.lua'
local QBCore = exports['qb-core']:GetCoreObject()
local lang = require '../localization/' .. Config.Locale .. '.lua'

local function CheckIfPlayerHasTargetActive()
    return exports.ox_target:isActive()
end

local function SellDrugs()
    local playerPed = PlayerPedId()
    local playerId = PlayerId()
    local playerServerId = GetPlayerServerId(playerId)

    if not CheckIfPlayerHasTargetActive() then
        QBCore.Functions.TriggerCallback('d_drugsell:server:checkPlayerDrugs',
            function(hasDrugs, drugName, drugAmount, drugPrice)
                if hasDrugs then
                    TriggerServerEvent('d_drugsell:server:sellDrugs', drugName, drugAmount, drugPrice)
                else
                    QBCore.Functions.Notify(lang.pl_pl.no_drugs, 'error')
                end
            end, playerServerId)
    end
end

local function CheckTargeting(entity)
    local playerPed = PlayerPedId()

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
        label = lang.pl_pl.press_to_sell,
        name = 'd_drugsell_target',
        icon = 'fas fa-hand-holding-usd',
        distance = Config.SellDistance,
        canInteract = function(entity, distance, data)
            CheckTargeting(entity)
        end,

        onSelect = function(data)
            SellDrugs()
        end
    }
    exports.ox_target:addGlobalPed(options)
end

-- listen to load so we can add the target to peds when they spawn
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        MakePedsTargetable()
    end
end)
