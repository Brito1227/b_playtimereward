# 🏆 Weekly Playtime Rewards System

This script tracks the weekly playtime of players and automatically rewards the **Top 3** players with in-game currency ("VIP Coins").  
It includes full support for **QBCore** and **ESX**, and is optimized using **ox_lib** and **oxmysql**.

---

## 🎯 About

I originally built this system for my own roleplay server project, but I've decided to share it with the community.  
It’s designed to be simple, customizable, and fully automated.

It has not been tested on esx, if any fix is ​​needed please report it.

---

## 📦 Features

- ⏱️ Tracks total session time per player  
- 🧠 Stores and updates playtime in database  
- 🏆 Rewards the top 3 most active players weekly  
- 💰 Automatically gives in-game currency (via configurable account type)  
- 📆 Uses `ox_lib` cron system to trigger rewards every Tuesday (default)  
- 📡 Sends a nicely formatted embed to a Discord webhook with the results  
- ⚙️ Supports both **QBCore** and **ESX**  
- 💻 Optional manual command to run the reward system (`/recompensasmanual`)  

---

## ✅ Requirements

- [oxmysql](https://github.com/overextended/oxmysql)  
- [ox_lib](https://github.com/overextended/ox_lib)  
- [QBCore Framework](https://github.com/qbcore-framework/qb-core) or [ESX Legacy](https://github.com/esx-framework/esx_core)

---

## 🛠️ Installation

1. Download or clone this repository.
2. Add it to your server resources.
3. Add the resource to your `server.cfg`:
   ```
   ensure b_playtimereward
   ```
4. Make sure you have the required `b_tempojogado` table in your database:
   ```sql
   CREATE TABLE IF NOT EXISTS `b_tempojogado` (
       `citizenid` VARCHAR(64) NOT NULL,
       `horas_jogadas` FLOAT NOT NULL DEFAULT 0,
       PRIMARY KEY (`citizenid`)
   );
   ```

---

## 💬 Example Discord Embed

The Discord message will look like this:

```
🏆 TOP 3 Weekly Players 🏆

1º — PandaRP [XYJ1245]
Hours: 14h23m2s
Reward: 50 VIP Coins

2º — Marcos [X8WS892]
Hours: 10h50m44s
Reward: 25 VIP Coins

3º — Luna [WNZ0132]
Hours: 9h16m8s
Reward: 15 VIP Coins

The coins have been delivered automatically, thank you!
```

---

## 🔁 Optional Manual Command

You can manually trigger the reward system via server console (if enabled in the config):

```
/recompensasmanual
```

> Only works if executed from server console (source = 0)

---

## 🗒️ Notes

- The system uses either `citizenid` (QBCore) or `getIdentifier()` (ESX) to track player time.
- Offline players still receive their rewards via database update.
- All logic is handled server-side for optimal performance and security.
