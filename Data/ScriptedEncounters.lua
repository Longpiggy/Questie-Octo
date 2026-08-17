-- Sparse presentation-only data for scripted dungeon encounters that do not
-- exist as ordinary creature spawns in the server creature table.
--
-- IMPORTANT: this table must never be treated as quest/gameplay truth. It is
-- only a fallback for map/minimap guidance when the canonical creature record
-- has no usable coordinates. If future server-derived creature coordinates
-- exist, those normal coordinates win automatically.
--
-- Wailing Caverns / Mutanus:
-- Current Turtle server script `wailing_caverns.cpp` summons creature 3654 at
-- world position (142.7, 254.0, -102.2) near the end of the Naralex escort.
-- Converting that world position through the current Wailing Caverns map-718
-- transform (verified against Cobrahn, Pythas, Serpentis, Disciple, Naralex,
-- Vangros and Zandara) gives approximately 45.8, 9.2.
--
-- The same server instance script requires Anacondra, Cobrahn, Pythas and
-- Serpentis to be DONE before Disciple of Naralex (3678) receives the special
-- gossip that starts the escort. Atlas-CFM was used only as a presentation
-- cross-check for the current dungeon layout/quest notes; no Atlas code or
-- quest-template data is copied here.
QuestieOcto.ScriptedEncounterData = QuestieOcto.ScriptedEncounterData or {
  [3654]={
    coords={{45.8,9.2,718}},
    note="Scripted encounter: Mutanus appears near the end of the Naralex event. Defeat the four Fanglords, then speak to the Disciple of Naralex near the instance entrance to begin the escort.",
  },
}
