local xMenuFrame, currentMenu

---@param menu xMenu
---@return boolean
local function doesCurrentItemContainAnyPanel(menu)
	local item = menu.items[menu.index]
	if item and (item.colorPanel or item.colorPicker or item.sliderPanel or item.gridPanel) then
		return true
	end

	return false
end

local function startControlsTick(menu)
	CreateThread(function()
		while menu:IsVisible() do
			if not currentMenu.disablePlayerControls then
				if IS_RDR3 then
					-- Next Weapon
					DisableControlAction(0, 0xFD0F0C2C, true)

					-- Previous Weapon
					DisableControlAction(0, 0xCC1075A7, true)
				else
					if currentMenu.currentItemContainsPanel then
						DisableControlAction(0, 1, true) -- INPUT_LOOK_LR
						DisableControlAction(0, 2, true) -- INPUT_LOOK_UD
					end

					DisableControlAction(0, 24, true) -- INPUT_ATTACK
					DisableControlAction(0, 106, true) -- INPUT_VEH_MOUSE_CONTROL_OVERRIDE
					DisableControlAction(0, 257, true) -- INPUT_ATTACK2
					DisableControlAction(0, 140, true) -- INPUT_MELEE_ATTACK_LIGHT
					DisableControlAction(0, 141, true) -- INPUT_MELEE_ATTACK_HEAVY
					DisableControlAction(0, 142, true) -- INPUT_MELEE_ATTACK_ALTERNATE
					DisableControlAction(0, 263, true) -- INPUT_MELEE_ATTACK1
					DisableControlAction(0, 264, true) -- INPUT_MELEE_ATTACK2
					DisableControlAction(0, 25, true) -- INPUT_AIM
				end
			end

			-- Disable vehicle radio scroll controls
			if CPlayer().InVehicle then
				DisableControlAction(0, 81, true) -- INPUT_VEH_NEXT_RADIO
				DisableControlAction(0, 82, true) -- INPUT_VEH_PREV_RADIO
			end

			Wait(0)
		end
	end)
end

-- xMenu Class
---@class xMenu
local xMenu = { ready = false, cache = {} }
local __menuInstance = {
	__index = xMenu,
	__type = "xMenu",
}

--- Returns a new instance of xMenu.
---
--- @param id string
--- @param label string
--- @param description string
--- @param closable boolean
--- @param disablePlayerControls boolean
--- @param disableIndexFallback boolean
--- @return xMenu | nil
function xMenu.new(id, label, description, closable, disablePlayerControls, disableIndexFallback)
	local self = setmetatable(EventBase(), __menuInstance)

	self.id = id
	self.label = label
	self.description = description
	self.closable = (closable == nil) and true or closable
	self.disablePlayerControls = disablePlayerControls or false

	self.lastItemId = 0
	self.eventBuses = {}
	self.items = {}
	self.index = 1
	self.minIndex = 1
	self.maxIndex = 8
	self.disableIndexFallback = not not disableIndexFallback
	self.controlsPaused = false
	self.currentItemContainsPanel = false

	self:on("close", function()
		PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET")
	end)

	xMenu.cache[id] = self

	return self
end

--- @return xMenu | nil
function xMenu.GetCurrentMenu()
	return currentMenu
end

--- @return boolean
function xMenu.IsAnyMenuOpened()
	return currentMenu ~= nil
end

local function refreshItemsInternal(menu)
	xMenuFrame:SendMessage({ action = "setItems", items = menu.items })
end

function xMenu:Refresh()
	if currentMenu ~= self then
		return
	end
	refreshItemsInternal(self)
end

-- Item class
local SET_FUNCTIONS <const> = {
	["Text"] = { key = "label", forbiddenItemTypes = {} },
	["Description"] = { key = "description", forbiddenItemTypes = {} },
	["RightText"] = { key = "rightText", forbiddenItemTypes = { "checkbox", "list" } },
	["Checked"] = { key = "checked", forbiddenItemTypes = { "button", "list" } },
	["ListIndex"] = { key = "listIndex", forbiddenItemTypes = { "button", "checkbox" } },
}

local xMenuItem = {}
local __itemInstance = {
	__index = xMenuItem,
	__type = "xMenuItem",
}

local function getMenuItemFromId(menuId, itemId)
	local menu = xMenu.cache[menuId]

	if not menu then
		return nil, nil
	end

	for i = 1, #menu.items do
		local menuItem = menu.items[i]

		if menuItem.id == itemId then
			return menuItem, menu
		end
	end

	return nil, nil
end

--- @class xMenuItem
--- @param type string
--- @param id string
--- @param menu string
--- @return xMenuItem
function xMenuItem.new(type, id, menu)
	local self = setmetatable(EventBase(), __itemInstance)

	self.type = type
	self.id = id
	self.menu = menu

	return self
