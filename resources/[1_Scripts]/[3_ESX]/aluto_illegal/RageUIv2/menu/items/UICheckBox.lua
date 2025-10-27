---@type table
local SettingsButton = {
    Rectangle = { Y = 0, Width = 444, Height = 35 },
    Text = { X = 8, Y = 3, Scale = 0.26 },
    LeftBadge = { Y = -2, Width = 40, Height = 35 },
    RightBadge = { X = 395, Y = -2, Width = 40, Height = 35 },
    RightText = { X = 390, Y = 4, Scale = 0.26 },
    SelectedSprite = { Dictionary = "commonmenu", Texture = "gradient_nav", Y = 0, Width = 444, Height = 35 },
}

---@type table
local SettingsCheckbox = {
    Dictionary = "commonmenu", Textures = {
        "shop_box_blankb", -- 1
        "shop_box_tickb", -- 2
        "shop_box_blank", -- 3
        "shop_box_tick", -- 4
        "shop_box_crossb", -- 5
        "shop_box_cross", -- 6
    },
    X = 400, Y = -2, Width = 40, Height = 40
}

RageUI.CheckboxStyle = {
    Tick = 1,
    Cross = 2
}

---StyleCheckBox
---@param Selected number
---@param Checked boolean
---@param Box number
---@param BoxSelect number
---@return nil
local function StyleCheckBox(Selected, Checked, Box, BoxSelect, OffSet)
    ---@type table
    local CurrentMenu = RageUI.CurrentMenu;
    if OffSet == nil then
        OffSet = 0
    end
    if Selected then
        if Checked then
            RenderSprite(SettingsCheckbox.Dictionary, SettingsCheckbox.Textures[Box], CurrentMenu.X + SettingsCheckbox.X + CurrentMenu.WidthOffset - OffSet, CurrentMenu.Y + SettingsCheckbox.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, SettingsCheckbox.Width, SettingsCheckbox.Height)
        else
            RenderSprite(SettingsCheckbox.Dictionary, SettingsCheckbox.Textures[1], CurrentMenu.X + SettingsCheckbox.X + CurrentMenu.WidthOffset - OffSet, CurrentMenu.Y + SettingsCheckbox.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, SettingsCheckbox.Width, SettingsCheckbox.Height)
        end
    else
        if Checked then
            RenderSprite(SettingsCheckbox.Dictionary, SettingsCheckbox.Textures[BoxSelect], CurrentMenu.X + SettingsCheckbox.X + CurrentMenu.WidthOffset - OffSet, CurrentMenu.Y + SettingsCheckbox.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, SettingsCheckbox.Width, SettingsCheckbox.Height)
        else
            RenderSprite(SettingsCheckbox.Dictionary, SettingsCheckbox.Textures[3], CurrentMenu.X + SettingsCheckbox.X + CurrentMenu.WidthOffset - OffSet, CurrentMenu.Y + SettingsCheckbox.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, SettingsCheckbox.Width, SettingsCheckbox.Height)
        end
    end
end


function RageUI.Checkbox(Label, Description, Checked, Style, Actions)
    ---@type table
    local CurrentMenu = RageUI.CurrentMenu;
    if CurrentMenu ~= nil then
        if CurrentMenu() then

            ---@type number
            local Option = RageUI.Options + 1
            if CurrentMenu.Pagination.Minimum <= Option and CurrentMenu.Pagination.Maximum >= Option then
                ---@type number
                local Selected = CurrentMenu.Index == Option
                local LeftBadgeOffset = ((Style.LeftBadge == RageUI.BadgeStyle.None or Style.LeftBadge == nil) and 0 or 27)
                local RightBadgeOffset = ((Style.RightBadge == RageUI.BadgeStyle.None or Style.RightBadge == nil) and 0 or 32)
                local BoxOffset = 0
                RageUI.ItemsSafeZone(CurrentMenu)

                local Hovered = false;

                ---@type boolean
                if CurrentMenu.EnableMouse == true and (CurrentMenu.CursorStyle == 0) or (CurrentMenu.CursorStyle == 1) then
                    Hovered = RageUI.ItemsMouseBounds(CurrentMenu, Selected, Option, SettingsButton);
                end
                
                if Selected then
                    RenderSprite(SettingsButton.SelectedSprite.Dictionary, SettingsButton.SelectedSprite.Texture, CurrentMenu.X, CurrentMenu.Y + SettingsButton.SelectedSprite.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, SettingsButton.SelectedSprite.Width + CurrentMenu.WidthOffset, SettingsButton.SelectedSprite.Height, 0, 122, 35, 235, 255)
                else
                    RenderSprite(SettingsButton.SelectedSprite.Dictionary, SettingsButton.SelectedSprite.Texture, CurrentMenu.X, CurrentMenu.Y + SettingsButton.SelectedSprite.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, SettingsButton.SelectedSprite.Width + CurrentMenu.WidthOffset, SettingsButton.SelectedSprite.Height, 0, 30, 30, 30, 255)
                end

                if type(Style) == "table" then
                    if Style.Enabled == true or Style.Enabled == nil then
                        if Selected then
                            RenderText(Label, CurrentMenu.X + SettingsButton.Text.X + LeftBadgeOffset, CurrentMenu.Y + SettingsButton.Text.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, 0, SettingsButton.Text.Scale, 30, 30, 30, 255)
                        else
                            RenderText(Label, CurrentMenu.X + SettingsButton.Text.X + LeftBadgeOffset, CurrentMenu.Y + SettingsButton.Text.Y + CurrentMenu.SubtitleHeight + RageUI.ItemOffset, 0, SettingsButton.Text.Scale, 255, 255, 255, 255)
                        end
                    end
                end

                BoxOffset = RightBadgeOffset
                if Style.Style ~= nil then
                    if Style.Style == RageUI.CheckboxStyle.Tick then
                        StyleCheckBox(Selected, Checked, 2, 4, BoxOffset)
                    elseif Style.Style == RageUI.CheckboxStyle.Cross then
                        StyleCheckBox(Selected, Checked, 5, 6, BoxOffset)
                    else
                        StyleCheckBox(Selected, Checked, 2, 4, BoxOffset)
                    end
                else
                    StyleCheckBox(Selected, Checked, 2, 4, BoxOffset)
                end

                if Selected and (CurrentMenu.Controls.Select.Active or (Hovered and CurrentMenu.Controls.Click.Active)) and (Style.Enabled == true or Style.Enabled == nil) then
                    local Audio = RageUI.Settings.Audio
                    RageUI.PlaySound(Audio[Audio.Use].Select.audioName, Audio[Audio.Use].Select.audioRef)
                    Checked = not Checked
                    if (Checked) then
                        if (Actions.onChecked ~= nil) then
                            Actions.onChecked();
                        end
                    else
                        if (Actions.onUnChecked ~= nil) then
                            Actions.onUnChecked();
                        end
                    end
                end

                RageUI.ItemOffset = RageUI.ItemOffset + SettingsButton.Rectangle.Height
                RageUI.ItemsDescription(CurrentMenu, Description, Selected)

                if (Actions.onSelected ~= nil) and (Selected) then
                    Actions.onSelected(Checked);
                end
            end
            RageUI.Options = RageUI.Options + 1
        end
    end
end
