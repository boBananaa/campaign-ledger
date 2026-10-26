# Replace a character pose

[User guide](USER_GUIDE.md) · [Install/update](INSTALLATION.md)

1. Select the registered character in the map.
2. Open **Campaign Tools → Pose Change**. It saves the registration before you
   remove anything. No DM toggle is needed. The ledger also has a Pose Change button.
3. Once the panel says **Registration saved**, delete the old model if desired.
4. Paste one replacement model. A recognized paste followed by selection of that
   new model transfers the registration automatically.
5. If it stays pending, select the whole replacement and click **Use selected model**.

The new model inherits the character ID, current resources, maximums, name and
plate settings. It does not reset to new-character defaults or refill spent resources.
The model's geometry, position and physical name are left alone. Character names
remain stable even when the replacement prefab has a different name. In Character
details, explicitly switching the name source clears that pose-name override.

If the replacement already carries another registration, it will not transfer
automatically. Click **Use selected model**, read the notice, then **Confirm
replacement**. The previous registration is archived before it is replaced;
Studio Undo can restore the edit. Selecting several models or a group containing
registered characters is rejected.

## While waiting

- The DM sees **Waiting for replacement** in Characters. Health, mana, AP,
  maximum edits and recovery operate on the saved registration during the swap.
- Closing the panel, toggling DM mode or reloading the plugin keeps the pending data.
  Open Pose Change again to continue. Save the place to preserve it across closing Studio.
- **Cancel pose change** restores the original model's registration and latest
  stats if the original still exists and its old data was not changed separately.
- After the original is deleted, cancellation is disabled. The snapshot stays
  saved until you provide a replacement; the plugin never silently discards it.
- The editor who started the transfer finishes it. Other editors can still use
  DM combat controls on its pending registration.

Pose Change does not delete, move or rename character models. The active character
ID transfers once, and only after the replacement and its stat plate are ready.
Detected conflicts or failed edits preserve the pending snapshot for recovery.
Simultaneous Team Create edits still need live validation; this is not a server lock.

Finish pending pose changes before exporting to another Roblox place. Pending
records are tied to the saved place ID and are not automatically claimed in a different world.

## Where the backup lives

The owned **ReplicatedStorage → CampaignToolsPoseChanges** folder holds pending
snapshots and archived overwritten registrations. It belongs to the saved place,
not GitHub or the original model. Avoid deleting it during a pending transfer.
Model stats retain the existing version-1 data format; ordinary registered
characters do not need conversion or re-registration.
