-- GENERATED RUNTIME DATABASE FINALIZER.
local L=QuestieOcto.RuntimeLocales or {}
for _,name in pairs({"items","quests","objects","units","zones","professions"}) do
  if pfDB[name] then
    pfDB[name].enUS=L[name] or {}
    pfDB[name].loc=pfDB[name].enUS
  end
end
QuestieOcto.RuntimeLocales=nil
pfDB["octo-enrichment-complete"]=true
