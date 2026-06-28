local QBCore = exports['qb-core']:GetCoreObject()
local blacklistedPeds = {}
local ped = nil
local targetName = 'd_drugsell_target'
local newTargetName = 'd_drugsell_steal'
local dealtPeds = {}
local thief = {}
local thief_npc = nil

local function CheckBlacklist(entity)
    local model = GetEntityModel(entity)
    return blacklistedPeds[model]
end

local function CheckTargeting(entity)
    if dealtPeds[entity] == true then
        return false
    end

    if CheckBlacklist(entity) then
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
            dealtPeds[ped] = true
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

local function MakePedRun(captured)
    local fleeDistance = 1000
    local fleeTime = -1 -- forever
    ClearPedTasksImmediately(captured)
    SetBlockingOfNonTemporaryEvents(captured, true)
    TaskSmartFleePed(captured, cache.ped, fleeDistance, fleeTime)
end

RegisterNetEvent('d_drugsell:client:thiefNpc', function()
    local captured = ped
    thief_npc = captured

    local options = {
        label = Lang.pl_pl.get_back_drugs,
        name = newTargetName,
        icon = Config.newTargetIcon,
        distance = Config.SellDistance,
        canInteract = function(entity, distance, coords, name, bone)
            return entity == captured and thief[captured] == true
        end,

        onSelect = function(data)
            TriggerServerEvent('d_drugsell:server:getbackdrugs')
            thief[captured] = false
        end
    }

    exports.ox_target:addLocalEntity(captured, options)
    thief[captured] = true

    MakePedRun(captured)
end)

RegisterNetEvent('d_drugsell:client:cleanthief', function()
    exports.ox_target:removeLocalEntity(thief_npc, newTargetName)
end)
