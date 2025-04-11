local jogadoresConectados = {}

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
        jogadoresConectados[src] = os.time()
    end)
elseif Config.Framework == "esx" then
    RegisterNetEvent('esx:playerLoaded', function(playerId, xPlayer)
        jogadoresConectados[playerId] = os.time()
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

    local entrada = jogadoresConectados[src]
    local saida = os.time()

    if entrada then
        local segundos = saida - entrada
        local horas = segundos / 3600

        MySQL.update([[ 
            INSERT INTO b_tempojogado (citizenid, horas_jogadas) 
            VALUES (?, ?) 
            ON DUPLICATE KEY UPDATE horas_jogadas = horas_jogadas + VALUES(horas_jogadas)
        ]], {
            GetPlayerIdentifier(Player), horas
        })

        jogadoresConectados[src] = nil
    end
end)

lib.cron.new(Config.CronExpression, function()
    RecompensarTopJogadores()
end)

function RecompensarTopJogadores()
    local resultado = MySQL.query.await([[  
        SELECT citizenid, horas_jogadas  
        FROM b_tempojogado  
        ORDER BY horas_jogadas DESC  
        LIMIT 3
    ]])

    if not resultado or #resultado == 0 then return end

    local mensagem = ""

    for i, jogador in ipairs(resultado) do
        local citizenid = jogador.citizenid
        local horasDecimais = jogador.horas_jogadas
        local coins = Config.Recompensas[i] or 5

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

        local nome = GetSteamNameFromCitizenID(citizenid) or 'Unknown'

        local totalSegundos = math.floor(horasDecimais * 3600)
        local horas = math.floor(totalSegundos / 3600)
        local minutos = math.floor((totalSegundos % 3600) / 60)
        local segundos = totalSegundos % 60
        local horasFormatadas = string.format("%dh%dm%ds", horas, minutos, segundos)

        mensagem = mensagem .. string.format(
            "%dº — %s [%s]\nHours: %s\nReward: **%d VIP Coins**\n\n",
            i, nome, citizenid, horasFormatadas, coins
        )
    end

    mensagem = mensagem .. Config.MensagemFinal

    EnviarParaDiscordWebhook(mensagem)

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


function EnviarParaDiscordWebhook(resultadoFormatado)
    local embed = { {
        ["title"] = "🏆 TOP 3 Weekly Players 🏆",
        ["description"] = resultadoFormatado,
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

if Config.ComandoManualAtivo then
    RegisterCommand(Config.NomeDoComandoManual, function(source)
        if source ~= 0 then return end
        RecompensarTopJogadores()
        print('Weekly reward executed!')
    end)
end
