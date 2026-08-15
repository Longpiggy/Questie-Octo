QuestieOcto.Options = QuestieOcto.Options or {}
local O = QuestieOcto.Options

O.configFrame=nil
O.initialized=false
O.openedFromGameMenu=false
O.stats={
  initializes=0,opens=0,closes=0,changes=0,
  lastSetKey="none",lastSetValue="none",
  aceGUI=false,aceRegistry=false,aceDialog=false
}

local APP_NAME="Questie Options"

-- ShaguTweaks' Darkened UI is the Vanilla compatibility reference here.
-- Keep the original Questie outer-shell tint, but treat the AceConfig content
-- like ShaguTweaks' Advanced Options: dark translucent backdrops instead of a
-- recursive gray vertex-color wash over every descendant texture.
local SHELL_R,SHELL_G,SHELL_B,SHELL_A=0.30,0.30,0.30,0.90
local INNER_R,INNER_G,INNER_B,INNER_A=0.035,0.035,0.035,0.84
local INNER_BORDER_R,INNER_BORDER_G,INNER_BORDER_B,INNER_BORDER_A=0.20,0.20,0.20,0.95
local TAB_R,TAB_G,TAB_B,TAB_A=0.28,0.28,0.28,1.0

local function ShouldSkipShellTexture(region)
  if not region or not region.GetTexture then return true end
  local texture=region:GetTexture()
  if not texture then return true end

  local name=region.GetName and region:GetName() or nil
  if name then
    if string.find(name,"Button",1,true) or string.find(name,"Icon",1,true) then return true end
  end

  if type(texture)=="string" then
    if string.find(texture,"Button",1,true)
       or string.find(texture,"Icon",1,true)
       or string.find(texture,"WHITE8X8",1,true)
       or string.find(texture,"StatusBar",1,true)
       or string.find(texture,"BarFill",1,true)
       or string.find(texture,"Portrait",1,true) then
      return true
    end
  end

  if region.GetBlendMode and region:GetBlendMode()=="ADD" then return true end
  return false
end

-- Only tint the physical AceGUI Frame itself. This preserves the successful
-- outer-frame look from 0.1.81 without washing the entire options contents gray.
local function DarkenOuterShell(frame)
  if not frame then return end

  if frame.SetBackdropBorderColor then
    frame:SetBackdropBorderColor(SHELL_R,SHELL_G,SHELL_B,SHELL_A)
  end

  if frame.GetRegions then
    local regions={frame:GetRegions()}
    for _,region in pairs(regions) do
      if region and region.GetObjectType and region:GetObjectType()=="Texture"
         and region.SetVertexColor and not ShouldSkipShellTexture(region) then
        region:SetVertexColor(SHELL_R,SHELL_G,SHELL_B,SHELL_A)
      end
    end
  end
end

local function IsTabTexture(region)
  if not region or not region.GetTexture then return false end
  local texture=region:GetTexture()
  return type(texture)=="string" and string.find(texture,"ChatFrameTab",1,true) and true or false
end

-- AceGUI's ScrollFrame places a UIPanelScrollBarTemplate just outside the
-- scrolling viewport. Keep that native Vanilla control above Questie's dark
-- content panels and do not recolor it as if it were a backdrop container.
local function IsAceConfigScrollbar(frame)
  if not frame or not frame.GetName then return false end
  local name=frame:GetName()
  return name and string.find(name,"AceConfigDialogScrollFrame",1,true)
              and string.find(name,"ScrollBar",1,true) and true or false
end

