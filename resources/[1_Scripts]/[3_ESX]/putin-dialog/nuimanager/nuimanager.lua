ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local dialogOpen = false
local currDialog = nil
local currFS = {}
local currFC = {}

function showDialog(name, label, input, maxLength, help, submitFunc, cancelFunc, pushEnter, textarea)
	if not dialogOpen then
		currDialog = name
		currFS = submitFunc
		currFC = cancelFunc
		SetNuiFocus(true, true)
		if textarea == nil then
			textarea = false
		end
		if pushEnter == nil then
			pushEnter = false
		end
		SendNUIMessage({
			action = "showDialog",
			menuAction = name,
			label = label,
			defaultInput = input,
			maxLength = maxLength,
			helpText = help,
			pushEnter = pushEnter,
			textarea = textarea,
		})
		dialogOpen = true
	else
		print('^1dialog box already open!')
	end
end

RegisterNUICallback('exit', function(data)
    SetNuiFocus(false, false)
	if currFC ~= nil then
		currFC()
	end
	currDialog = nil
	currFS = nil
	currFC = nil
	dialogOpen = false
end)

RegisterNUICallback('submit', function(data)
	SetNuiFocus(false, false)
	dialogOpen = false
	if data.currMA == currDialog then
		local doSubmitFunction = currFS
		currDialog = nil
		currFS = nil
		currFC = nil
		doSubmitFunction(data.text)
	else
		print("Cheater alert! Someone is trying to submit a dialog that isn't open!")
	end
end)

RegisterCommand('sertyleak_dialog', function(src, args)
    showDialog(
        'unique_dialog_name', 
        'Montant a prendre', 
        '0', 
        10, 
        'recktification66k', 
        function(data)
			ESX.ShowNotification("Vous avez prit "..data.."")
        end, 
        function()
            ESX.ShowNotification("Vous avez annulé l'action")
        end, 
        false, 
        true
    )
end)
