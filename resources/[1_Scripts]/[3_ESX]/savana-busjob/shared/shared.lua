shared = {}
shared.Framework = "auto" -- qb, esx
shared.UseTarget = true
shared.debug = false
shared.infoText = true
shared.CustomKey = false -- Custom Vehicle Keys

shared.BusJob = {
    [1] = {
        ped = "a_m_m_genfat_02",
        pedCoords = vector4(454.23, -600.75, 28.57, 257.30),
        blip = {
            size = 0.7,
            color = 5,
            sprite = 513,
            text = "Bus Job",
            blipname = "Bus Job",
        },
        Jobs = {
            {
                level = 1, xp = 50,
                imgSrc = 'images/bus/tourbus.png',
                name = 'Tour Bus',  
                vehicles = 'tourbus', totalPrice = 150, 
                start = { vector3(462.65, -605.81, 28.50), 215.05}, 
                stops = {
                    vector4(304.36, -764.56, 29.31, 252.09),
                    vector4(216.2522, -1009.2938, 29.2561, 258.1628),
                    vector4(22.6132, -953.4213, 29.3576, 162.0023),
                    vector4(51.5821, -768.8035, 44.1811, 73.0378),            
                    vector4(234.6856, -372.0683, 44.3527, 345.4192),   
                    vector4(394.3994, -201.1967, 59.1583, 70.8903),
                    vector4(316.4517, 167.6647, 103.7771, 133.1958)                 

                }, 
                ends = vector3(466.47, -588.31, 28.50)
            },
            {
                level = 5, xp = 75,
                imgSrc = 'images/bus/bus.png',
                name = 'City Bus',  
                vehicles = 'bus', totalPrice = 200, 
                start = { vector3(462.65, -605.81, 28.50), 215.05}, 
                stops = {
                    vector4(304.36, -764.56, 29.31, 252.09),
                    vector4(-110.31, -1686.29, 29.31, 223.84),
                    vector4(-712.83, -824.56, 23.54, 194.7),
                    vector4(-692.63, -670.44, 30.86, 61.84),
                    vector4(-250.14, -886.78, 30.63, 8.67),
                }, 
                ends = vector3(466.47, -588.31, 28.50)
            },
            {
                level = 10, xp = 150,
                imgSrc = 'images/bus/airbus.png',
                name = 'Airport Bus',  
                vehicles = 'airbus', totalPrice = 400, 
                start = { vector3(462.65, -605.81, 28.50), 215.05}, 
                stops = {
                    vector4(304.36, -764.56, 29.31, 252.09),
                    vector4(247.0506, -658.0617, 38.7834, 76.0060),
                    vector4(266.9132, -353.4374, 44.7808, 158.1808),
                    vector4(137.9880, -419.0701, 41.1295, 272.3218),
                    vector4(-116.3035, -1309.6704, 29.3017, 282.0903),
                    vector4(-294.2579, -1483.3800, 30.6520, 267.2313),
                    vector4(-426.7500, -1836.9141, 19.9458, 208.1177),
                    vector4(-1029.4093, -2491.1777, 20.1693, 244.6902),
                    vector4(-1034.3373, -2733.1995, 20.1693, 352.8683),
                }, 
                ends = vector3(466.47, -588.31, 28.50)
            },
            {
                level = 20, xp = 300,
                imgSrc = 'images/bus/coach.png',
                name = 'Interstate',  
                vehicles = 'coach', totalPrice = 750, 
                start = { vector3(462.65, -605.81, 28.50), 215.05}, 
                stops = {
                    vector4(845.6084, 65.5506, 67.3035, 57.9013),
                    vector4(1562.7502, 882.4903, 77.4696, 72.3812),
                    vector4(2888.5774, 4199.5815, 50.1097, 118.6051),
                    vector4(2803.9941, 4923.5039, 34.4743, 124.6325),
                    vector4(2237.8335, 5205.2827, 60.9060, 162.6792),
                    vector4(1657.9965, 4871.0542, 42.0743, 274.8327),
                    vector4(2149.2622, 4744.5986, 41.1407, 8.7595),
                    vector4(2743.2681, 4385.7104, 48.7480, 23.3471),
                    vector4(2760.1606, 3390.5181, 56.1079, 245.3017),
                }, 
                ends = vector3(466.47, -588.31, 28.50)
            },
         },
    },
}

