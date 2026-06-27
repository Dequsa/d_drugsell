local QBCore = exports['qb-core']:GetCoreObject()
local blacklistedPeds = {}
local ped = nil
local targetName = 'd_drugsell_target'

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

    local playerPed = cache.ped
    if IsPedDeadOrDying(playerPed, 1) or IsPedDeadOrDying(entity, 1) then
        return false
    end

    if IsPedAPlayer(entity) and isPedHuman(entity) then
        return false
    end

    ped = entity
    return true
end

local function MakePedsTargetable()
    local options = {
        label = Lang.pl_pl.press_to_sell,
        name = targetName,
        icon = Config.TargetIcon,
        distance = Config.SellDistance,
        canInteract = function(entity, distance, coords, name, bone)
            return CheckTargeting(entity)
        end,

        onSelect = function(data)
            TriggerServerEvent('d_drugsell:server:sellDrugs')
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

AddEventHandler('onClientResourceStop', function()
    exports.ox_target:removeGlobalPed(targetName)
end)

RegisterNetEvent('d_drugsell:client:handleDealAnimations', function()
    FreezeEntityPosition(ped, true)

    local dealAnimDict = 'anim@mp_player_intcelebrationpaired@f_m_manly_handshake'
    local dealAnimName = 'manly_handshake_right'
    local dealAnimDictTarget = 'anim@mp_player_intcelebrationpaired@m_m_manly_handshake'
    local dealAnimNameTarget = 'manly_handshake_left'

    RequestAnimDict(dealAnimDict)
    RequestAnimDict(dealAnimDictTarget)
    while not HasAnimDictLoaded(dealAnimDict) or not HasAnimDictLoaded(dealAnimDictTarget) do
        Citizen.Wait(0)
    end

    local screenX, screenY = GetScreenResolution()

    local data = {
        duration = Config.DealDuration,
        label = Lang.pl_pl.start_deal_progress_bar,
        canCancel = false,

        -- anim = {
        --     dict = dealAnimDict,
        --     clip = dealAnimName,
        -- },

        prop = {
            model = GetHashKey(Config.Prop),
            bone = GetEntityBoneIndexByName(cache.ped, Config.Bone),
            pos = vec3(0.0, 0.0, 0.0),
            rot = vec3(0.0, 0.0, 0.0)
        },

        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = true
        }
    }

    local coords = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)
    local dist = 1.5

    local offsetX = -math.sin(math.rad(heading)) * dist
    local offsetY = math.cos(math.rad(heading)) * dist

    SetEntityCoords(ped, coords.x + offsetX, coords.y + offsetY, coords.z, false, false, false, false)
    SetEntityHeading(ped, (heading + 180.0) % 360.0)

    TaskPlayAnim(ped, dealAnimDictTarget, dealAnimNameTarget, 8.0, -8.0, Config.DealDuration, 0, nil, false, false,
        false)
    TaskPlayAnim(cache.ped, dealAnimDict, dealAnimName, 8.0, -8.0, Config.DealDuration, 0, nil, false, false, false)
    lib.progressBar(data)

    FreezeEntityPosition(ped, false)
end)
