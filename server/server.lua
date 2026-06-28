local QBCore = exports['qb-core']:GetCoreObject()
local cooldowns = {}
local stolenAmounts = {}
local stolenItems = {}

local function RemoveRandomAmountOfDrugs(xPlayer, item)
    local maxPossibleSell = math.min(item.amount, Config.MaxSellAmount)
    local minPossibleSell = Config.MinSellAmount
    local amountToRemove = math.random(minPossibleSell, maxPossibleSell)

    exports.ox_inventory:RemoveItem(xPlayer.PlayerData.source, item.name, amountToRemove)
    return amountToRemove
end

local function SuccessfulSell(item, src, xPlayer, modPrice)
    local sellAmount = RemoveRandomAmountOfDrugs(xPlayer, item)

    if modPrice == nil then
        modPrice = Config.Drugs[item.name]
    else
        modPrice = Config.Drugs[item.name] * modPrice
    end
    
    local profit = modPrice * sellAmount
    xPlayer.Functions.AddMoney('cash', profit)

    TriggerClientEvent('d_drugsell:client:handleDealAnimations', src)
    TriggerClientEvent('QBCore:Notify', src, string.format(Lang.pl_pl.sold_some, sellAmount, item.name, profit), 'success')
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
        
        local stolenAmount = RemoveRandomAmountOfDrugs(xPlayer, item)
        stolenAmounts[src] = stolenAmount
        stolenItems[src] = item
        TriggerClientEvent('d_drugsell:client:thiefNpc', src)
        TriggerClientEvent('d_drugsell:client:handleDealAnimations', src)
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

RegisterNetEvent('d_drugsell:server:getbackdrugs', function()
    local src = source
    if stolenAmounts[src] == nil or stolenItems[src] == nil then
        return
    end

    local stolenAmount = stolenAmounts[src]
    local stolenDrug = stolenItems[src]

    stolenAmounts[src] = nil
    stolenItems[src] = nil

    exports.ox_inventory:AddItem(src, stolenDrug.name, stolenAmount)
    TriggerClientEvent('d_drugsell:client:cleanthief')
end)


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
                events[randomEvent](src, xPlayer, item)
            end
        else
            FailedSell(src, xPlayer)
        end
    end
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
    stolenAmounts[source] = nil
    stolenItems[source] = nil
end)
