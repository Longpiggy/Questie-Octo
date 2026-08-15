QuestieOcto.PreparedMap = QuestieOcto.PreparedMap or {}
local P = QuestieOcto.PreparedMap

P.cache={}
P.readyMaps={}
P.cacheRevision={}
P.stateRevision=1
P.running=false
P.generation=0
P.stats={preparedMaps=0,descriptors=0,currentMap=nil,currentReady=false,stateRevision=1,revisionBumps=0}

local function ExactRole(role)
  return role=="available" or role=="turnin" or role=="flightMaster"
      or role=="auctioneer" or role=="banker" or role=="mailbox" or role=="rareMob"
end

local function DescriptorKey(node,x,y)
  -- Questie 5/6/3.3.5 places available and complete frames on the same source
  -- coordinate, with the complete texture one draw level above available.
  -- pfQuest likewise resolves coincident quest nodes by visual layer. Collapse
  -- those two semantic entries into one prepared pin so the tooltip retains
  -- both quests while Questie-Octo's turn-in priority selects the complete icon.
  if node.role=="available" or node.role=="turnin" then
    return "exact:quest-source:"..tostring(node.sourceKind)..":"..tostring(node.sourceID)..":"..
      string.format("%.2f",x)..":"..string.format("%.2f",y)
  end

  return "exact:"..tostring(node.questID)..":"..tostring(node.role)..":"..
    tostring(node.sourceKind)..":"..tostring(node.sourceID)..":"..
    string.format("%.2f",x)..":"..string.format("%.2f",y)
end

local function AreaKey(node,area)
  return "area:"..tostring(node.sourceKind)..":"..tostring(node.sourceID)..":"..
    tostring(area.key)
end

local function FullPointKey(prefix,node,x,y)
  return tostring(prefix)..":"..tostring(node.questID)..":"..tostring(node.role)..":"..
    tostring(node.sourceKind)..":"..tostring(node.sourceID)..":"..
    tostring(node.itemID or 0)..":"..string.format("%.2f",x)..":"..string.format("%.2f",y)
end

local function AddNormal(plan,node,x,y,clusterCount,kind,key)
  table.insert(plan,{
    type="node",
    node=node,
    x=x,
    y=y,
    clusterCount=clusterCount or 1,
    kind=kind,
    key=key
  })
end

function P:BuildPlanFromNodes(mapID,nodes)
  mapID=tonumber(mapID)
  if not mapID then return nil end

  local plan={}

  for _,node in pairs(nodes or {}) do
    if node.role~="itemStart" then
      if ExactRole(node.role) then
        local points=QuestieOcto.Clustering:PointsForNodeOnMap(node,mapID)

        for _,point in pairs(points) do
          AddNormal(
            plan,node,point.x,point.y,1,"exact",
            DescriptorKey(node,point.x,point.y)
          )
        end
      else
        local points=QuestieOcto.Clustering:PointsForNodeOnMap(node,mapID)

        if QuestieOcto.MinimapSettings:Get("objectiveNodeDensity")=="full" then
          for _,point in pairs(points) do
            AddNormal(
              plan,node,point.x,point.y,1,"objectiveFull",
              FullPointKey("objective-full",node,point.x,point.y)
            )
          end
        else
          local areas=QuestieOcto.Clustering:BuildAreas(
            points,QuestieOcto.Clustering.objectiveRadius
          )

          for _,area in pairs(areas) do
            AddNormal(plan,node,area.x,area.y,area.n,"objective",AreaKey(node,area))
          end
        end
      end
    end
  end

  if QuestieOcto.MinimapSettings:Get("itemStartDensity")=="full" then
    for _,node in pairs(nodes or {}) do
      if node.role=="itemStart" then
        local points=QuestieOcto.Clustering:PointsForNodeOnMap(node,mapID)
        for _,point in pairs(points) do
          AddNormal(
            plan,node,point.x,point.y,1,"itemStartFull",
            FullPointKey("itemstart-full",node,point.x,point.y)
          )
        end
      end
    end
  else
    local itemAreas=QuestieOcto.ItemStartAreas:BuildForMap(nodes or {},mapID)
    for _,area in pairs(itemAreas) do
      table.insert(plan,{
        type="itemStartArea",
        area=area,
        key="itemarea:"..tostring(area.key)
      })
    end
  end

  table.sort(plan,function(a,b)
    return tostring(a.key)<tostring(b.key)
  end)

  return plan
end

function P:SetPreparedMap(mapID,plan)
  mapID=tonumber(mapID)
  if not mapID or not plan then return nil end

  local wasReady=self.readyMaps[mapID] and true or false
  local old=self.cache[mapID]
  local oldCount=old and table.getn(old) or 0

  self.cache[mapID]=plan
  self.readyMaps[mapID]=true
  self.cacheRevision[mapID]=self.stateRevision

  if not wasReady then
    self.stats.preparedMaps=self.stats.preparedMaps+1
  end

  self.stats.descriptors=self.stats.descriptors-oldCount+table.getn(plan)

  if tonumber(self.stats.currentMap)==mapID then
    self.stats.currentReady=true
  end

  QuestieOcto:SendMessage("PREPARED_MAP_READY",mapID)
  return plan
end

function P:BuildMap(mapID)
  mapID=tonumber(mapID)
  if not mapID or not QuestieOcto.Nodes.ready then return nil end

  local plan=self:BuildPlanFromNodes(mapID,QuestieOcto.Nodes:GetMapNodes(mapID))
  return self:SetPreparedMap(mapID,plan)
end

function P:Get(mapID)
  mapID=tonumber(mapID)
  if not mapID then return nil end
  if self.cacheRevision[mapID]~=self.stateRevision then return nil end
  return self.cache[mapID]
end

