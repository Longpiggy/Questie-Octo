# Questie-Octo Changelog

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
