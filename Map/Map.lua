QuestieOcto.Map = QuestieOcto.Map or {}
local M = QuestieOcto.Map

local function DisplaySettings()
  return QuestieOcto.MinimapSettings
end

local function IsPermanentRole(role)
  return role=="flightMaster" or role=="auctioneer" or role=="banker"
      or role=="mailbox" or role=="rareMob"
end

local function IsSpecialQuestNode(node)
  return node and (node.pvp or node.repeatable or node.event) and true or false
end

local function IsQuestMarkerNodeEnabled(node)
  local settings=DisplaySettings()
  if IsSpecialQuestNode(node) then
    return settings:Get("showSpecialQuestsWorldMap") and true or false
  end
  return settings:Get("showAllQuestsWorldMap") and true or false
end

local function IsPvPQuestNodeEnabled(node)
  if node and node.pvp then
    return DisplaySettings():Get("showPvPRelatedQuests") and true or false
  end
  return true
end

local function IsRoleEnabled(role)
  local settings=DisplaySettings()
  if role=="auctioneer" then return settings:Get("showMapAuctioneer") and true or false end
  if role=="banker" then return settings:Get("showMapBanker") and true or false end
  if role=="flightMaster" then return settings:Get("showMapFlightMaster") and true or false end
  if role=="mailbox" then return settings:Get("showMapMailbox") and true or false end
  if role=="rareMob" then return settings:Get("showMapRareMonsters") and true or false end
  if not settings:Get("enableMapIcons") then return false end

  if role=="itemStart" then
    return settings:Get("enableAvailable")
       and settings:Get("showItemStartQuests")
       and settings:Get("showItemStartMap")
       and true or false
  elseif role=="available" then
    return settings:Get("enableAvailable") and true or false
  elseif role=="turnin" then
    return settings:Get("enableTurnins") and true or false
  else
    return settings:Get("enableObjectives") and true or false
  end
end


M.enabled=true
M.mapID=nil
M.generation=0
M.syncing=false
M.resync=false
M.prune=false
M.frames={}
M.stats={active=0,created=0,reused=0,hidden=0,exact=0,objectiveAreas=0,itemStartAreas=0,syncs=0,visibleAvailable=0,visibleItemStart=0,visibleObjective=0,visibleTurnin=0,inputNodes=0,multiEntryPins=0,itemStartRawNodes=0,itemStartAreaPins=0,preparedHits=0,preparedMisses=0,preparedDescriptors=0,mapPriorityRequests=0}

local ICON_ROOT="Interface\\AddOns\\Questie-Octo\\UI\\Icons\\"
local TEX_AVAILABLE=ICON_ROOT.."available"
local TEX_MOBDROP=ICON_ROOT.."available_mobdrop"
local TEX_OBJECTSTART=ICON_ROOT.."available_object"
local TEX_COMPLETE=ICON_ROOT.."complete"
local TEX_EVENT_AVAILABLE=ICON_ROOT.."eventquest"
local TEX_EVENT_COMPLETE=ICON_ROOT.."eventquest_complete"
local TEX_REPEATABLE_AVAILABLE=ICON_ROOT.."repeatable"
local TEX_PVP_AVAILABLE=ICON_ROOT.."pvp_available"
local TEX_PVP_COMPLETE=ICON_ROOT.."pvp_complete"
local TEX_INCOMPLETE=ICON_ROOT.."incomplete"
local TEX_SLAY=ICON_ROOT.."slay"
local TEX_LOOT=ICON_ROOT.."loot"
local TEX_OBJECT=ICON_ROOT.."object"
local TEX_EVENT=ICON_ROOT.."event"
local TEX_INTERACT=ICON_ROOT.."interact"
local TEX_FLIGHT=ICON_ROOT.."flight"
local TEX_AUCTIONEER=ICON_ROOT.."auctioneer"
local TEX_BANKER=ICON_ROOT.."banker"
local TEX_MAILBOX=ICON_ROOT.."mailbox"
local TEX_RARE=ICON_ROOT.."rares"