local function RaiseScrollbar(frame)
  if not frame then return end

  if IsAceConfigScrollbar(frame) then
    local parent=frame.GetParent and frame:GetParent() or nil
    local base=(parent and parent.GetFrameLevel and parent:GetFrameLevel()) or 0
    if frame.SetFrameLevel then frame:SetFrameLevel(base+20) end

    -- Vanilla's UIPanelScrollBarTemplate thumb artwork is wider than the
    -- 16-pixel Slider frame used by AceGUI. On the 1.12 client that narrow
    -- slider can crop the outer edge of the native thumb texture even though
    -- the control is correctly positioned in the right gutter. Give the
    -- slider its native visual width instead of moving it inward; this lets the
    -- full thumb render at the same right-side location.
    if frame.SetWidth and (not frame.questieOctoFullThumbWidth) then
      frame:SetWidth(20)
      frame.questieOctoFullThumbWidth=true
    end

    -- UIPanelScrollBarTemplate's arrow buttons and thumb artwork are children/
    -- regions of the slider. Raising them too avoids client-specific 1.12
    -- ordering where the thumb can otherwise appear partly behind the panel.
    if frame.GetChildren then
      local children={frame:GetChildren()}
      for _,child in pairs(children) do
        if child and child.SetFrameLevel then child:SetFrameLevel(base+21) end
      end
    end
    return
  end

  if frame.GetChildren then
    local children={frame:GetChildren()}
    for _,child in pairs(children) do
      RaiseScrollbar(child)
    end
  end
end

-- ShaguTweaks' own config builds dark panels by coloring frame backdrops
-- (.1/.1/.1) rather than painting a gray vertex color over all child regions.
-- Do the same for Questie's AceGUI content tree. Backdrop-less controls remain
-- untouched; their native checkbox/slider/button artwork therefore stays crisp.
local function DarkenInnerContent(frame)
  if not frame then return end

  -- Leave the native Vanilla scrollbar completely untouched by the panel
  -- darkening pass. It is a control, not a content backdrop.
  if IsAceConfigScrollbar(frame) then return end

  if frame.SetBackdropColor then
    frame:SetBackdropColor(INNER_R,INNER_G,INNER_B,INNER_A)
  end
  if frame.SetBackdropBorderColor then
    frame:SetBackdropBorderColor(INNER_BORDER_R,INNER_BORDER_G,INNER_BORDER_B,INNER_BORDER_A)
  end

  -- The top Questie tabs use ChatFrameTab textures instead of a backdrop.
  -- Tint only that known decorative texture; do not touch checkbox, slider,
  -- icon, highlight or status-bar artwork.
  if frame.GetRegions then
    local regions={frame:GetRegions()}
    for _,region in pairs(regions) do
      if region and region.GetObjectType and region:GetObjectType()=="Texture"
         and region.SetVertexColor and IsTabTexture(region) then
        region:SetVertexColor(TAB_R,TAB_G,TAB_B,TAB_A)
      end
    end
  end

  if frame.GetChildren then
    local children={frame:GetChildren()}
    for _,child in pairs(children) do
      DarkenInnerContent(child)
    end
  end
end

function O:ApplyDarkTheme()
  if not self.configFrame or not self.configFrame.frame then return end

  local shell=self.configFrame.frame
  DarkenOuterShell(shell)

  -- Apply the inner treatment only below the outer shell. Keeping the shell
  -- separate is important because its DialogFrame textures need vertex tinting,
  -- while AceConfig's content containers look better with dark backdrops.
  if shell.GetChildren then
    local children={shell:GetChildren()}
    for _,child in pairs(children) do
      DarkenInnerContent(child)
    end
  end

  -- Run after backdrop darkening so the scrollbar is always the final/top UI
  -- layer, including after AceConfig rebuilds the currently selected tab.
  RaiseScrollbar(shell)
end

local function Settings()
  return QuestieOcto.MinimapSettings
end

local function ClearSavedConfigPosition()
  local Dialog=LibStub and LibStub("AceConfigDialog-3.0",true)
  if not Dialog or not Dialog.GetStatusTable then return end

  local status=Dialog:GetStatusTable(APP_NAME)
  if status then
    status.top=nil
    status.left=nil
  end
end

local function GetValue(info)
  local key=info[table.getn(info)]
  return Settings():Get(key)
end

local function SetValue(info,value)
  local key=info[table.getn(info)]
  O.stats.lastSetKey=tostring(key or "nil")
  O.stats.lastSetValue=tostring(value)
  local changed=Settings():Set(key,value)
  if changed then
    O.stats.changes=O.stats.changes+1
  end

  -- AceConfigDialog refreshes the custom frame immediately after setters.
  -- Clear AceGUI's persisted drag coordinates before that refresh happens.
  ClearSavedConfigPosition()