end

-- Define items "set" functions
for name, data in pairs(SET_FUNCTIONS) do
	--- @return xMenuItem
	xMenuItem["Set" .. name] = function(self, value)
		for i = 1, #data.forbiddenItemTypes do
			if data.forbiddenItemTypes[i] == self.type then
				return self
			end
		end

		local item, parentMenu = getMenuItemFromId(self.menu, self.id)
		if not item then
			return
		end

		item[data.key] = value

		-- Refresh if the menu is visible
		if parentMenu:IsVisible() then
			refreshItemsInternal(parentMenu)
		end

		return self
	end
end

function xMenuItem:Remove()
	local item, parentMenu = getMenuItemFromId(self.menu, self.id)
	if not item then
		return
	end

	for i = 1, #parentMenu.items do
		if parentMenu.items[i].id == self.id then
			table.remove(parentMenu.items, i)
			break
		end
	end

	-- Refresh if the menu is visible
	if parentMenu:IsVisible() then
		refreshItemsInternal(currentMenu)
	end
end

function xMenuItem:GetListIndex()
	if self.type ~= "list" then
		return
	end

	local item, parentMenu = getMenuItemFromId(self.menu, self.id)
	if not item then
		return
	end

	return item.listIndex
end

--- @param type string
function xMenuItem:AddColorPanel(type)
	local item, parentMenu = getMenuItemFromId(self.menu, self.id)
	if not item then
		return
	end

	item.colorPanel = { type = type, index = 0, minIndex = 0, maxIndex = 7 }

	-- Refresh if the menu is visible
	if parentMenu:IsVisible() then
		refreshItemsInternal(parentMenu)
	end

	return self
end

function xMenuItem:AddColorPicker()
	local item, parentMenu = getMenuItemFromId(self.menu, self.id)
	if not item then
		return
	end

	item.colorPicker = true

	-- Refresh if the menu is visible
	if parentMenu:IsVisible() then
		refreshItemsInternal(parentMenu)
	end

	return self
end

--- @param maxRange number
function xMenuItem:AddSliderPanel(maxRange)
	local item, parentMenu = getMenuItemFromId(self.menu, self.id)
	if not item then
		return
	end

	item.sliderPanel = { maxRange = maxRange }

	-- Refresh if the menu is visible
	if parentMenu:IsVisible() then
		refreshItemsInternal(parentMenu)
	end

	return self
end

--- @param topText string
--- @param bottomText string
--- @param leftText string
--- @param rightText string
function xMenuItem:AddGridPanel(topText, bottomText, leftText, rightText)
	local item, parentMenu = getMenuItemFromId(self.menu, self.id)
	if not item then
		return
	end

	item.gridPanel = {
		type = "default",
		xAxis = 0.5,
		yAxis = 0.5,
		topText = topText,
		bottomText = bottomText,
		leftText = leftText,
		rightText = rightText,
	}

	-- Refresh if the menu is visible
	if parentMenu:IsVisible() then
		refreshItemsInternal(parentMenu)
	end

	return self
end

--- @param leftText string
--- @param rightText string
function xMenuItem:AddHorizontalGridPanel(leftText, rightText)
	local item, parentMenu = getMenuItemFromId(self.menu, self.id)
	if not item then
		return
	end

	item.gridPanel = { type = "horizontal", xAxis = 0.5, leftText = leftText, rightText = rightText }

	-- Refresh if the menu is visible
	if parentMenu:IsVisible() then
		refreshItemsInternal(parentMenu)
	end

	return self
end

--- @param x number
--- @param y number
function xMenuItem:SetGridPanelAxis(x, y)
	local item, parentMenu = getMenuItemFromId(self.menu, self.id)
	if not item or not item.gridPanel then
		return
	end
	if x ~= nil and (x < 0.0 or x > 1.0) then
		return
	end
	if y ~= nil and (y < 0.0 or y > 1.0) then
		return
	end

	item.gridPanel.xAxis = x
	item.gridPanel.yAxis = y

	-- Refresh if the menu is visible
	if parentMenu:IsVisible() then
		refreshItemsInternal(parentMenu)
	end

	return self
end

---@param icon string
function xMenuItem:SetIcon(icon)
	local item, parentMenu = getMenuItemFromId(self.menu, self.id)
	if not item then
		return
	end

	item.icon = icon

	-- Refresh if the menu is visible
	if parentMenu:IsVisible() then
		refreshItemsInternal(parentMenu)
	end

	return self
end

setmetatable(xMenuItem, {
	__index = EventBase,
	__call = function(self, ...)
		return xMenu.new(...)
	end,
})

--- Get xMenu next item id.
--- @return string
function xMenu:GetNextItemId()
	self.lastItemId += 1

	return "item_" .. self.lastItemId
end

