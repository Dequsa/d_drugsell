local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('d_drugsell:server:checkPlayerDrugs', function(source, cb, serverId)
    local xPlayer = QBCore.Functions.GetPlayer(serverId)
    if xPlayer then
        for drugName, drugPrice in pairs(Config.Drugs) do
            local item = xPlayer.Functions.GetItemByName(drugName)
            if item and item.amount > Config.MinSellAmount then
                cb(true, item.name, item.amount, drugPrice)
                return
            end
        end
    end
    cb(false)
end)


local function SetUpperLimit(drugAmount)
    return math.min(drugAmount, Config.MaxSellAmount)
end

local function RemoveRandomAmountOfDrugs(xPlayer, drugName, drugAmount)
    local maxPossibleSell = SetUpperLimit(drugAmount)
    local minPossibleSell = Config.MinSellAmount
    local amountToRemove = math.random(minPossibleSell, maxPossibleSell)

    exports.ox_inventory:RemoveItem(xPlayer.PlayerData.source, drugName, amountToRemove)
    return amountToRemove
end

local function AntiyExploitCheck(xPlayer, drugName, drugAmount)
    if not xPlayer then return false end

    local item = xPlayer.Functions.GetItemByName(drugName)
        return item and item.amount >= drugAmount or false
end

RegisterNetEvent('d_drugsell:server:sellDrugs', function(drugName, drugAmount, drugPrice)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if xPlayer then
        if AntiyExploitCheck(xPlayer, drugName, drugAmount) then
            local sellAmount = RemoveRandomAmountOfDrugs(xPlayer, drugName, drugAmount)
            local profit = drugPrice * sellAmount
            xPlayer.Functions.AddMoney('cash', profit)
            TriggerClientEvent('QBCore:Notify', source, string.format(Lang.pl_pl.sold_some, sellAmount, drugName, profit), 'success')
        else
            TriggerClientEvent('QBCore:Notify', source, Lang.pl_pl.not_enough_drugs, 'error')
            print('[d_drugsell] Exploit attempt detected from player ' .. xPlayer.PlayerData.citizenid .. ' (ID: ' .. source .. ')')
        end
    end
end)