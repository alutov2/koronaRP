ReportsInfos = {
    Waiting = 0,
    Taked = 0,
}

RegisterNetEvent('korona:ReceiveReportsList')
AddEventHandler('korona:ReceiveReportsList', function(table)
    Reports = table
    ReportsInfos.Waiting = 0
    ReportsInfos.Taked = 0

    for k, v in pairs(Reports) do
        if v.state == 'waiting' then
            ReportsInfos.Waiting = ReportsInfos.Waiting + 1
        elseif v.state == 'taked' then
            ReportsInfos.Taked = ReportsInfos.Taked + 1
        end
    end
end)