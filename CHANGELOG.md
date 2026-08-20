# Questie-Octo Changelog

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
