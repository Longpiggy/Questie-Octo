QuestieOcto.Tooltips = QuestieOcto.Tooltips or {}
local T = QuestieOcto.Tooltips

local function Settings()
  return QuestieOcto.MinimapSettings
end

local function QuestTitle(q)
  local title=tostring(q.title or ("Quest "..tostring(q.id or "")))
  if Settings():Get("enableTooltipsQuestLevel") then
    title="["..tostring(q.level or 0).."] "..title
  end
  if Settings():Get("enableTooltipsQuestID") then
    title=title.." ("..tostring(q.id or 0)..")"
  end
  return title
end

local function FormatDropRate(rate)
  rate=tonumber(rate)
  if not rate then return nil end
  if rate>=10 then return string.format("%.0f",rate) end
  if rate>=2 then return string.format("%.1f",rate) end
  if rate>=0.01 then return string.format("%.2f",rate) end
  return string.format("%.3f",rate)
end

local function DifficultyColor(level,questID)
  -- Use the same authority as the native Quest Log.  Octo/Turtle modifies the
  -- low-level/easy band, so reproducing stock Classic thresholds makes map
  -- tooltips disagree with the Quest Log (green there, gray here).
  if QuestieOcto.GetNativeQuestDifficultyColor then
    local r,g,b=QuestieOcto:GetNativeQuestDifficultyColor(level,questID)
    if r then return r,g,b end
  end
  return 1,1,0
end

local function RoleText(role)
  if role=="available" or role=="itemStart" then return "(Available)" end
  if role=="turnin" then return "(Complete)" end
  return "(Active)"
end
local function RareRankText(rank)
  rank=tonumber(rank)
  if rank==4 then return "Rare" end
  if rank==2 then return "Rare Elite" end
  return nil
end

local function RespawnText(seconds)
  seconds=tonumber(seconds)
  if not seconds or seconds<=0 then return nil end

  if math.mod(seconds,60)==0 then
    return "~"..tostring(math.floor(seconds/60)).." min"
  end

  return "~"..tostring(math.floor(seconds/60)).."m "..tostring(math.mod(seconds,60)).."s"
end

local function SourceDisplayName(source)
  local name=tostring(source.name or "Creature")
  local rank=RareRankText(source.rank)
  if rank then name=name.." ["..rank.."]" end
  if Settings():Get("enableTooltipsNPCID") and source.id then
    name=name.." (NPC "..tostring(source.id)..")"
  end
  return name
end

local function NormalizeFirstRowFont()
  -- WoW 1.12 gives GameTooltipTextLeft1 a larger title font by default.
  -- Copy the normal second-row font onto line 1 for item-start source lists.
  local first=getglobal and getglobal("GameTooltipTextLeft1") or nil
  local normal=getglobal and getglobal("GameTooltipTextLeft2") or nil

  if first and normal and normal.GetFont and first.SetFont then
    local font,size,flags=normal:GetFont()
    if font and size then
      first:SetFont(font,size,flags)
    end
  end
end


local function Extra(node)
  if node.role=="itemStart" and node.itemName then
    local text
    if node.vendor then text="Sells ["..tostring(node.itemName).."]"
    else text="Drops ["..tostring(node.itemName).."]" end
    if node.chance and Settings():Get("enableTooltipDroprates") then text=text.." ("..(FormatDropRate(node.chance) or tostring(node.chance)).."%)" end
    return text.." - item starts quest"
  end
  if node.role=="objectiveCreature"
     or node.role=="objectiveObject"
     or node.role=="objectiveItemSource" then
    if node.objectiveText and node.objectiveText~="" then
      local text=node.objectiveText
      if node.role=="objectiveItemSource" and node.chance and Settings():Get("enableTooltipDroprates") then
        local rate=FormatDropRate(node.chance)
        if rate then text=text.." |cff999999["..rate.."%]|r" end
      end
      return text
    end
    if node.role=="objectiveItemSource" and node.itemName then
      local text="["..tostring(node.itemName).."]"
      if node.vendor then text=text.." (Vendor)" end
      if node.chance and Settings():Get("enableTooltipDroprates") then text=text.." ("..(FormatDropRate(node.chance) or tostring(node.chance)).."%)" end
      return text
    end
    return nil
  end
  return nil
end

