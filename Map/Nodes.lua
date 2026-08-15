QuestieOcto.Nodes = QuestieOcto.Nodes or {}
local N = QuestieOcto.Nodes

N.ready=false
N.running=false
N.generation=0
N.nodes={}
N.byMap={}
N.stats={
  total=0,
  availableCreature=0,
  availableObject=0,
  itemStart=0,
  objectiveCreature=0,
  objectiveObject=0,
  objectiveItemSource=0,
  turnin=0,
  flightMaster=0,
  auctioneer=0,
  banker=0,
  mailbox=0,
  rareMob=0,
}

local function NewStats()
  return {
    total=0,
    availableCreature=0,
    availableObject=0,
    itemStart=0,
    objectiveCreature=0,
    objectiveObject=0,
    objectiveItemSource=0,
    turnin=0,
    flightMaster=0,
    auctioneer=0,
    banker=0,
    mailbox=0,
    rareMob=0,
  }
end

local function ResetStats()
  N.stats=NewStats()
end

local function CurrentStats()
  return N.buildStats or N.stats
end

local function CurrentNodes()
  return N.buildNodes or N.nodes
end

local function CurrentByMap()
  return N.buildByMap or N.byMap
end

local function ApplyIconScaleKey(node)
  return node
end

local function IsPresentationEvent(q)
  if not q or not q.eventID or not QuestieOcto.EventAvailability then return false end
  if QuestieOcto.EventAvailability.IsPresentationEventForQuest then
    return QuestieOcto.EventAvailability:IsPresentationEventForQuest(q) and true or false
  end
  return QuestieOcto.EventAvailability:IsPresentationEvent(q.eventID) and true or false
end

local function AddNode(node)
  node=ApplyIconScaleKey(node)
  CurrentStats().total=CurrentStats().total+1
  node.nodeID=CurrentStats().total
  table.insert(CurrentNodes(),node)

  local coords=node.coords
  if coords then
    -- A canonical node belongs to a map once, even if the source has dozens
    -- of spawn coordinates on that map. Clustering handles those coordinates
    -- later. 0.1.5 incorrectly inserted the same node once per coordinate,
    -- causing hundreds of duplicate render work items.
    local seenMaps={}
    for _,coord in pairs(coords) do
      if type(coord)=="table" and tonumber(coord[3]) then
        local mapID=tonumber(coord[3])
        if not seenMaps[mapID] then
          seenMaps[mapID]=true
          local byMap=CurrentByMap()
          byMap[mapID]=byMap[mapID] or {}
          table.insert(byMap[mapID],node)
        end
      end
    end
  end
end

local function ApplyObjectiveState(node,state)
  if state then
    node.objectiveIndex=state.objectiveIndex
    node.objectiveText=state.objectiveText
    node.objectiveType=state.objectiveType
    node.current=state.current
    node.required=state.required
    node.objectiveComplete=state.complete and true or false
  end
  return node
end

local function AddCreatureNode(questID,role,creatureID,itemID,chance,objectiveState,vendor)
  local q=QuestieOcto.QuestModel:Get(questID)
  local node={
    questID=questID,role=role,event=IsPresentationEvent(q),eventID=q and q.eventID or nil,pvp=q and q.pvp or false,repeatable=q and q.repeatable or false,sourceKind="creature",sourceID=creatureID,
    sourceName=QuestieOcto.DatabaseAPI:GetCreatureName(creatureID),
    sourceRank=QuestieOcto.DatabaseAPI:GetCreatureRank(creatureID),
    respawnSeconds=QuestieOcto.DatabaseAPI:GetCreatureRespawnSeconds(creatureID),
    itemID=itemID,itemName=itemID and QuestieOcto.DatabaseAPI:GetItemName(itemID) or nil,
    chance=chance,vendor=vendor and true or false,coords=QuestieOcto.DatabaseAPI:GetCreatureCoords(creatureID)
  }
  AddNode(ApplyObjectiveState(node,objectiveState))
end

