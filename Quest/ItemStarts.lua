QuestieOcto.ItemStarts = QuestieOcto.ItemStarts or {}
local I = QuestieOcto.ItemStarts

I.byQuest={}
I.ready=false
I.running=false
I.generation=0
I.stats={ quests=0, starterItems=0, creatureSources=0, objectSources=0 }

local MIN_DROP_CHANCE=1

local function ResetStats()
  I.stats={ quests=0, starterItems=0, creatureSources=0, objectSources=0 }
end

local function AddCreature(entry,seen,creatureID,chance,vendor)
  local key=tostring(creatureID)
  if seen[key] then return end
  seen[key]=true
  table.insert(entry.creatureSources,{
    kind="creature",id=creatureID,chance=chance,vendor=vendor and true or false,
    rank=QuestieOcto.DatabaseAPI:GetCreatureRank(creatureID),
    faction=QuestieOcto.DatabaseAPI:GetCreatureFaction(creatureID)
  })
  I.stats.creatureSources=I.stats.creatureSources+1
end

local function AddObject(entry,seen,objectID,chance)
  local key=tostring(objectID)
  if seen[key] then return end
  seen[key]=true
  table.insert(entry.objectSources,{kind="gameObject",id=objectID,chance=chance})
  I.stats.objectSources=I.stats.objectSources+1
end

local function ResolveSources(entry,itemID)
  local sources=QuestieOcto.DatabaseAPI:GetItemSources(itemID)
  local seenCreature={}
  local seenObject={}

  if sources and sources.Creature then
    for creatureID,chance in pairs(sources.Creature) do
      chance=tonumber(chance) or 0
      if chance>=MIN_DROP_CHANCE then AddCreature(entry,seenCreature,creatureID,chance,false) end
    end
  end

  if sources and sources.GameObject then
    for objectID,chance in pairs(sources.GameObject) do
      chance=tonumber(chance) or 0
      if chance>=MIN_DROP_CHANCE and chance>0 then AddObject(entry,seenObject,objectID,chance) end
    end
  end

  if sources and sources.Reference then
    for refID,chance in pairs(sources.Reference) do
      chance=tonumber(chance) or 0
      if chance>=MIN_DROP_CHANCE then
        local ref=QuestieOcto.DatabaseAPI:GetReferenceLootRaw(refID)
        if ref and ref["U"] then
          for creatureID in pairs(ref["U"]) do AddCreature(entry,seenCreature,creatureID,chance,false) end
        end
        if ref and ref["O"] then
          for objectID in pairs(ref["O"]) do AddObject(entry,seenObject,objectID,chance) end
        end
      end
    end
  end

  if sources and sources.Vendor then
    for creatureID in pairs(sources.Vendor) do AddCreature(entry,seenCreature,creatureID,nil,true) end
  end
end

function I:ResolveQuest(questID)
  local q=QuestieOcto.QuestModel:Get(questID)
  if not q or not q.starts.item then return nil end

  local result={ questID=questID, items={} }

  for _,itemID in pairs(q.starts.item) do
    local entry={
      itemID=itemID,
      name=QuestieOcto.DatabaseAPI:GetItemName(itemID),
      creatureSources={},
      objectSources={}
    }

    ResolveSources(entry,itemID)
    table.insert(result.items,entry)
    self.stats.starterItems=self.stats.starterItems+1
  end

  return result
end

function I:Rebuild()
  if not QuestieOcto.AvailableQuests.ready then return end

  self.generation=self.generation+1
  local generation=self.generation
  self.byQuest={}
  self.ready=false
  self.running=true
  ResetStats()

  local ids={}
  for questID in pairs(QuestieOcto.AvailableQuests.available) do
    local q=QuestieOcto.QuestModel:Get(questID)
    if q and q.starts.item then table.insert(ids,questID) end
  end
  table.sort(ids)

  local pos=1
  local function step()
    if generation~=I.generation then return end
    local count=0
    while pos<=table.getn(ids) and count<64 do
      local questID=ids[pos]
      pos=pos+1
      local resolved=I:ResolveQuest(questID)
      if resolved then I.byQuest[questID]=resolved; I.stats.quests=I.stats.quests+1 end
      count=count+1
    end
    if pos<=table.getn(ids) then
      QuestieOcto.Scheduler:Enqueue(step,"itemstart-resolve")
      return
    end
    I.running=false
    I.ready=true
    QuestieOcto:SendMessage("ITEM_STARTS_READY")
  end
  QuestieOcto.Scheduler:Enqueue(step,"itemstart-resolve")
end

function I:OnAvailableReady()
  self:Rebuild()
end

QuestieOcto:RegisterMessage("AVAILABLE_QUESTS_READY",I,"OnAvailableReady")