end

local function EnabledMinimap()
  return Settings():Get("enableMiniMapIcons") and true or false
end


local function CreateGeneralTab()
  return {
    name="General", type="group", order=1,
    args={
      icon_header={type="header",order=1,name="Icon Settings"},
      enableMapIcons={type="toggle",order=2,name="Enable Map Icons",desc="Show/hide all Questie icons from the main map.",width="full",get=GetValue,set=SetValue},
      world_map_visibility_header={type="header",order=3,name="World Map Visibility"},
      showAllQuestsWorldMap={type="toggle",order=3.1,name="Show Quests on the World Map",desc="Show normal available quest-start/pickup markers and normal completed quest turn-in markers on continent/world overview maps. Selected zone and city maps are unaffected. Special repeatable, PvP and verified event quest markers are controlled by the next option. Objective/slay/full-node/cluster markers are controlled separately. Minimap and tracker visibility are unchanged. ( Default: enabled )",width="full",get=GetValue,set=SetValue},
      showSpecialQuestsWorldMap={type="toggle",order=3.2,name="Show Special Quests on the World Map",desc="Show special quest pickup/turn-in markers on continent/world overview maps: repeatable quests (blue), PvP quests (red), and verified active event quests (green). Selected zone and city maps are unaffected. Objective markers are unaffected. ( Default: disabled )",width="full",get=GetValue,set=SetValue},
      showMapFlightMaster={type="toggle",order=3.3,name="Show Flight Master on the World Map",desc="Show or hide Flight Master markers on the World Map only. Minimap Flight Masters remain controlled independently. ( Default: enabled )",width="full",get=GetValue,set=SetValue},
      enableMiniMapIcons={type="toggle",order=4,name="Enable Minimap Icons",desc="Show/hide all Questie icons from the minimap.",width="full",get=GetValue,set=SetValue},
      type_header={type="header",order=5,name="Quest Icon Types"},
      enableObjectives={type="toggle",order=5,name="Enable Objective Icons",desc="Show active quest objective icons on the map and minimap.",width="full",get=GetValue,set=SetValue},
      enableTurnins={type="toggle",order=6,name="Enable Completed Quest Icons",desc="Show quest turn-in locations on the map and minimap.",width="full",get=GetValue,set=SetValue},
      enableAvailable={type="toggle",order=7,name="Enable Available Quest Icons",desc="Show available quest locations on the map and minimap.",width="full",get=GetValue,set=SetValue},

      objective_nodes={type="group",order=8,name="Objective Nodes",inline=true,args={
        objectiveNodeDensity={type="select",order=1,name="Objective Node Density",desc="Clustered groups nearby spawn points for readability. Full Nodes shows every known creature/object spawn coordinate using compact pfQuest-style spawn markers.",width="double",values={clustered="Clustered",full="Full Nodes"},get=GetValue,set=SetValue},
      }},

      item_start_options={type="group",order=9,name="Item-Start Quests",inline=true,args={
        showItemStartQuests={type="toggle",order=1,name="Show Item-Start Quests",desc="Master toggle for quest markers whose quest begins from a dropped or looted item.",width="full",get=GetValue,set=SetValue},
        showItemStartMap={type="toggle",order=2,name="Show on World Map",desc="Show item-start quest source markers on the world map.",width="full",disabled=function() return not Settings():Get("showItemStartQuests") end,get=GetValue,set=SetValue},
        showItemStartMinimap={type="toggle",order=3,name="Show on Minimap",desc="Show item-start quest source markers on the minimap.",width="full",disabled=function() return not Settings():Get("showItemStartQuests") end,get=GetValue,set=SetValue},
        itemStartDensity={type="select",order=4,name="Node Density",desc="Clustered combines nearby item-start sources into hunting areas. Full Nodes shows every known source spawn coordinate.",width="double",values={clustered="Clustered",full="Full Nodes"},disabled=function() return not Settings():Get("showItemStartQuests") end,get=GetValue,set=SetValue},
      }},

      quest_options={type="group",order=10,name="Quest Options",inline=true,args={
        questLogShowLevels={type="toggle",order=1,name="Show Quest Levels",desc="Show the quest level before each quest title in the native Quest Log.",width="full",get=GetValue,set=SetValue},
        showLowLevelQuests={type="toggle",order=2,name="Show Low-Level Quests",desc="Show otherwise-valid quests below the normal green quest range. Use Levels Below to limit how far below your current level they are shown. Questie-Octo default: enabled.",get=GetValue,set=SetValue},
        lowLevelQuestRange={type="range",order=2.1,name=function()
          local value=tonumber(Settings():Get("lowLevelQuestRange")) or 35
          if value>=35 then return "Levels Below: All" end
          return "Levels Below: "..tostring(value)
        end,desc="How many displayed quest levels below your current level may be shown. Example: at level 60, 15 shows level 45+ quests. All preserves the unrestricted low-level quest view. ( Default: All )",width="normal",min=5,max=35,step=5,arg={questieHideEditBox=true,questieMaxLabel="All",questieCommitOnMouseUp=true,questieLiveLabelPrefix="Levels Below: "},disabled=function() return not Settings():Get("showLowLevelQuests") end,get=GetValue,set=SetValue},
        showRepeatableQuests={type="toggle",order=3,name="Show Repeatable Quests",desc="Show available repeatable quests. Active objectives and turn-ins remain visible. ( Default: enabled )",width="full",get=GetValue,set=SetValue},
        showEventQuests={type="toggle",order=4,name="Show Event Quests",desc="Show or hide available event quests on the map and minimap. Event quests use Questie's event quest artwork. Accepted objectives and turn-ins remain visible. ( Default: disabled )",width="full",get=GetValue,set=SetValue},
        showPvPRelatedQuests={type="toggle",order=5,name="Show PVP Related Quests",desc="Show or hide PvP-related quest markers on the map and minimap. When disabled, all PvP quest markers are hidden, including available quests, active objectives, and turn-ins. ( Default: enabled )",width="full",get=GetValue,set=SetValue},
      }},
      reset_header={type="header",order=90,name="Reset Questie Options"},
      reset_text={type="description",order=91,name="Restore Questie-Octo options to their defaults. Quest data and completed-quest history are not deleted.",fontSize="medium"},
      resetOptions={type="execute",order=92,name="Reset Options",desc="Reset Questie-Octo presentation and availability options.",func=function()
        Settings():Reset()
        ClearSavedConfigPosition()
        local Registry=LibStub and LibStub("AceConfigRegistry-3.0",true)
        if Registry and Registry.NotifyChange then Registry:NotifyChange(APP_NAME) end
      end},
    },
  }