local function AddObjectNode(questID,role,objectID,itemID,chance,objectiveState)
  local q=QuestieOcto.QuestModel:Get(questID)
  local node={
    questID=questID,role=role,event=IsPresentationEvent(q),eventID=q and q.eventID or nil,pvp=q and q.pvp or false,repeatable=q and q.repeatable or false,sourceKind="gameObject",sourceID=objectID,
    sourceName=QuestieOcto.DatabaseAPI:GetObjectName(objectID),
    itemID=itemID,itemName=itemID and QuestieOcto.DatabaseAPI:GetItemName(itemID) or nil,
    chance=chance,coords=QuestieOcto.DatabaseAPI:GetObjectCoords(objectID)
  }
  AddNode(ApplyObjectiveState(node,objectiveState))
end

local function BuildAvailableQuestNodes(questID)
  local q=QuestieOcto.QuestModel:Get(questID)
  if not q then return end

  if q.starts.creature then
    for _,id in pairs(q.starts.creature) do
      AddCreatureNode(questID,"available",id,nil,nil)
      CurrentStats().availableCreature=CurrentStats().availableCreature+1
    end
  end

  if q.starts.gameObject then
    for _,id in pairs(q.starts.gameObject) do
      AddObjectNode(questID,"available",id,nil,nil)
      CurrentStats().availableObject=CurrentStats().availableObject+1
    end
  end
end

local function BuildItemStartQuestNodes(questID,resolved,availableSet)
  -- ItemStarts is a derived cache; the published AvailableQuests snapshot is
  -- the authoritative visibility gate. Never let an older item-start cache
  -- bypass completion/event/repeatable filtering during an async refresh.
  if not availableSet[questID] or not resolved then return end

  for _,item in pairs(resolved.items or {}) do
    for _,src in pairs(item.creatureSources or {}) do
      AddCreatureNode(questID,"itemStart",src.id,item.itemID,src.chance,nil,src.vendor)
      CurrentStats().itemStart=CurrentStats().itemStart+1
    end

    for _,src in pairs(item.objectSources or {}) do
      AddObjectNode(questID,"itemStart",src.id,item.itemID,src.chance)
      CurrentStats().itemStart=CurrentStats().itemStart+1
    end
  end
end


local function PlayerFactionCode()
  local playerFaction=UnitFactionGroup and UnitFactionGroup("player") or nil
  if playerFaction=="Alliance" then return "A" end
  if playerFaction=="Horde" then return "H" end
  return nil
end

local function FactionAllows(allowed,factionCode)
  return type(allowed)=="string" and factionCode and string.find(allowed,factionCode,1,true) and true or false
end

local function TrackingMeta(metaKey)
  return QuestieOcto.DatabaseAPI and QuestieOcto.DatabaseAPI.GetTrackingMeta and QuestieOcto.DatabaseAPI:GetTrackingMeta(metaKey) or nil
end

local function BuildServiceCreatureNodes(metaKey,role,statKey)
  local list=TrackingMeta(metaKey)
  if not list then return end
  local factionCode=PlayerFactionCode()
  if not factionCode then return end

  for creatureID,allowed in pairs(list) do
    creatureID=tonumber(creatureID)
    if creatureID and creatureID>0 and FactionAllows(allowed,factionCode) then
      local coords=QuestieOcto.DatabaseAPI:GetCreatureCoords(creatureID)
      if coords and next(coords) then
        AddNode({
          questID=0,
          role=role,
          sourceKind="creature",
          sourceID=creatureID,
          sourceName=QuestieOcto.DatabaseAPI:GetCreatureName(creatureID),
          coords=coords,
          serviceFaction=allowed
        })
        CurrentStats()[statKey]=(CurrentStats()[statKey] or 0)+1
      end
    end
  end
end

local function BuildMailboxNodes()
  local list=TrackingMeta("mailbox")
  if not list then return end
  local factionCode=PlayerFactionCode()
  if not factionCode then return end

  for signedObjectID,allowed in pairs(list) do
    local objectID=math.abs(tonumber(signedObjectID) or 0)
    if objectID>0 and FactionAllows(allowed,factionCode) then
      local coords=QuestieOcto.DatabaseAPI:GetObjectCoords(objectID)
      if coords and next(coords) then
        AddNode({
          questID=0,
          role="mailbox",
          sourceKind="gameObject",
          sourceID=objectID,
          sourceName=QuestieOcto.DatabaseAPI:GetObjectName(objectID),
          coords=coords,
          serviceFaction=allowed
        })
        CurrentStats().mailbox=CurrentStats().mailbox+1
      end
    end
  end
