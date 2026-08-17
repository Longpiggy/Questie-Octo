# Questie-Octo

A lightweight quest helper for Turtle WoW / OctoWoW, focused on clear quest, objective, map, minimap, and tracker information.

## Requirements

**ClassicAPI.dll is required and is not included with Questie-Octo.**

[Download the latest ClassicAPI release here.](https://github.com/brues-code/ClassicAPI/releases/latest)

## Installation

1. Download the latest Questie-Octo release.
2. Extract the `Questie-Octo` folder into your WoW `Interface/AddOns` folder.
3. Make sure the addon path ends like this:

   `Interface/AddOns/Questie-Octo/Questie-Octo.toc`

4. Install ClassicAPI separately using its release instructions.
5. Restart the game if it was already running.

## First Steps

### Open Questie-Octo settings

Type this in chat:

`/qo`

This is the easiest way to open the settings and works regardless of which UI addon you use.

You can also use:

`/questieocto`

On supported game menus, including pfUI and DragonflightUI-Reforged, you may also see a **Questie Options** button in the Escape menu.

### Unlock and move the quest tracker

1. Open the settings with `/qo`.
2. Select the **Tracker** tab.
3. Uncheck **Lock Tracker**.
4. Left-click and drag the **top/header area of the tracker** to move it.
5. Re-enable **Lock Tracker** when you are happy with its position.

The tracker is transparent by default, so the draggable header can be easy to miss.

If the tracker gets moved somewhere inconvenient, use **Tracker → Reset Tracker Position**.

### Track quests manually

Questie-Octo can automatically track accepted quests.

To manually track or untrack a quest, use **Shift + Left Click** on the quest in the Quest Log.

## Useful Commands

- `/qo` — open or close Questie-Octo settings
- `/qo quests` — open the quest browser
- `/qo help` — show available Questie-Octo commands

## Notes

Questie-Octo requires ClassicAPI as an external dependency. `ClassicAPI.dll` is intentionally not bundled with the addon.
