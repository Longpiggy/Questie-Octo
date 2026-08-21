# Questie-Octo current instance / entrance map audit

Audit date: 2026-08-21

## Authority used

This audit compares the actual Questie-Octo 1.0.54 source/runtime state against:

1. the current user-supplied `DBFilesClient.zip` for client `Map.dbc`, `AreaTable.dbc`, `WorldMapArea.dbc`, `AreaTrigger.dbc`, and related DBC facts;
2. the current user-supplied `BlizzardInterfaceCode` extraction for native map/UI behavior;
3. the supplied current Turtle/Tortoise server source for creature/gameobject spawns, quest templates, scripts, and AreaTrigger teleport destinations.

Questie 5/6 and pfQuest remain comparison/reference implementations only.

## Full instance-coordinate audit

The current client exposes 40 dungeon/raid server maps represented by 47 usable instance/floor `WorldMapArea` contexts in the audited set. Questie-Octo already has map/minimap dimensions for those contexts. Existing Vanilla instances and the previously supported Turtle instances were left alone where their merged coordinates were already valid and contained no generic placeholder pattern.

Three newer instance maps formed a clear common failure cluster:

| Instance | Server map | Client area | 1.0.54 creature records | Placeholder state |
| --- | ---: | ---: | ---: | --- |
| Timbermaw Hold | 819 | 5640 | 26 | 26/26 had a `50,50` map point |
| Windhorn Canyon | 820 | 5641 | 27 | 27/27 had a `50,50` map point |
| Frostmane Hollow | 822 | 5734 | 12 | 10/12 had a `50,50` map point |

The current client DBC now supplies authoritative bounds for all three:

```text
Timbermaw Hold   map 819 / area 5640 / WorldMapArea 696
  y1=-2991  y2=-4416  x1=-7195  x2=-8157

Windhorn Canyon  map 820 / area 5641 / WorldMapArea 698
  y1=-3184  y2=-4418  x1=-7163  x2=-7992

Frostmane Hollow map 822 / area 5734 / WorldMapArea 704
  y1=-3157  y2=-4168  x1=-7453  x2=-8106
```

The conversion is the same normal pfQuest-style world-to-map transformation used for healthy maps:

```text
mapX = 100 - (worldY - y1) / ((y2 - y1) / 100)
mapY = 100 - (worldX - x1) / ((x2 - x1) / 100)
```

The formula was cross-checked against already healthy current-instance data before applying corrections.

## Safe 1.0.55 corrections

Only ordinary server-backed static spawns that convert inside the client map rectangle are changed.

- Timbermaw Hold: 24 existing static creature records are rebuilt from 251 current server spawn positions. The two inherited `50,50` records for scripted encounters Peroth'arn (60686) and Ursol (62947) are deliberately not rewritten because current server data has no ordinary map-819 spawn for either entity.
- Windhorn Canyon: all 27 existing creature records are rebuilt from current map-820 server spawns. Two Rocktail Scorpid server points transform beyond the playable map rectangle and are omitted; the remaining server-backed points are retained.
- Frostmane Hollow: all 12 existing creature records are rebuilt from current map-822 server spawns.
- Windhorn Relic (2020320): all 28 current gameobject positions are restored for quests 41976/41977.
- Tablet of Kaz'gan (2020339): the current gameobject position is restored for quest 42040.

No quest template, objective identity, drop relation, faction rule, or completion rule is changed. This is a coordinate/presentation correction.

## Entrance audit

The current client `AreaTrigger.dbc` contains exact physical portal-trigger positions, and current Turtle server `areatrigger_teleport` data maps those triggers to destination maps. Together these can form an authoritative future dungeon-entrance dataset, including current custom instances.

That feature is intentionally **not** enabled in 1.0.55. A raw teleport list is not automatically equivalent to a player-facing quest entrance marker because:

- several dungeons have multiple valid entrances/exits;
- some triggers are one-way, conditioned, or used by internal transitions;
- helper `WorldMapArea` rectangles overlap outdoor zones and must not be projected as ordinary quest zones;
- server data can contain test or deliberately unavailable destinations.

When implemented later, entrance guidance should use verified physical AreaTrigger points rather than projecting the overlapping `*Entrance` WorldMapArea helper rectangles.

## Multi-context / floor identity audit

The client can reuse one area ID in distinct map contexts. A confirmed example is area 3457:

```text
WorldMapArea 657: server map 532, area 3457, Karazhan
WorldMapArea 682: server map 814, area 3457, UpperKarazhan
```

Questie-Octo still has some area-ID-centric map paths, so Lower/Upper Karazhan deserves a separate map-identity audit. Existing behavior is left untouched in 1.0.55 because no regression was demonstrated and an architectural identity change would be unrelated to the safe coordinate repair.

## Deliberately unchanged

- No dungeon entrance helper markers were added.
- No continent projection was added for instance helper maps.
- No scripted encounter position was guessed.
- No working Vanilla/custom dungeon coordinates were regenerated merely for consistency.
- No fullscreen World Map scheduler experiment was mixed into this data pass.
- No minimap movement/performance path was changed.

This keeps 1.0.55 limited to corrections supported simultaneously by current client map geometry and current server spawn data.
