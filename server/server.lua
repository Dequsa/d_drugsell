local QBCore = exports['qb-core']:GetCoreObject()
local cooldowns = {}

-- QBCore.Functions.CreateCallback('d_drugsell:server:checkPlayerDrugs', function(source, cb)
--     local xPlayer = QBCore.Functions.GetPlayer(source)
--     if xPlayer then
--         for drugName in pairs(Config.Drugs) do
--             local item = xPlayer.Functions.GetItemByName(drugName)
--             if item and item.amount >= Config.MinSellAmount then
--                 cb(true)
--                 return
--             end
--         end
--     end
--     cb(false)
-- end)

local function RemoveRandomAmountOfDrugs(xPlayer, drugName, drugAmount)
    local maxPossibleSell = math.min(drugAmount, Config.MaxSellAmount)
    local minPossibleSell = Config.MinSellAmount
    local amountToRemove = math.random(minPossibleSell, maxPossibleSell)

    exports.ox_inventory:RemoveItem(xPlayer.PlayerData.source, drugName, amountToRemove)
    return amountToRemove
end

local function SuccessfulSell(item, src, xPlayer, modPrice)
    local drugAmount = item.amount
    local sellAmount = RemoveRandomAmountOfDrugs(xPlayer, item.name, drugAmount)

    if modPrice == nil then
        modPrice = Config.Drugs[item.name]
    else
        modPrice = Config.Drugs[item.name] * modPrice
    end

    local profit = modPrice * sellAmount
    xPlayer.Functions.AddMoney('cash', profit)
    TriggerClientEvent('QBCore:Notify', src, string.format(Lang.pl_pl.sold_some, sellAmount, item.name, profit),
        'success')
end

local function FailedSell(src, xPlayer)
    TriggerClientEvent('QBCore:Notify', src, Lang.pl_pl.not_enough_drugs, 'error')
    -- print('[d_drugsell] Exploit attempt detected from player ' .. xPlayer.PlayerData.citizenid .. ' (ID: ' .. src .. ')')
end

local function EventRandomizer()
    local roll = math.random()
    local sum = 0
    for event, chance in pairs(Config.EventType) do
        sum = sum + chance
        if roll <= sum then
            return event
        end
    end
end

local events = {
    undercover_cop = function(src, xPlayer, item)
        TriggerClientEvent('QBCore:Notify', src, string.format(Lang.pl_pl.u_c, '`'), 'error')
    end,
    no_pay = function(src, xPlayer, item)
        TriggerClientEvent('QBCore:Notify', src, Lang.pl_pl.no_pay, 'error')
    end,
    over_pay = function(src, xPlayer, item)
        TriggerClientEvent('QBCore:Notify', src, Lang.pl_pl.over_pay, 'success')
        local min = 10
        local max = Config.MaxPriceModifier * 10
        local priceModifier = math.random(min, max) / 10
        SuccessfulSell(item, src, xPlayer, priceModifier)
    end,
    dismissive = function(src, xPlayer, item)
        TriggerClientEvent('QBCore:Notify', src, Lang.pl_pl.dissmisive, 'error')
    end,
    normal = function(src, xPlayer, item)
        SuccessfulSell(item, src, xPlayer, nil)
    end
}

RegisterNetEvent('d_drugsell:server:sellDrugs', function()
    local src = source
    local now = os.time()

    if cooldowns[src] and cooldowns[src] > now then
        TriggerClientEvent('QBCore:Notify', src, string.format(Lang.pl_pl.cooldown, cooldowns[src] - now), 'error')
        return
    end

    cooldowns[src] = now + Config.SellCooldown

    local xPlayer = QBCore.Functions.GetPlayer(src)
    if xPlayer then
        local item = nil
        for drugName in pairs(Config.Drugs) do
            local found = xPlayer.Functions.GetItemByName(drugName)
            if found and found.amount >= Config.MinSellAmount then
                item = found
                break
            end
        end

        if item then
            local randomEvent = EventRandomizer()
            if events[randomEvent] then
                TriggerClientEvent('d_drugsell:client:handleDealAnimations', src)
                events[randomEvent](src, xPlayer, item)
            end
        else
            FailedSell(src, xPlayer)
        end
    end
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)
