# Install or publish Campaign Tools

[Overview](../README.md) · [User guide](USER_GUIDE.md)

## One file for everyone

Use **[CampaignTools.rbxmx](../dist/CampaignTools.rbxmx)**. Ledger, D20 and Turn Watch
are in one self-contained Script, so they publish as one Roblox plugin asset.
The optional [CampaignTools.zip](../dist/CampaignTools.zip) includes that same file,
source, documentation and tests; it is not the file to upload as a plugin.

1. Open Studio → **Plugins → Plugins Folder**.
2. Copy `CampaignTools.rbxmx` into that folder.
3. Reopen Studio once after saving your work.

Player mode is the default. Turn Watch and hovered character stats activate in an
enabled D&D world; the turn text stays hidden outside combat. Players do not need
to enable the viewer themselves. The single **Campaign Tools** toolbar button opens
a launcher containing all settings. A DM turns **DM controls: On**, then clicks
**Enable D&D in this world** once in the saved session map. **Open Ledger** and
**Open D20** launch the DM windows. **Open Characters** opens the independent
resizable character list. **Pose Change** is available to players as well as DMs.
The launcher and all windows start closed;
closing the launcher leaves the player viewer running.
The local DM choice is remembered. It is a convenience setting, not an access restriction.

Each person installs the plugin once. Team Create shares the world flag and authored
stats, not plugin installations. Every party member should use the same current build.

## Migrate from the three standalone plugins

Move these files out of the local Plugins folder, keeping them as backups:

- `CampaignLedger.rbxmx`
- `CampaignD20.rbxmx`
- `CampaignTurnWatch.rbxmx`

Install `CampaignTools.rbxmx`, then reopen Studio once when ready. Do not run the
combined and standalone copies together. Existing character IDs, resources, maxima,
plates and the enabled-world flag are compatible; no re-registration is needed.
The combined plugin starts in player mode on its first installation, so the DM
enables **DM controls** locally. Hover preferences can be adjusted independently.

## Publish one Roblox plugin

To publish without replacing the local plugins yet:

1. Import `CampaignTools.rbxmx` into **ServerStorage** using **Insert → Import Roblox Model**.
2. Select the imported **CampaignTools Script**.
3. Choose **Plugins → Publish as Plugin**, then provide its name and description.
4. Configure its Creator Store distribution if other people should install it.

Alternatively, after installing the combined plugin locally, select the Script
inside **PluginDebugService → user_CampaignTools.rbxmx → CampaignTools** and publish it.
Use the combined Script, not an older copy in the Script Sync folder. The Script
returns immediately outside plugin context; importing it does not install or start it.

Update the same Roblox asset for future releases. Creator Store publishing and
account/distribution requirements are separate from this local build. Nothing has
been uploaded automatically. See [Roblox's publishing instructions](https://create.roblox.com/docs/studio/plugins#upload-plugins).

When installing the Roblox-published version, move the manually installed
`CampaignTools.rbxmx` out of Plugins so only one copy runs.

## Reload, hide or disable

After replacing a local file, reopen Studio, or right-click the installed plugin
under **PluginDebugService** and choose **Reload Plugin**. Do not use **Save and
Reload Plugin** with stale in-memory source; it can overwrite the new disk copy.

- **DM controls off** removes DM content and closes Characters, Ledger and D20; player displays and Pose Change stay available.
- In the launcher, **Turn text** hides/shows the local turn notice; **End combat** in Ledger hides it for everyone.
- **Hover-only** in the launcher changes the local stats display preference.
- **Stat plates: Off** hides all plugin overhead displays locally, even on hover. It preserves character data and the hover-only preference.
- **Disable D&D in this world** deactivates campaign sessions for installed collaborators, preserving stats. The launcher stays available for re-enabling.
- To disable the entire combined plugin locally, move its file outside Plugins and reopen Studio.

World isolation and export behavior are explained in the [user guide](USER_GUIDE.md#world-isolation-and-exporting).
