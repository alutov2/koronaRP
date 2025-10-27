--[[ INIT ]]
--
IMPOSTEUR = IMPOSTEUR or {}

GlobalCFG = {}

IMPOSTEUR.CancelledTimeouts = {}

IMPOSTEUR.Classes = IMPOSTEUR.Classes or {}
IMPOSTEUR.Items = {}
IMPOSTEUR.Groups = {}
IMPOSTEUR.Weapons = {}
IMPOSTEUR.WeaponsFromHash = {}
if IS_GTA5 then
	IMPOSTEUR.WeaponsComponents = {}
	IMPOSTEUR.WeaponsComponentsByHash = {}
elseif IS_RDR3 then
	IMPOSTEUR.WeaponsComponentsGroups = {}
	IMPOSTEUR.WeaponsComponentsGroupsByHash = {}
end
IMPOSTEUR.Blips = {}
IMPOSTEUR.Farms = {}

IMPOSTEUR.Global = IMPOSTEUR.Global or {}

IMPOSTEUR.Enums = IMPOSTEUR.Enums or {}
IMPOSTEUR.Enums.RAGE = IMPOSTEUR.Enums.RAGE or {}

E = IMPOSTEUR.Enums
rageE = IMPOSTEUR.Enums.RAGE

GlobalCFG.PedsByHash = {}

collectgarbage("generational")
CURRENT_RESOURCE = GetCurrentResourceName()
IS_SERVER = IsDuplicityVersion()

local svMode = GetConvar("sv_mode", "PROD")
DEV_RC = svMode == "DEV_RC"
DEV = DEV_RC or svMode == "DEV"

if IS_SERVER then
	local gameName = GetConvar("gamename", "gta5")

	if gameName == "gta5" then
		IS_GTA, IS_GTA5 = true, true
		PRODUCT_NAME = "FiveM"
	elseif gameName == "gta4" then
		IS_GTA, IS_GTA4 = true, true
		PRODUCT_NAME = "LibertyM"
	elseif gameName == "rdr3" then
		IS_RDR, IS_RDR3 = true, true
		PRODUCT_NAME = "RedM"
	else
		PRODUCT_NAME = "Unknown"
	end
else
	local gameName = GetGameName()

	if gameName == "fivem" then
		IS_GTA, IS_GTA5 = true, true
		PRODUCT_NAME = "FiveM"
	elseif gameName == "libertym" then
		IS_GTA, IS_GTA4 = true, true
		PRODUCT_NAME = "LibertyM"
	elseif gameName == "redm" then
		IS_RDR, IS_RDR3 = true, true
		PRODUCT_NAME = "RedM"
	else
		PRODUCT_NAME = "Unknown"
	end
end

PROJECT = GetConvar("sv_projectType", "rp:life")
MAP = GetConvar("sv_map", IS_GTA5 and "gta5" or "rdr3")
SERVER_ID = GetConvar("sv_id", "unity")

