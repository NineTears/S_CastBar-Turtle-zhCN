local S_CastBar_Tooltip = AceLibrary("Gratuity-2.0")
local InCasting_SpellName, S_icon, CastSpellName, ShowAimed = nil, nil, nil, false
local dir = "Interface\\Icons\\"
CastingBarFrame:RegisterEvent("VARIABLES_LOADED")
CastingBarFrame:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")

--没有技能图标的请在这里添加
local DefaultIcons = {
	["采集草药"]	= "spell_nature_naturetouchgrow",
	["采矿"]		= "trade_mining",
	["剥皮"]		= "inv_misc_pelt_wolf_01",
	["开锁"]		= "INV_Misc_Gear_03",
	["火炮"]		= "INV_Ammo_Bullet_01",
}

--支持Clique点击施法插件显示技能图标
local Clique_Click_Frame = {
	"PlayerFrame",
	"PetFrame",
	"PartyMemberFrame",
	"TargetFrame",
	"TargetofTargetFrame",
	"NotGridContainer",
}

--引导法术增加跳数
local SpellToTicks = {
    -- 术士
	["吸取灵魂"]	= 5,
	["火焰之雨"]	= 4,
    -- 德鲁伊
	["宁静"]		= 4,
    -- 牧师
	["精神鞭笞"]	= 3,
	-- 法师
	["暴风雪"]		= 8,
}

--技能图标
CastingBarFrame.Icon = CreateFrame("Frame", nil, CastingBarFrame)
CastingBarFrame.Icon:SetWidth(22)
CastingBarFrame.Icon:SetHeight(22)
CastingBarFrame.Icon:SetPoint("RIGHT", CastingBarFrame, "LEFT", -10, 2.5)
CastingBarFrame.Icon.Texture = CastingBarFrame.Icon:CreateTexture(nil, "ARTWORK")
CastingBarFrame.Icon.Texture:SetAllPoints()
CastingBarFrame.Icon.Texture:SetTexCoord(.1, .9, .1, .9)

--施法条文字
CastingBarText:SetFont(STANDARD_TEXT_FONT, 14)
CastingBarText:SetShadowOffset(1, -1)
CastingBarText:SetShadowColor(0, 0, 0)
CastingBarText:ClearAllPoints()
CastingBarText:SetPoint("TOP", 0, 5)

--延迟条
CastingBarFrame.lag = CastingBarFrame:CreateTexture(nil, "BACKGROUND")
CastingBarFrame.lag:SetHeight(CastingBarFrame:GetHeight() - 2)
CastingBarFrame.lag:SetPoint("RIGHT", CastingBarFrame, "RIGHT", 0, 2)
CastingBarFrame.lag:SetTexture(.9, 0, 0, 1)

--纵向排列spark
local Barticks = setmetatable({},{
    __index = function(t,k)
        local spark = CastingBarFrame:CreateTexture(nil, "OVERLAY")
        t[k] = spark
        spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        spark:SetVertexColor(1, 1, 1, 0.8)
        spark:SetBlendMode("ADD")
        spark:SetWidth(20)
        return spark
    end
})

local function CastingBarFrameTicksSet(ticks)
    if (ticks and ticks > 0) then
        local delta = (CastingBarFrame:GetWidth() / ticks)
        for k = 1, ticks do
            local tick = Barticks[k]
            tick:ClearAllPoints()
            tick:SetHeight(CastingBarFrame:GetHeight() * 2.0)
            tick:SetPoint("CENTER", CastingBarFrame, "LEFT", delta * (k - 1), 1)
            tick:Show()
        end
    else
        for _, tick in ipairs(Barticks) do
            tick:Hide()
        end
    end
end

--瞄准射击
local function Aimed_Start()
	local SSAS = AceLibrary("SpellStatus-AimedShot-1.0")
	local active = SSAS:Active()
	if active and ShowAimed then
		local spell, rank = GetSpellInfo(CastSpellName)
		local id = GetSpellIndex(spell, rank)
		local _, duration = SSAS:MatchSpellId(id)
		InCasting_SpellName = spell
		ShowAimed = false
		CastingBarFrameStatusBar:SetStatusBarColor(1.0, 0.7, 0.0)
		CastingBarSpark:Show()
		CastingBarFrame.startTime = GetTime()
		CastingBarFrame.maxValue = CastingBarFrame.startTime + (duration / 1000) + 0.2
		CastingBarFrameStatusBar:SetMinMaxValues(CastingBarFrame.startTime, CastingBarFrame.maxValue)
		CastingBarFrameStatusBar:SetValue(CastingBarFrame.startTime)
		CastingBarText:SetText(spell)
		CastingBarFrame:SetAlpha(1.0)
		CastingBarFrame.holdTime = 0
		CastingBarFrame.casting = 1
		CastingBarFrame.fadeOut = nil
		CastingBarFrame:Show()
		CastingBarFrame.mode = "casting"
	end
end

local function CanAimed_Start()
	if (CastSpellName == "瞄准射击") then
		Aimed_Start()
	end
end

--hook UseAction函数
hooksecurefunc("UseAction", function(slot, checkCursor, onSelf)
	if GetActionText(slot) then return end
	S_icon = GetActionTexture(slot)
	S_CastBar_Tooltip:SetAction(slot)
	CastSpellName = S_CastBar_Tooltip:GetLine(1)
	
	CanAimed_Start()
end)

