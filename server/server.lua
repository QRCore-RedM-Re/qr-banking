CreateThread(function()
    local ready = 0
    local buis = 0
    local cur = 0
    local sav = 0
    local gang = 0

    local accts = MySQL.Sync.fetchAll('SELECT * FROM bank_accounts WHERE account_type = ?', { 'Business' })
    buis = #accts
    if accts[1] ~= nil then
        for k, v in pairs(accts) do
            local acctType = v.business
            if businessAccounts[acctType] == nil then
                businessAccounts[acctType] = {}
            end
            businessAccounts[acctType][tonumber(v.businessid)] = generateBusinessAccount(tonumber(v.account_number), tonumber(v.sort_code), tonumber(v.businessid))
            while businessAccounts[acctType][tonumber(v.businessid)] == nil do Wait(0) end
        end
    end
    ready = ready + 1

    local savings = MySQL.Sync.fetchAll('SELECT * FROM bank_accounts WHERE account_type = ?', { 'Savings' })
    sav = #savings
    if savings[1] ~= nil then
        for k, v in pairs(savings) do
            savingsAccounts[v.citizenid] = generateSavings(v.citizenid)
        end
    end
    ready = ready + 1

    local gangs = MySQL.Sync.fetchAll('SELECT * FROM bank_accounts WHERE account_type = ?', { 'Gang' })
    gang = #gangs
    if gangs[1] ~= nil then
        for k, v in pairs(gangs) do
            gangAccounts[v.gangid] = loadGangAccount(v.gangid)
        end
    end
    ready = ready + 1

    repeat Wait(0) until ready == 5
    local totalAccounts = (buis + cur + sav + gang)
end)

exports('business', function(acctType, bid)
    if businessAccounts[acctType] then
        if businessAccounts[acctType][tonumber(bid)] then
            return businessAccounts[acctType][tonumber(bid)]
        end
    end
end)

RegisterServerEvent('qr-banking:server:modifyBank', function(bank, k, v)
    if banks[tonumber(bank)] then
        banks[tonumber(bank)][k] = v
        TriggerClientEvent('qr-banking:client:syncBanks', -1, banks)
    end
end)

exports('modifyBank', function(bank, k, v)
    TriggerEvent('qr-banking:server:modifyBank', bank, k, v)
end)

exports('registerAccount', function(cid)
    local _cid = tonumber(cid)
    currentAccounts[_cid] = generateCurrent(_cid)
end)

exports('current', function(cid)
    if currentAccounts[cid] then
        return currentAccounts[cid]
    end
end)

exports('savings', function(cid)
    if savingsAccounts[cid] then
        return savingsAccounts[cid]
    end
end)

exports('gang', function(gid)
    if gangAccounts[cid] then
        return gangAccounts[cid]
    end
end)

function checkAccountExists(acct, sc)
    local success
    local cid
    local actype
    local processed = false
    local exists = MySQL.Sync.fetchAll('SELECT * FROM bank_accounts WHERE account_number = ? AND sort_code = ?', { acct, sc })
    if exists[1] ~= nil then
        success = true
        cid = exists[1].character_id
        actype = exists[1].account_type
    else
        success = false
        cid = false
        actype = false
    end
    processed = true
    repeat Wait(0) until processed == true
    return success, cid, actype
end

RegisterServerEvent('qr-base:itemUsed', function(_src, data)
    if data.item == "moneybag" then
        TriggerClientEvent('qr-banking:client:usedMoneyBag', _src, data)
    end
end)

RegisterServerEvent('qr-banking:server:unpackMoneyBag', function(item)
    local _src = source
    if item then
        local player = QRCore.Functions.GetPlayer(_src)
        local xPlayerCID = player.PlayerData.citizenid
        local decode = json.decode(item.metapublic)
    end
end)

function getCharacterName(cid)
    local src = source
    local player = QRCore.Functions.GetPlayer(src)
    local name = player.PlayerData.name
end

