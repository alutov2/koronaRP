local blips = {
    {title = "Garage", color = 39, id = 50, x = 216.210983, y = -810.105469, z = 30.712036}, -- Parking Central
    {title = "Fourrière", color = 17, id = 67, x = 402.197815, y = -1632.540649, z = 29.279907} -- JSP wollah
}

Citizen.CreateThread(function()
    for _, info in pairs(blips) do
        info.blip = AddBlipForCoord(info.x, info.y, info.z)
        SetBlipSprite(info.blip, info.id)
        SetBlipDisplay(info.blip, 4)
        SetBlipScale(info.blip, 1.0)
        SetBlipColour(info.blip, info.color)
        SetBlipAsShortRange(info.blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(info.title)
        EndTextCommandSetBlipName(info.blip)
    end
end)