local function stringsplit(s, sep)
	local t = {}

	for str in s:gmatch(("([^%s]+)"):format(sep or "%s")) do
		t[#t + 1] = str
	end

	return t
end

local PROJECT_PARTS <const> = stringsplit(PROJECT, ":")

function MATCH_PROJECT(projectMatch)
	local projectMatchParts = stringsplit(projectMatch, ":")

	for i = 1, #projectMatchParts do
		local projectMatchPart = projectMatchParts[i]

		if projectMatchPart == "*" or projectMatchPart == PROJECT_PARTS[i] then
			if i == #projectMatchParts then
				return true
			end
		else
			break
		end
	end

	return false
end

local modules_entries = GetNumResourceMetadata(CURRENT_RESOURCE, "_module")

for i = 0, modules_entries - 1, 1 do
	local module_name = GetResourceMetadata(CURRENT_RESOURCE, "_module", i)
	local module_extra = json.decode(GetResourceMetadata(CURRENT_RESOURCE, "_module_extra", i))

	if module_name and module_extra then
		if IS_SERVER or module_extra.server_only == nil then
			local module = Modules(module_name, module_extra.path)

			if module_extra.description then
				module:Description(module_extra.description)
			end

			if module_extra.author then
				module:Author(module_extra.author)
			end

			if module_extra.version then
				module:Version(module_extra.version)
			end
		end
	end
end

function IMPOSTEUR.EventFormatter(eventName)
	return ("seed:%s"):format(eventName)
end

-- Cfx.re --
--- @param threadFunction function
function IMPOSTEUR.Thread(threadFunction)
	CreateThread(threadFunction)
end

--- @param threadFunction function
function IMPOSTEUR.ThreadNow(threadFunction)
	Citizen.CreateThreadNow(threadFunction)
end

do
	local eventManager = EventBase()

	--- @param eventName string
	--- @param fn function
	function IMPOSTEUR.RemoveListener(eventName, fn)
		eventManager:removeListener(eventName, fn)
	end

	--- @param eventName string
	function IMPOSTEUR.RemoveListeners(eventName)
		eventManager:removeListeners(eventName)
	end

	--- @param eventName string
	--- @param eventRoutine function
	--- @return any
	function IMPOSTEUR.On(eventName, eventRoutine)
		return eventManager:on(eventName, eventRoutine)
	end

	--- @param eventName string
	--- @param eventRoutine function
	--- @return any
	function IMPOSTEUR.Once(eventName, eventRoutine)
		return eventManager:once(eventName, eventRoutine)
	end

	--- @param eventName string
	function IMPOSTEUR.EmitSync(eventName, ...)
		eventManager:emitSync(eventName, ...)
	end

	--- @param eventName string
	function IMPOSTEUR.Emit(eventName, ...)
		eventManager:emit(eventName, ...)
	end
end

--- @param eventName string
--- @param eventRoutine function
function IMPOSTEUR.OnNet(eventName, eventRoutine)
	RegisterNetEvent(IMPOSTEUR.EventFormatter(eventName), eventRoutine)
end

if IS_SERVER then
	--- @param eventName string
	--- @param playerId number
	function IMPOSTEUR.EmitClient(eventName, playerId, ...)
		local _eventName = IMPOSTEUR.EventFormatter(eventName)
		IO.Debug("EmitClient [S->C]", _eventName, playerId)
		TriggerClientEvent(_eventName, playerId, ...)
	end

	--- @param eventName string
	--- @param playerId number
	--- @param bps number
	function IMPOSTEUR.EmitLatentClient(eventName, playerId, bps, ...)
		local _eventName = IMPOSTEUR.EventFormatter(eventName)
		IO.Debug("EmitLatentClient [S->C]", _eventName, playerId, bps)
		TriggerLatentClientEvent(_eventName, playerId, bps, ...)
	end

	local msgpack_pack_args = msgpack.pack_args
	local strlen = string.len

	function TriggerClientsEvent(eventName, playersId, ...)
		local _TriggerClientEventInternal = TriggerClientEventInternal
		local payload = msgpack_pack_args(...)
		local payloadLen = strlen(payload)

		for i = 1, #playersId do
			_TriggerClientEventInternal(eventName, playersId[i], payload, payloadLen)
		end
	end

	--- @param eventName string
	--- @param playersId table
	function IMPOSTEUR.EmitClients(eventName, playersId, ...)
		local _eventName = IMPOSTEUR.EventFormatter(eventName)
		local _TriggerClientEventInternal = TriggerClientEventInternal
		local payload = msgpack_pack_args(...)
		local payloadLen = strlen(payload)

		IO.Debug("EmitClients [S->C]", _eventName, playersId)

		for i = 1, #playersId do
			_TriggerClientEventInternal(_eventName, playersId[i], payload, payloadLen)
		end
	end

	--- @param eventName string
	--- @param playersId table
	--- @param bps number
	function IMPOSTEUR.EmitLatentClients(eventName, playersId, bps, ...)
		local _eventName = IMPOSTEUR.EventFormatter(eventName)
		local _bps = tonumber(bps)
		local _TriggerLatentClientEventInternal = TriggerLatentClientEventInternal
		local payload = msgpack_pack_args(...)
		local payloadLen = strlen(payload)

		IO.Debug("EmitLatentClients [S->C]", _eventName, playersId, bps)

		for i = 1, #playersId do
			_TriggerLatentClientEventInternal(_eventName, playersId[i], payload, payloadLen, _bps)
		end
	end
else
	--- @param eventName string
	function IMPOSTEUR.EmitServer(eventName, ...)
		local _eventName = IMPOSTEUR.EventFormatter(eventName)
		IO.Debug("EmitServer [C->S]", _eventName)
		TriggerServerEvent(_eventName, ...)
	end
end

---@param name string
---@param label string
---@param options table
---@return Item
function IMPOSTEUR.RegisterItem(name, label, options)
	local item = IMPOSTEUR.Classes.Item(name, label, options)
	IMPOSTEUR.Items[name] = item
	return item
end

---@return Item
function IMPOSTEUR.GetItem(itemName)
	assert(type(itemName) == "string", ("IMPOSTEUR.GetItem expects 'itemName' as a 'string'"):format(itemName))
	return IMPOSTEUR.Items[itemName]
end

function IMPOSTEUR.DoesItemExist(itemName)
	return not not IMPOSTEUR.GetItem(itemName)
end

function IMPOSTEUR.GetCurrency(currencyName)
	assert(
		type(currencyName) == "string",
		("IMPOSTEUR.GetCurrency expects 'currencyName' as a 'string'"):format(currencyName)
	)
	return GlobalCFG.Currencies[currencyName]
end

function IMPOSTEUR.GetLocalizedShopTokenName()
	return "Union"
end

function IMPOSTEUR.DoesCurrencyExist(currencyName)
	return not not IMPOSTEUR.GetCurrency(currencyName)
end

--[[ GROUP MANAGER ]]
--

--- Return a Group by Name.
---
--- @return Group|nil
function IMPOSTEUR.GetGroup(groupName)
	return IMPOSTEUR.Groups[groupName]
end

function IMPOSTEUR.DoesGroupExist(groupName)
	return not not IMPOSTEUR.GetGroup(groupName)
end

function IMPOSTEUR.GroupCanTarget(targetGroup1, targetGroup2)
	local group1, group2 = IMPOSTEUR.GetGroup(targetGroup1), IMPOSTEUR.GetGroup(targetGroup2)

	if group1 and group2 then
		if group1.name == GlobalCFG.DefaultGroup then
			return false
		end

		if group1.name == group2.name then
			return true
		end

		if group1.inherits == group2.name then
			return true
		end

		return IMPOSTEUR.GroupCanTarget(IMPOSTEUR.GetGroup(group1.inherits).name, group2.name)
	end

	return false
end

function IMPOSTEUR.RegisterGroup(name, inherits)
	assert(type(name) == "string", "IMPOSTEUR.RegisterGroup expects 'name' as a 'string'")
	assert(type(inherits) == "string", "IMPOSTEUR.RegisterGroup expects 'inherits' as a 'string'")

	if not IMPOSTEUR.GetGroup(name) then
		local group = IMPOSTEUR.Classes.Group(name, inherits)
		IMPOSTEUR.Groups[name] = group
		return group
	end
end
function IMPOSTEUR.GetSkillStageByPoints(points)
	local lastStagePoints = 0

	for minPoints in pairs(GlobalCFG.SkillsStages) do
		if points >= minPoints and minPoints > lastStagePoints then
			lastStagePoints = minPoints
		end
	end

	return GlobalCFG.SkillsStages[lastStagePoints], lastStagePoints
end

function IMPOSTEUR.LocalizeCurrency(currencyName, amount, symbol)
	local currency = IMPOSTEUR.GetCurrency(currencyName)
	if not currency then
		return ("Currency %s not found"):format(currencyName)
	end

	if currency.localeDivisor then
		amount = amount / currency.localeDivisor
	end

	local localizedAmount = Utils.Math.GroupDigits(amount)

	if symbol then
		localizedAmount = ("%s %s"):format(localizedAmount, currency.symbol)
	end

	return localizedAmount
end

function IMPOSTEUR.LocalizeShopToken(amount)
	return Utils.Math.GroupDigits(amount)
end

IMPOSTEUR.GradesListTweaker = {}

function IMPOSTEUR.GradesListTweaker.AddingGrade(grades, gradePosition) -- adding with table.insert
	for i = gradePosition + 1, #grades do
		grades[i].position += 1
	end
end

function IMPOSTEUR.GradesListTweaker.RemovedGrade(grades, gradePosition) -- removed with table.remove
	for i = gradePosition + 1, #grades do
		grades[i].position = i - 1
	end
end

function IMPOSTEUR.GradesListTweaker.UpdatedGradePosition(grades, gradeId, position, oldPosition)
	if position < oldPosition then
		for i = 1, #grades do
			local otherGrade = grades[i]
			if otherGrade.id ~= gradeId then
				if otherGrade.position >= position and otherGrade.position < oldPosition then
					otherGrade.position = otherGrade.position + 1
				end
			end
		end
	else
		for i = 1, #grades do
			local otherGrade = grades[i]
			if otherGrade.id ~= gradeId then
				if otherGrade.position > oldPosition and otherGrade.position <= position then
					otherGrade.position = otherGrade.position - 1
				end
			end
		end
	end

	table.sort(grades, function(a, b)
		return a.position < b.position
	end)
end

function IMPOSTEUR.SecondsToLocalizedString(seconds, minUnits, noZeros)
	minUnits = minUnits or 2

	local days = math.floor(seconds / (60 * 60 * 24))
	local hours = math.floor((seconds % (60 * 60 * 24)) / (60 * 60))
	local minutes = math.floor((seconds % (60 * 60)) / 60)
	seconds = math.ceil(seconds % 60)

	local unitsAdded = 0
	local sexyDateStr, sexyDateStrLen = "", 0

	if days > 0 then
		sexyDateStr = ("%s%u jour%s"):format(sexyDateStr, days, days > 1 and "s" or "")
		unitsAdded += 1
	end

	sexyDateStrLen = sexyDateStr:len()
	if hours > 0 or (not noZeros and sexyDateStrLen > 0) then
		sexyDateStr = ("%s%s%u heure%s"):format(
			sexyDateStr,
			sexyDateStrLen > 0 and " " or "",
			hours,
			hours > 1 and "s" or ""
		)
		unitsAdded += 1
	end

	sexyDateStrLen = sexyDateStr:len()
	if (minutes > 0 or (not noZeros and sexyDateStrLen > 0)) and unitsAdded < minUnits then
		sexyDateStr = ("%s%s%u minute%s"):format(
			sexyDateStr,
			sexyDateStrLen > 0 and " " or "",
			minutes,
			minutes > 1 and "s" or ""
		)
		unitsAdded += 1
	end

	sexyDateStrLen = sexyDateStr:len()
	if unitsAdded < minUnits then
		sexyDateStr = ("%s%s%u seconde%s"):format(
			sexyDateStr,
			sexyDateStrLen > 0 and " " or "",
			seconds,
			seconds > 1 and "s" or ""
		)
		unitsAdded += 1
	end

	return sexyDateStr
end

local TimeoutCallbacksIID = IID.NewFactory(1, 0xFFFFFFFF)

function IMPOSTEUR.SetTimeout(msec, cb)
	local id = TimeoutCallbacksIID:NextId()

	Citizen.SetTimeout(msec, function()
		if IMPOSTEUR.CancelledTimeouts[id] then
			IMPOSTEUR.CancelledTimeouts[id] = nil
			return
		end

		cb()
	end)

	return id
end

function IMPOSTEUR.ClearTimeout(id)
	IMPOSTEUR.CancelledTimeouts[id] = true
end

function IMPOSTEUR.GetCurrentMapInfo()
	return GlobalCFG.Maps[MAP]
end

IMPOSTEUR.Colors = IMPOSTEUR.Colors
	or {
		Red = { 255, 0, 0 },
		Green = { 0, 255, 0 },
		Blue = { 0, 0, 255 },
		White = { 255, 255, 255 },
		Black = { 0, 0, 0 },
	}

function IMPOSTEUR.DefaultColor()
	return { 255, 255, 255 }
end
DefaultColor = IMPOSTEUR.DefaultColor

function IMPOSTEUR.Color(colorName)
	return { 255, 0, 0 }
end
Color = IMPOSTEUR.Color

function IMPOSTEUR.RAGE_DefaultColor()
	return rageE.Colors["Default"]
end
RAGE_DefaultColor = IMPOSTEUR.RAGE_DefaultColor

function IMPOSTEUR.RAGE_Color(colorName)
	return rageE.Colors[colorName]
end
RAGE_Color = IMPOSTEUR.RAGE_Color

function IMPOSTEUR.RAGE_NewLine()
	return rageE.Colors["NewLine"]
end
RAGE_NewLine = IMPOSTEUR.RAGE_NewLine

function IMPOSTEUR.RAGE_Bold()
	return rageE.Colors["Bold"]
end
RAGE_Bold = IMPOSTEUR.RAGE_Bold

if IS_GTA5 then
	rageE.Colors = {
		["Default"] = "~s~",
		["White"] = "~w~",
		["Red"] = "~r~",
		["LightRed"] = "~r~", -- rdr3 extension
		["DarkRed"] = "~r~", -- rdr3 extension
		["Blue"] = "~b~",
		["LightBlue"] = "~b~", -- rdr3 extension
		["DarkBlue"] = "~b~", -- rdr3 extension
		["Green"] = "~g~",
		["Yellow"] = "~y~",
		["LightYellow"] = "~y~", -- rdr3 extension
		["Purple"] = "~p~",
		["Pink"] = "~q~",
		["LightPink"] = "~q~", -- rdr3 extension
		["Orange"] = "~o~",
		["LightOrange"] = "~o~", -- rdr3 extension
		["Grey"] = "~c~",
		["DarkGrey"] = "~m~",
		["Black"] = "~u~", -- ~u~ or ~l~
		["NewLine"] = "~n~",
		["Bold"] = "~h~",
	}
elseif IS_RDR3 then
	rageE.Colors = {
		["Default"] = "~s~",
		["White"] = "~COLOR_WHITE~",
		["Red"] = "~COLOR_RED~",
		["LightRed"] = "~COLOR_REDLIGHT~", -- rdr3 extension
		["DarkRed"] = "~COLOR_REDDARK~", -- rdr3 extension
		["Blue"] = "~COLOR_BLUE~",
		["LightBlue"] = "~COLOR_BLUELIGHT~", -- rdr3 extension
		["DarkBlue"] = "~COLOR_BLUEDARK~", -- rdr3 extension
		["Green"] = "~COLOR_GREEN~",
		["Yellow"] = "~COLOR_YELLOW~",
		["LightYellow"] = "~COLOR_YELLOWLIGHT~", -- rdr3 extension
		["Purple"] = "~COLOR_PURPLE~",
		["Pink"] = "~COLOR_PINK~",
		["LightPink"] = "~COLOR_PINKLIGHT~", -- rdr3 extension
		["Orange"] = "~COLOR_ORANGE~",
		["LightOrange"] = "~COLOR_ORANGELIGHT~", -- rdr3 extension
		["Grey"] = "~COLOR_GREY~",
		["DarkGrey"] = "~COLOR_GREYDARK~",
		["Black"] = "~COLOR_BLACK~",
		["NewLine"] = "~n~",
		["Bold"] = "~b~",
		["Italic"] = "~i~",
	}
end

rageE.LoadingIconSymbols = {
	LOADING_ICON_EMPTY = 0,
	LOADING_ICON_SPINNER = 2,
	LOADING_ICON_STAR = 4,
	LOADING_ICON_LOADING = 5,
}

if IS_GTA5 then
	rageE.PedComponentNUM = 12
	rageE.PedComponent = {
		["Face"] = 0,
		["Mask"] = 1,
		["Hair"] = 2,
		["Torso"] = 3,
		["Legs"] = 4,
		["Bag"] = 5,
		["Shoes"] = 6,
		["Accessory"] = 7,
		["Undershirt"] = 8,
		["Kevlar"] = 9,
		["Decal"] = 10,
		["Torso2"] = 11,
	}

	rageE.PedPropNUM = 9
	rageE.PedProp = {
		["Head"] = 0,
		["Eyes"] = 1,
		["Ears"] = 2,
		["Mouth"] = 3,
		["LeftHand"] = 4,
		["RightHand"] = 5,
		["LeftWrist"] = 6,
		["RightWrist"] = 7,
		["Hip"] = 8,
	}

	rageE.PedOverlayNUM = 13
	rageE.PedOverlay = {
		["Blemishes"] = 0, --Problèmes peau
		["FacialHair"] = 1, --Pilosité faciale
		["Eyebrows"] = 2, --Sourcils
		["Ageing"] = 3, --Signes de vieillissement
		["Makeup"] = 4,
		["Blush"] = 5,
		["Complexion"] = 6, --Teint
		["SunDamage"] = 7, --Aspect de la peau
		["Lipstick"] = 8,
		["Freckles"] = 9, --Tâche cutanées
		["ChestHair"] = 10,
		["BodyBlemishes"] = 11,
		["AddBodyBlemishes"] = 12,
	}

	rageE.FaceFeatureNUM = 20
	rageE.FaceFeature = {
		["NoseWidth"] = 0,
		["NosePeakHeight"] = 1,
		["NosePeakLength"] = 2,
		["NoseBoneHigh"] = 3,
		["NosePeakLowering"] = 4,
		["NoseBoneTwist"] = 5,
		["EyeBrownHigh"] = 6,
		["EyeBrownForward"] = 7,
		["CheeksBoneHigh"] = 8,
		["CheeksBoneWidth"] = 9,
		["CheeksWidth"] = 10,
		["EyesOpening"] = 11,
		["LipsThickness"] = 12,
		["JawBoneWidth"] = 13, --Bone size to sides
		["JawBoneBackLength"] = 14, --Bone size to back
		["ChimpBoneLowering"] = 15, --Go down
		["ChimpBoneLength"] = 16, --Go forward
		["ChimpBoneWidth"] = 17,
		["ChimpHole"] = 18,
		["NeckThickness"] = 19,
	}

	rageE.PedBoneTag = {
		SKEL_ROOT = 0x0,
		SKEL_Pelvis = 0x2E28,
		SKEL_L_Thigh = 0xE39F,
		SKEL_L_Calf = 0xF9BB,
		SKEL_L_Foot = 0x3779,
		SKEL_L_Toe0 = 0x83C,
		EO_L_Foot = 0x84C5,
		EO_L_Toe = 0x68BD,
		IK_L_Foot = 0xFEDD,
		PH_L_Foot = 0xE175,
		MH_L_Knee = 0xB3FE,
		SKEL_R_Thigh = 0xCA72,
		SKEL_R_Calf = 0x9000,
		SKEL_R_Foot = 0xCC4D,
		SKEL_R_Toe0 = 0x512D,
		EO_R_Foot = 0x1096,
		EO_R_Toe = 0x7163,
		IK_R_Foot = 0x8AAE,
		PH_R_Foot = 0x60E6,
		MH_R_Knee = 0x3FCF,
		RB_L_ThighRoll = 0x5C57,
		RB_R_ThighRoll = 0x192A,
		SKEL_Spine_Root = 0xE0FD,
		SKEL_Spine0 = 0x5C01,
		SKEL_Spine1 = 0x60F0,
		SKEL_Spine2 = 0x60F1,
		SKEL_Spine3 = 0x60F2,
		SKEL_L_Clavicle = 0xFCD9,
		SKEL_L_UpperArm = 0xB1C5,
		SKEL_L_Forearm = 0xEEEB,
		SKEL_L_Hand = 0x49D9,
		SKEL_L_Finger00 = 0x67F2,
		SKEL_L_Finger01 = 0xFF9,
		SKEL_L_Finger02 = 0xFFA,
		SKEL_L_Finger10 = 0x67F3,
		SKEL_L_Finger11 = 0x1049,
		SKEL_L_Finger12 = 0x104A,
		SKEL_L_Finger20 = 0x67F4,
		SKEL_L_Finger21 = 0x1059,
		SKEL_L_Finger22 = 0x105A,
		SKEL_L_Finger30 = 0x67F5,
		SKEL_L_Finger31 = 0x1029,
		SKEL_L_Finger32 = 0x102A,
		SKEL_L_Finger40 = 0x67F6,
		SKEL_L_Finger41 = 0x1039,
		SKEL_L_Finger42 = 0x103A,
		PH_L_Hand = 0xEB95,
		IK_L_Hand = 0x8CBD,
		RB_L_ForeArmRoll = 0xEE4F,
		RB_L_ArmRoll = 0x1470,
		MH_L_Elbow = 0x58B7,
		SKEL_R_Clavicle = 0x29D2,
		SKEL_R_UpperArm = 0x9D4D,
		SKEL_R_Forearm = 0x6E5C,
		SKEL_R_Hand = 0xDEAD,
		SKEL_R_Finger00 = 0xE5F2,
		SKEL_R_Finger01 = 0xFA10,
		SKEL_R_Finger02 = 0xFA11,
		SKEL_R_Finger10 = 0xE5F3,
		SKEL_R_Finger11 = 0xFA60,
		SKEL_R_Finger12 = 0xFA61,
		SKEL_R_Finger20 = 0xE5F4,
		SKEL_R_Finger21 = 0xFA70,
		SKEL_R_Finger22 = 0xFA71,
		SKEL_R_Finger30 = 0xE5F5,
		SKEL_R_Finger31 = 0xFA40,
		SKEL_R_Finger32 = 0xFA41,
		SKEL_R_Finger40 = 0xE5F6,
		SKEL_R_Finger41 = 0xFA50,
		SKEL_R_Finger42 = 0xFA51,
		PH_R_Hand = 0x6F06,
		IK_R_Hand = 0x188E,
		RB_R_ForeArmRoll = 0xAB22,
		RB_R_ArmRoll = 0x90FF,
		MH_R_Elbow = 0xBB0,
		SKEL_Neck_1 = 0x9995,
		SKEL_Head = 0x796E,
		IK_Head = 0x322C,
		FACIAL_facialRoot = 0xFE2C,
		FB_L_Brow_Out_000 = 0xE3DB,
		FB_L_Lid_Upper_000 = 0xB2B6,
		FB_L_Eye_000 = 0x62AC,
		FB_L_CheekBone_000 = 0x542E,
		FB_L_Lip_Corner_000 = 0x74AC,
		FB_R_Lid_Upper_000 = 0xAA10,
		FB_R_Eye_000 = 0x6B52,
		FB_R_CheekBone_000 = 0x4B88,
		FB_R_Brow_Out_000 = 0x54C,
		FB_R_Lip_Corner_000 = 0x2BA6,
		FB_Brow_Centre_000 = 0x9149,
		FB_UpperLipRoot_000 = 0x4ED2,
		FB_UpperLip_000 = 0xF18F,
		FB_L_Lip_Top_000 = 0x4F37,
		FB_R_Lip_Top_000 = 0x4537,
		FB_Jaw_000 = 0xB4A0,
		FB_LowerLipRoot_000 = 0x4324,
		FB_LowerLip_000 = 0x508F,
		FB_L_Lip_Bot_000 = 0xB93B,
		FB_R_Lip_Bot_000 = 0xC33B,
		FB_Tongue_000 = 0xB987,
		RB_Neck_1 = 0x8B93,
		SPR_L_Breast = 0xFC8E,
		SPR_R_Breast = 0x885F,
		IK_Root = 0xDD1C,
		SKEL_Neck_2 = 0x5FD4,
		SKEL_Pelvis1 = 0xD003,
		SKEL_PelvisRoot = 0x45FC,
		SKEL_SADDLE = 0x9524,
		MH_L_CalfBack = 0x1013,
		MH_L_ThighBack = 0x600D,
		SM_L_Skirt = 0xC419,
		MH_R_CalfBack = 0xB013,
		MH_R_ThighBack = 0x51A3,
		SM_R_Skirt = 0x7712,
		SM_M_BackSkirtRoll = 0xDBB,
		SM_L_BackSkirtRoll = 0x40B2,
		SM_R_BackSkirtRoll = 0xC141,
		SM_M_FrontSkirtRoll = 0xCDBB,
		SM_L_FrontSkirtRoll = 0x9B69,
		SM_R_FrontSkirtRoll = 0x86F1,
		SM_CockNBalls_ROOT = 0xC67D,
		SM_CockNBalls = 0x9D34,
		MH_L_Finger00 = 0x8C63,
		MH_L_FingerBulge00 = 0x5FB8,
		MH_L_Finger10 = 0x8C53,
		MH_L_FingerTop00 = 0xA244,
		MH_L_HandSide = 0xC78A,
		MH_Watch = 0x2738,
		MH_L_Sleeve = 0x933C,
		MH_R_Finger00 = 0x2C63,
		MH_R_FingerBulge00 = 0x69B8,
		MH_R_Finger10 = 0x2C53,
		MH_R_FingerTop00 = 0xEF4B,
		MH_R_HandSide = 0x68FB,
		MH_R_Sleeve = 0x92DC,
		FACIAL_jaw = 0xB21,
		FACIAL_underChin = 0x8A95,
		FACIAL_L_underChin = 0x234E,
		FACIAL_chin = 0xB578,
		FACIAL_chinSkinBottom = 0x98BC,
		FACIAL_L_chinSkinBottom = 0x3E8F,
		FACIAL_R_chinSkinBottom = 0x9E8F,
		FACIAL_tongueA = 0x4A7C,
		FACIAL_tongueB = 0x4A7D,
		FACIAL_tongueC = 0x4A7E,
		FACIAL_tongueD = 0x4A7F,
		FACIAL_tongueE = 0x4A80,
		FACIAL_L_tongueE = 0x35F2,
		FACIAL_R_tongueE = 0x2FF2,
		FACIAL_L_tongueD = 0x35F1,
		FACIAL_R_tongueD = 0x2FF1,
		FACIAL_L_tongueC = 0x35F0,
		FACIAL_R_tongueC = 0x2FF0,
		FACIAL_L_tongueB = 0x35EF,
		FACIAL_R_tongueB = 0x2FEF,
		FACIAL_L_tongueA = 0x35EE,
		FACIAL_R_tongueA = 0x2FEE,
		FACIAL_chinSkinTop = 0x7226,
		FACIAL_L_chinSkinTop = 0x3EB3,
		FACIAL_chinSkinMid = 0x899A,
		FACIAL_L_chinSkinMid = 0x4427,
		FACIAL_L_chinSide = 0x4A5E,
		FACIAL_R_chinSkinMid = 0xF5AF,
		FACIAL_R_chinSkinTop = 0xF03B,
		FACIAL_R_chinSide = 0xAA5E,
		FACIAL_R_underChin = 0x2BF4,
		FACIAL_L_lipLowerSDK = 0xB9E1,
		FACIAL_L_lipLowerAnalog = 0x244A,
		FACIAL_L_lipLowerThicknessV = 0xC749,
		FACIAL_L_lipLowerThicknessH = 0xC67B,
		FACIAL_lipLowerSDK = 0x7285,
		FACIAL_lipLowerAnalog = 0xD97B,
		FACIAL_lipLowerThicknessV = 0xC5BB,
		FACIAL_lipLowerThicknessH = 0xC5ED,
		FACIAL_R_lipLowerSDK = 0xA034,
		FACIAL_R_lipLowerAnalog = 0xC2D9,
		FACIAL_R_lipLowerThicknessV = 0xC6E9,
		FACIAL_R_lipLowerThicknessH = 0xC6DB,
		FACIAL_nose = 0x20F1,
		FACIAL_L_nostril = 0x7322,
		FACIAL_L_nostrilThickness = 0xC15F,
		FACIAL_noseLower = 0xE05A,
		FACIAL_L_noseLowerThickness = 0x79D5,
		FACIAL_R_noseLowerThickness = 0x7975,
		FACIAL_noseTip = 0x6A60,
		FACIAL_R_nostril = 0x7922,
		FACIAL_R_nostrilThickness = 0x36FF,
		FACIAL_noseUpper = 0xA04F,
		FACIAL_L_noseUpper = 0x1FB8,
		FACIAL_noseBridge = 0x9BA3,
		FACIAL_L_nasolabialFurrow = 0x5ACA,
		FACIAL_L_nasolabialBulge = 0xCD78,
		FACIAL_L_cheekLower = 0x6907,
		FACIAL_L_cheekLowerBulge1 = 0xE3FB,
		FACIAL_L_cheekLowerBulge2 = 0xE3FC,
		FACIAL_L_cheekInner = 0xE7AB,
		FACIAL_L_cheekOuter = 0x8161,
		FACIAL_L_eyesackLower = 0x771B,
		FACIAL_L_eyeball = 0x1744,
		FACIAL_L_eyelidLower = 0x998C,
		FACIAL_L_eyelidLowerOuterSDK = 0xFE4C,
		FACIAL_L_eyelidLowerOuterAnalog = 0xB9AA,
		FACIAL_L_eyelashLowerOuter = 0xD7F6,
		FACIAL_L_eyelidLowerInnerSDK = 0xF151,
		FACIAL_L_eyelidLowerInnerAnalog = 0x8242,
		FACIAL_L_eyelashLowerInner = 0x4CCF,
		FACIAL_L_eyelidUpper = 0x97C1,
		FACIAL_L_eyelidUpperOuterSDK = 0xAF15,
		FACIAL_L_eyelidUpperOuterAnalog = 0x67FA,
		FACIAL_L_eyelashUpperOuter = 0x27B7,
		FACIAL_L_eyelidUpperInnerSDK = 0xD341,
		FACIAL_L_eyelidUpperInnerAnalog = 0xF092,
		FACIAL_L_eyelashUpperInner = 0x9B1F,
		FACIAL_L_eyesackUpperOuterBulge = 0xA559,
		FACIAL_L_eyesackUpperInnerBulge = 0x2F2A,
		FACIAL_L_eyesackUpperOuterFurrow = 0xC597,
		FACIAL_L_eyesackUpperInnerFurrow = 0x52A7,
		FACIAL_forehead = 0x9218,
		FACIAL_L_foreheadInner = 0x843,
		FACIAL_L_foreheadInnerBulge = 0x767C,
		FACIAL_L_foreheadOuter = 0x8DCB,
		FACIAL_skull = 0x4221,
		FACIAL_foreheadUpper = 0xF7D6,
		FACIAL_L_foreheadUpperInner = 0xCF13,
		FACIAL_L_foreheadUpperOuter = 0x509B,
		FACIAL_R_foreheadUpperInner = 0xCEF3,
		FACIAL_R_foreheadUpperOuter = 0x507B,
		FACIAL_L_temple = 0xAF79,
		FACIAL_L_ear = 0x19DD,
		FACIAL_L_earLower = 0x6031,
		FACIAL_L_masseter = 0x2810,
		FACIAL_L_jawRecess = 0x9C7A,
		FACIAL_L_cheekOuterSkin = 0x14A5,
		FACIAL_R_cheekLower = 0xF367,
		FACIAL_R_cheekLowerBulge1 = 0x599B,
		FACIAL_R_cheekLowerBulge2 = 0x599C,
		FACIAL_R_masseter = 0x810,
		FACIAL_R_jawRecess = 0x93D4,
		FACIAL_R_ear = 0x1137,
		FACIAL_R_earLower = 0x8031,
		FACIAL_R_eyesackLower = 0x777B,
		FACIAL_R_nasolabialBulge = 0xD61E,
		FACIAL_R_cheekOuter = 0xD32,
		FACIAL_R_cheekInner = 0x737C,
		FACIAL_R_noseUpper = 0x1CD6,
		FACIAL_R_foreheadInner = 0xE43,
		FACIAL_R_foreheadInnerBulge = 0x769C,
		FACIAL_R_foreheadOuter = 0x8FCB,
		FACIAL_R_cheekOuterSkin = 0xB334,
		FACIAL_R_eyesackUpperInnerFurrow = 0x9FAE,
		FACIAL_R_eyesackUpperOuterFurrow = 0x140F,
		FACIAL_R_eyesackUpperInnerBulge = 0xA359,
		FACIAL_R_eyesackUpperOuterBulge = 0x1AF9,
		FACIAL_R_nasolabialFurrow = 0x2CAA,
		FACIAL_R_temple = 0xAF19,
		FACIAL_R_eyeball = 0x1944,
		FACIAL_R_eyelidUpper = 0x7E14,
		FACIAL_R_eyelidUpperOuterSDK = 0xB115,
		FACIAL_R_eyelidUpperOuterAnalog = 0xF25A,
		FACIAL_R_eyelashUpperOuter = 0xE0A,
		FACIAL_R_eyelidUpperInnerSDK = 0xD541,
		FACIAL_R_eyelidUpperInnerAnalog = 0x7C63,
		FACIAL_R_eyelashUpperInner = 0x8172,
		FACIAL_R_eyelidLower = 0x7FDF,
		FACIAL_R_eyelidLowerOuterSDK = 0x1BD,
		FACIAL_R_eyelidLowerOuterAnalog = 0x457B,
		FACIAL_R_eyelashLowerOuter = 0xBE49,
		FACIAL_R_eyelidLowerInnerSDK = 0xF351,
		FACIAL_R_eyelidLowerInnerAnalog = 0xE13,
		FACIAL_R_eyelashLowerInner = 0x3322,
		FACIAL_L_lipUpperSDK = 0x8F30,
		FACIAL_L_lipUpperAnalog = 0xB1CF,
		FACIAL_L_lipUpperThicknessH = 0x37CE,
		FACIAL_L_lipUpperThicknessV = 0x38BC,
		FACIAL_lipUpperSDK = 0x1774,
		FACIAL_lipUpperAnalog = 0xE064,
		FACIAL_lipUpperThicknessH = 0x7993,
		FACIAL_lipUpperThicknessV = 0x7981,
		FACIAL_L_lipCornerSDK = 0xB1C,
		FACIAL_L_lipCornerAnalog = 0xE568,
		FACIAL_L_lipCornerThicknessUpper = 0x7BC,
		FACIAL_L_lipCornerThicknessLower = 0xDD42,
		FACIAL_R_lipUpperSDK = 0x7583,
		FACIAL_R_lipUpperAnalog = 0x51CF,
		FACIAL_R_lipUpperThicknessH = 0x382E,
		FACIAL_R_lipUpperThicknessV = 0x385C,
		FACIAL_R_lipCornerSDK = 0xB3C,
		FACIAL_R_lipCornerAnalog = 0xEE0E,
		FACIAL_R_lipCornerThicknessUpper = 0x54C3,
		FACIAL_R_lipCornerThicknessLower = 0x2BBA,
		MH_MulletRoot = 0x3E73,
		MH_MulletScaler = 0xA1C2,
		MH_Hair_Scale = 0xC664,
		MH_Hair_Crown = 0x1675,
		SM_Torch = 0x8D6,
		FX_Light = 0x8959,
		FX_Light_Scale = 0x5038,
		FX_Light_Switch = 0xE18E,
		BagRoot = 0xAD09,
		BagPivotROOT = 0xB836,
		BagPivot = 0x4D11,
		BagBody = 0xAB6D,
		BagBone_R = 0x937,
		BagBone_L = 0x991,
		SM_LifeSaver_Front = 0x9420,
		SM_R_Pouches_ROOT = 0x2962,
		SM_R_Pouches = 0x4141,
		SM_L_Pouches_ROOT = 0x2A02,
		SM_L_Pouches = 0x4B41,
		SM_Suit_Back_Flapper = 0xDA2D,
		SPR_CopRadio = 0x8245,
		SM_LifeSaver_Back = 0x2127,
		MH_BlushSlider = 0xA0CE,
		SKEL_Tail_01 = 0x347,
		SKEL_Tail_02 = 0x348,
		MH_L_Concertina_B = 0xC988,
		MH_L_Concertina_A = 0xC987,
		MH_R_Concertina_B = 0xC8E8,
		MH_R_Concertina_A = 0xC8E7,
		MH_L_ShoulderBladeRoot = 0x8711,
		MH_L_ShoulderBlade = 0x4EAF,
		MH_R_ShoulderBladeRoot = 0x3A0A,
		MH_R_ShoulderBlade = 0x54AF,
		FB_R_Ear_000 = 0x6CDF,
		SPR_R_Ear = 0x63B6,
		FB_L_Ear_000 = 0x6439,
		SPR_L_Ear = 0x5B10,
		FB_TongueA_000 = 0x4206,
		FB_TongueB_000 = 0x4207,
		FB_TongueC_000 = 0x4208,
		SKEL_L_Toe1 = 0x1D6B,
		SKEL_R_Toe1 = 0xB23F,
		SKEL_Tail_03 = 0x349,
		SKEL_Tail_04 = 0x34A,
		SKEL_Tail_05 = 0x34B,
		SPR_Gonads_ROOT = 0xBFDE,
		SPR_Gonads = 0x1C00,
		FB_L_Brow_Out_001 = 0xE3DB,
		FB_L_Lid_Upper_001 = 0xB2B6,
		FB_L_Eye_001 = 0x62AC,
		FB_L_CheekBone_001 = 0x542E,
		FB_L_Lip_Corner_001 = 0x74AC,
		FB_R_Lid_Upper_001 = 0xAA10,
		FB_R_Eye_001 = 0x6B52,
		FB_R_CheekBone_001 = 0x4B88,
		FB_R_Brow_Out_001 = 0x54C,
		FB_R_Lip_Corner_001 = 0x2BA6,
		FB_Brow_Centre_001 = 0x9149,
		FB_UpperLipRoot_001 = 0x4ED2,
		FB_UpperLip_001 = 0xF18F,
		FB_L_Lip_Top_001 = 0x4F37,
		FB_R_Lip_Top_001 = 0x4537,
		FB_Jaw_001 = 0xB4A0,
		FB_LowerLipRoot_001 = 0x4324,
		FB_LowerLip_001 = 0x508F,
		FB_L_Lip_Bot_001 = 0xB93B,
		FB_R_Lip_Bot_001 = 0xC33B,
		FB_Tongue_001 = 0xB987,
	}

	rageE.CombatRange = {
		NEAR = 0, -- keeps within 5-15m
		MEDIUM = 1, -- keeps within 7-30m
		FAR = 2, -- keeps within 15-40m
		VERY_FAR = 3, -- keeps within 22-45m
	}

	-- Set a specific combat attribute
	rageE.CombatAttribute = {
		INVALID = -1,
		USE_COVER = 0, -- AI will only use cover if this is set
		USE_VEHICLE = 1, -- AI will only use vehicles if this is set
		DO_DRIVEBYS = 2, -- AI will only driveby from a vehicle if this is set
		LEAVE_VEHICLES = 3, -- Will be forced to stay in a ny vehicel if this isn't set
		CAN_USE_DYNAMIC_STRAFE_DECISIONS = 4, -- This ped can make decisions on whether to strafe or not based on distance to destination, recent bullet events, etc.
		ALWAYS_FIGHT = 5, -- Ped will always fight upon getting threat response task
		FLEE_WHILST_IN_VEHICLE = 6, -- If in combat and in a vehicle, the ped will flee rather than attacking
		JUST_FOLLOW_VEHICLE = 7, -- If in combat and chasing in a vehicle, the ped will keep a distance behind rather than ramming
		PLAY_REACTION_ANIMS = 8, -- Deprecated
		WILL_SCAN_FOR_DEAD_PEDS = 9, -- Peds will scan for and react to dead peds found
		IS_A_GUARD = 10, -- Deprecated
		JUST_SEEK_COVER = 11, -- The ped will seek cover only
		BLIND_FIRE_IN_COVER = 12, -- Ped will only blind fire when in cover
		AGGRESSIVE = 13, -- Ped may advance
		CAN_INVESTIGATE = 14, -- Ped can investigate events such as distant gunfire, footsteps, explosions etc
		CAN_USE_RADIO = 15, -- Ped can use a radio to call for backup (happens after a reaction)
		CAN_CAPTURE_ENEMY_PEDS = 16, -- Deprecated
		ALWAYS_FLEE = 17, -- Ped will always flee upon getting threat response task
		CAN_TAUNT_IN_VEHICLE = 20, -- Ped can do unarmed taunts in vehicle
		CAN_CHASE_TARGET_ON_FOOT = 21, -- Ped will be able to chase their targets if both are on foot and the target is running away
		WILL_DRAG_INJURED_PEDS_TO_SAFETY = 22, -- Ped can drag injured peds to safety
		REQUIRES_LOS_TO_SHOOT = 23, -- Ped will require LOS to the target it is aiming at before shooting
		USE_PROXIMITY_FIRING_RATE = 24, -- Ped is allowed to use proximity based fire rate (increasing fire rate at closer distances)
		DISABLE_SECONDARY_TARGET = 25, -- Normally peds can switch briefly to a secondary target in combat, setting this will prevent that
		DISABLE_ENTRY_REACTIONS = 26, -- This will disable the flinching combat entry reactions for peds, instead only playing the turn and aim anims
		PERFECT_ACCURACY = 27, -- Force ped to be 100% accurate in all situations (added by Jay Reinebold)
		CAN_USE_FRUSTRATED_ADVANCE = 28, -- If we don't have cover and can't see our target it's possible we will advance, even if the target is in cover
		MOVE_TO_LOCATION_BEFORE_COVER_SEARCH = 29, -- This will have the ped move to defensive areas and within attack windows before performing the cover search
		CAN_SHOOT_WITHOUT_LOS = 30, -- Allow shooting of our weapon even if we don't have LOS (this isn't X-ray vision as it only affects weapon firing)
		MAINTAIN_MIN_DISTANCE_TO_TARGET = 31, -- Ped will try to maintain a min distance to the target, even if using defensive areas (currently only for cover finding + usage)
		CAN_USE_PEEKING_VARIATIONS = 34, -- Allows ped to use steamed variations of peeking anims
		DISABLE_PINNED_DOWN = 35, -- Disables pinned down behaviors
		DISABLE_PIN_DOWN_OTHERS = 36, -- Disables pinning down others
		OPEN_COMBAT_WHEN_DEFENSIVE_AREA_IS_REACHED = 37, -- When defensive area is reached the area is cleared and the ped is set to use defensive combat movement
		DISABLE_BULLET_REACTIONS = 38, -- Disables bullet reactions
		CAN_BUST = 39, -- Allows ped to bust the player
		IGNORED_BY_OTHER_PEDS_WHEN_WANTED = 40, -- This ped is ignored by other peds when wanted
		CAN_COMMANDEER_VEHICLES = 41, -- Ped is allowed to "jack" vehicles when needing to chase a target in combat
		CAN_FLANK = 42, -- Ped is allowed to flank
		SWITCH_TO_ADVANCE_IF_CANT_FIND_COVER = 43, -- Ped will switch to advance if they can't find cover
		SWITCH_TO_DEFENSIVE_IF_IN_COVER = 44, -- Ped will switch to defensive if they are in cover
		CLEAR_PRIMARY_DEFENSIVE_AREA_WHEN_REACHED = 45, -- Ped will clear their primary defensive area when it is reached
		CAN_FIGHT_ARMED_PEDS_WHEN_NOT_ARMED = 46, -- Ped is allowed to fight armed peds when not armed
		ENABLE_TACTICAL_POINTS_WHEN_DEFENSIVE = 47, -- Ped is not allowed to use tactical points if set to use defensive movement (will only use cover)
		DISABLE_COVER_ARC_ADJUSTMENTS = 48, -- Ped cannot adjust cover arcs when testing cover safety (atm done on corner cover points when  ped usingdefensive area + no LOS)
		USE_ENEMY_ACCURACY_SCALING = 49, -- Ped may use reduced accuracy with large number of enemies attacking the same local player target
		CAN_CHARGE = 50, -- Ped is allowed to charge the enemy position
		REMOVE_AREA_SET_WILL_ADVANCE_WHEN_DEFENSIVE_AREA_REACHED = 51, -- When defensive area is reached the area is cleared and the ped is set to use will advance movement
		USE_VEHICLE_ATTACK = 52, -- Use the vehicle attack mission during combat (only works on driver)
		USE_VEHICLE_ATTACK_IF_VEHICLE_HAS_MOUNTED_GUNS = 53, -- Use the vehicle attack mission during combat if the vehicle has mounted guns (only works on driver)
		ALWAYS_EQUIP_BEST_WEAPON = 54, -- Always equip best weapon in combat
		CAN_SEE_UNDERWATER_PEDS = 55, -- Ignores in water at depth visibility check
		DISABLE_AIM_AT_AI_TARGETS_IN_HELIS = 56, -- Will prevent this ped from aiming at any AI targets that are in helicopters
		DISABLE_SEEK_DUE_TO_LINE_OF_SIGHT = 57, -- Disables peds seeking due to no clear line of sight
		DISABLE_FLEE_FROM_COMBAT = 58, -- To be used when releasing missions peds if we don't want them fleeing from combat (mission peds already prevent flee)
		DISABLE_TARGET_CHANGES_DURING_VEHICLE_PURSUIT = 59, -- Disables target changes during vehicle pursuit
		CAN_THROW_SMOKE_GRENADE = 60, -- Ped may throw a smoke grenade at player loitering in combat
		CLEAR_AREA_SET_DEFENSIVE_IF_DEFENSIVE_CANNOT_BE_REACHED = 62, -- Will clear a set defensive area if that area cannot be reached
		DISABLE_BLOCK_FROM_PURSUE_DURING_VEHICLE_CHASE = 64, -- Disable block from pursue during vehicle chases
		DISABLE_SPIN_OUT_DURING_VEHICLE_CHASE = 65, -- Disable spin out during vehicle chases
		DISABLE_CRUISE_IN_FRONT_DURING_BLOCK_DURING_VEHICLE_CHASE = 66, -- Disable cruise in front during block during vehicle chases
		CAN_IGNORE_BLOCKED_LOS_WEIGHTING = 67, -- Makes it more likely that the ped will continue targeting a target with blocked los for a few seconds
		DISABLE_REACT_TO_BUDDY_SHOT = 68, -- Disables the react to buddy shot behaviour.
		PREFER_NAVMESH_DURING_VEHICLE_CHASE = 69, -- Prefer pathing using navmesh over road nodes
		ALLOWED_TO_AVOID_OFFROAD_DURING_VEHICLE_CHASE = 70, -- Ignore road edges when avoiding
		PERMIT_CHARGE_BEYOND_DEFENSIVE_AREA = 71, -- Permits ped to charge a target outside the assigned defensive area.
		USE_ROCKETS_AGAINST_VEHICLES_ONLY = 72, -- This ped will switch to an RPG if target is in a vehicle, otherwise will use alternate weapon.
		DISABLE_TACTICAL_POINTS_WITHOUT_CLEAR_LOS = 73, -- Disables peds moving to a tactical point without clear los
		DISABLE_PULL_ALONGSIDE_DURING_VEHICLE_CHASE = 74, -- Disables pull alongside during vehicle chase
		DISABLE_ALL_RANDOMS_FLEE = 78, -- If set on a ped, they will not flee when all random peds flee is set to TRUE (they are still able to flee due to other reasons)
		WILL_GENERATE_DEAD_PED_SEEN_SCRIPT_EVENTS = 79, -- This ped will send out a script DeadPedSeenEvent when they see a dead ped
		USE_MAX_SENSE_RANGE_WHEN_RECEIVING_EVENTS = 80, -- This will use the receiving peds sense range rather than the range supplied to the communicate event
		RESTRICT_IN_VEHICLE_AIMING_TO_CURRENT_SIDE = 81, -- When aiming from a vehicle the ped will only aim at targets on his side of the vehicle
		USE_DEFAULT_BLOCKED_LOS_POSITION_AND_DIRECTION = 82, -- LOS to the target is blocked we return to our default position and direction until we have LOS (no aiming)
		REQUIRES_LOS_TO_AIM = 83, -- LOS to the target is blocked we return to our default position and direction until we have LOS (no aiming)
		CAN_CRUISE_AND_BLOCK_IN_VEHICLE = 84, -- Allow vehicles spawned infront of target facing away to enter cruise and wait to block approaching target
		PREFER_AIR_COMBAT_WHEN_IN_AIRCRAFT = 85, -- Peds flying aircraft will prefer to target other aircraft over entities on the ground
		ALLOW_DOG_FIGHTING = 86, -- Allow peds flying aircraft to use dog fighting behaviours
		PREFER_NON_AIRCRAFT_TARGETS = 87, -- This will make the weight of targets who aircraft vehicles be reduced greatly compared to targets on foot or in ground based vehicles
		PREFER_KNOWN_TARGETS_WHEN_COMBAT_CLOSEST_TARGET = 88, -- When peds are tasked to go to combat, they keep searching for a known target for a while before forcing an unknown one
		FORCE_CHECK_ATTACK_ANGLE_FOR_MOUNTED_GUNS = 89, -- Only allow mounted weapons to fire if within the correct attack angle (default 25-degree cone). On a flag in order to keep exiting behaviour and only fix in specific cases.
		BLOCK_FIRE_FOR_VEHICLE_PASSENGER_MOUNTED_GUNS = 90, -- Blocks the firing state for passenger-controlled mounted weapons. Existing flags USE_VEHICLE_ATTACK and USE_VEHICLE_ATTACK_IF_VEHICLE_HAS_MOUNTED_GUNS only work for drivers.
	}

	-- Set a specific flee attribute
	rageE.FleeAttribute = {
		USE_COVER = 1,
		USE_VEHICLE = 2,
		CAN_SCREAM = 4,
		PREFER_PAVEMENTS = 8,
		WANDER_AT_END = 16,
		LOOK_FOR_CROWDS = 32,
		RETURN_TO_ORIGNAL_POSITION_AFTER_FLEE = 64,
		DISABLE_HANDS_UP = 128,
		UPDATE_TO_NEAREST_HATED_PED = 256,
		NEVER_FLEE = 512,
		DISABLE_COWER = 1024,
		DISABLE_EXIT_VEHICLE = 2048,
		DISABLE_REVERSE_IN_VEHICLE = 4096,
		DISABLE_ACCELERATE_IN_VEHICLE = 8192,
		DISABLE_FLEE_FROM_INDIRECT_THREATS = 16384,
		COWER_INSTEAD_OF_FLEE = 32768,
		FORCE_EXIT_VEHICLE = 65536,
		DISABLE_HESITATE_IN_VEHICLE = 131072,
		DISABLE_AMBIENT_CLIPS = 262144,
	}

	rageE.AlertnessState = {
		NOT_ALERT = 0, -- Ped hasn't received any events recently
		ALERT = 1, -- Ped has received at least one event
		VERY_ALERT = 2, -- Ped has received multiple events
		MUST_GO_TO_COMBAT = 3, -- This value basically means the ped should be in combat but isn't because he's not allowed to investigate etc
	}