end

local function CreateMapTab()
  return {
    name="Map", type="group", order=10,
    args={
      map_options={type="header",order=1,name="Map Options"},
      alwaysGlowMap={type="toggle",order=1.1,name="Enable Map Icon Glow",desc="Draw Questie's glow texture behind objective map icons, colored uniquely per objective. ( Default: disabled )",width="full",get=GetValue,set=SetValue},
      questObjectiveColors={type="toggle",order=1.2,name="Enable Different Map Icon Color for Each Quest",desc="Tint objective map icons with Questie's deterministic per-quest color.",width="full",get=GetValue,set=SetValue},
      notes_header={type="header",order=2,name="Map Note Options"},
      globalScale={type="range",order=2.2,name="Global Scale for Map Icons",desc="How large the Map Icons are. Full Nodes use pfQuest's native 14px baseline at scale 1. ( Default: 1 )",width="double",min=0.01,max=4,step=0.01,disabled=function() return not Settings():Get("enableMapIcons") end,get=GetValue,set=SetValue},

      miscellaneous_icons={type="header",order=20,name="Miscellaneous icons"},
      showMapRareMonsters={type="toggle",order=20.1,name="Rare Monsters",desc="Show Rare Monster icons on the World Map.",width="full",get=GetValue,set=SetValue},
      showMapAuctioneer={type="toggle",order=20.2,name="Auctioneer",desc="Show Auctioneer icons on the World Map.",width="full",get=GetValue,set=SetValue},
      showMapBanker={type="toggle",order=20.3,name="Banker",desc="Show Banker icons on the World Map.",width="full",get=GetValue,set=SetValue},
      showMapFlightMaster={type="toggle",order=20.4,name="Flight Master",desc="Show Flight Master icons on the World Map.",width="full",get=GetValue,set=SetValue},
      showMapMailbox={type="toggle",order=20.5,name="Mailbox",desc="Show Mailbox icons on the World Map.",width="full",get=GetValue,set=SetValue},
      showMapBattlemaster={type="toggle",order=20.6,name="Battlemaster",desc="Show Battlemaster icons on the World Map. ( Default: disabled )",width="full",get=GetValue,set=SetValue},
      showMapInnkeeper={type="toggle",order=20.7,name="Innkeeper",desc="Show Innkeeper icons on the World Map. ( Default: disabled )",width="full",get=GetValue,set=SetValue},
      showMapMeetingStone={type="toggle",order=20.8,name="Meeting Stones",desc="Show Meeting Stone icons on the World Map. ( Default: disabled )",width="full",get=GetValue,set=SetValue},
      showMapRepair={type="toggle",order=20.9,name="Repair",desc="Show Repair icons on the World Map. ( Default: disabled )",width="full",get=GetValue,set=SetValue},
      showMapSpiritHealer={type="toggle",order=21.0,name="Spirit Healer",desc="Show Spirit Healer icons on the World Map. ( Default: disabled )",width="full",get=GetValue,set=SetValue},
      showMapStableMaster={type="toggle",order=21.1,name="Stable Master",desc="Show Stable Master icons on the World Map. ( Default: disabled )",width="full",get=GetValue,set=SetValue},
      showMapVendor={type="toggle",order=21.2,name="Vendor",desc="Show Vendor icons on the World Map. ( Default: disabled )",width="full",get=GetValue,set=SetValue},
    },
  }