function format_int(number)
    local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
    int = int:reverse():gsub("(%d%d%d)", "%1,")
    return minus .. int:reverse():gsub("^,", "") .. fraction
end

lib.callback.register('qr-banking:getBankingInformation', function(source)
    local src = source
    local player = QRCore.Functions.GetPlayer(src)
    if not player then return nil end

    local banking = {
        ['name'] = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        ['bankbalance'] = '$'.. format_int(player.PlayerData.money['bank']),
        ['cash'] = '$'.. format_int(player.PlayerData.money['cash']),
        ['accountinfo'] = player.PlayerData.charinfo.account,
    }
    return banking
end)

RegisterServerEvent('qr-banking:doQuickDeposit', function(amount)
    local src = source
    local player = QRCore.Functions.GetPlayer(src)
    local currentCash = player.Functions.GetMoney('cash')

    if tonumber(amount) <= currentCash then
        local cash = player.Functions.RemoveMoney('cash', tonumber(amount), 'banking-quick-depo')
        local bank = player.Functions.AddMoney('bank', tonumber(amount), 'banking-quick-depo')

        if not cash then return end
        if not bank then return end

        TriggerClientEvent('qr-banking:openBankScreen', src)
        TriggerClientEvent('qr-banking:successAlert', src, 'You made a cash deposit of $'..amount..' successfully.')
        TriggerEvent('qr-log:server:CreateLog', 'banking', 'Banking', 'lightgreen', "**"..GetPlayerName(player.PlayerData.source) .. " (citizenid: "..player.PlayerData.citizenid.." | id: "..player.PlayerData.source..")** made a cash deposit of $"..amount.." successfully.")
    end
end)

RegisterServerEvent('qr-banking:doQuickWithdraw', function(amount, branch)
    local src = source
    local player = QRCore.Functions.GetPlayer(src)
    local currentCash = player.Functions.GetMoney('bank')

    if tonumber(amount) <= currentCash then
        local cash = player.Functions.RemoveMoney('bank', tonumber(amount), 'banking-quick-withdraw')
        local bank = player.Functions.AddMoney('cash', tonumber(amount), 'banking-quick-withdraw')

        if not bank then return end
        if not cash then return end

        TriggerClientEvent('qr-banking:openBankScreen', src)
        TriggerClientEvent('qr-banking:successAlert', src, 'You made a cash withdrawal of $'..amount..' successfully.')
        TriggerEvent('qr-log:server:CreateLog', 'banking', 'Banking', 'red', "**"..GetPlayerName(player.PlayerData.source) .. " (citizenid: "..player.PlayerData.citizenid.." | id: "..player.PlayerData.source..")** made a cash withdrawal of $"..amount.." successfully.")
    end
end)

RegisterServerEvent('qr-banking:savingsDeposit', function(amount)
    local src = source
    local player = QRCore.Functions.GetPlayer(src)
    local currentBank = player.Functions.GetMoney('bank')

    if tonumber(amount) <= currentBank then
        local bank = player.Functions.RemoveMoney('bank', tonumber(amount))
        local savings = savingsAccounts[player.PlayerData.citizenid].AddMoney(tonumber(amount), 'Current Account to Savings Transfer')

        if not bank then return end
        if not savings then return end

        TriggerClientEvent('qr-banking:openBankScreen', src)
        TriggerClientEvent('qr-banking:successAlert', src, 'You made a savings deposit of $'..tostring(amount)..' successfully.')
        TriggerEvent('qr-log:server:CreateLog', 'banking', 'Banking', 'lightgreen', "**"..GetPlayerName(player.PlayerData.source) .. " (citizenid: "..player.PlayerData.citizenid.." | id: "..player.PlayerData.source..")** made a savings deposit of $"..tostring(amount).." successfully..")
    end
end)

