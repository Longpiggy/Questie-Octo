QuestieOcto.GameMenu = QuestieOcto.GameMenu or {}
local GM = QuestieOcto.GameMenu

GM.button=nil
GM.installed=false
GM.stats={ installs=0,clicks=0,anchor="none" }

local function Install()
  if GM.installed then return end
  if not GameMenuFrame or not GameMenuButtonUIOptions or not GameMenuButtonKeybindings then
    return
  end

  -- ShaguTweaks uses GameMenuButtonTemplate and inserts its Advanced Options
  -- button between Blizzard Options and Key Bindings. Preserve that exact
  -- Vanilla-safe presentation mechanic while coexisting with ShaguTweaks.
  local anchor=GameMenuButtonAdvancedOptions or GameMenuButtonUIOptions

  local button=CreateFrame(
    "Button",
    "GameMenuButtonQuestieOctoOptions",
    GameMenuFrame,
    "GameMenuButtonTemplate"
  )
  GM.button=button

  button:SetPoint("TOP",anchor,"BOTTOM",0,-1)
  button:SetText("Questie Options")
  button:SetScript("OnClick",function()
    GM.stats.clicks=GM.stats.clicks+1

    if HideUIPanel then
      HideUIPanel(GameMenuFrame)
    else
      GameMenuFrame:Hide()
    end

    if QuestieOcto.Options and QuestieOcto.Options.ShowFromGameMenu then
      QuestieOcto.Options:ShowFromGameMenu()
    elseif QuestieOcto.Options then
      QuestieOcto.Options:Show()
    end
  end)

  -- Make room for one additional standard GameMenu button.
  GameMenuFrame:SetHeight(GameMenuFrame:GetHeight()+32)

  GameMenuButtonKeybindings:ClearAllPoints()
  GameMenuButtonKeybindings:SetPoint("TOP",button,"BOTTOM",0,-1)

  GM.installed=true
  GM.stats.installs=GM.stats.installs+1
  GM.stats.anchor=(anchor==GameMenuButtonAdvancedOptions) and "Shagu Advanced Options" or "Blizzard Options"
end

-- Install after all addons have loaded so ShaguTweaks, when present, has
-- already inserted GameMenuButtonAdvancedOptions. This prevents load-order
-- fights over Key Bindings anchoring.
local events=CreateFrame("Frame","QuestieOctoGameMenuInstaller",UIParent)
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent",function()
  QuestieOcto.Scheduler:After(0.10,Install,"questie-gamemenu-install")
end)