end

rageE.ModTypeNUM = 50
rageE.ModType = {
	SPOILER = 0,
	BUMPER_F = 1,
	BUMPER_R = 2,
	SKIRT = 3,
	EXHAUST = 4,
	CHASSIS = 5,
	GRILL = 6,
	BONNET = 7,
	WING_L = 8,
	WING_R = 9,
	ROOF = 10,

	ENGINE = 11,
	BRAKES = 12,
	GEARBOX = 13,
	HORN = 14,
	SUSPENSION = 15,
	ARMOUR = 16,

	TOGGLE_NITROUS = 17,
	TOGGLE_TURBO = 18,
	TOGGLE_SUBWOOFER = 19,
	TOGGLE_TYRE_SMOKE = 20,
	TOGGLE_HYDRAULICS = 21,
	TOGGLE_XENON_LIGHTS = 22,

	WHEELS = 23,
	REAR_WHEELS = 24,

	-- Lowrider
	PLTHOLDER = 25,
	PLTVANITY = 26,

	INTERIOR1 = 27,
	INTERIOR2 = 28,
	INTERIOR3 = 29,
	INTERIOR4 = 30,
	INTERIOR5 = 31,
	SEATS = 32,
	STEERING = 33,
	KNOB = 34,
	PLAQUE = 35,
	ICE = 36,

	TRUNK = 37,
	HYDRO = 38,

	ENGINEBAY1 = 39,
	ENGINEBAY2 = 40,
	ENGINEBAY3 = 41,

	CHASSIS2 = 42,
	CHASSIS3 = 43,
	CHASSIS4 = 44,
	CHASSIS5 = 45,

	DOOR_L = 46,
	DOOR_R = 47,

	LIVERY = 48,
	LIGHTBAR = 49,
}