end

local function CreateMinimapTab()
  return {
    name="Minimap", type="group", order=11,
    args={
      options_header={type="header",order=1,name="Minimap Options"},
      alwaysGlowMinimap={type="toggle",order=1.1,name="Enable Minimap Icon Glow",desc="Draw Questie's glow texture behind objective minimap icons, colored uniquely per objective.",width="full",disabled=function() return not EnabledMinimap() end,get=GetValue,set=SetValue},
      questMinimapObjectiveColors={type="toggle",order=1.2,name="Enable Different Minimap Icon Color for Each Quest",desc="Tint objective minimap icons with Questie's deterministic per-quest color.",width="full",disabled=function() return not EnabledMinimap() end,get=GetValue,set=SetValue},
      notes_header={type="header",order=2,name="Minimap Note Options"},
      globalMiniMapScale={type="range",order=2.2,name="Global Scale for Minimap Icons",desc="How large the Minimap icons are. Full Nodes use pfQuest's native 14px baseline at scale 1. ( Default: 1 )",width="double",min=0.01,max=4,step=0.01,disabled=function() return not EnabledMinimap() end,get=GetValue,set=SetValue},

      miscellaneous_icons={type="header",order=20,name="Miscellaneous icons"},
      showMinimapRareMonsters={type="toggle",order=20.1,name="Rare Monsters",desc="Show Rare Monster icons on the Minimap.",width="full",get=GetValue,set=SetValue},
      showMinimapAuctioneer={type="toggle",order=20.2,name="Auctioneer",desc="Show Auctioneer icons on the Minimap.",width="full",get=GetValue,set=SetValue},
      showMinimapBanker={type="toggle",order=20.3,name="Banker",desc="Show Banker icons on the Minimap.",width="full",get=GetValue,set=SetValue},
      showMinimapFlightMaster={type="toggle",order=20.4,name="Flight Master",desc="Show Flight Master icons on the Minimap.",width="full",get=GetValue,set=SetValue},
      showMinimapMailbox={type="toggle",order=20.5,name="Mailbox",desc="Show Mailbox icons on the Minimap.",width="full",get=GetValue,set=SetValue},
      showMinimapBattlemaster={type="toggle",order=20.6,name="Battlemaster",desc="Show Battlemaster icons on the Minimap. ( Default: disabled )",width="full",get=GetValue,set=SetValue},
      showMinimapInnkeeper={type="toggle",order=20.7,name="Innkeeper",desc="Show Innkeeper icons on the Minimap. ( Default: disabled )",width="full",get=GetValue,set=SetValue},
      showMinimapMeetingStone={type="toggle",order=20.8,name="Meeting Stones",desc="Show Meeting Stone icons on the Minimap. ( Default: disabled )",width="full",get=GetValue,set=SetValue},
      showMinimapRepair={type="toggle",order=20.9,name="Repair",desc="Show Repair icons on the Minimap. ( Default: disabled )",width="full",get=GetValue,set=SetValue},
      showMinimapSpiritHealer={type="toggle",order=21.0,name="Spirit Healer",desc="Show Spirit Healer icons on the Minimap. ( Default: disabled )",width="full",get=GetValue,set=SetValue},
      showMinimapStableMaster={type="toggle",order=21.1,name="Stable Master",desc="Show Stable Master icons on the Minimap. ( Default: disabled )",width="full",get=GetValue,set=SetValue},
      showMinimapVendor={type="toggle",order=21.2,name="Vendor",desc="Show Vendor icons on the Minimap. ( Default: disabled )",width="full",get=GetValue,set=SetValue},
    },
  }
