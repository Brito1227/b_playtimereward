Config = {}

-- Choose your framework: "qbcore" or "esx"
Config.Framework = "qbcore"

-- Cron expression to define when rewards are distributed
-- Default: Every Tuesday at 09:00
Config.CronExpression = '0 9 * * 2'

-- Players database table name 
Config.Database = {
    PlayersTable = "players"
}

-- Account type to give rewards (e.g., "coins", "bank", "money")
Config.MoneyAccount = "coins"

-- Rewards for top 3 players (1st, 2nd, 3rd)
Config.Recompensas = {
    50,
    25,
    15
}

-- Discord Webhook URL
Config.Webhook = "https://discord.com/api/webhooks/SEU_WEBHOOK_AQUI"

-- Bot name that sends the Discord message
Config.BotName = "Assistente Panda"

-- Embed color for Discord message
Config.EmbedColor = 6501492

-- Final message sent on Discord after top 3 listing
Config.MensagemFinal = "The coins have been delivered automatically, thank you!"

-- Allow manual command to trigger rewards (true or false)
Config.ComandoManualAtivo = true

-- Name of the manual reward command (e.g. /recompensasmanual)
Config.NomeDoComandoManual = "recompensasmanual"