local function TextureForNode(node)
  if node.role=="flightMaster" then return TEX_FLIGHT end
  if node.role=="auctioneer" then return TEX_AUCTIONEER end
  if node.role=="banker" then return TEX_BANKER end
  if node.role=="mailbox" then return TEX_MAILBOX end
  if node.role=="rareMob" then return TEX_RARE end
  if node.role=="itemStart" then
    -- Presentation priority: PvP > Repeatable > Event > Normal.
    if node.pvp then return TEX_PVP_AVAILABLE end
    if node.repeatable then return TEX_REPEATABLE_AVAILABLE end
    if node.event then return TEX_EVENT_AVAILABLE end
    return TEX_AVAILABLE
  end
  if node.role=="available" then
    if node.pvp then return TEX_PVP_AVAILABLE end
    if node.repeatable then return TEX_REPEATABLE_AVAILABLE end
    if node.event then return TEX_EVENT_AVAILABLE end
    return TEX_AVAILABLE
  end
  if node.role=="turnin" then
    if node.pvp then return TEX_PVP_COMPLETE end
    -- Questie 6 uses its ordinary completion question mark for repeatable
    -- turn-ins. Repeatability therefore wins over event presentation here too.
    if node.repeatable then return TEX_COMPLETE end
    if node.event then return TEX_EVENT_COMPLETE end
    return TEX_COMPLETE
  end
  if node.role=="objectiveItemSource" then
    if node.sourceKind=="gameObject" then return TEX_OBJECT end
    return TEX_LOOT
  end
  if node.role=="objectiveObject" then return TEX_OBJECT end
  if node.role=="objectiveCreature" then return TEX_SLAY end
  return TEX_INCOMPLETE
end
local function RolePriority(role)
  if IsPermanentRole(role) then return role=="rareMob" and 6 or 5 end
  -- A quest that can be picked up should be visually dominant when the
  -- exact same source/area also participates in active objective/loot data.
  if role=="turnin" then return 50 end
  if role=="available" or role=="itemStart" then return 40 end
  if role=="objectiveObject" then return 20 end
  if role=="objectiveItemSource" then return 15 end
  return 10
end

local function VariantPriority(node)
  if node and node.pvp then return 3 end
  if node and node.repeatable then return 2 end
  if node and node.event then return 1 end
  return 0
end

local function VisualPriority(node)
  return RolePriority(node.role)*10+VariantPriority(node)
end

local function ScaleKeyForRole(role)
  return nil
end

local function DrawSublevelForRole(role)
  if IsPermanentRole(role) then return role=="rareMob" and 2 or 1 end
  -- Questie 5.2.3/6.0.0/3.3.5 map utils:
  -- available = OVERLAY 5, complete = OVERLAY 6, objectives = OVERLAY 0.
  if role=="turnin" then return 6 end
  if role=="available" or role=="itemStart" then return 5 end
  return 0
end

local function ApplyVisualRole(pin,node)
  local priority=VisualPriority(node)
  if not pin.visualPriority or priority>pin.visualPriority then
    pin.visualPriority=priority
    pin.role=node.role
    pin.questID=node.questID
    pin.event=node.event
    pin.pvp=node.pvp and true or false
    pin.repeatable=node.repeatable and true or false
    pin.sourceKind=node.sourceKind
    pin.sourceID=node.sourceID
    pin.iconScaleKey=node.iconScaleKey or ScaleKeyForRole(node.role)
    pin.texture:SetTexture(TextureForNode(node))
    pin.texture:SetDrawLayer("OVERLAY",DrawSublevelForRole(node.role))
    -- Miscellaneous/rare markers stay below quest pins so an overlapping
    -- quest objective, starter or turn-in remains visible and clickable.
    if pin.SetFrameLevel and WorldMapButton then
      if IsPermanentRole(node.role) then
        pin:SetFrameLevel(WorldMapButton:GetFrameLevel()+7)
      else
        pin:SetFrameLevel(WorldMapButton:GetFrameLevel()+8)
      end
    end
    if QuestieOcto.Visuals then QuestieOcto.Visuals:ApplyPin(pin,node,false,1) end
  end
end


function M:GetTextureForNode(node)
  return TextureForNode(node)
end

function M:GetRolePriority(role)
  return RolePriority(role)
end

function M:GetVisualPriority(node)
  return VisualPriority(node)
end

function M:GetDrawSublevelForRole(role)
  return DrawSublevelForRole(role)
end

function M:GetScaleKeyForRole(role)
  return ScaleKeyForRole(role)
end

function M:GetIconTypeScale(node)
  return 1
end

function M:GetPinScale(pin)
  -- Auctioneer, Banker and Mailbox service artwork share the same compact
  -- intrinsic footprint. The player-facing global map/minimap scale remains
  -- unchanged.
  if pin and (pin.role=="auctioneer" or pin.role=="banker" or pin.role=="mailbox") then
    return 0.9
  end
  return 1
end

function M:ResizePin(pin)
  if not pin then return end
  local globalScale=tonumber(DisplaySettings():Get("globalScale")) or 1
  local typeScale=self:GetPinScale(pin)
  -- pfQuest renders tracking/rares.tga inside a 14px node with a 1px inset,
  -- leaving a 12px visible star.  Our texture fills the pin, so use 12px
  -- for the miscellaneous rare marker to match that less-intrusive footprint.
  local baseSize=pin.fullNode and 14 or ((pin.role=="rareMob") and 12 or 16)
  local size=baseSize*globalScale*typeScale
  pin:SetWidth(size)
  pin:SetHeight(size)
  if QuestieOcto.Visuals then QuestieOcto.Visuals:ResizeGlow(pin) end
  pin.questieOctoScaleSize=size
  self.stats.scaleResizes=(self.stats.scaleResizes or 0)+1
  self.stats.lastScaleSize=size