end

local function CreateTrackerTab()
  return {
    name="Tracker", type="group", order=12,
    args={
      tracker_header={type="header",order=1,name="Tracker Options"},
      trackerEnabled={type="toggle",order=2,name="Enable Quest Tracker",desc="Show or hide the Questie quest/objective tracker.",width="full",get=GetValue,set=SetValue},
      resetTracker={type="execute",order=2.5,name="Reset Tracker Position",desc="Return the Questie tracker to its default top-right position.",func=function()
        if QuestieOcto.TrackerFrame and QuestieOcto.TrackerFrame.ResetLocation then QuestieOcto.TrackerFrame:ResetLocation() end
      end},
      trackerLocked={type="toggle",order=3,name="Lock Tracker",desc="Prevent the Questie tracker from being moved.",width="full",get=GetValue,set=SetValue},
      trackerAutoTrack={type="toggle",order=4,name="Auto Track Quests",desc="Automatically track accepted quests. Shift + Left Click a quest in the Quest Log to manually remove or restore it.",width="full",get=GetValue,set=SetValue},
      trackerShowCompleted={type="toggle",order=5,name="Show Completed Quests",desc="Keep completed quests visible in the tracker until they are turned in.",width="full",get=GetValue,set=SetValue},
      trackerHideCompletedObjectives={type="toggle",order=6,name="Hide Completed Objectives",desc="Hide objective lines once that individual objective is complete.",width="full",get=GetValue,set=SetValue},
      sorting_header={type="header",order=10,name="Sorting"},
      trackerSort={type="select",order=11,name="Sort Quests",desc="Choose how tracked quests are ordered.",width="double",values={zone="Zone",proximity="Proximity",level="Level"},get=GetValue,set=SetValue},
      appearance_header={type="header",order=20,name="Appearance"},
      trackerHideInCombat={type="toggle",order=12,name="Hide Tracker in Combat",desc="Temporarily hide the Questie tracker while you are in combat. Tracking and collapse state are unchanged.",width="full",get=GetValue,set=SetValue},
      trackerOutlineText={type="toggle",order=20.1,name="Outline",desc="Use WoW's OUTLINE font flag for tracker text. Temporary comparison option.",width="full",get=GetValue,set=SetValue},
      trackerThickOutlineText={type="toggle",order=20.2,name="Thick Outline",desc="Use WoW's THICKOUTLINE font flag for tracker text. Enabling this disables Outline so the two styles can be compared cleanly.",width="full",get=GetValue,set=SetValue},
      trackerFontSize={type="range",order=21,name="Tracker Font Size",desc="Font size used by the Questie tracker. ( Default: 11 )",width="double",min=8,max=18,step=1,get=GetValue,set=SetValue},
      trackerMaxWidth={type="range",order=22,name="Maximum Tracker Width",desc="Maximum width of the Questie tracker in pixels. Long objectives wrap inside this width. ( Default: 280 )",width="double",min=200,max=500,step=10,get=GetValue,set=SetValue},
      trackerVisibleRows={type="range",order=23,name="Visible Rows",desc="Maximum number of complete tracker rows shown at once. The tracker height is calculated automatically so text is never partially cropped. ( Default: 30 )",width="double",min=6,max=60,step=1,get=GetValue,set=SetValue},
      trackerBackgroundOpacity={type="range",order=24,name="Tracker Background Opacity",desc="Opacity of the tracker background. 0 is fully transparent, matching old Questie's default tracker presentation. ( Default: 0 )",width="double",min=0,max=1,step=0.05,get=GetValue,set=SetValue},
      manual_hint={type="description",order=30,name="Shift + Left Click a quest in the Quest Log to track or untrack it manually.",fontSize="medium"},
    },
  }
