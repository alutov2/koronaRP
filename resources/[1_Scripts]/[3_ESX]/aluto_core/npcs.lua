local peds = {
	{ model = "a_m_m_business_01", x = 216.210983, y = -810.105469, z = 29.712036, h = 50 }, --Garage
	{ model = "a_m_y_stbla_02", x = 402.197815, y = -1632.540649, z = 28.279907, h = 50 }, -- Fourrière
	{ model = "s_m_y_dealer_01", x = 1508.531860, y = 3574.971436, z = 37.732544, h = 25.511812 }, -- Traitement Sandy
}

Citizen.CreateThread(function()
	for _, info in pairs(peds) do
		RequestModel(info.model)
		while not HasModelLoaded(info.model) do
			Citizen.Wait(100)
		end
		pedCreated = CreatePed(0, info.model, info.x, info.y, info.z, info.h, false, false)
		SetBlockingOfNonTemporaryEvents(pedCreated, true)
		SetEntityInvincible(pedCreated, true)
		FreezeEntityPosition(pedCreated, true)
	end
end)