end


local function IsExactRole(role)
  return role=="available" or role=="turnin" or IsPermanentRole(role)
end

local function EntryKey(node)
  return tostring(node.questID)..":"..tostring(node.role)..":"..
    tostring(node.sourceKind)..":"..tostring(node.sourceID)..":"..tostring(node.itemID or 0)
end

local function AddEntry(pin,node)
  pin.entries=pin.entries or {}
  local key=EntryKey(node)
  if not pin.entries[key] then
    pin.entries[key]={node=node}
  end
  ApplyVisualRole(pin,node)
end

local function UpdatePosition(pin,x,y,offsetX,offsetY)
  offsetX=offsetX or 0
  offsetY=offsetY or 0

  if pin.x==x and pin.y==y and pin.offsetX==offsetX and pin.offsetY==offsetY then
    return
  end

  pin.x=x
  pin.y=y
  pin.offsetX=offsetX
  pin.offsetY=offsetY

  pin:ClearAllPoints()
  pin:SetPoint(
    "CENTER",WorldMapButton,"TOPLEFT",
    WorldMapButton:GetWidth()*(x/100)+offsetX,
    -WorldMapButton:GetHeight()*(y/100)+offsetY
  )
end

local function DisplayedMapID()
  -- Vanilla selected-zone map -> name -> canonical DB map ID.
  local cid=GetCurrentMapContinent and GetCurrentMapContinent() or 0
  local zid=GetCurrentMapZone and GetCurrentMapZone() or 0
  if not cid or cid<=0 or not zid or zid<=0 then return nil end
  if not GetMapZones then return nil end

  local zones={GetMapZones(cid)}
  local name=zones[zid]
  if not name then return nil end

  -- Derive ID by looking at existing canonical node map indexes.
  -- Zone DB identity remains hidden behind generated node coordinates.
  if QuestieOcto.DatabaseAPI.GetMapIDByName then
    return QuestieOcto.DatabaseAPI:GetMapIDByName(name)
  end

  return nil
end

local function DisplayedContinentMapID()
  local cid=GetCurrentMapContinent and GetCurrentMapContinent() or 0
  local zid=GetCurrentMapZone and GetCurrentMapZone() or 0
  if not cid or cid<=0 or (zid and zid>0) then return nil end
  if not QuestieOcto.ContinentProjection then return nil end
  return QuestieOcto.ContinentProjection:GetClientContinentMapID(cid)
end

local function DisplayedContextKey()
  local mapID=DisplayedMapID()
  if mapID then return tonumber(mapID) end
  local continentMapID=DisplayedContinentMapID()
  if continentMapID~=nil then return -1000-tonumber(continentMapID) end
  return nil
end

function M:GetOrCreate(key,node,x,y,clusterCount,generation,kind)
  if not IsRoleEnabled(node.role) or not IsPvPQuestNodeEnabled(node) then return nil end

  local pin=self.frames[key]

  if not pin then
    pin=CreateFrame("Button",nil,WorldMapButton)
    pin:SetWidth(16)
    pin:SetHeight(16)
    pin:SetFrameLevel(WorldMapButton:GetFrameLevel()+8)

    local tex=pin:CreateTexture(nil,"OVERLAY")
    tex:SetAllPoints(pin)
    pin.texture=tex

    pin:SetScript("OnEnter",function() QuestieOcto.Tooltips:Show(this) end)
    pin:SetScript("OnLeave",function() GameTooltip:Hide() end)

    self.frames[key]=pin
    self.stats.created=self.stats.created+1
  else
    self.stats.reused=self.stats.reused+1
  end

  pin.itemStartArea=nil
  pin.displayName=node.sourceName or "Quest source"
  pin.clusterCount=math.max(pin.clusterCount or 1,clusterCount or 1)
  pin.seenGeneration=generation

  if pin.entryGeneration~=generation then
    pin.entryGeneration=generation
    pin.entries={}
    pin.visualPriority=nil
    pin.role=nil
    pin.event=nil
    pin.pvp=nil
    pin.repeatable=nil
    pin.fullNode=nil
    pin.fullNodeNode=nil
    pin.iconScaleKey=nil
    pin.sourceKind=node.sourceKind
    if QuestieOcto.Visuals then QuestieOcto.Visuals:ClearPin(pin,1) end
  end

  -- Place at canonical coordinates first. Final layout resolves overlap
  -- after the complete visible pin set is known.
  UpdatePosition(pin,x,y,0,0)
  AddEntry(pin,node)
  if kind=="objectiveFull" or kind=="itemStartFull" then
    if QuestieOcto.Visuals and QuestieOcto.Visuals.ApplyFullNode then
      QuestieOcto.Visuals:ApplyFullNode(pin,node,false,1)
      pin.fullNodeNode=node
    end
  end
  self:ResizePin(pin)

  if not pin:IsShown() then pin:Show() end

  if kind=="exact" then
    self.stats.exact=self.stats.exact+1
  elseif kind=="itemStart" then
    self.stats.itemStartAreas=self.stats.itemStartAreas+1
  else
    self.stats.objectiveAreas=self.stats.objectiveAreas+1
  end

  return pin
