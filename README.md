# SocialBar

A lightweight, movable World of Warcraft addon for **WoW Midnight (Retail)** that shows your Battle.net friends and guild members who are currently online — right on your screen at all times. Hover to see who's online and where they are. Right-click to invite them instantly.

---

## Features

- **Movable bar** — drag it anywhere on your screen, position is saved between sessions
- **Friends button** — shows all Battle.net friends currently playing WoW Retail (Classic filtered out)
- **Guild button** — shows all guild members currently online with rank and zone
- **Hover tooltips** — class-colored names, level, class, status, current zone, and realm for cross-realm friends
- **AFK / DND status** — see at a glance if someone is away or busy before you invite
- **Right-click invite** — invite anyone directly from a dropdown menu
- **Online count** — optionally shows live counts on the buttons (e.g. `Friends (4)`)
- **Gear button (⚙)** — quick access to all settings without typing any commands
- **Full settings panel** — available under Interface > AddOns > SocialBar
- **Horizontal or vertical layout** — switch between side-by-side and stacked buttons
- **Customizable appearance** — transparency and font size

---

## Installation

### Manual
1. Download and unzip the `SocialBar` folder
2. Place the `SocialBar` folder into:
   - **Windows:** `C:\Program Files\World of Warcraft\_retail_\Interface\AddOns\`
   - **Mac:** `/Applications/World of Warcraft/_retail_/Interface/AddOns/`
3. Launch WoW, click **AddOns** at the character select screen, and make sure **SocialBar** is enabled

### Via CurseForge App
Search for **SocialBar** in the CurseForge app and click Install.

---

## How It Works

### The Bar
When you log in, a small dark bar appears on your screen with three elements:
- **Friends** button (blue) — your Battle.net friends playing WoW Retail
- **Guild** button (green) — your guild members currently online
- **⚙ Gear** button — settings access

You can **left-click and drag** the bar background to reposition it anywhere. The position is automatically saved.

### Tooltips
Hovering over either button shows a tooltip with:
- Each online player's name in their **class color**
- Their **AFK / DND status** (if applicable), shown in orange or red
- Their **level and class** in parentheses
- Their current **zone**
- Their **realm** (if cross-realm, shown in grey after their name)

Example tooltip line:
```
Valdris [AFK] (Lvl 80 Paladin) - Ashenveil
```

All tooltip fields can be individually toggled on or off in settings.

### Inviting
**Right-click** the Friends or Guild button to open an invite dropdown. Click any name to send them a group invite. Cross-realm invites are handled automatically.

### Settings
There are three ways to access settings:

| Method | What it does |
|--------|-------------|
| **Left-click ⚙** | Opens quick settings dropdown |
| **Right-click ⚙** | Opens full Interface > AddOns settings panel |
| **Right-click bar background** | Opens quick settings dropdown |

---

## Slash Commands

| Command | Description |
|---------|-------------|
| `/socialbar` | Shows available commands |
| `/socialbar config` | Opens the full settings panel |
| `/socialbar reset` | Resets the bar to its default position |
| `/sbdebug` | Prints diagnostic info to chat (see Debugging below) |

---

## Settings Reference

### Quick Dropdown (⚙ left-click)
- **Switch to Vertical / Horizontal** — toggle button layout
- **Show / Hide Online Count** — toggle count display on buttons
- **Show / Hide AFK/DND Status** — toggle status badges in tooltips
- **Show / Hide Character Level** — toggle level display in tooltips
- **Show / Hide Character Class** — toggle class display in tooltips
- **Font Size +/-** — increase or decrease font size one step at a time
- **More / Less Transparent** — adjust bar transparency one step at a time
- **Open Full Settings...** — opens the Interface panel
- **Reset Position** — snaps bar back to default position

### Full Settings Panel (Interface > AddOns > SocialBar or ⚙ right-click)

**General**
- **Show online count on buttons** — checkbox toggle

**Tooltip Info**
- **Show AFK / DND status** — checkbox toggle
- **Show character level** — checkbox toggle
- **Show character class** — checkbox toggle

**Layout**
- **Vertical layout** — checkbox toggle

**Appearance**
- **Transparency** — slider from 1 (most transparent) to 10 (opaque)
- **Font Size** — slider from 8pt to 18pt
- **Reset Position** — button to restore default bar position

---

## Debugging

If something isn't working correctly, type `/sbdebug` in chat. This will print detailed information including:

- Total Battle.net friends and how many are online
- Each friend's online status, game client, character name, class, and zone
- How many friends and guild members are currently in the addon's cache

### Common Issues

**Friends list shows empty**
- Make sure you have Battle.net friends (not just in-game friends). The addon uses the modern BNet API
- Friends playing WoW Classic are intentionally filtered out — only Retail (Midnight) is shown
- Try hovering over the Friends button to trigger a refresh, or relog

**Guild list shows empty**
- You may not be in a guild, or no members are currently online
- The tooltip will tell you "Not in a guild" if that's the case

**Invite not working**
- Check that you are not already in a full group (max 5 players for party, 40 for raid)
- Cross-realm invites require the `Name-Realm` format — this is handled automatically
- You cannot invite players on WoW Classic from a Retail character

**Bar disappeared**
- Type `/socialbar reset` to snap it back to the default position (top-left area of screen)

**Addon shows as incompatible**
- Check that the Interface version in `SocialBar.toc` matches the current WoW patch
- Type `/dump select(4, GetBuildInfo())` in-game to get the current interface number

---

## Compatibility

- **WoW Version:** Midnight (Retail) — Interface `120001`
- **Not compatible with:** WoW Classic, Cataclysm Classic, Anniversary Classic
- **API used:** `C_BattleNet`, `C_PartyInfo`, `C_GuildInfo`, `BNGetNumFriends`, `GetGuildRosterInfo`

---

## Changelog

### 1.2.0
- Fixed `GuildRoster()` API rename — updated to `C_GuildInfo.GuildRoster()` for Midnight compatibility
- Fixed vertical layout gear button rendering — now correctly stays as a small centered icon instead of stretching to full button width
- Removed bar color picker — bar is now fixed dark with transparency-only control, simplifying the Appearance settings
- Updated invite API to use `C_PartyInfo.InviteUnit()` for Midnight compatibility

### 1.1.0
- Tooltip now shows character level and class for friends and guild members
- Tooltip now shows AFK / DND status badges (orange for AFK, red for DND)
- Fixed class color lookup for Death Knight and Demon Hunter using `C_ClassColor.GetClassColor()` — future-proof for new classes
- Added three new toggles: Show Status, Show Level, Show Class — available in both the quick dropdown and the full settings panel
- New **Tooltip Info** section added to the Interface > AddOns settings panel

### 1.0.0
- Initial release
- Movable Friends/Guild bar with hover tooltips and right-click invite
- Battle.net friends support (filters out Classic players)
- Full customization: transparency, font size, layout
- Three settings access methods: gear button, right-click menu, Interface panel
- Slash commands: `/socialbar`, `/sbdebug`

---

## License

Free to use and modify. If you redistribute or fork this addon, a credit mention is appreciated.
