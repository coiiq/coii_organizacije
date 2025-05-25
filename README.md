
# 🚔 ESX Organization System | STAR Points, Upgrades, Vehicles & Logs

A powerful and immersive FiveM ESX-based organizational system built for roleplay servers with mafia/gang-like groups. It provides a dynamic way to manage upgrades, vehicles, storage, and competition between groups using STAR points.

## ✨ Features

- 🎯 STAR Points system (earnable via exports)
- 🛠️ Upgrade shop (vehicle upgrades, expandable safe weight and changing organization's plates)
- 🚐 Organization van/shop system with animations
- 🚗 Organization vehicles with cinematic camera and return logic
- 📦 Safe with expanding weight capacity (uses `ox_inventory`)
- 📊 Leaderboard system with live ranking
- 🧩 Fully configurable via `config.lua`
- 🔔 Discord logging for major actions

---

## 🧾 Admin Commands (CONFIGURABLE IN CONFIG.LUA)

| Command         | Description                   |
|-----------------|-------------------------------|
| `/addstars`     | Add STAR points to a society  |
| `/removestars`  | Remove STAR points            |
| `/checkstars`   | Check current STAR balance    |
| `/resetplates`  | Reset organization plates     |

> All commands require admin permissions.

---

## 🚐 Organization Shop (Van System)

- Players can access the shop by walking to the organization van.
- Uses `ox_target` for interaction.
- Includes animations when opening the menu.

---

## 🎬 Vehicle Handling Animations

- When spawning a vehicle: cinematic camera plays + visual effects + discord log.
- When returning vehicle: animation + notification with Discord log.

---

## 📤 Exports

Export these in other scripts to interact with the system:

```lua
-- Get upgrade level
exports['coii_organizacije']:getUpgradeLevel('society_name', 'vehicle_mods')

-- Remove STAR points
exports['coii_organizacije']:removePoints('society_name', 10)

-- Add STAR points
exports['coii_organizacije']:addPoints('society_name', 20)
```

---

## 📡 Discord Logs

This system logs the following events to your Discord webhook:

- Vehicle spawned
- Shop location (coords)
- Upgrade purchased
- Purchasing custom plate prefix
- STAR points added/removed
- Leaderboard refresh

Example webhook config in `sv_config.lua`:

```lua
Config.Webhook = 'https://discord.com/api/webhooks/...'
Config.LeaderboardWebhook = 'https://discord.com/api/webhooks/...'
Config.ShopWebhook = 'https://discord.com/api/webhooks/...'
```

---

## 📊 Leaderboard Logging

Leaderboard is updated automatically and logs the top organizations and their STAR point balance to a Discord webhook when refreshed.

- Triggered manually or on interval
- Displays: Top 5 organizations by points
- Uses `ox_lib` context menu for in-game viewing

---

## 💾 Dependencies

- [`ox_lib`](https://github.com/overextended/ox_lib)
- [`ox_inventory`](https://github.com/overextended/ox_inventory)
- [`ox_target`](https://github.com/overextended/ox_target)
- `es_extended` (1.9.4+)
- `oxmysql`

---

## 🔧 Installation

1. Place the resource in your `resources` folder.
2. Add to `server.cfg`:
   ```cfg
   ensure coii_organizacije
   ```
3. Import the included `SQL` file into your database.
4. Configure everything in `config.lua`.

---

## 🛠️ Support

For support or bug reports, open an issue on GitHub or contact: `coii`
