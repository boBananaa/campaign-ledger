# Campaign Tools

One Roblox Studio plugin for D&D sessions: hovered character stats, party/enemy turn
text, a DM ledger and a D20 roller.

**[Combined plugin](dist/CampaignTools.rbxmx)** · [Install or publish](docs/INSTALLATION.md) · [User guide](docs/USER_GUIDE.md) · [Version backups](BACKUPS.md#version-checkpoints)

## Everyone installs the same file

| Mode | Features |
| --- | --- |
| **Player — default** | Turn Watch and hover stats activate in an enabled D&D world. No Ledger or D20 menu. |
| **DM controls — opt-in** | Open Campaign Tools and enable DM controls to use Ledger, D20 and world setup. Menus start closed. |

## Get started

1. Install **CampaignTools.rbxmx** through **Plugins → Plugins Folder**, then reopen Studio.
2. Click the single **Campaign Tools** toolbar button. As DM, turn **DM controls: On**, then **Enable D&D in this world** in the session map.
3. Click **Open Ledger**, select an existing character and click **Register selected model**.
4. Players install the same plugin once. Turn text and hover stats need no extra activation.

These tools run in **Studio edit mode / Team Create**. The shared world setting
activates installed plugins; joining a world cannot install one automatically.
Stats stay with saved character models. After publishing an exported map under a
new place ID, the DM clicks **Enable D&D in this world** once in that destination.

The launcher holds the display switches and DM controls in one place. Closing it
leaves player turn text and hover stats running. All menus start closed.

When moving to the combined plugin, remove the three old standalone plugin files
from the Plugins folder to avoid running both versions. Keep them elsewhere as backups.
This updated build is prepared locally; update the existing Roblox plugin asset to distribute it.

## Help

- [Installation, migration, publishing and reload](docs/INSTALLATION.md)
- [Combat, recovery, names and display preferences](docs/USER_GUIDE.md)
- [Backups](BACKUPS.md) · [Known issues and validation](QA.md)
- Contributors: [Build guide](docs/DEVELOPMENT.md) · [Design](DESIGN.md)
