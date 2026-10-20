# Install, reload or turn off

[Back to the overview](../README.md) · [User guide](USER_GUIDE.md)

## Install

1. [Download the latest release](https://github.com/boBananaa/campaign-ledger/releases/latest).
2. In Studio, open **Plugins → Plugins Folder**. On Mac, Plugins is also in the
   menu bar at the top of the screen.
3. Copy the `.rbxmx` files you need into that folder:

   | Role | Files |
   | --- | --- |
   | DM | `CampaignLedger.rbxmx`; optionally `CampaignD20.rbxmx` |
   | Player | `CampaignTurnWatch.rbxmx` |

4. Reopen Studio once if the plugins do not appear.

Each collaborator installs their own copy. These are Studio tools for edit mode,
not interfaces for players in a running Roblox game. Installed plugins are available
across places on that computer; character stats belong to the saved place/model.

The release ZIP includes source and documentation as well as all three plugins.
For the latest committed build, download files from [dist/](../dist); the latest
published release may contain an older build.

## Reload an updated copy

Replace the installed `.rbxmx` file with the new one, then reopen Studio.

For a reload without reopening: enable **Plugin Debugging Enabled** under Studio
Settings → Studio, find the plugin in **PluginDebugService**, right-click it and
choose **Reload Plugin**. Use **Save and Reload Plugin** only when you intend to
save the in-memory plugin source; it can overwrite a newer copy on disk.

## Hide a panel or turn notice

- Click **DM Ledger** or **D20 Roller** again, or close its panel with **×**.
- Click **Turn Watch** to hide the turn notice on your screen.
- **End combat** hides the notice for everyone in the same place.

Closing a panel does not unload the plugin or disable its overhead stats viewer.

## Temporarily disable these local plugins

1. Open **Plugins → Plugins Folder**.
2. Move the relevant `CampaignLedger.rbxmx`, `CampaignD20.rbxmx` or
   `CampaignTurnWatch.rbxmx` file to a folder outside Plugins. Keep the file so
   you can restore it later.
3. Reopen Studio.

To restore it, move the file back and reopen Studio. Disabling a plugin does not
remove saved character stats. Ledger and Turn Watch both supply the hover viewer;
move both out if you want to stop that viewer completely.

## Install from source

For a source-based install, select the corresponding synced Script under
**ServerScriptService → DnD Test Scripts**, then **Plugins → Save as Local Plugin**.

See the [developer guide](DEVELOPMENT.md) for Script Sync direction and build steps.