end

local function BuildRareMobNodes()
  local list=TrackingMeta("rares")
  if not list then return end

  for creatureID,rareLevel in pairs(list) do
    creatureID=tonumber(creatureID)
    if creatureID and creatureID>0 then
      local coords=QuestieOcto.DatabaseAPI:GetCreatureCoords(creatureID)
      if coords and next(coords) then
        AddNode({
          questID=0,
          role="rareMob",
          sourceKind="creature",
          sourceID=creatureID,
          sourceName=QuestieOcto.DatabaseAPI:GetCreatureName(creatureID),
          sourceRank=QuestieOcto.DatabaseAPI:GetCreatureRank(creatureID),
          respawnSeconds=QuestieOcto.DatabaseAPI:GetCreatureRespawnSeconds(creatureID),
          rareLevel=tonumber(rareLevel),
          coords=coords
        })
        CurrentStats().rareMob=CurrentStats().rareMob+1
      end
    end
  end
end

local function BuildPermanentMapNodes()
  -- Questie 3.3.5/7/8 model Auctioneer, Banker and Flight Master as
  -- townsfolk map categories. pfQuest supplies the Vanilla/Turtle-compatible
  -- faction lists, mailbox object IDs, rare-mob list and spawn coordinates.
  BuildServiceCreatureNodes("flight","flightMaster","flightMaster")
  BuildServiceCreatureNodes("auctioneer","auctioneer","auctioneer")
  BuildServiceCreatureNodes("banker","banker","banker")
  BuildMailboxNodes()
  BuildRareMobNodes()
end

local function BuildActiveNodes()
  for questID,state in pairs(QuestieOcto.QuestLog.active) do
    local q=QuestieOcto.QuestModel:Get(questID)
    if q then
      if state.complete then
        for _,id in pairs(q.finishes.creature or {}) do
          AddCreatureNode(questID,"turnin",id,nil,nil)
          CurrentStats().turnin=CurrentStats().turnin+1
        end
        for _,id in pairs(q.finishes.gameObject or {}) do
          AddObjectNode(questID,"turnin",id,nil,nil)
          CurrentStats().turnin=CurrentStats().turnin+1
        end
      else
        local resolved=QuestieOcto.Objectives.byQuest[questID]
        if resolved then
          for _,src in pairs(resolved.creature) do
            if not src.complete then
              AddCreatureNode(questID,"objectiveCreature",src.id,src.itemID,nil,src)
              CurrentStats().objectiveCreature=CurrentStats().objectiveCreature+1
            end
          end
          for _,src in pairs(resolved.gameObject) do
            if not src.complete then
              AddObjectNode(questID,"objectiveObject",src.id,src.itemID,nil,src)
              CurrentStats().objectiveObject=CurrentStats().objectiveObject+1
            end
          end
          for _,item in pairs(resolved.item) do
            if not item.complete then
              for _,src in pairs(item.sources) do
                if src.kind=="creature" then
                  AddCreatureNode(questID,"objectiveItemSource",src.id,item.itemID,src.chance,item,src.vendor)
                else
                  AddObjectNode(questID,"objectiveItemSource",src.id,item.itemID,src.chance,item)
                end
                CurrentStats().objectiveItemSource=CurrentStats().objectiveItemSource+1
              end
            end
          end
        end
      end
    end
  end
end