shared.PedModels = {
    `a_f_m_skidrow_01`,
    `a_f_m_soucentmc_01`,
    `a_f_m_soucent_01`,
    `a_f_m_soucent_02`,
    `a_f_m_tourist_01`,
    `a_f_m_trampbeac_01`,
    `a_f_m_tramp_01`,
    `a_f_o_genstreet_01`,
    `a_f_o_indian_01`,
    `a_f_o_ktown_01`,
    `a_f_o_salton_01`,
    `a_f_o_soucent_01`,
    `a_f_o_soucent_02`,
    `a_f_y_beach_01`,
    `a_f_y_bevhills_01`,
    `a_f_y_bevhills_02`,
    `a_f_y_bevhills_03`,
    `a_f_y_bevhills_04`,
    `a_f_y_business_01`,
    `a_f_y_business_02`,
    `a_f_y_business_03`,
    `a_f_y_business_04`,
    `a_f_y_eastsa_01`,
    `a_f_y_eastsa_02`,
    `a_f_y_eastsa_03`,
    `a_f_y_epsilon_01`,
    `a_f_y_fitness_01`,
    `a_f_y_fitness_02`,
    `a_f_y_genhot_01`,
    `a_f_y_golfer_01`,
    `a_f_y_hiker_01`,
    `a_f_y_hipster_01`,
    `a_f_y_hipster_02`,
    `a_f_y_hipster_03`,
    `a_f_y_hipster_04`,
    `a_f_y_indian_01`,
    `a_f_y_juggalo_01`,
    `a_f_y_runner_01`,
    `a_f_y_rurmeth_01`,
    `a_f_y_scdressy_01`,
    `a_f_y_skater_01`,
    `a_f_y_soucent_01`,
    `a_f_y_soucent_02`,
    `a_f_y_soucent_03`,
    `a_f_y_tennis_01`,
    `a_f_y_tourist_01`,
    `a_f_y_tourist_02`,
    `a_f_y_vinewood_01`,
    `a_f_y_vinewood_02`,
    `a_f_y_vinewood_03`,
    `a_f_y_vinewood_04`,
    `a_f_y_yoga_01`,
    `g_f_y_ballas_01`,
    `ig_barry`,
    `ig_bestmen`,
    `ig_beverly`,
    `ig_car3guy1`,
    `ig_car3guy2`,
    `ig_casey`,
    `ig_chef`,
    `ig_chengsr`,
    `ig_chrisformage`,
    `ig_clay`,
    `ig_claypain`,
    `ig_cletus`,
    `ig_dale`,
    `ig_dreyfuss`,
    `ig_fbisuit_01`,
    `ig_floyd`,
    `ig_groom`,
    `ig_hao`,
    `ig_hunter`,
    `csb_prolsec`,
    `ig_joeminuteman`,
    `ig_josef`,
    `ig_josh`,
    `ig_lamardavis`,
    `ig_lazlow`,
    `ig_lestercrest`,
    `ig_lifeinvad_01`,
    `ig_lifeinvad_02`,
    `ig_manuel`,
    `ig_milton`,
    `ig_mrk`,
    `ig_nervousron`,
    `ig_nigel`,
    `ig_old_man1a`,
    `ig_old_man2`,
    `ig_oneil`,
    `ig_orleans`,
    `ig_ortega`,
    `ig_paper`,
    `ig_priest`,
    `ig_prolsec_02`,
    `ig_ramp_gang`,
    `ig_ramp_hic`,
    `ig_ramp_hipster`,
    `ig_ramp_mex`,
    `ig_roccopelosi`,
    `ig_russiandrunk`,
    `ig_siemonyetarian`,
    `ig_solomon`,
    `ig_stevehains`,
    `ig_stretch`,
    `ig_talina`,
    `ig_taocheng`,
    `ig_taostranslator`,
    `ig_tenniscoach`,
    `ig_terry`,
    `ig_tomepsilon`,
    `ig_tylerdix`,
    `ig_wade`,
    `ig_zimbor`,
    `s_m_m_paramedic_01`,
    `a_m_m_afriamer_01`,
    `a_m_m_beach_01`,
    `a_m_m_beach_02`,
    `a_m_m_bevhills_01`,
    `a_m_m_bevhills_02`,
    `a_m_m_business_01`,
    `a_m_m_eastsa_01`,
    `a_m_m_eastsa_02`,
    `a_m_m_farmer_01`,
    `a_m_m_fatlatin_01`,
    `a_m_m_genfat_01`,
    `a_m_m_genfat_02`,
    `a_m_m_golfer_01`,
    `a_m_m_hasjew_01`,
    `a_m_m_hillbilly_01`,
    `a_m_m_hillbilly_02`,
    `a_m_m_indian_01`,
    `a_m_m_ktown_01`,
    `a_m_m_malibu_01`,
    `a_m_m_mexcntry_01`,
    `a_m_m_mexlabor_01`,
    `a_m_m_og_boss_01`,
    `a_m_m_paparazzi_01`,
    `a_m_m_polynesian_01`,
    `a_m_m_prolhost_01`,
    `a_m_m_rurmeth_01`,
}

