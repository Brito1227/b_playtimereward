local connectedPlayers = {}

local QBCore, ESX

CreateThread(function()
    if Config.Framework == "qbcore" then
        QBCore = exports['qb-core']:GetCoreObject()
    elseif Config.Framework == "esx" then
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    end
end)

if Config.Framework == "qbcore" then
    RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function(Player)
        local src = source
        connectedPlayers[src] = os.time()
    end)
elseif Config.Framework == "esx" then
    RegisterNetEvent('esx:playerLoaded', function(playerId, xPlayer)
        connectedPlayers[playerId] = os.time()
    end)
end

AddEventHandler('playerDropped', function(reason)
    local src = source

    local Player
    if Config.Framework == "qbcore" then
        Player = QBCore.Functions.GetPlayer(src)
    elseif Config.Framework == "esx" then
        Player = ESX.GetPlayerFromId(src)
    end

    if not Player then return end

    local joinTime = connectedPlayers[src]
    local leaveTime = os.time()

    if joinTime then
        local secondsPlayed = leaveTime - joinTime
        local hoursPlayed = secondsPlayed / 3600

        MySQL.update([[ 
            INSERT INTO b_tempojogado (citizenid, horas_jogadas) 
            VALUES (?, ?) 
            ON DUPLICATE KEY UPDATE horas_jogadas = horas_jogadas + VALUES(horas_jogadas)
        ]], {
            GetPlayerIdentifier(Player), hoursPlayed
        })

        connectedPlayers[src] = nil
    end
end)

lib.cron.new(Config.CronExpression, function()
    RewardTopPlayers()
end)

function RewardTopPlayers()
    local result = MySQL.query.await([[  
        SELECT citizenid, horas_jogadas  
        FROM b_tempojogado  
        ORDER BY horas_jogadas DESC  
        LIMIT 3
    ]])

    if not result or #result == 0 then return end

    local message = ""

    for i, player in ipairs(result) do
        local citizenid = player.citizenid
        local decimalHours = player.horas_jogadas
        local coins = Config.Rewards[i] or 5

        local Player
        if Config.Framework == "qbcore" then
            Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
        elseif Config.Framework == "esx" then
            for _, id in pairs(GetPlayers()) do
                local temp = ESX.GetPlayerFromId(tonumber(id))
                if temp and temp.getIdentifier() == citizenid then
                    Player = temp
                end
            end
        end

        if Player then
            AddMoney(Player, coins)
        else
            MySQL.update(string.format([[  
                UPDATE %s  
                SET money = JSON_SET(money, '$.%s', JSON_EXTRACT(money, '$.%s') + ?)  
                WHERE citizenid = ?
            ]], Config.Database.PlayersTable, Config.MoneyAccount, Config.MoneyAccount), {
                coins, citizenid
            })
        end

        local name = GetSteamNameFromCitizenID(citizenid) or 'Unknown'

        local totalSeconds = math.floor(decimalHours * 3600)
        local h = math.floor(totalSeconds / 3600)
        local m = math.floor((totalSeconds % 3600) / 60)
        local s = totalSeconds % 60
        local formattedTime = string.format("%dh%dm%ds", h, m, s)

        message = message .. string.format(
            "%dº — %s [%s]\nHours: %s\nReward: **%d VIP Coins**\n\n",
            i, name, citizenid, formattedTime, coins
        )
    end

    message = message .. Config.FinalMessage

    SendToDiscordWebhook(message)

    MySQL.update("DELETE FROM b_tempojogado")
end

function AddMoney(Player, amount)
    if Config.Framework == "qbcore" then
        Player.Functions.AddMoney(Config.MoneyAccount, amount, 'Weekly Reward')
    elseif Config.Framework == "esx" then
        Player.addAccountMoney(Config.MoneyAccount, amount)
    end
end

function GetPlayerIdentifier(Player)
    if Config.Framework == "qbcore" then
        return Player.PlayerData.citizenid
    elseif Config.Framework == "esx" then
        return Player.getIdentifier()
    end
end

function GetSteamNameFromCitizenID(citizenid)
    local field = Config.Framework == "qbcore" and "citizenid" or "identifier"

    local query = string.format("SELECT name FROM %s WHERE %s = ?", Config.Database.PlayersTable, field)

    local data = MySQL.single.await(query, { citizenid })

    return data and data.name or nil
end

function SendToDiscordWebhook(formattedResult)
    local embed = { {
        ["title"] = "🏆 TOP 3 Weekly Players 🏆",
        ["description"] = formattedResult,
        ["color"] = Config.EmbedColor,
        ["footer"] = {
            ["text"] = "Weekly Reward • " .. os.date("%x %X")
        }
    } }

    PerformHttpRequest(Config.Webhook, function(err, text, headers)
        if err ~= 204 then
            print("[Webhook ERROR]", err)
        end
    end, 'POST', json.encode({
        username = Config.BotName,
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

if Config.ManualCommandEnabled then
    RegisterCommand(Config.ManualCommandName, function(source)
        if source ~= 0 then return end
        RewardTopPlayers()
        print('Weekly reward executed!')
    end)
end