end

local function RefreshPinVisual(pin)
  local fullNode=pin.fullNodeNode
  pin.visualPriority=nil
  pin.role=nil
  pin.questID=nil
  pin.sourceID=nil
  pin.iconScaleKey=nil
  pin.fullNode=nil

  for _,entry in pairs(pin.entries or {}) do
    if entry.node then ApplyVisualRole(pin,entry.node) end
  end
  if fullNode and QuestieOcto.Visuals and QuestieOcto.Visuals.ApplyFullNode then
    QuestieOcto.Visuals:ApplyFullNode(pin,fullNode,false,1)
  end
  M:ResizePin(pin)
end

function M:RemoveQuest(questID)
  questID=tonumber(questID)
  if not questID then return 0 end

  local removed=0

  for _,pin in pairs(self.frames) do
    local changed=false

    if pin.itemStartArea and tonumber(pin.itemStartArea.questID)==questID then
      pin.itemStartArea=nil
      pin.entries={}
      changed=true
    else
      for key,entry in pairs(pin.entries or {}) do
        if entry.node and tonumber(entry.node.questID)==questID then
          pin.entries[key]=nil
          removed=removed+1
          changed=true
        end
      end
    end

    if changed then
      if pin.itemStartArea or next(pin.entries or {}) then
        RefreshPinVisual(pin)
      else
        if pin:IsShown() then
          pin:Hide()
          self.stats.hidden=self.stats.hidden+1
        end
      end
    end
  end

  -- Questie 5.2.3/6.0.0 UnloadQuestFrames removes every frame belonging
  -- to the quest, including both world-map and minimap copies.
  if QuestieOcto.Minimap and QuestieOcto.Minimap.RemoveQuest then
    removed=removed+QuestieOcto.Minimap:RemoveQuest(questID)
  end

  return removed
end

function M:HideAll()
  for _,pin in pairs(self.frames) do
    if pin:IsShown() then
      pin:Hide()
      self.stats.hidden=self.stats.hidden+1
    end
  end
  self.stats.active=0
end

function M:GetDisplayedMapID()
  return DisplayedMapID()
end

function M:GetNearbyQuestTooltipPins(pin,maxPixels)
  local result={}
  if not pin or not pin:IsShown() then return result end

  maxPixels=tonumber(maxPixels) or 5
  local width=WorldMapButton and WorldMapButton:GetWidth() or 0
  local height=WorldMapButton and WorldMapButton:GetHeight() or 0
  if width<=0 or height<=0 then
    result[1]=pin
    return result
  end

  local px=(tonumber(pin.x) or 0)*width/100+(tonumber(pin.offsetX) or 0)
  local py=(tonumber(pin.y) or 0)*height/100+(tonumber(pin.offsetY) or 0)

  local _,other
  for _,other in pairs(self.frames or {}) do
    if other and other:IsShown() and not IsPermanentRole(other.role) and (other.itemStartArea or next(other.entries or {})) then
      local ox=(tonumber(other.x) or 0)*width/100+(tonumber(other.offsetX) or 0)
      local oy=(tonumber(other.y) or 0)*height/100+(tonumber(other.offsetY) or 0)
      local dx=px-ox
      local dy=py-oy
      if dx*dx+dy*dy<=maxPixels*maxPixels then
        result[table.getn(result)+1]=other
      end
    end
  end

  if table.getn(result)==0 then result[1]=pin end

  table.sort(result,function(a,b)
    local ay=tonumber(a.y) or 0
    local by=tonumber(b.y) or 0
    if ay==by then return (tonumber(a.x) or 0)<(tonumber(b.x) or 0) end
    return ay<by
  end)

  return result
end

function M:SetMap(mapID)
  mapID=tonumber(mapID)
  if tonumber(self.mapID)==mapID then return end
  self.mapID=mapID
  self.generation=self.generation+1
  self.syncing=false
  self.resync=false
  self.prune=false
  self:HideAll()