local function AddSourceIDLine(pin)
  if pin.sourceKind=="creature" and pin.sourceID and Settings():Get("enableTooltipsNPCID") then
    GameTooltip:AddLine("NPC ID: "..tostring(pin.sourceID),.65,.65,.65)
  end
end

local function SortedEntries(pin)
  local rows={}
  for _,entry in pairs(pin.entries or {}) do
    rows[table.getn(rows)+1]=entry
  end

  table.sort(rows,function(a,b)
    local qa=QuestieOcto.QuestModel:Get(a.node.questID)
    local qb=QuestieOcto.QuestModel:Get(b.node.questID)
    local la=qa and qa.level or 0
    local lb=qb and qb.level or 0
    if la==lb then
      return tonumber(a.node.questID or 0)<tonumber(b.node.questID or 0)
    end
    return la<lb
  end)

  return rows
end

local function AddQuestEntries(pin,seen)
  local rows=SortedEntries(pin)
  local _,entry

  for _,entry in pairs(rows) do
    local node=entry.node
    local unique=tostring(node.questID)..":"..tostring(node.role)..":"..
      tostring(node.sourceKind)..":"..tostring(node.sourceID)..":"..
      tostring(node.itemID or 0)

    if not seen[unique] then
      seen[unique]=true

      local q=QuestieOcto.QuestModel:Get(node.questID)
      if q then
        local r,g,b=DifficultyColor(q.level,q.id)
        GameTooltip:AddDoubleLine(
          QuestTitle(q),
          RoleText(node.role),
          r,g,b,1,.82,0
        )
        local extra=Extra(node)
        if extra then GameTooltip:AddLine("  "..extra,.82,.82,.82,true) end
        if node.itemID and Settings():Get("enableTooltipsItemID") then
          GameTooltip:AddLine("  Item ID: "..tostring(node.itemID),.65,.65,.65)
        end
      end
    end
  end
end

local function RareSourceInfo(pin)
  for _,entry in pairs(pin.entries or {}) do
    local node=entry.node
    if node and node.sourceKind=="creature" then
      local rank=RareRankText(node.sourceRank)
      if rank then return rank,node.respawnSeconds end
    end
  end
  return nil,nil
end

local function QuestSourceTitle(pin)
  local title=pin.displayName or "Quest source"
  local rank=RareSourceInfo(pin)
  if rank then title=title.." ["..rank.."]" end
  return title
end

local function AddRareSourceRespawn(pin)
  local rank,respawnSeconds=RareSourceInfo(pin)
  if not rank then return end
  local respawn=RespawnText(respawnSeconds)
  if respawn then GameTooltip:AddLine("Respawn: "..respawn,.75,.75,.75) end
end

local function ShowCombinedNearbyQuestTooltip(pin,pins)
  GameTooltip:SetOwner(pin,"ANCHOR_CURSOR")
  GameTooltip:ClearLines()

  local seen={}
  local first=true
  local _,near

  for _,near in pairs(pins) do
    if near.itemStartArea then
      -- Existing item-start area formatting stays self-contained. Nearby
      -- ordinary quest markers are still included below it.
      local area=near.itemStartArea
      if not first then GameTooltip:AddLine(" ",1,1,1) end
      first=false

      GameTooltip:AddLine(tostring(area.displayName or "Item-start source"),.2,1,.35)
      local q=QuestieOcto.QuestModel:Get(area.questID)
      if q then
        local key="itemstart:"..tostring(area.questID)
        if not seen[key] then
          seen[key]=true
          local r,g,b=DifficultyColor(q.level,q.id)
          GameTooltip:AddDoubleLine(QuestTitle(q),"(Available)",r,g,b,1,.82,0)
        end
      end
    elseif near.entries and next(near.entries) then
      if not first then GameTooltip:AddLine(" ",1,1,1) end
      first=false

      local title=QuestSourceTitle(near)
      if near.clusterCount and near.clusterCount>1 then
        title=title.." |cffaaaaaa("..tostring(near.clusterCount).." nearby spawns)|r"
      end

      GameTooltip:AddLine(title,.2,1,.35)
      AddSourceIDLine(near)
      AddRareSourceRespawn(near)
      AddQuestEntries(near,seen)
    end
  end

  NormalizeFirstRowFont()
  GameTooltip:Show()
end