shared.Locales = {
    ['open_job'] = '[E] - Bus Job',
    ['open_job_target'] = 'Bus Job',
    ['cancel_job'] = '[E] - Cancel Job',
    ['cancel_job_target'] = 'Cancel Job',
    ['get_to_bus'] = 'Go to ~y~Bus~w~',
    ['get_to_station'] = 'Go to ~y~Station~w~',
    ['passenger_boarding'] = 'Press ~y~E~w~ to load and unload passengers',
    ['active_duty'] = "You're on active duty!",
    ['back_to_the_station'] = 'You got the last passenger. Go back to the bus station',
    ['remaining_stations'] = 'Remaining stations : ',
    ['new_passengers'] = 'Wait for the passenger to get off and the new passenger to get on',
    ['end_work'] = 'Press ~y~E~w~ to deliver the bus',
    ["xpAndMoney"] = "You have got: ",
    ["price"] = 'Price: $',
    ["xp"] = 'XP:'
}

-- Auto Framework Detection
if shared.Framework == "auto" then
    if GetResourceState("qb-core") == "started" then
        shared.Framework = "qb"
    elseif GetResourceState("es_extended") == "started" then
        shared.Framework = "esx"
    else
        print("Couldn't find a framework. Using custom framework.")
        shared.Framework = "custom"
    end
end

-- Framework Object
if shared.Framework == "qb" or shared.Framework == "QB" or shared.Framework == "qb-core" then
    shared.Framework = "qb"
    FrameworkObject = exports['qb-core']:GetCoreObject()
elseif shared.Framework == "qbold" then
    FrameworkObject = nil
    shared.Framework = "qb"
    
    Citizen.CreateThread(function()
        while FrameworkObject == nil do
            TriggerEvent('QBCore:GetObject', function(obj) FrameworkObject = obj end)
            Citizen.Wait(50)
        end
    end)
elseif shared.Framework == "esx" or shared.Framework == "ESX" or shared.Framework == "es_extended" then
    shared.Framework = "esx"
    FrameworkObject = exports['es_extended']:getSharedObject()
elseif shared.Framework == "esxold" then
    FrameworkObject = nil
    shared.Framework = "esx"

    Citizen.CreateThread(function()
        while FrameworkObject == nil do
            TriggerEvent('esx:getSharedObject', function(obj) FrameworkObject = obj end)
            Citizen.Wait(50)
        end
    end)
elseif shared.Framework == 'auto' then
    if GetResourceState('qb-core') == 'started' then
        FrameworkObject = exports['qb-core']:GetCoreObject()
        shared.Framework = "qb"
    elseif GetResourceState('es_extended') == 'started' then
        FrameworkObject = exports['es_extended']:getSharedObject()
        shared.Framework = "esx"
    end

else
    shared.Framework = "custom"
    -- Write your own code shared object code.
    FrameworkObject = nil
end

