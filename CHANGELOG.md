# Questie-Octo Changelog

## 1.0.61
- Removed the 1.0.60 dungeon entrance quest markers from outdoor maps; normal objectives in pre-instance caves/tunnels and inside dungeons remain unchanged.
- Dungeon objectives can now use the tracker **Objectives → Show on Map** action when their dungeon/detail map is available to the client, including while inside the dungeon or when another map addon already has that map displayed.

## 1.0.60
- Added dungeon entrance markers for active dungeon quests, so outdoor maps can point to the verified entrance while the dungeon itself continues to show the real quest objectives.
- Dungeons with multiple entrances now choose the doorway that best matches the active objective instead of showing every entrance at once.
- Added entrance guidance for supported Turtle dungeons such as Crescent Grove, Hateforge Quarry, Karazhan Crypt, Gilneas City, Stormwind Vault, and Black Morass alongside the classic dungeon set.

## 1.0.59
- Fixed stray `~` characters sometimes appearing in unrelated item, player, or other GameTooltips after viewing a Questie-Octo tooltip.
- Questie-Octo's centered respawn/drop-rate separator now cleans itself up whenever the tooltip is cleared or hidden.

## 1.0.58
- Fixed **The Sal'Galaz Mines** and **Restoration** missing valid quest objectives.
- Improved **Marauders of Darrowshire** and **Deeprun Rat Roundup** map guidance so they point to the creatures players actually need to hunt or interact with.
- Restored the missing **Furen's Notes** delivery objective for **Klockmort Spannerspan**.

## 1.0.57
- Restored LevelRange-style **Friendly / Hostile / Contested** zone information, based on the player faction.
- Fixed **Westfall** not showing a level-range panel: the current client contains two AreaTable entries named Westfall, so Questie-Octo now resolves continent hovers from the exact native World Map highlight texture before falling back to zone names.
- Audited all 53 supported leveling zones against the current 1.18.1 client map data. Every supported zone has a valid WorldMapArea; the remaining outdoor map contexts are non-leveling entrance/helper/special maps and stay intentionally excluded.
- Current-client faction ownership was audited from AreaTable data, including Turtle zones: Thalassian Highlands is Alliance, Blackstone Island is Horde, and the other supported custom leveling zones are Contested.

## 1.0.56
- Added an optional **Show Zone Level Ranges** World Map feature under **Other → Interface**, directly above Dark Theme.
- Updated the integrated Turtle zone list for the current 1.18.1 client, adding **Moonwhisper Coast (50–56)** and the previously missing **Icepoint Rock (40–50)**.
- Zone hover matching now uses current client map IDs/localized area data instead of relying on English zone-name keys, including the old Northwind trailing-space edge case.
- The integration is intentionally focused on zone level ranges; LevelRange-Turtle's separate fishing/instance/raid option system is not imported.

## 1.0.55
- Rebuilt static quest-objective locations for **Windhorn Canyon, Timbermaw Hold, and Frostmane Hollow** from the current Octo client map data and current Turtle server spawns.
- Fixed the inherited `50,50` placeholder markers in those instances and restored missing quest-object locations, including all **Windhorn Relics** and the **Tablet of Kaz'gan**.
- Completed a wider instance/entrance audit. Ambiguous helper-map projection, unavailable content, and scripted encounters without ordinary server spawns were deliberately left unchanged rather than guessed.
- If you are updating directly from 1.0.53, this build also includes 1.0.54's fix for stale completed-quest history after Hardcore restarts or delete/recreate cases at level 1 with 0 XP.

## 1.0.54
- Fixed old completed-quest history carrying over when a character starts fresh at level 1 with 0 XP, including Hardcore restarts and delete/recreate cases that reuse the same character name.
- Questie-Octo now discards only the inherited completion/reset history for that unmistakably fresh character state, then rebuilds completion state from the current server character.
- Settings, tracker position, UI preferences, and other character options are preserved.

## 1.0.53
- Fixed moving party/teammate markers appearing to blink or snap on the minimap while the player was moving continuously.
- Our mistake was leaving an old Vanilla indoor/outdoor detection trick inside minimap movement rediscovery; it briefly changed the native minimap zoom and forced Blizzard's own moving markers to redraw.
- Questie-Octo now keeps normal movement updates read-only and only settles that minimap state when the minimap or zone context actually changes. The 1.0.49 performance improvements remain in place.

## 1.0.52
- Fixed tracker objectives occasionally appearing as only `: 0/10` (or similar) after logging in.
- Our mistake was trusting the first Quest Log snapshot too early, before Turtle had always finished loading objective names.
- Questie-Octo now rechecks the Quest Log during the first few seconds after login while keeping the lower-memory compiled runtime.

## 1.0.51
- Temporarily disabled **In Search of Solar Knowledge (40795)** from appearing as an available quest because current live-realm behavior does not match the bundled database.
- The quest data is retained so it can be restored easily when its live availability is confirmed.

## 1.0.50
- Added a right-click menu to quests in the tracker.
- Use **Objectives → Show on Map** to open the World Map to an unfinished objective.
- Completed quests can use **Show on Map** to locate their turn-in.
- Existing left-click and Shift+Left Click tracker controls are unchanged.
