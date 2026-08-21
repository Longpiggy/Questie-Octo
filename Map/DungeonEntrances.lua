QuestieOcto.DungeonEntrances = QuestieOcto.DungeonEntrances or {}
local D = QuestieOcto.DungeonEntrances

-- Verified dungeon entrance guidance for active quests.
-- Source authority: current Octo DBFilesClient AreaTrigger/WorldMapArea data
-- plus current Turtle/Tortoise areatrigger_teleport server rows.
--
-- This is deliberately curated rather than a dump of every teleport trigger:
-- exits, internal-only transitions, condition-gated shortcuts/raids, unavailable
-- content, AQ20 helper-map geometry, and the shared Lower/Upper Karazhan area
-- identity are excluded until their runtime conditions/map identity are safe.

D.byMap={
  [209]={dungeonName="Shadowfang Keep",xScale=3.810000,yScale=2.540000,entrances={
    {id=145,name="Shadowfang Keep Entrance",minimumLevel=10,serverPhase=0,exterior={55.389,32.280,130},target={14.806,34.177}},
  }},
  [491]={dungeonName="Razorfen Kraul",xScale=7.364500,yScale=4.909598,entrances={
    {id=244,name="Razorfen Kraul Entrance",minimumLevel=15,serverPhase=0,exterior={57.774,10.169,17},target={30.112,17.026}},
  }},
  [717]={dungeonName="The Stockade",xScale=3.781500,yScale=2.521000,entrances={
    {id=101,name="Stormwind Stockades Entrance",minimumLevel=15,serverPhase=0,exterior={49.677,33.869,1519},target={49.931,31.914}},
  }},
  [718]={dungeonName="Wailing Caverns",xScale=11.700000,yScale=7.850000,entrances={
    {id=228,name="Wailing Caverns Entrance",minimumLevel=10,serverPhase=0,exterior={52.279,64.979,17},target={43.727,52.428}},
  }},
  [719]={dungeonName="Blackfathom Deeps",xScale=12.218700,yScale=8.064200,entrances={
    {id=257,name="Blackfathom Deeps Entrance",minimumLevel=10,serverPhase=0,exterior={83.647,89.059,331},target={68.997,94.752}},
  }},
  [721]={dungeonName="Gnomeregan",xScale=11.250000,yScale=7.400000,entrances={
    {id=324,name="Gnomeregan Entrance",minimumLevel=15,serverPhase=0,exterior={82.488,60.886,1},target={23.004,88.635}},
    {id=523,name="Gnomeregan Back Entrance",minimumLevel=15,serverPhase=0,exterior={79.349,70.116,1},target={23.455,33.968}},
  }},
  [722]={dungeonName="Razorfen Downs",xScale=8.810000,yScale=5.890000,entrances={
    {id=442,name="Razorfen Downs Entrance",minimumLevel=25,serverPhase=0,exterior={49.082,7.064,17},target={81.865,84.835}},
  }},
  [1176]={dungeonName="Zul'Farrak",xScale=13.833300,yScale=9.229100,entrances={
    {id=924,name="Zul'Farrak Entrance",minimumLevel=35,serverPhase=0,exterior={61.290,80.468,440},target={43.400,9.047}},
  }},
  [1337]={dungeonName="Uldaman",xScale=8.936700,yScale=5.957800,entrances={
    {id=286,name="Uldaman Entrance",minimumLevel=30,serverPhase=0,exterior={64.806,90.102,3},target={32.971,27.294}},
    {id=902,name="Uldaman Back Entrance",minimumLevel=30,serverPhase=0,exterior={32.341,56.770,3},target={70.605,29.964}},
  }},
  [1477]={dungeonName="The Temple of Atal'Hakkar",xScale=6.950300,yScale=4.633500,entrances={
    {id=446,name="Sunken Temple Entrance",minimumLevel=35,serverPhase=0,exterior={22.584,64.564,8},target={50.712,86.893}},
  }},
  [1583]={dungeonName="Blackrock Spire",xScale=8.868400,yScale=5.912300,entrances={
    {id=1468,name="Blackrock Spire Entrance",minimumLevel=45,serverPhase=0,exterior={32.797,59.382,25},target={73.227,61.767}},
  }},
  [1584]={dungeonName="Blackrock Depths",xScale=19.850000,yScale=12.680000,entrances={
    {id=1466,name="Blackrock Depths Entrance",minimumLevel=40,serverPhase=0,exterior={72.448,27.622,51},target={57.637,16.714}},
  }},
  [1977]={dungeonName="Zul'Gurub",xScale=21.208301,yScale=14.145801,entrances={
    {id=3928,name="Zul'Gurub Entrance",minimumLevel=60,serverPhase=1,exterior={45.822,82.440,33},target={70.247,51.109}},
  }},
  [2017]={dungeonName="Stratholme",xScale=11.853499,yScale=7.898599,entrances={
    {id=2214,name="Stratholme Back Entrance",minimumLevel=45,serverPhase=0,exterior={51.556,78.207,139},target={15.351,27.452}},
    {id=2216,name="Stratholme Right Entrance",minimumLevel=45,serverPhase=0,exterior={68.706,84.212,139},target={36.289,2.390}},
    {id=2217,name="Stratholme Left Entrance",minimumLevel=45,serverPhase=0,exterior={69.610,84.215,139},target={38.870,2.380}},
  }},
  [2057]={dungeonName="Scholomance",xScale=3.200500,yScale=2.133700,entrances={
    {id=2567,name="Scholomance Entrance",minimumLevel=45,serverPhase=0,exterior={31.037,27.281,28},target={60.918,40.535}},
  }},
  [2100]={dungeonName="Maraudon",xScale=21.120901,yScale=14.108900,entrances={
    {id=3133,name="Maraudon Orange Entrance",minimumLevel=30,serverPhase=0,exterior={64.061,35.417,405},target={55.308,87.034}},
    {id=3134,name="Maraudon Purple Entrance",minimumLevel=30,serverPhase=0,exterior={69.497,45.493,405},target={47.772,68.482}},
  }},
  [2366]={dungeonName="Black Morass",xScale=10.858599,yScale=7.266101,entrances={
    {id=1632,name="Black Morass Entrance",minimumLevel=58,serverPhase=0,exterior={43.530,36.431,440},target={0.857,30.908}},
  }},
  [2437]={dungeonName="Ragefire Chasm",xScale=7.388600,yScale=4.925700,entrances={
    {id=2230,name="Ragefire Chasm Entrance",minimumLevel=8,serverPhase=0,exterior={46.766,51.307,1637},target={37.592,92.118}},
  }},
  [2557]={dungeonName="Dire Maul",xScale=19.190000,yScale=12.500000,entrances={
    {id=3183,name="Dire Maul Entrance",minimumLevel=45,serverPhase=0,exterior={35.141,70.565,357},target={39.517,27.396}},
    {id=3184,name="Dire Maul Entrance",minimumLevel=45,serverPhase=0,exterior={32.799,65.146,357},target={30.693,7.347}},
    {id=3185,name="Dire Maul Entrance",minimumLevel=45,serverPhase=0,exterior={23.486,64.139,357},target={3.909,24.446}},
    {id=3186,name="Dire Maul Entrance",minimumLevel=45,serverPhase=0,exterior={39.692,68.249,357},target={55.840,18.348}},
    {id=3187,name="Dire Maul Entrance",minimumLevel=45,serverPhase=0,exterior={39.676,70.317,357},target={55.809,26.249}},
    {id=3189,name="Dire Maul Entrance",minimumLevel=45,serverPhase=0,exterior={37.080,75.094,357},target={46.511,43.994}},
  }},
  [5077]={dungeonName="Crescent Grove",xScale=26.432100,yScale=17.511600,entrances={
    {id=5004,name="Crescent Grove Entrance",minimumLevel=32,serverPhase=0,exterior={48.460,22.390,331},target={57.740,82.649}},
  }},
  [5086]={dungeonName="Karazhan Crypt",xScale=5.467500,yScale=3.919697,entrances={
    {id=5008,name="Karazhan Crypt Entrance",minimumLevel=55,serverPhase=0,exterior={60.866,27.902,41},target={7.839,61.239}},
  }},
  [5087]={dungeonName="Stormwind Vault",xScale=3.545000,yScale=2.347400,entrances={
    {id=5002,name="Stormwind Vault Entrance",minimumLevel=58,serverPhase=0,exterior={37.294,41.402,1519},target={22.773,61.570}},
    {id=5003,name="Stormwind Vault Mirror Lake Entrance",minimumLevel=58,serverPhase=0,exterior={71.256,38.529,12},target={22.773,61.570}},
  }},
  [5103]={dungeonName="Hateforge Quarry",xScale=7.521199,yScale=5.103306,entrances={
    {id=5009,name="Hateforge Quarry Entrance",minimumLevel=48,serverPhase=0,exterior={2.774,41.511,46},target={87.200,44.032}},
  }},
  [5135]={dungeonName="Scarlet Monastery Library",xScale=3.201900,yScale=2.134600,entrances={
    {id=614,name="Scarlet Monastery Library Entrance",minimumLevel=20,serverPhase=0,exterior={14.617,67.543,85},target={86.148,74.844}},
  }},
  [5136]={dungeonName="Scarlet Monastery Graveyard",xScale=6.199800,yScale=4.133201,entrances={
    {id=45,name="Scarlet Monastery Graveyard Entrance",minimumLevel=20,serverPhase=0,exterior={15.203,69.689,85},target={16.468,17.035}},
  }},
  [5138]={dungeonName="The Deadmines",xScale=6.565900,yScale=4.349700,entrances={
    {id=78,name="Deadmines Entrance",minimumLevel=10,serverPhase=0,exterior={61.962,22.493,40},target={90.476,88.159}},
  }},
  [5153]={dungeonName="Scarlet Monastery Armory",xScale=6.126900,yScale=4.084600,entrances={
    {id=612,name="Scarlet Monastery Armory Entrance",minimumLevel=20,serverPhase=0,exterior={14.299,68.149,85},target={39.743,1.826}},
  }},
  [5163]={dungeonName="Scarlet Monastery Cathedral",xScale=7.033000,yScale=4.688701,entrances={
    {id=610,name="Scarlet Monastery Cathedral Entrance",minimumLevel=20,serverPhase=0,exterior={14.714,69.716,85},target={39.598,8.693}},
  }},
  [5204]={dungeonName="Black Morass",xScale=12.719902,yScale=8.454800,entrances={
    {id=1632,name="Black Morass Entrance",minimumLevel=58,serverPhase=0,exterior={43.530,36.431,440},target={40.002,10.708}},
  }},
  [5208]={dungeonName="Gilneas City",xScale=12.501801,yScale=8.374401,entrances={
    {id=5014,name="Gilneas City Entrance",minimumLevel=40,serverPhase=0,exterior={72.225,69.787,5179},target={15.807,59.486}},
  }},
}