--- Check whether an xMenu is visible or not.
--- @return boolean
function xMenu:IsVisible()
	return currentMenu and currentMenu.id == self.id
end

function xMenu:GetHoveredItem()
	if not self:IsVisible() then
		return nil
	end

	return self.items[self.index]
end

--- Add a button to an xMenu.
--- @param label string
--- @param description string
--- @return xMenuItem
function xMenu:AddButton(label, description)
	local id = self:GetNextItemId()
	local itemInstance = xMenuItem.new("button", id, self.id)

	self.items[#self.items + 1] = { type = "button", id = id, label = label, description = description }
	self.eventBuses[id] = itemInstance

	return itemInstance
end

--- Add a list to an xMenu.
--- @param label string
--- @param content string[]
--- @param description string
--- @param index number
function xMenu:AddList(label, content, description, index)
	local id = self:GetNextItemId()
	local itemInstance = xMenuItem.new("list", id, self.id)

	self.items[#self.items + 1] =
		{ type = "list", id = id, label = label, description = description, content = content, listIndex = index or 1 }
	self.eventBuses[id] = itemInstance

	return itemInstance
end

--- Add a numeral list to an xMenu.
--- @param label string
--- @param min number
--- @param max number
--- @param description string
--- @param index number
function xMenu:AddNumeralList(label, min, max, description, index)
	local id = self:GetNextItemId()
	local itemInstance = xMenuItem.new("list", id, self.id)

	local content, contentLen = {}, 0

	for i = min, max do
		contentLen = contentLen + 1
		content[contentLen] = i
	end

	self.items[#self.items + 1] =
		{ type = "list", id = id, label = label, description = description, content = content, listIndex = index or 1 }
	self.eventBuses[id] = itemInstance

	return itemInstance
end

--- Add a checkbox to an xMenu.
--- @param label string
--- @param checked boolean
--- @param description string
--- @return string id Item ID
function xMenu:AddCheckbox(label, checked, description)
	local id = self:GetNextItemId()
	local itemInstance = xMenuItem.new("checkbox", id, self.id)

	self.items[#self.items + 1] =
		{ type = "checkbox", id = id, label = label, description = description, checked = checked }
	self.eventBuses[id] = itemInstance

	return itemInstance
end

---@param menu xMenu
---@param toggle boolean
---@param skipParent boolean
---@param triggeredByPlayer boolean
---@param submenu xMenu
---@return boolean
local function showMenuInternal(menu, toggle, skipParent, triggeredByPlayer, submenu, skipBeforeOpening)
	local isAnyMenuOpened = currentMenu ~= nil

	if toggle then
		if isAnyMenuOpened then
			return false
		end

		if not skipBeforeOpening then
			-- Allows to cancel opening
			local preventOpening = false

			menu:emit("beforeOpening", function()
				preventOpening = true
			end, triggeredByPlayer)

			if preventOpening then
				return false
			end
		end

		xMenuFrame:SendMessage({
			action = "createMenu",
			id = menu.id,
			label = menu.label,
			description = menu.description,
			closable = menu.closable,
			index = (menu.index - 1),
			minIndex = (menu.minIndex - 1),
			maxIndex = (menu.maxIndex - 1),
			disableIndexFallback = menu.disableIndexFallback,
			items = menu.items,
			controlsPaused = menu.controlsPaused,
		})

		xMenuFrame:Show()

		menu.currentItemContainsPanel = doesCurrentItemContainAnyPanel(menu)
		xMenuFrame:Focus(menu.currentItemContainsPanel, not menu.disablePlayerControls)

		currentMenu = menu
		menu:emit("open", menu.index)
		startControlsTick(menu)

		return true
	else
		if not isAnyMenuOpened then
			return false
		end

		xMenuFrame:Hide()
		xMenuFrame:Unfocus()
		xMenuFrame:SendMessage({ action = "menuClosed" })
		currentMenu = nil

		local parentMenu = not skipParent and menu.previousMenu or nil
		local nextMenu = parentMenu or submenu

		menu:emit("close", not not triggeredByPlayer, nextMenu)

		-- Go back to parent menu if any
		if parentMenu then
			showMenuInternal(parentMenu, true)
			menu.previousMenu = nil
		end

		return true
	end
end

--- Shows an xMenu.
--- @param toggle boolean
--- @param skipParent boolean
function xMenu:Show(toggle, skipParent)
	return showMenuInternal(self, toggle, skipParent)
end

---@param submenu xMenu
function xMenu:AddSubmenu(submenu, action)
	local button = self:AddButton(submenu.label)
	button:SetRightText("➤")

	button:on("buttonPress", function()
		-- Allows to cancel opening
		local preventOpening = false

		submenu:emit("beforeOpening", function()
			preventOpening = true
		end, false)

		if preventOpening then
			return
		end

		-- Closes parent menu
		showMenuInternal(self, false, true, true, submenu, false)

		if action then
			action()
		end

		-- Opens submenu
		submenu.previousMenu = self
		showMenuInternal(submenu, true, false, false, nil, true)
	end)

	return button
end

function xMenu:Reset(keepIndex)
	self.items = {}
	self.eventBuses = {}
	self.lastItemId = 0

	local isMenuVisible = self:IsVisible()
	if not keepIndex then
		self.index = 1
		self.minIndex = 1
		self.maxIndex = 8 -- NOTE: This index have to be MAX_MENU_ITEMS (from Vue project) + 1

		if isMenuVisible then
			xMenuFrame:SendMessage({ action = "resetMenuIndex", id = self.id })
		end
	end

	-- If the menu is visible, refresh
	if isMenuVisible then
		refreshItemsInternal(currentMenu)
	end
end

---@param menu xMenu
function xMenu:SwitchTo(menu)
	-- Allows to cancel opening
	local preventOpening = false

	menu:emit("beforeOpening", function()
		preventOpening = true
	end, false)

	if preventOpening then
		return false
	end

	showMenuInternal(self, false, true, false, menu, false)

	menu.previousMenu = self
	showMenuInternal(menu, true, false, false, nil, true)

	return true
end

---@param index number
function xMenu:SetIndex(index)
	local isIndexInvalid = index < 1 or index > #self.items
	if isIndexInvalid or self.index == index then
		return
	end

	self.index = index
	xMenuFrame:SendMessage({ action = "setMenuIndex", id = self.id, index = index })
end

---@param paused boolean
function xMenu:PauseControls(paused)
	self.controlsPaused = paused
	xMenuFrame:SendMessage({ action = "setMenuControlsPaused", id = self.id, paused = paused })
end

-- Metatable
setmetatable(xMenu, {
	__index = EventBase,
	__call = function(self, ...)
		return xMenu.new(...)
	end,
})

---@type xMenu
IMPOSTEUR.Classes.xMenu = xMenu

-- Frame creation
IMPOSTEUR.On("nui:ready", function()
	local frameName <const> = "xmenu"
	local frame = IMPOSTEUR.AddFrame(
		frameName,
		("https://cfx-nui-%s/client/libs/xmenu/dist/index.html"):format(CURRENT_RESOURCE),
		false
	)

	frame:OnMessage(function(data, cb)
		local menu = currentMenu

		if data.action == "closed" then
			showMenuInternal(menu, false, false, true)
		else
			local item = getMenuItemFromId(menu.id, data.id)

			-- Dispatch events
			if data.action == "buttonPressed" then
				menu:emit("buttonPress", data.id)
				menu.eventBuses[data.id]:emit("buttonPress")
				PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET")
			elseif data.action == "listChanged" then
				item.listIndex = data.listIndex
				menu:emit("listChange", data.id, data.listIndex, data.listText)
				menu.eventBuses[data.id]:emit("listChange", data.listIndex, data.listText)
				PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET")
			elseif data.action == "checkboxChanged" then
				item.checked = data.checked
				menu:emit("checkboxChange", data.id, data.checked)
				menu.eventBuses[data.id]:emit("checkboxChange", data.checked)
				PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET")
			elseif data.action == "itemHovered" then
				menu.index = data.itemIndex
				menu.minIndex = data.minIndex
				menu.maxIndex = data.maxIndex
				menu.currentItemContainsPanel = doesCurrentItemContainAnyPanel(menu)

				xMenuFrame:Focus(menu.currentItemContainsPanel, not menu.disablePlayerControls)

				menu:emit("hovered", data.id)
				menu.eventBuses[data.id]:emit("hovered")
				PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET")
			elseif data.action == "colorUpdated" then
				menu:emit("colorUpdated", data.id, data.index)
				menu.eventBuses[data.id]:emit("colorUpdated", data.index)
				PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET")
			elseif data.action == "rgbColorUpdated" then
				menu:emit("colorUpdated", data.id, data.color)
				menu.eventBuses[data.id]:emit("colorUpdated", data.color)
			elseif data.action == "sliderValueUpdated" then
				menu:emit("sliderUpdated", data.id, data.value)
				menu.eventBuses[data.id]:emit("sliderUpdated", data.value)
			elseif data.action == "gridUpdated" then
				local x, y = data.x + 0.0, data.y + 0.0

				if data.x ~= nil then
					item.gridPanel.xAxis = x
				end
				if data.y ~= nil then
					item.gridPanel.yAxis = y
				end

				menu:emit("gridUpdated", data.id, x, y)
				menu.eventBuses[data.id]:emit("gridUpdated", x, y)
			end
		end

		cb({})
	end)

	xMenuFrame = frame
end)