function T:Show(pin)
  if not pin then return end

  local permanentLabels={
    flightMaster="Flight Master",
    auctioneer="Auctioneer",
    banker="Banker",
    mailbox="Mailbox",
    rareMob="[Rare]"
  }
  local permanentLabel=permanentLabels[pin.role]
  if permanentLabel then
    GameTooltip:SetOwner(pin,"ANCHOR_CURSOR")
    GameTooltip:ClearLines()
    local title=pin.displayName or permanentLabel
    if pin.role=="rareMob" then
      GameTooltip:SetText(tostring(title),1,.82,0)
      local level=nil
      local respawnSeconds=nil
      for _,entry in pairs(pin.entries or {}) do
        if entry.node and entry.node.role=="rareMob" then
          level=entry.node.rareLevel
          respawnSeconds=entry.node.respawnSeconds
          break
        end
      end
      if level then
        GameTooltip:AddLine("[Rare] - Level "..tostring(level),1,.82,0)
      else
        GameTooltip:AddLine("[Rare]",1,.82,0)
      end
      local respawn=RespawnText(respawnSeconds)
      if respawn then
        GameTooltip:AddLine("Respawn: "..respawn,.75,.75,.75)
      end
    else
      GameTooltip:SetText(tostring(title),.2,1,.35)
      GameTooltip:AddLine(permanentLabel,1,.82,0)
    end
    GameTooltip:Show()
    return
  end

  if not Settings():Get("enableTooltips") then return end

  if pin:GetParent()==WorldMapButton and
     QuestieOcto.Map and QuestieOcto.Map.GetNearbyQuestTooltipPins then
    local nearby=QuestieOcto.Map:GetNearbyQuestTooltipPins(pin,5)
    if table.getn(nearby)>1 then
      ShowCombinedNearbyQuestTooltip(pin,nearby)
      return
    end
  end

  GameTooltip:SetOwner(pin,"ANCHOR_CURSOR")
  GameTooltip:ClearLines()


  if pin.itemStartArea then
    local area=pin.itemStartArea

    -- Use AddDoubleLine with an empty right column for every source row.
    -- This avoids the first source row inheriting the tooltip's title-sized
    -- presentation while keeping every monster line visually identical.
    for _,source in pairs(area.sourceList or {}) do
      GameTooltip:AddDoubleLine(
        SourceDisplayName(source).." ("..tostring(source.count).." nearby spawns)",
        "",
        .2,1,.35,
        .2,1,.35
      )

      local rank=RareRankText(source.rank)
      local respawn=rank and RespawnText(source.respawnSeconds) or nil
      if respawn then
        local rareTag=RareRankText(source.rank) or "Rare"
        GameTooltip:AddLine("["..rareTag.."] Respawn: "..respawn,.75,.75,.75)
      end
    end

    local q=QuestieOcto.QuestModel:Get(area.questID)
    if q then
      local r,g,b=DifficultyColor(q.level,q.id)
      GameTooltip:AddDoubleLine(
        QuestTitle(q),
        "(Available)",
        r,g,b,
        1,.82,0
      )
    end

    local chance=nil
    for _,source in pairs(area.sourceList or {}) do
      if source.chance then
        chance=source.chance
        break
      end
    end

    local itemLabel=tostring(area.itemName or ("Item "..tostring(area.itemID)))
    if Settings():Get("enableTooltipsItemID") and area.itemID then
      itemLabel=itemLabel.." (Item "..tostring(area.itemID)..")"
    end
    local line="Drops ["..itemLabel.."]"
    if chance and Settings():Get("enableTooltipDroprates") then line=line.." ("..(FormatDropRate(chance) or tostring(chance)).."%)" end
    GameTooltip:AddLine(line.." - item starts quest",.82,.82,.82,true)

    NormalizeFirstRowFont()
    GameTooltip:Show()
    return
  end

  if not pin.entries then return end

  local title=QuestSourceTitle(pin)
  if pin.clusterCount and pin.clusterCount>1 then
    title=title.." |cffaaaaaa("..tostring(pin.clusterCount).." nearby spawns)|r"
  end
  GameTooltip:SetText(title,.2,1,.35)

  AddSourceIDLine(pin)
  AddRareSourceRespawn(pin)
  AddQuestEntries(pin,{})

  GameTooltip:Show()
end