RegisterServerEvent('qr-banking:savingsWithdraw', function(amount)
    local src = source
    local player = QRCore.Functions.GetPlayer(src)
    local currentSavings = savingsAccounts[player.PlayerData.citizenid].GetBalance()

    if tonumber(amount) <= currentSavings then
        local savings = savingsAccounts[player.PlayerData.citizenid].RemoveMoney(tonumber(amount), 'Savings to Current Account Transfer')
        local bank = player.Functions.AddMoney('bank', tonumber(amount), 'banking-quick-withdraw')

        if not bank then return end
        if not savings then return end

        TriggerClientEvent('qr-banking:openBankScreen', src)
        TriggerClientEvent('qr-banking:successAlert', src, 'You made a savings withdrawal of $'..tostring(amount)..' successfully.')
        TriggerEvent('qr-log:server:CreateLog', 'banking', 'Banking', 'red', "**"..GetPlayerName(player.PlayerData.source) .. " (citizenid: "..player.PlayerData.citizenid.." | id: "..player.PlayerData.source..")** made a savings withdrawal of $"..tostring(amount).." successfully.")
    end
end)

RegisterServerEvent('qr-banking:createSavingsAccount', function()
    local src = source
    local player = QRCore.Functions.GetPlayer(src)
    local success = createSavingsAccount(player.PlayerData.citizenid)

    repeat Wait(0) until success ~= nil
    TriggerClientEvent('qr-banking:openBankScreen', src)
    TriggerClientEvent('qr-banking:successAlert', src, 'You have successfully opened a savings account.')
    TriggerEvent('qr-log:server:CreateLog', 'banking', 'Banking', "lightgreen", "**"..GetPlayerName(player.PlayerData.source) .. " (citizenid: "..player.PlayerData.citizenid.." | id: "..player.PlayerData.source..")** opened a savings account")
end)

lib.addCommand('givecash', {
    help = 'Give cash to player.',
    params = {
        { name = 'id', help = 'Player Id', type = 'playerId' },
        { name = 'amount', help = 'Amount of Cash', type = 'number' }
    }
}, function(source, args)
    local src = source
    local id = tonumber(args.id)
    local amount = math.ceil(tonumber(args.amount))

    if not id and not amount then return TriggerClientEvent('QRCore:Notify', src, 9, "Usage /givecash [ID] [AMOUNT]", 2000, 0, 'mp_lobby_textures', 'cross') end

    local player = QRCore.Functions.GetPlayer(src)
    local otherPlayer = QRCore.Functions.GetPlayer(id)

    if player and otherPlayer then
        if player.PlayerData.metadata.isdead then return TriggerClientEvent('QRCore:Notify', src, 9, "You are dead LOL.", 2000, 0, 'mp_lobby_textures', 'cross') end

        local distance = player.PlayerData.metadata.inlaststand and 3.0 or 10.0
        if not #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(id))) < distance then return TriggerClientEvent('QRCore:Notify', src, 9, "You are too far away lmfao.", 2000, 0, 'mp_lobby_textures', 'cross') end

        if not player.Functions.RemoveMoney('cash', amount) then return TriggerClientEvent('QRCore:Notify', src, 9, "You don\'t have this amount.", 2000, 0, 'mp_lobby_textures', 'cross') end
        if not otherPlayer.Functions.AddMoney('cash', amount) then return TriggerClientEvent('QRCore:Notify', src, 9, "Could not give item to the given id.", 2000, 0, 'mp_lobby_textures', 'cross') end

        TriggerClientEvent('QRCore:Notify', src, 9, "Success fully gave to ID " .. tostring(id) .. ' ' .. tostring(amount) .. '$.', 2000, 0, 'hud_textures', 'check')
        TriggerClientEvent('QRCore:Notify', id, "Success recived gave " .. tostring(amount) .. '$ from ID ' .. tostring(src), 2000, 0, 'hud_textures', 'check')
        TriggerClientEvent("payanimation", src)
    else
        TriggerClientEvent('QRCore:Notify', src, 9, "Wrong ID.", 2000, 0, 'mp_lobby_textures', 'cross')
    end
end)