end

function M:RenderItemStartArea(area,generation)
  if not IsRoleEnabled("itemStart") then return end
  local itemQuest=QuestieOcto.QuestModel:Get(area.questID)
  if itemQuest and itemQuest.pvp and not DisplaySettings():Get("showPvPRelatedQuests") then return end
  local itemEvent=itemQuest and itemQuest.eventID and QuestieOcto.EventAvailability and QuestieOcto.EventAvailability:IsPresentationEvent(itemQuest.eventID) or false
  local itemPvP=itemQuest and itemQuest.pvp or false
  local itemRepeatable=itemQuest and itemQuest.repeatable or false

  local key="itemarea:"..tostring(area.key)
  local pin=self.frames[key]

  if not pin then
    pin=CreateFrame("Button",nil,WorldMapButton)
    pin:SetWidth(16)
    pin:SetHeight(16)
    pin:SetFrameLevel(WorldMapButton:GetFrameLevel()+8)

    local tex=pin:CreateTexture(nil,"OVERLAY")
    tex:SetAllPoints(pin)
    pin.texture=tex

    pin:SetScript("OnEnter",function() QuestieOcto.Tooltips:Show(this) end)
    pin:SetScript("OnLeave",function() GameTooltip:Hide() end)

    self.frames[key]=pin
    self.stats.created=self.stats.created+1
  else
    self.stats.reused=self.stats.reused+1
  end

  pin.seenGeneration=generation
  pin.itemStartArea=area
  pin.entries={}
  pin.visualPriority=40
  pin.role="itemStart"
  pin.questID=area.questID
  pin.event=itemEvent
  pin.pvp=itemPvP
  pin.repeatable=itemRepeatable
  pin.iconScaleKey=nil
  pin.sourceKind="area"
  pin.displayName=area.displayName
  pin.clusterCount=area.n
  pin.texture:SetTexture(TextureForNode({role="itemStart",event=pin.event,pvp=pin.pvp,repeatable=pin.repeatable}))
  pin.texture:SetDrawLayer("OVERLAY",5)
  if QuestieOcto.Visuals then
    QuestieOcto.Visuals:ApplyPin(pin,{role="itemStart",questID=area.questID,pvp=pin.pvp,repeatable=pin.repeatable},false,1)
  end
  self:ResizePin(pin)

  UpdatePosition(pin,area.x,area.y,0,0)

  if not pin:IsShown() then pin:Show() end
  self.stats.itemStartAreaPins=self.stats.itemStartAreaPins+1
end

function M:RenderNode(node,generation)
  if not self.mapID then return end

  -- Clustered item-start sources are represented by geographic area pins.
  -- Full Nodes intentionally renders their raw spawn coordinates.
  if node.role=="itemStart" and DisplaySettings():Get("itemStartDensity")~="full" then return end

  local radius=QuestieOcto.Clustering.objectiveRadius
  local kind="objective"

  if node.role=="itemStart" then
    radius=QuestieOcto.Clustering.itemStartRadius
    kind="itemStart"
  end

  if IsExactRole(node.role) then
    local points=QuestieOcto.Clustering:PointsForNodeOnMap(node,self.mapID)
    for _,p in pairs(points) do
      local key="exact:"..tostring(node.sourceKind)..":"..tostring(node.sourceID)..":"..
        string.format("%.2f",p.x)..":"..string.format("%.2f",p.y)
      self:GetOrCreate(key,node,p.x,p.y,1,generation,"exact")
    end
    return
  end

  local points=QuestieOcto.Clustering:PointsForNodeOnMap(node,self.mapID)
  local areas=QuestieOcto.Clustering:BuildAreas(points,radius)

  for _,area in pairs(areas) do
    local key="area:"..tostring(node.sourceKind)..":"..tostring(node.sourceID)..":"..tostring(area.key)
    self:GetOrCreate(key,node,area.x,area.y,area.n,generation,kind)
  end
end

local function ResetVisibleOffsets(generation)
  local groups={}

  for _,pin in pairs(M.frames) do
    if pin:IsShown() and pin.seenGeneration==generation and pin.x and pin.y then
      local key=string.format("%.2f:%.2f",tonumber(pin.x) or 0,tonumber(pin.y) or 0)
      groups[key]=groups[key] or {}
      table.insert(groups[key],pin)
    end
  end

  -- Keep the pfQuest database coordinate as the anchor. Only separate icons in
  -- screen space when several markers occupy that exact coordinate, so a
  -- service/rare marker never hides a quest marker (or another service icon).
  local offsets={{0,0},{10,0},{-10,0},{0,10},{0,-10},{8,8},{-8,8},{8,-8},{-8,-8}}
  for _,group in pairs(groups) do
    table.sort(group,function(a,b)
      local ap=IsPermanentRole(a.role) and 1 or 0
      local bp=IsPermanentRole(b.role) and 1 or 0
      if ap~=bp then return ap<bp end -- quest marker keeps the canonical point
      if tostring(a.role)~=tostring(b.role) then return tostring(a.role)<tostring(b.role) end
      return tonumber(a.sourceID or 0)<tonumber(b.sourceID or 0)
    end)

    for index,pin in ipairs(group) do
      local off=offsets[math.mod(index-1,table.getn(offsets))+1]
      UpdatePosition(pin,pin.x,pin.y,off[1],off[2])
    end
  end