--hook UseContainerItem函数
hooksecurefunc("UseContainerItem", function(bag, slot)
	if bag and slot then
		S_icon = GetContainerItemInfo(bag, slot)
		CastSpellName = select(4, string.find(GetContainerItemLink(bag, slot) or "", "item:(%d+).+%[(.+)%]"))
	end
end)

--hook CastSpell函数
hooksecurefunc("CastSpell", function(id, bookType)
	local spellName = GetSpellName(id, bookType)
	S_icon = GetSpellTexture(id, bookType)
	CastSpellName = spellName

	CanAimed_Start()
end)

--hook CastSpellByName函数
hooksecurefunc("CastSpellByName", function(spell)
	local spellName, _, icon = GetSpellInfo(spell)
	S_icon = icon
	CastSpellName = spellName

	CanAimed_Start()
end)

--hook CastingBarFrame_OnEvent事件
hooksecurefunc("CastingBarFrame_OnEvent", function()
	local GetFocus_Frame, Clique_spellname, Clique_spellrank = GetMouseFocus() and GetMouseFocus():GetName() or "", nil
	
	if event == "SPELLCAST_START" then
		InCasting_SpellName = arg1
		
		if TradeSkillFrame then
			for i=1, GetNumTradeSkills(), 1 do
				local skillName = GetTradeSkillInfo(i)
				if skillName == arg1 then
					S_icon = GetTradeSkillIcon(i)
				end
			end
		end

		if arg1 == ATTACK then
			S_icon = select(3,GetSpellInfo(arg1))
		end

		CastingBarFrameTicksSet(0)
	elseif event == "SPELLCAST_CHANNEL_START" then
		if arg2 ~= CHANNELING then
			InCasting_SpellName = arg2
			S_icon = select(3,GetSpellInfo(arg2))
		else
			InCasting_SpellName = CastSpellName
		end
		
		--引导法术增加跳数
		if SpellToTicks[CastSpellName] then
			CastingBarFrameTicksSet(SpellToTicks[CastSpellName])
		else
			CastingBarFrameTicksSet(0)
		end
	elseif event == "CURRENT_SPELL_CAST_CHANGED" then
		ShowAimed = true
	elseif event == "SPELLCAST_STOP" then
		ShowAimed = false
	elseif event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
		ShowAimed = false
	elseif event == "VARIABLES_LOADED" then
		--默认位置
		this:ClearAllPoints()
		this:SetPoint("BOTTOM", "CastingBarMove", 0, 7)
		this.SetPoint = function() end
		this.ClearAllPoints = function() end
	end

	if S_icon then
		this.Icon.Texture:SetTexture(S_icon)
		this.Icon:Show()
		LibIconBorder(this.Icon)
	end
end)

CastingBarFrame:SetScript("OnShow", function()
	local min, max = this:GetMinMaxValues()
	local lagvalue = ( select(3,GetNetStats()) / 1000 ) / ( max - min )
	if lagvalue > 1 then lagvalue = 1 end
	this.lag:SetWidth(this:GetWidth() * lagvalue)

	local GetBarText = tostring(CastingBarText:GetText())

	--指定的技能图标
	if DefaultIcons[GetBarText] then
		S_icon = dir .. DefaultIcons[GetBarText]
	elseif string.find(GetBarText, "打开") then
		S_icon = dir .. "Spell_Nature_MoonKey"
	elseif string.byte(GetBarText) < 127 then
		S_icon = dir .. "INV_Misc_QuestionMark"
	end

	--支持Clique点击施法插件显示技能图标		
	if IsAddOnLoaded("Clique") then
		for _,v in Clique.db.char do
			for i=1, table.getn(Clique_Click_Frame) do
				if string.find(GetFocus_Frame, Clique_Click_Frame[i]) then
					for _,entry in ipairs(v) do
						Clique_spellname = entry.name
						if entry.rank then
							Clique_spellrank = LEVEL.." "..entry.rank
						else
							Clique_spellrank = ""
						end
						break
					end
				end
			end
		end
		if Clique_spellname then
			local id, bookType = GetSpellIndex(Clique_spellname, Clique_spellrank)
			S_icon = GetSpellTexture(id, bookType)
		end
	end

	if S_icon then
		this.Icon.Texture:SetTexture(S_icon)
		this.Icon:Show()
		LibIconBorder(this.Icon)
	end
end)

local function CastingBarTime_toString(end_time)
	local endtime = end_time - GetTime()
	if endtime < 0 then endtime = 0 end
	return string.format("%.1fs", endtime)
end

HookScript(CastingBarFrame, "OnUpdate", function()
	--施法条计时
	if ( CastingBarFrame.casting ) then
		CastingBarText:SetText(InCasting_SpellName.." "..CastingBarTime_toString(CastingBarFrame.maxValue))
	elseif ( CastingBarFrame.channeling ) then
		CastingBarText:SetText(InCasting_SpellName.." "..CastingBarTime_toString(CastingBarFrame.endTime))
	end
end)

--移动
function CastingBar_AjustPosition()
	if (CastingBarMove:IsVisible()) then
		CastingBarMove:Hide();
	else
		CastingBarMove:Show();
	end
end