function D:GetMapData(mapID)
  return self.byMap[tonumber(mapID)]
end

local function DistanceSquared(data,point,entrance)
  local target=entrance and entrance.target or nil
  if not target or not point then return nil end
  local px=tonumber(point.x or point[1])
  local py=tonumber(point.y or point[2])
  local tx=tonumber(target[1])
  local ty=tonumber(target[2])
  if not px or not py or not tx or not ty then return nil end

  -- Weight percentage axes by the current client WorldMapArea dimensions so
  -- "nearest entrance" follows physical instance geometry rather than treating
  -- every floor as a square.
  local dx=(px-tx)*(tonumber(data.xScale) or 1)
  local dy=(py-ty)*(tonumber(data.yScale) or 1)
  return dx*dx+dy*dy
end

function D:SelectForPoints(mapID,points)
  local data=self:GetMapData(mapID)
  if not data then return {} end
  local entrances=data.entrances or {}
  local entranceCount=table.getn(entrances)
  if entranceCount<=1 then
    if entranceCount==1 then return {entrances[1]} end
    return {}
  end

  -- Multiple valid doorways (Gnomeregan, Uldaman, Maraudon, Stratholme,
  -- Dire Maul, Stormwind Vault) are selected from their authoritative inside
  -- teleport destinations. If we have no internal point, fail safe instead of
  -- guessing and covering the outdoor map with every entrance.
  if not points or table.getn(points)==0 then return {} end

  local selected={}
  for _,point in pairs(points) do
    local bestDistance=nil
    local tied={}
    for _,entrance in pairs(entrances) do
      local distance=DistanceSquared(data,point,entrance)
      if distance then
        if not bestDistance or distance<bestDistance-0.0001 then
          bestDistance=distance
          tied={entrance}
        elseif math.abs(distance-bestDistance)<=0.0001 then
          table.insert(tied,entrance)
        end
      end
    end
    for _,entrance in pairs(tied) do selected[entrance.id]=entrance end
  end

  local result={}
  for _,entrance in pairs(entrances) do
    if selected[entrance.id] then table.insert(result,entrance) end
  end
  return result
end