function N:Rebuild()
  if not QuestieOcto.AvailableQuests.ready
     or not QuestieOcto.Objectives.ready
     or not QuestieOcto.ItemStarts.ready
     or not QuestieOcto.DatabaseAPI:IsReady()
     or not QuestieOcto.QuestLog.snapshot then
    self.ready=false
    return
  end

  self.generation=self.generation+1
  local generation=self.generation

  -- Build into private buffers. The published node set stays live until the
  -- replacement is complete, preventing map/minimap disappearance during an
  -- asynchronous rebuild.
  local hadReady=self.ready and true or false
  if not hadReady then self.ready=false end
  self.running=true
  self.buildNodes={}
  self.buildByMap={}
  self.buildStats=NewStats()

  -- Capture the input snapshots. A newer publication triggers another rebuild
  -- and increments generation, while this build can finish/cancel safely
  -- without walking a table that changes underneath next().
  local availableSet=QuestieOcto.AvailableQuests.available or {}
  local itemStartSet=QuestieOcto.ItemStarts.byQuest or {}
  local availableCursor=nil
  local itemStartCursor=nil

  local function Publish()
    if generation~=N.generation then return end
    N.nodes=N.buildNodes or {}
    N.byMap=N.buildByMap or {}
    N.stats=N.buildStats or N.stats
    N.buildNodes=nil
    N.buildByMap=nil
    N.buildStats=nil
    N.running=false
    N.ready=true
    QuestieOcto:SendMessage("NODES_READY")
  end

  local function SortMaps()
    if generation~=N.generation then return end
    local mapIDs={}
    for mapID in pairs(N.buildByMap or {}) do table.insert(mapIDs,mapID) end
    table.sort(mapIDs)
    local pos=1

    local function SortStep()
      if generation~=N.generation then return end
      local count=0
      while pos<=table.getn(mapIDs) and count<4 do
        local mapNodes=N.buildByMap[mapIDs[pos]]
        pos=pos+1
        if mapNodes then
          table.sort(mapNodes,function(a,b)
            if a.questID~=b.questID then return a.questID<b.questID end
            if a.role~=b.role then return tostring(a.role)<tostring(b.role) end
            if a.sourceKind~=b.sourceKind then return tostring(a.sourceKind)<tostring(b.sourceKind) end
            return tonumber(a.sourceID or 0)<tonumber(b.sourceID or 0)
          end)
        end
        count=count+1
      end
      if pos<=table.getn(mapIDs) then
        QuestieOcto.Scheduler:Enqueue(SortStep,"nodes-sort")
      else
        Publish()
      end
    end

    QuestieOcto.Scheduler:Enqueue(SortStep,"nodes-sort")
  end

  local permanentBuilders={
    function() BuildServiceCreatureNodes("flight","flightMaster","flightMaster") end,
    function() BuildServiceCreatureNodes("auctioneer","auctioneer","auctioneer") end,
    function() BuildServiceCreatureNodes("banker","banker","banker") end,
    BuildMailboxNodes,
    BuildRareMobNodes,
  }

  local function PermanentStep(index)
    if generation~=N.generation then return end
    local fn=permanentBuilders[index]
    if not fn then SortMaps(); return end
    fn()
    QuestieOcto.Scheduler:Enqueue(function() PermanentStep(index+1) end,"nodes-permanent")
  end

  local function ItemStartStep()
    if generation~=N.generation then return end
    local count=0
    while count<24 do
      local questID,resolved=next(itemStartSet,itemStartCursor)
      if questID==nil then
        PermanentStep(1)
        return
      end
      itemStartCursor=questID
      BuildItemStartQuestNodes(questID,resolved,availableSet)
      count=count+1
    end
    QuestieOcto.Scheduler:Enqueue(ItemStartStep,"nodes-itemstart")
  end

  local function AvailableStep()
    if generation~=N.generation then return end
    local count=0
    while count<32 do
      local questID=next(availableSet,availableCursor)
      if questID==nil then
        QuestieOcto.Scheduler:Enqueue(ItemStartStep,"nodes-itemstart")
        return
      end
      availableCursor=questID
      BuildAvailableQuestNodes(questID)
      count=count+1
    end
    QuestieOcto.Scheduler:Enqueue(AvailableStep,"nodes-available")
  end

  QuestieOcto.Scheduler:Enqueue(function()
    if generation~=N.generation then return end
    BuildActiveNodes()
    QuestieOcto.Scheduler:Enqueue(AvailableStep,"nodes-available")
  end,"nodes-active")
end

function N:GetMapNodes(mapID)
  return self.byMap[tonumber(mapID)] or {}
end

function N:OnInputReady()
  self:Rebuild()
end

QuestieOcto:RegisterMessage("OBJECTIVES_READY",N,"OnInputReady")
QuestieOcto:RegisterMessage("ITEM_STARTS_READY",N,"OnInputReady")
QuestieOcto:RegisterMessage("AVAILABLE_QUESTS_READY",N,"OnInputReady")
