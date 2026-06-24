local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('d_drugsell:server:checkPlayerDrugs', function(source,cb, serverId)
    local xPlayer = QBCore.Functions.GetPlayer(serverId)
    if xPlayer then
        local drugs = xPlayer.PlayerData.items
        for _, item in pairs(drugs) do
            if item.name == 'weed' or item.name == 'coke' or item.name == 'meth' then
                local drugName = item.name
                local drugAmount = item.amount
                local drugPrice = 0

                for name, price in pairs(Config.Drugs) do
                    if name == drugName then
                        drugPrice = price
                        break
                    end
                end

                cb(true, drugName, drugAmount, drugPrice)
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
    local playerDrugs = xPlayer.PlayerData.items
    for _, item in pairs(playerDrugs) do
        if item.name == drugName then
            if item.amount < drugAmount then
                return false
            end
        end
    end
    return true
end

ServerEvent('d_drugsell:server:sellDrugs', function(drugName, drugAmount, drugPrice)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if xPlayer then
        if AntiyExploitCheck(xPlayer, drugName, drugAmount) then
            local profit = drugPrice * RemoveRandomAmountOfDrugs(xPlayer, drugName, drugAmount)
            xPlayer.Functions.AddMoney('cash', profit)
            TriggerClientEvent('QBCore:Notify', source, string.format(lang.pl_pl.sold_some, drugAmount, drugName, profit), 'success')
        else
            TriggerClientEvent('QBCore:Notify', source, lang.pl_pl.not_enough_drugs, 'error')
            print('[d_drugsell] Exploit attempt detected from player ' .. xPlayer.PlayerData.citizenid .. ' (ID: ' .. source .. ')')
        end
    end
end)