end

function M:Finish(generation,doPrune)
  if generation~=self.generation then return end

  if doPrune then
    for _,pin in pairs(self.frames) do
      if pin:IsShown() and pin.seenGeneration~=generation then
        pin:Hide()
        self.stats.hidden=self.stats.hidden+1
      end
    end
  end

  -- Keep every marker at its canonical database/resolved coordinate.
  -- Vanilla-style overlap is intentionally accepted.
  ResetVisibleOffsets(generation)

  local active=0
  local visibleAvailable=0
  local visibleItemStart=0
  local visibleObjective=0
  local visibleTurnin=0

  for _,pin in pairs(self.frames) do
    if pin:IsShown() then
      active=active+1
      if pin.role=="available" then
        visibleAvailable=visibleAvailable+1
      elseif pin.role=="itemStart" then
        visibleItemStart=visibleItemStart+1
      elseif pin.role=="turnin" then
        visibleTurnin=visibleTurnin+1
      else
        visibleObjective=visibleObjective+1
      end
    end
  end

  local multiEntryPins=0

  for _,pin in pairs(self.frames) do
    if pin:IsShown() then
      local entries=0
      for _ in pairs(pin.entries or {}) do entries=entries+1 end
      if entries>1 then multiEntryPins=multiEntryPins+1 end
    end
  end

  self.stats.active=active
  self.stats.visibleAvailable=visibleAvailable
  self.stats.visibleItemStart=visibleItemStart
  self.stats.visibleObjective=visibleObjective
  self.stats.visibleTurnin=visibleTurnin
  self.stats.multiEntryPins=multiEntryPins
  self.stats.syncs=self.stats.syncs+1
  self.syncing=false

  if self.resync then
    local p=self.prune
    self.resync=false
    self.prune=false
    self:RequestSync(p)
  end
end

function M:RenderPreparedDescriptor(desc,generation)
  if desc.type=="itemStartArea" then
    M:RenderItemStartArea(desc.area,generation)
    return
  end

  if desc.type=="node" then
    M:GetOrCreate(
      desc.key,
      desc.node,
      desc.x,
      desc.y,
      desc.clusterCount or 1,
      generation,
      desc.kind or "objective"
    )
  end
end

local function IsContinentQuestRole(role)
  return role=="available" or role=="turnin" or role=="itemStart"
end

local function ContinentPinKey(node,mapID,x,y)
  if IsContinentQuestRole(node.role) then
    return "continent:quest-source:"..tostring(node.sourceKind)..":"..tostring(node.sourceID)..":"..
      tostring(mapID)..":"..string.format("%.2f",x)..":"..string.format("%.2f",y)
  end
  return "continent:"..tostring(node.role)..":"..tostring(node.sourceKind)..":"..tostring(node.sourceID)..":"..
    tostring(mapID)..":"..string.format("%.2f",x)..":"..string.format("%.2f",y)
end

function M:RenderContinentNode(node,mapID,generation)
  if not node or not IsRoleEnabled(node.role) or not IsPvPQuestNodeEnabled(node) then return 0 end
  -- World Map Visibility toggles apply only to continent/world overviews.
  -- Selected zone and city maps keep normal/special quest markers visible and
  -- are controlled by Enable Available/Completed Quest Icons instead.
  if IsContinentQuestRole(node.role) and not IsQuestMarkerNodeEnabled(node) then return 0 end
  -- The continent overview intentionally shows only quest start/turn-in markers
  -- plus Flight Masters. Objective/slay/full-node/cluster data remains zone-only.
  if not IsContinentQuestRole(node.role) and node.role~="flightMaster" then return 0 end

  local projection=QuestieOcto.ContinentProjection
  if not projection then return 0 end
  local points=QuestieOcto.Clustering:PointsForNodeOnMap(node,mapID)
  if not points or table.getn(points)==0 then return 0 end

  local rendered=0
  if node.role=="itemStart" then
    -- Item-start sources can have dozens of spawn points. On a continent map
    -- they represent one available quest, so use a single centroid marker per
    -- source/zone instead of turning the continent into an objective-node map.
    local sx,sy,n=0,0,0
    for _,point in pairs(points) do
      local px,py=projection:Project(mapID,point.x,point.y)
      if px and py then sx=sx+px; sy=sy+py; n=n+1 end
    end
    if n>0 then
      local x,y=sx/n,sy/n
      self:GetOrCreate(ContinentPinKey(node,mapID,x,y),node,x,y,1,generation,"exact")
      return 1
    end
    return 0
  end

  for _,point in pairs(points) do
    local x,y=projection:Project(mapID,point.x,point.y)
    if x and y then
      self:GetOrCreate(ContinentPinKey(node,mapID,x,y),node,x,y,1,generation,"exact")
      rendered=rendered+1
    end
  end
  return rendered
