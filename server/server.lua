local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('d_drugsell:server:checkPlayerDrugs', function(source, cb, serverId)
    local xPlayer = QBCore.Functions.GetPlayer(serverId)
    if xPlayer then
        for drugName, drugPrice in pairs(Config.Drugs) do
            local item = xPlayer.Functions.GetItemByName(drugName)
            if item and item.amount > 0 then
                cb(true, item.name, item.amount, drugPrice)
                return
            end
        end
    end
    cb(false)
end)


local function RemoveRandomAmountOfDrugs(xPlayer, drugName, drugAmount)
    local amountToRemove = math.random(1, drugAmount)
    xPlayer.Functions.RemoveItem(drugName, amountToRemove)
    return amountToRemove
end

local function AntiyExploitCheck(xPlayer, drugName, drugAmount)
    if not xPlayer then return false end

    local item = xPlayer.Functions.GetItemByName(drugName)
        if item.name == drugName then
            if item.amount < drugAmount then
                return false
            end
        end
    return true
end

RegisterNetEvent('d_drugsell:server:sellDrugs', function(drugName, drugAmount, drugPrice)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if xPlayer then
        if AntiyExploitCheck(xPlayer, drugName, drugAmount) then
            local profit = drugPrice * RemoveRandomAmountOfDrugs(xPlayer, drugName, drugAmount)
            xPlayer.Functions.AddMoney('cash', profit)
            TriggerClientEvent('QBCore:Notify', source, string.format(Lang.pl_pl.sold_some, drugAmount, drugName, profit), 'success')
        else
            TriggerClientEvent('QBCore:Notify', source, Lang.pl_pl.not_enough_drugs, 'error')
            print('[d_drugsell] Exploit attempt detected from player ' .. xPlayer.PlayerData.citizenid .. ' (ID: ' .. source .. ')')
        end
    end
end)