end

local function CreateTooltipTab()
  return {
    name="Tooltips", type="group", order=13,
    args={
      header={type="header",order=1,name="Tooltip Options"},
      enableTooltips={type="toggle",order=2,name="Enable Questie Tooltips",desc="Enable Questie information on map/minimap markers and when hovering relevant creatures, items, and game objects.",width="full",get=GetValue,set=SetValue},
      enableTooltipsQuestLevel={type="toggle",order=3,name="Show Quest Levels",desc="Show the quest level before the quest title.",width="full",disabled=function() return not Settings():Get("enableTooltips") end,get=GetValue,set=SetValue},
      enableTooltipDroprates={type="toggle",order=4,name="Show Drop Rates",desc="Show database drop-rate percentages for item objectives and item-start quests.",width="full",disabled=function() return not Settings():Get("enableTooltips") end,get=GetValue,set=SetValue},
      id_header={type="header",order=10,name="Tooltip IDs"},
      enableTooltipsQuestID={type="toggle",order=11,name="Show Quest IDs",desc="Append quest IDs to Questie quest titles.",width="full",disabled=function() return not Settings():Get("enableTooltips") end,get=GetValue,set=SetValue},
      enableTooltipsNPCID={type="toggle",order=12,name="Show NPC IDs",desc="Show creature/NPC database IDs in Questie tooltips.",width="full",disabled=function() return not Settings():Get("enableTooltips") end,get=GetValue,set=SetValue},
      enableTooltipsItemID={type="toggle",order=13,name="Show Item IDs",desc="Show item database IDs in Questie tooltips.",width="full",disabled=function() return not Settings():Get("enableTooltips") end,get=GetValue,set=SetValue},
    },
  }
end


local function CreateOptionsTable()
  return {
    name="Questie Options",
    type="group",
    childGroups="tab",
    args={
      general_tab=CreateGeneralTab(),
      map_tab=CreateMapTab(),
      minimap_tab=CreateMinimapTab(),
      tracker_tab=CreateTrackerTab(),
      tooltip_tab=CreateTooltipTab(),
      quests_tab=QuestieOcto.QuestResearch:GetOptionsTab(),
    },
  }
end