end

function M:StartContinentSync(continentMapID,doPrune)
  continentMapID=tonumber(continentMapID)
  if continentMapID==nil or not QuestieOcto.ContinentProjection then return end

  local contextKey=-1000-continentMapID
  if tonumber(self.mapID)~=contextKey then self:SetMap(contextKey) end
  if not QuestieOcto.Nodes.ready then
    self.syncing=false
    return
  end

  self.generation=self.generation+1
  local generation=self.generation
  self.syncing=true
  self.stats.reused=0
  self.stats.exact=0
  self.stats.objectiveAreas=0
  self.stats.itemStartAreas=0
  self.stats.inputNodes=0

  local mapIDs=QuestieOcto.ContinentProjection:GetZoneMapIDs(continentMapID)
  local pos=1
  local rendered=0

  local function step()
    if generation~=M.generation then return end
    local mapsThisFrame=0
    while pos<=table.getn(mapIDs) and mapsThisFrame<4 and rendered<1000 do
      local mapID=mapIDs[pos]
      pos=pos+1
      mapsThisFrame=mapsThisFrame+1
      local nodes=QuestieOcto.Nodes:GetMapNodes(mapID)
      M.stats.inputNodes=M.stats.inputNodes+table.getn(nodes)
      for _,node in pairs(nodes) do
        if rendered>=1000 then break end
        rendered=rendered+M:RenderContinentNode(node,mapID,generation)
      end
    end

    if pos<=table.getn(mapIDs) and rendered<1000 then
      QuestieOcto.Scheduler:Enqueue(step,"map-continent-render")
    else
      M:Finish(generation,doPrune)
    end
  end

  QuestieOcto.Scheduler:Enqueue(step,"map-continent-render")
end

function M:StartSync(doPrune)
  if not self.enabled or not WorldMapButton then return end

  -- Quest icon visibility is separate from townsfolk/service markers.
  -- Always build the map pass; IsRoleEnabled filters each semantic role.
  local mapID=DisplayedMapID()
  if not mapID then
    local continentMapID=DisplayedContinentMapID()
    if continentMapID~=nil then
      self:StartContinentSync(continentMapID,doPrune)
      return
    end
    self:SetMap(nil)
    return
  end

  if not QuestieOcto.PreparedMap:Get(mapID) then
    -- Any map the player actually opens becomes top priority immediately.
    -- This works even before the global Nodes build has completed.
    if QuestieOcto.ZoneBootstrap then
      QuestieOcto.ZoneBootstrap:Request(mapID,0.01)
      self.stats.mapPriorityRequests=(self.stats.mapPriorityRequests or 0)+1
    end

    if not QuestieOcto.Nodes.ready then
      return
    end
  end

  if tonumber(self.mapID)~=tonumber(mapID) then self:SetMap(mapID) end

  self.generation=self.generation+1
  local generation=self.generation
  self.syncing=true
  self.stats.reused=0
  self.stats.exact=0
  self.stats.objectiveAreas=0
  self.stats.itemStartAreas=0

  local nodes=QuestieOcto.Nodes:GetMapNodes(mapID)
  self.stats.inputNodes=table.getn(nodes)
  self.stats.itemStartRawNodes=0
  self.stats.itemStartAreaPins=0

  for _,node in pairs(nodes) do
    if node.role=="itemStart" then
      self.stats.itemStartRawNodes=self.stats.itemStartRawNodes+1
    end
  end

  local prepared=QuestieOcto.PreparedMap:Get(mapID)

  if prepared then
    self.stats.preparedHits=self.stats.preparedHits+1
    self.stats.preparedDescriptors=table.getn(prepared)

    -- Prepared descriptors contain no DB discovery or clustering work.
    -- Typical zone maps can therefore appear in one rendering tick.
    local pos=1
    local function preparedStep()
      if generation~=M.generation then return end

      local count=0
      local renderLimit=math.min(table.getn(prepared),1000)
      while pos<=renderLimit and count<128 do
        M:RenderPreparedDescriptor(prepared[pos],generation)
        pos=pos+1
        count=count+1
      end

      if pos<=math.min(table.getn(prepared),1000) then
        QuestieOcto.Scheduler:Enqueue(preparedStep,"map-prepared-render")
      else
        M:Finish(generation,doPrune)
      end
    end

    QuestieOcto.Scheduler:Enqueue(preparedStep,"map-prepared-render")
    return
  end

  self.stats.preparedMisses=self.stats.preparedMisses+1

  -- First visit before background preparation reached this zone:
  -- prepare just this map, then render it on the next scheduler turn.
  QuestieOcto.Scheduler:Enqueue(function()
    if generation~=M.generation then return end

    QuestieOcto.PreparedMap:BuildMap(mapID)
    local ready=QuestieOcto.PreparedMap:Get(mapID)

    if not ready then
      M.syncing=false
      return
    end

    local pos=1
    local function fallbackPreparedStep()
      if generation~=M.generation then return end

      local count=0
      while pos<=table.getn(ready) and count<128 do
        M:RenderPreparedDescriptor(ready[pos],generation)
        pos=pos+1
        count=count+1
      end

      if pos<=table.getn(ready) then
        QuestieOcto.Scheduler:Enqueue(fallbackPreparedStep,"map-first-prepare-render")
      else
        M:Finish(generation,doPrune)
      end
    end

    fallbackPreparedStep()
  end,"map-first-prepare")