function P:IsReady(mapID)
  mapID=tonumber(mapID)
  return mapID
     and self.readyMaps[mapID]
     and self.cacheRevision[mapID]==self.stateRevision
     and true or false
end

local function DescriptorQuestID(desc)
  if not desc then return nil end
  if desc.type=="node" and desc.node then return tonumber(desc.node.questID) end
  if desc.type=="itemStartArea" and desc.area then return tonumber(desc.area.questID) end
  return nil
end

function P:RemoveQuest(questID)
  questID=tonumber(questID)
  if not questID then return 0 end

  -- Questie has no separate prepared-descriptor cache: UnloadQuestFrames()
  -- removes the quest from both map presentations immediately. Keep our
  -- approved cache optimization semantically equivalent by purging the quest
  -- from every cached map before either presentation can consume it again.
  self.stateRevision=self.stateRevision+1
  self.stats.stateRevision=self.stateRevision
  self.stats.revisionBumps=(self.stats.revisionBumps or 0)+1
  self.stats.currentReady=false
  self.lastRevisionReason="quest-remove"

  local removed=0
  for mapID,plan in pairs(self.cache) do
    local filtered={}
    for _,desc in pairs(plan or {}) do
      if DescriptorQuestID(desc)==questID then
        removed=removed+1
      else
        table.insert(filtered,desc)
      end
    end

    self.cache[mapID]=filtered
    if self.readyMaps[mapID] then
      self.cacheRevision[mapID]=self.stateRevision
    end
  end

  self.stats.descriptors=math.max(0,(self.stats.descriptors or 0)-removed)
  if self.stats.currentMap and self.readyMaps[self.stats.currentMap] then
    self.stats.currentReady=true
  end

  return removed
end

function P:BumpStateRevision(reason)
  self.stateRevision=self.stateRevision+1
  self.stats.stateRevision=self.stateRevision
  self.stats.revisionBumps=(self.stats.revisionBumps or 0)+1
  self.stats.currentReady=false
  self.lastRevisionReason=reason
end

function P:Invalidate()
  self.generation=self.generation+1
  self.cache={}
  self.readyMaps={}
  self.cacheRevision={}
  self.running=false
  self.stats.preparedMaps=0
  self.stats.descriptors=0
  self.stats.currentReady=false
end

function P:PrepareAll()
  if not QuestieOcto.Nodes.ready then return end

  -- Transactional map-plan rebuild. Keep every currently published plan alive
  -- until that specific map's replacement is ready; density/filter toggles
  -- must never invalidate the live cache first and make pins blink off/on.
  self.generation=self.generation+1
  local generation=self.generation
  self.running=true

  local current=QuestieOcto.API:GetBestMapForPlayer()
  self.stats.currentMap=current

  -- Density changes are shared by the minimap and World Map, but the two can
  -- be looking at different maps. The minimap always follows `current`, while
  -- the World Map can stay open on any selected zone. Rebuild both visible
  -- contexts first so Clustered <-> Full Nodes changes are immediate on each
  -- presentation instead of waiting for the displayed World Map zone to be
  -- reached by the background PrepareAll pass.
  local displayed=nil
  if WorldMapFrame and WorldMapFrame:IsVisible() and QuestieOcto.Map and
     QuestieOcto.Map.GetDisplayedMapID then
    displayed=QuestieOcto.Map:GetDisplayedMapID()
  end

  local mapSet={}
  for mapID in pairs(QuestieOcto.Nodes.byMap or {}) do mapSet[tonumber(mapID)]=true end
  -- Include formerly populated maps so a rebuild that legitimately removes
  -- every node from a map publishes an empty plan rather than leaving stale pins.
  for mapID in pairs(self.readyMaps or {}) do mapSet[tonumber(mapID)]=true end

  local ids={}
  for mapID in pairs(mapSet) do if mapID then table.insert(ids,mapID) end end
  table.sort(ids)

  local function publishMap(mapID)
    if generation~=P.generation then return false end
    local plan=P:BuildPlanFromNodes(mapID,QuestieOcto.Nodes:GetMapNodes(mapID)) or {}
    P:SetPreparedMap(mapID,plan)
    return true
  end

  -- Publish the open World Map zone first, then the player's current zone for
  -- the minimap. Either may be the same map. SetPreparedMap broadcasts
  -- PREPARED_MAP_READY, so both renderers immediately consume the replacement.
  if displayed and mapSet[tonumber(displayed)] then
    publishMap(tonumber(displayed))
  end
  if current and tonumber(current)~=tonumber(displayed) and mapSet[tonumber(current)] then
    publishMap(tonumber(current))
  end

  local pos=1
  local function step()
    if generation~=P.generation then return end

    local requested=QuestieOcto.ZoneBootstrap and QuestieOcto.ZoneBootstrap.requestedMapID
    if requested and not P.readyMaps[tonumber(requested)] and QuestieOcto.ZoneBootstrap.running then
      QuestieOcto.Scheduler:Enqueue(step,"prepare-maps-yield")
      return
    end

    local count=0
    while pos<=table.getn(ids) and count<3 do
      local mapID=ids[pos]
      pos=pos+1
      if tonumber(mapID)~=tonumber(current) and tonumber(mapID)~=tonumber(displayed) then
        publishMap(mapID)
        count=count+1
      end
    end

    if pos<=table.getn(ids) then
      QuestieOcto.Scheduler:Enqueue(step,"prepare-maps")
    else
      P.running=false
      QuestieOcto:SendMessage("PREPARED_MAPS_COMPLETE")
    end
  end

  QuestieOcto.Scheduler:Enqueue(step,"prepare-maps")
end

function P:OnNodesReady()
  self:PrepareAll()
end

QuestieOcto:RegisterMessage("NODES_READY",P,"OnNodesReady")