function O:Initialize()
  if self.initialized then return true end

  local AceGUI=LibStub and LibStub("AceGUI-3.0",true)
  local Registry=LibStub and LibStub("AceConfigRegistry-3.0",true)
  local Dialog=LibStub and LibStub("AceConfigDialog-3.0",true)

  self.stats.aceGUI=AceGUI and true or false
  self.stats.aceRegistry=Registry and true or false
  self.stats.aceDialog=Dialog and true or false

  if not AceGUI or not Registry or not Dialog then
    QuestieOcto:Error("Questie-style AceConfig runtime unavailable")
    return false
  end

  -- Equivalent to Questie 5/6 RegisterOptionsTable(), without AceConfigCmd.
  -- We intentionally avoid Blizzard InterfaceOptions registration on 1.12.
  Registry:RegisterOptionsTable(APP_NAME,CreateOptionsTable())

  -- Questie 5.2.3/6.0.0/3.3.5 create a standalone AceGUI Frame, then feed
  -- AceConfigDialog into that frame and keep it for later toggling.
  local configFrame=AceGUI:Create("Frame")
  configFrame:Hide()

  Dialog:SetDefaultSize(APP_NAME,625,700)
  Dialog:Open(APP_NAME,configFrame)
  configFrame:SetLayout("Fill")

  -- Questie 5/6/3.3.5 use one persistent AceGUI frame as the options shell.
  -- On this Vanilla/Ace3v runtime, AceConfigDialog calls SetStatusTable() on
  -- that same custom root frame after every option activation. AceGUI Frame's
  -- SetStatusTable() immediately runs ApplyStatus(), which clears/reanchors the
  -- physical frame. Turtle's 1.12 layout path can therefore visibly jump the
  -- window even when status.top/status.left are nil.
  --
  -- The mature Questie behavior we need is simpler: refresh the option widgets,
  -- not the already-open outer shell. The frame is non-resizable here, so after
  -- its initial Questie size has been applied there is no legitimate refresh
  -- reason to re-run outer-frame geometry. Preserve the status table for Ace3
  -- semantics, but deliberately do not call ApplyStatus() on later refreshes.
  if configFrame.SetStatusTable then
    configFrame.SetStatusTable=function(self,status)
      if status then
        status.top=nil
        status.left=nil
        self.status=status
      end
    end
  end

  if configFrame.EnableResize then
    configFrame:EnableResize(false)
  end

  configFrame:Hide()
  self.configFrame=configFrame

  -- Questie 5.2.3/6.0.0/3.3.5/7/8 register the actual standalone
  -- AceGUI config object in UISpecialFrames through a global name. The widget
  -- already exposes IsShown()/Hide(), so Vanilla ESC can close the real shell
  -- directly; no hidden proxy frame is required.
  QuestieOctoConfigFrame=configFrame
  local registered=false
  for _,name in pairs(UISpecialFrames or {}) do
    if name=="QuestieOctoConfigFrame" then registered=true break end
  end
  if not registered then
    table.insert(UISpecialFrames,"QuestieOctoConfigFrame")
  end

  -- Vanilla GameMenu compatibility: when Questie Options was opened from ESC,
  -- closing it returns to the Game Menu, matching ShaguTweaks' proven 1.12 flow.
  -- Slash-command opens do not trigger this behavior.
  configFrame:SetCallback("OnClose",function()
    O.stats.closes=O.stats.closes+1
    if O.openedFromGameMenu then
      O.openedFromGameMenu=false
      if GameMenuFrame and ShowUIPanel then
        ShowUIPanel(GameMenuFrame)
      end
      if UpdateMicroButtons then UpdateMicroButtons() end
    end
  end)

  self.initialized=true
  self.stats.initializes=self.stats.initializes+1

  -- QuestieOctoConfigFrame above is the UISpecialFrames participant, matching
  -- the supplied Questie options architecture.

  return true
end

local function RecenterConfigFrame(configFrame)
  ClearSavedConfigPosition()

  if not configFrame or not configFrame.frame then return end
  local frame=configFrame.frame

  -- Keep Questie's persistent AceGUI frame architecture, but make drag
  -- placement temporary: every explicit open returns to the default center.
  if frame.ClearAllPoints then frame:ClearAllPoints() end
  if frame.SetPoint then frame:SetPoint("CENTER",UIParent,"CENTER",0,0) end
end

function O:Show()
  if not self:Initialize() then return end

  local Dialog=LibStub("AceConfigDialog-3.0")
  -- Questie 3.3.5 refreshes the existing standalone frame through Open().
  Dialog:Open(APP_NAME,self.configFrame)
  RecenterConfigFrame(self.configFrame)
  self:ApplyDarkTheme()
  self.stats.opens=self.stats.opens+1
end

function O:Hide()
  if self.configFrame and self.configFrame:IsShown() then
    self.configFrame:Hide()
  end
end

function O:ShowFromGameMenu()
  self.openedFromGameMenu=true
  self:Show()
end

function O:Toggle()
  if not self:Initialize() then return end
  if self.configFrame:IsShown() then
    self:Hide()
  else
    self:Show()
  end
end

-- Build the hidden frame after login rather than during file load.
QuestieOcto.Scheduler:After(0.10,function()
  O:Initialize()
end,"questie-options-init")