end

function M:RefreshVisualSettings()
  for _,pin in pairs(self.frames) do
    if pin.itemStartArea then
      if QuestieOcto.Visuals then QuestieOcto.Visuals:ClearPin(pin,1) end
    elseif pin.entries and next(pin.entries) then
      pin.visualPriority=nil
      pin.role=nil
      pin.iconScaleKey=nil
      RefreshPinVisual(pin)
      if QuestieOcto.Visuals then QuestieOcto.Visuals:SetAlpha(pin,1) end
    end
  end

  if QuestieOcto.Minimap and QuestieOcto.Minimap.RefreshVisualSettings then
    QuestieOcto.Minimap:RefreshVisualSettings()
  end
end

function M:RescaleIcons(changedKey,changedValue)
  self.stats.rescalePasses=(self.stats.rescalePasses or 0)+1

  -- Scaling is presentation-only. Do not rebuild a pin's semantic visual here:
  -- doing so used to replace Full Nodes with the normal Questie objective
  -- texture until the next map sync. The global slider now changes size only.
  for _,pin in pairs(self.frames) do
    self:ResizePin(pin)
  end
end

function M:ApplySettings()
  self:RescaleIcons()
  self:RequestSync(true)
end

function M:OnSettingChanged(key,value)
  if key=="enableMapIcons" or key=="showAllQuestsWorldMap" or key=="showSpecialQuestsWorldMap" or key=="showPvPRelatedQuests" or key=="enableObjectives" or key=="enableTurnins" or
     key=="enableAvailable" or key=="showItemStartQuests" or key=="showItemStartMap" or
     key=="showMapAuctioneer" or key=="showMapBanker" or
     key=="showMapFlightMaster" or key=="showMapMailbox" or
     key=="showMapRareMonsters" then
    self:RequestSync(true)
  end
end

function M:RequestSync(doPrune)
  if self.syncing then
    self.resync=true
    if doPrune then self.prune=true end
    return
  end

  QuestieOcto.Scheduler:After(0.01,function()
    M:StartSync(doPrune and true or false)
  end,"map-sync")
end

function M:OnNodesReady()
  self:RequestSync(true)
end

QuestieOcto:RegisterMessage("NODES_READY",M,"OnNodesReady")

function M:OnPreparedMapReady(mapID)
  if WorldMapFrame and WorldMapFrame:IsVisible()
     and tonumber(mapID)==tonumber(DisplayedMapID()) then
    self:RequestSync(true)
  end
end

QuestieOcto:RegisterMessage("PREPARED_MAP_READY",M,"OnPreparedMapReady")

local f=CreateFrame("Frame","QuestieOctoWorldMapEvents",UIParent)
f:RegisterEvent("WORLD_MAP_UPDATE")
f:RegisterEvent("QUEST_LOG_UPDATE")
f:SetScript("OnEvent",function()
  if event=="WORLD_MAP_UPDATE" then
    if WorldMapFrame and WorldMapFrame:IsVisible() then
      local contextKey=DisplayedContextKey()
      if tonumber(contextKey)~=tonumber(M.mapID) then
        M:SetMap(contextKey)
        M:RequestSync(false)
      end
    end
  elseif event=="QUEST_LOG_UPDATE" then
    M:RequestSync(false)
  end
end)
