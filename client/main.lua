local CurrentActionData, currentTask = {}, {}
local HasAlreadyEnteredMarker, isDead, hasAlreadyJoined, playerInService = false, false, false, false
local LastStation, LastPart, LastPartNum, CurrentAction, CurrentActionMsg
isInShopMenu = false
ESX = nil
local JobBlips, publicBlip = {}, false
local spawnedVehicles = {}

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent(Config.cl_config.es_extended, function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	ESX.PlayerData = ESX.GetPlayerData()
end)

function cleanPlayer(playerPed)
	ClearPedBloodDamage(playerPed)
	ResetPedVisibleDamage(playerPed)
	ClearPedLastWeaponDamage(playerPed)
	ResetPedMovementClipset(playerPed, 0)
end

function setUniform(uniform, playerPed)
	TriggerEvent('skinchanger:getSkin', function(skin)
		local uniformObject

		if skin.sex == 0 then
			uniformObject = Config.Uniforms[uniform].male
		else
			uniformObject = Config.Uniforms[uniform].female
		end

		if uniformObject then
			TriggerEvent('skinchanger:loadClothes', skin, uniformObject)
		else
			ESX.ShowNotification(_U('no_outfit'))
		end
	end)
end

function OpenCloakroomMenu()
	local playerPed = PlayerPedId()
	local grade = ESX.PlayerData.job.grade_name

	local elements = {
		{label = _U('citizen_wear'), value = 'citizen_wear'},
		{label = _U('winemaker_wear'), uniform = grade}
	}
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'cloakroom', {
		title    = _U('cloakroom'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		cleanPlayer(playerPed)

		if data.current.value == 'citizen_wear' then
			
				ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
					TriggerEvent('skinchanger:loadSkin', skin)
				end)

			if Config.EnableESXService then
				ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
					if isInService then
						playerInService = false

						local notification = {
							title    = _U('service_anonunce'),
							subject  = '',
							msg      = _U('service_out_announce', GetPlayerName(PlayerId())),
							iconType = 1
						}

						TriggerServerEvent('esx_service:notifyAllInService', notification, 'winemaker')

						TriggerServerEvent('esx_service:disableService', 'winemaker')
						ESX.ShowNotification(_U('service_out'))
					end
				end, 'winemaker')
			end
		end

		if Config.EnableESXService and data.current.value ~= 'citizen_wear' then
			local awaitService

			ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
				if not isInService then

					ESX.TriggerServerCallback('esx_service:enableService', function(canTakeService, maxInService, inServiceCount)
						if not canTakeService then
							ESX.ShowNotification(_U('service_max', inServiceCount, maxInService))
						else
							awaitService = true
							playerInService = true

							local notification = {
								title    = _U('service_anonunce'),
								subject  = '',
								msg      = _U('service_in_announce', GetPlayerName(PlayerId())),
								iconType = 1
							}

							TriggerServerEvent('esx_service:notifyAllInService', notification, 'winemaker')
							TriggerEvent('yrp_winemaker:updateBlip')
							ESX.ShowNotification(_U('service_in'))
						end
					end, 'winemaker')

				else
					awaitService = true
				end
			end, 'winemaker')

			while awaitService == nil do
				Citizen.Wait(5)
			end

			-- if we couldn't enter service don't let the player get changed
			if not awaitService then
				return
			end
		end

		if data.current.uniform then
			setUniform(data.current.uniform, playerPed)
		elseif data.current.value == 'freemode_ped' then
			local modelHash

			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
				if skin.sex == 0 then
					modelHash = GetHashKey(data.current.maleModel)
				else
					modelHash = GetHashKey(data.current.femaleModel)
				end

				ESX.Streaming.RequestModel(modelHash, function()
					SetPlayerModel(PlayerId(), modelHash)
					SetModelAsNoLongerNeeded(modelHash)
					SetPedDefaultComponentVariation(PlayerPedId())

					TriggerEvent('esx:restoreLoadout')
				end)
			end)
		end
	end, function(data, menu)
		menu.close()

		CurrentAction     = 'menu_cloakroom'
		CurrentActionMsg  = _U('open_cloackroom')
		CurrentActionData = {}
	end)
end

function OpenWinemakerActionsMenu()
	local elements ={
		{label = 'Menu Facturation', value = 'facture'}
	}
	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'winemaker' and (ESX.PlayerData.job.grade_name == 'boss') then
		table.insert(elements, {label = 'Passer une annonce',     value = 'announce'})
	end
	ESX.UI.Menu.CloseAll()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'winemaker_actions', {
		title    = 'Winemaker',
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		local player, distance = ESX.Game.GetClosestPlayer()
		
		if data.current.value == "facture" then
        	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'facture_client', {
        	    title    = 'Facturation Client',
        	    align    = 'top-left',
        	    elements = {
        	      {label = 'Faire une Facture',       value = 'billing'}              
        	    }},function(data2, menu2)
	            
	            local player, distance = ESX.Game.GetClosestPlayer()        
					if distance ~= -1 and distance <= 3.0 then
            
              if data2.current.value == 'billing' then
                ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'billing',{
                    title = 'Facturation'
                },function(data2, menu2)
                    local amount = tonumber(data2.value)
                    if amount == nil then
                        ESX.ShowNotification('Montant Invalide')
                    else
                      menu2.close()
                      local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                      if closestPlayer == -1 or closestDistance > 3.0 then
                        ESX.ShowNotification('Aucune personne au alentour')
                      else
                        TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_winemaker', _U('winemaker'), amount)
                      end
                    end
                  end,function(data2, menu2)
                 	menu2.close()
                end)
              end
            else
              ESX.ShowNotification(_U('no_players_nearby'))
            end    
          end,
          function(data2, menu2)
            menu2.close()
          end)
		end
	end, function(data, menu)
		menu.close()
	end)
end
function OpenStockMenu(station)
	local elements = {
		{label = _U('remove_object'),  value = 'get_stock'},
		{label = _U('deposit_object'), value = 'put_stock'}
	}

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stock', {
		title    = _U('stock'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)

		if data.current.value == 'put_stock' then
			OpenPutStocksMenu()
		elseif data.current.value == 'get_stock' then
			OpenGetStocksMenu()
		end

	end, function(data, menu)
		menu.close()

		CurrentAction     = 'menu_stock'
		CurrentActionMsg  = _U('open_stock')
		CurrentActionData = {station = station}
	end)
end

function OpenGetStocksMenu()
	ESX.TriggerServerCallback('yrp_winemaker:getStockItems', function(items)
		local elements = {}

		for i=1, #items, 1 do
			table.insert(elements, {
				label = 'x' .. items[i].count .. ' ' .. items[i].label,
				value = items[i].name
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
			title    = _U('inventory'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_get_item_count', {
				title = _U('quantity')
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if not count then
					ESX.ShowNotification(_U('quantity_invalid'))
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('yrp_winemaker:getStockItem', itemName, count)

					Citizen.Wait(300)
					OpenGetStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

function OpenPutStocksMenu()
	ESX.TriggerServerCallback('yrp_winemaker:getPlayerInventory', function(inventory)
		local elements = {}

		for i=1, #inventory.items, 1 do
			local item = inventory.items[i]

			if item.count > 0 then
				table.insert(elements, {
					label = item.label .. ' x' .. item.count,
					type = 'item_standard',
					value = item.name
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
			title    = _U('inventory'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_put_item_count', {
				title = _U('quantity')
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if not count then
					ESX.ShowNotification(_U('quantity_invalid'))
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('yrp_winemaker:putStockItems', itemName, count)

					Citizen.Wait(300)
					OpenPutStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
	blips()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
	deleteBlips()
	blips()
end)

function deleteBlips()
	if JobBlips[1] ~= nil then
		for i=1, #JobBlips, 1 do
		RemoveBlip(JobBlips[i])
		JobBlips[i] = nil
		end
	end
end

RegisterNetEvent('esx_phone:loaded')
AddEventHandler('esx_phone:loaded', function(phoneNumber, contacts)
	local specialContact = {
		name       = _U('phone_winemaker'),
		number     = 'winemaker',
		base64Icon = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNiAoV2luZG93cykiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6NDFGQTJDRkI0QUJCMTFFN0JBNkQ5OENBMUI4QUEzM0YiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6NDFGQTJDRkM0QUJCMTFFN0JBNkQ5OENBMUI4QUEzM0YiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDo0MUZBMkNGOTRBQkIxMUU3QkE2RDk4Q0ExQjhBQTMzRiIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDo0MUZBMkNGQTRBQkIxMUU3QkE2RDk4Q0ExQjhBQTMzRiIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PoW66EYAAAjGSURBVHjapJcLcFTV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'
	}

	TriggerEvent('esx_phone:addSpecialContact', specialContact.name, specialContact.number, specialContact.base64Icon)
end)

-- don't show dispatches if the player isn't in service
AddEventHandler('esx_phone:cancelMessage', function(dispatchNumber)
	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'winemaker' and ESX.PlayerData.job.name == dispatchNumber then
		-- if esx_service is enabled
		if Config.EnableESXService and not playerInService then
			CancelEvent()
		end
	end
end)

AddEventHandler('yrp_winemaker:hasEnteredMarker', function(station, part, partNum)
	if part == 'Cloakroom' then
		CurrentAction     = 'menu_cloakroom'
		CurrentActionMsg  = _U('open_cloackroom')
		CurrentActionData = {}
	elseif part == 'Stocks' then
		CurrentAction     = 'menu_stock'
		CurrentActionMsg  = _U('open_stock')
		CurrentActionData = {station = station}
	elseif part == 'Vehicles' then
		CurrentAction     = 'menu_vehicle_spawner'
		CurrentActionMsg  = _U('garage_prompt')
		CurrentActionData = {station = station, part = part, partNum = partNum}
	elseif part == 'BossActions' then
		CurrentAction     = 'menu_boss_actions'
		CurrentActionMsg  = _U('open_bossmenu')
		CurrentActionData = {}
	elseif part == 'Pick' then
		CurrentAction     = 'menu_collect'
		CurrentActionMsg  = _U('open_collect')
		CurrentActionData = {part = part}
	elseif part == 'Traitement' then
		CurrentAction     = 'menu_traitement'
		CurrentActionMsg  = _U('open_traitement')
		CurrentActionData = {part = part}
	elseif part == 'Sell' then
		CurrentAction     = 'menu_sell'
		CurrentActionMsg  = _U('open_sell')
		CurrentActionData = {part = part}
	end
end)

AddEventHandler('yrp_winemaker:hasExitedMarker', function(station, part, partNum)
	CurrentAction = nil
end)

--Create blips
Citizen.CreateThread(function()
	if publicBlip == false then
		for k,v in pairs(Config.WinemakerStations) do
			local blip = AddBlipForCoord(v.Blip.Coords)
	
			SetBlipSprite (blip, v.Blip.Sprite)
			SetBlipDisplay(blip, v.Blip.Display)
			SetBlipScale  (blip, v.Blip.Scale)
			SetBlipColour (blip, v.Blip.Colour)
			SetBlipAsShortRange(blip, true)

			BeginTextCommandSetBlipName('STRING')
			AddTextComponentString('Winemaker')
			EndTextCommandSetBlipName(blip)
		end
		publicBlip = true
	end
end)

function blips()
    if ESX.PlayerData.job and ESX.PlayerData.job.name == 'winemaker' then

		for k,v in pairs(Config.Zones)do
			local blip2 = AddBlipForCoord(v.Pos.x, v.Pos.y, v.Pos.z)

			SetBlipSprite (blip2, 85)
			SetBlipDisplay(blip2, 4)
			SetBlipScale  (blip2, 0.8)
			SetBlipColour (blip2, 27)
			SetBlipAsShortRange(blip2, true)

			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(v.Name)
			EndTextCommandSetBlipName(blip2)
			table.insert(JobBlips, blip2)
		end
	end
end

-- Draw markers and more
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)

		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'winemaker' then
			local playerPed = PlayerPedId()
			local playerCoords = GetEntityCoords(playerPed)
			local isInMarker, hasExited, letSleep = false, false, true
			local currentStation, currentPart, currentPartNum

			for k,v in pairs(Config.WinemakerStations) do
				for i=1, #v.Cloakrooms, 1 do
					local distance = #(playerCoords - v.Cloakrooms[i])

					if distance < Config.cl_config.DrawDistance then
						DrawMarker(20, v.Cloakrooms[i], 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.cl_config.Color.r, Config.cl_config.Color.g, Config.cl_config.Color.b, 100, false, true, 2, true, false, false, false)
						letSleep = false

						if distance < Config.cl_config.Size.x then
							isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Cloakroom', i
						end
					end
				end

				for i=1, #v.Stocks, 1 do
					local distance = #(playerCoords - v.Stocks[i])

					if distance < Config.cl_config.DrawDistance then
						DrawMarker(21, v.Stocks[i], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, Config.cl_config.Color.r, Config.cl_config.Color.g, Config.cl_config.Color.b, 100, false, true, 2, true, false, false, false)
						letSleep = false

						if distance < Config.cl_config.Size.x then
							isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Stocks', i
						end
					end
				end

				for i=1, #v.Vehicles, 1 do
					local distance = #(playerCoords - v.Vehicles[i].Spawner)

					if distance < Config.cl_config.DrawDistance then
						DrawMarker(36, v.Vehicles[i].Spawner, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.cl_config.Color.r, Config.cl_config.Color.g, Config.cl_config.Color.b, 100, false, true, 2, true, false, false, false)
						letSleep = false

						if distance < Config.cl_config.Size.x then
							isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Vehicles', i
						end
					end
				end

				if Config.cl_config.EnablePlayerManagement and ESX.PlayerData.job.grade_name == 'boss' then
					for i=1, #v.BossActions, 1 do
						local distance = #(playerCoords - v.BossActions[i])

						if distance < Config.cl_config.DrawDistance then
							DrawMarker(22, v.BossActions[i], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.cl_config.Color.r, Config.cl_config.Color.g, Config.cl_config.Color.b, 100, false, true, 2, true, false, false, false)
							letSleep = false

							if distance < Config.cl_config.Size.x then
								isInMarker, currentStation, currentPart, currentPartNum = true, k, 'BossActions', i
							end
						end
					end
				end

				--- Blips Metier
				for i=1, #v.Pick, 1 do
					local distance = #(playerCoords - v.Pick[i])

					if distance < Config.cl_config.DrawDistance then
						if distance < 2 then
							DrawMarker(1, v.Pick[i], 0.0, 0.0, 0.0, 0, 0.0, 0.0, 2.5, 2.5, 1.5, Config.cl_config.Color.r, Config.cl_config.Color.g, Config.cl_config.Color.b, 100, false, true, 2, true, false, false, false)
						else
							DrawMarker(22, v.Pick[i], 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.7, 0.7, 0.7, Config.cl_config.Color.r, Config.cl_config.Color.g, Config.cl_config.Color.b, 100, false, true, 2, true, false, false, false)
						end
						letSleep = false

						if distance < Config.cl_config.Size.x then
							isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Pick', i
						end
					end
				end

				for i=1, #v.Traitement, 1 do
					local distance = #(playerCoords - v.Traitement[i])

					if distance < Config.cl_config.DrawDistance then
						DrawMarker(1, v.Traitement[i], 0.0, 0.0, 0.0, 0, 0.0, 0.0, 2.5, 2.5, 1.5, Config.cl_config.Color.r, Config.cl_config.Color.g, Config.cl_config.Color.b, 100, false, true, 2, true, false, false, false)
						letSleep = false

						if distance < Config.cl_config.Size.x then
							isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Traitement', i
						end
					end
				end

				for i=1, #v.Sell, 1 do
					local distance = #(playerCoords - v.Sell[i])

					if distance < Config.cl_config.DrawDistance then
						DrawMarker(20, v.Sell[i], 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.cl_config.Color.r, Config.cl_config.Color.g, Config.cl_config.Color.b, 100, false, true, 2, true, false, false, false)
						letSleep = false

						if distance < Config.cl_config.Size.x then
							isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Sell', i
						end
					end
				end
			end

			if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum)) then
				if
					(LastStation and LastPart and LastPartNum) and
					(LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum)
				then
					TriggerEvent('yrp_winemaker:hasExitedMarker', LastStation, LastPart, LastPartNum)
					hasExited = true
				end

				HasAlreadyEnteredMarker = true
				LastStation             = currentStation
				LastPart                = currentPart
				LastPartNum             = currentPartNum

				TriggerEvent('yrp_winemaker:hasEnteredMarker', currentStation, currentPart, currentPartNum)
			end

			if not hasExited and not isInMarker and HasAlreadyEnteredMarker then
				HasAlreadyEnteredMarker = false
				TriggerEvent('yrp_winemaker:hasExitedMarker', LastStation, LastPart, LastPartNum)
			end

			if letSleep then
				Citizen.Wait(500)
			end
		else
			Citizen.Wait(500)
		end
	end
end)


-- Key Controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)

		if CurrentAction then
			ESX.ShowHelpNotification(CurrentActionMsg)

			if IsControlJustReleased(0, 38) and ESX.PlayerData.job and ESX.PlayerData.job.name == 'winemaker' then

				if CurrentAction == 'menu_cloakroom' then
					OpenCloakroomMenu()
				elseif CurrentAction == 'menu_stock' then
					if not Config.EnableESXService then
						OpenStockMenu(CurrentActionData.station)
					elseif playerInService then
						OpenStockMenu(CurrentActionData.station)
					else
						ESX.ShowNotification(_U('service_not'))
					end
				elseif CurrentAction == 'menu_vehicle_spawner' then
					if not Config.EnableESXService then
						OpenVehicleSpawnerMenu('car', CurrentActionData.station, CurrentActionData.part, CurrentActionData.partNum)
					elseif playerInService then
						OpenVehicleSpawnerMenu('car', CurrentActionData.station, CurrentActionData.part, CurrentActionData.partNum)
					else
						ESX.ShowNotification(_U('service_not'))
					end
				elseif CurrentAction == 'delete_vehicle' then
					ESX.Game.DeleteVehicle(CurrentActionData.vehicle)
				elseif CurrentAction == 'menu_boss_actions' then
					ESX.UI.Menu.CloseAll()
					TriggerEvent('esx_society:openBossMenu', 'winemaker', function(data, menu)
						menu.close()

						CurrentAction     = 'menu_boss_actions'
						CurrentActionMsg  = _U('open_bossmenu')
						CurrentActionData = {}
					end) -- disable washing money
				elseif CurrentAction == 'menu_collect' then
					SendNUIMessage({
                        yrp_jobs = true
					})
					SetNuiFocus( true, true )
				elseif CurrentAction == 'menu_traitement' then
					SendNUIMessage({
                        yrp_jobs_package = true
					})
					SetNuiFocus( true, true )
				elseif CurrentAction == 'menu_sell' then
					SendNUIMessage({
                        yrp_jobs_sell = true
					})
					SetNuiFocus( true, true )
				end

				CurrentAction = nil
			end
		end -- CurrentAction end

		if IsControlJustReleased(0, 167) and not isDead and ESX.PlayerData.job and ESX.PlayerData.job.name == 'winemaker' and not ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'winemaker_actions') then
			if not Config.EnableESXService then
				OpenWinemakerActionsMenu()
			elseif playerInService then
				OpenWinemakerActionsMenu()
			else
				ESX.ShowNotification(_U('service_not'))
			end
		end
	end
end)

AddEventHandler('playerSpawned', function(spawn)
	isDead = false

	if not hasAlreadyJoined then
		TriggerServerEvent('yrp_winemaker:spawned')
	end
	hasAlreadyJoined = true
end)

AddEventHandler('esx:onPlayerDeath', function(data)
	isDead = true
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		TriggerEvent('yrp_winemaker:unrestrain')
		TriggerEvent('esx_phone:removeSpecialContact', 'winemaker')

		if Config.EnableESXService then
			TriggerServerEvent('esx_service:disableService', 'winemaker')
		end

		if Config.EnableHandcuffTimer and handcuffTimer.active then
			ESX.ClearTimeout(handcuffTimer.task)
		end
	end
end)

---------------
 -- Vehicle --
---------------

function OpenVehicleSpawnerMenu(type, station, part, partNum)
	local playerCoords = GetEntityCoords(PlayerPedId())

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle', {
		title    = _U('garage_title'),
		align    = 'top-left',
		elements = {
			{label = _U('garage_storeditem'), action = 'garage'},
			{label = _U('garage_storeitem'), action = 'store_garage'},
			{label = _U('garage_buyitem'), action = 'buy_vehicle'}
	}}, function(data, menu)
		if data.current.action == 'buy_vehicle' then
			local shopElements = {}
			local shopCoords = Config.WinemakerStations[station][part][partNum].InsideShop
			local authorizedVehicles = Config.AuthorizedVehicles[type][ESX.PlayerData.job.grade_name]

			if authorizedVehicles then
				if #authorizedVehicles > 0 then
					for k,vehicle in ipairs(authorizedVehicles) do
						if IsModelInCdimage(vehicle.model) then
							local vehicleLabel = GetLabelText(GetDisplayNameFromVehicleModel(vehicle.model))

							table.insert(shopElements, {
								label = ('%s'):format(vehicleLabel),
								name  = vehicleLabel,
								model = vehicle.model,
								price = vehicle.price,
								props = vehicle.props,
								type  = type
							})
						end
					end

					if #shopElements > 0 then
						OpenShopMenu(shopElements, playerCoords, shopCoords)
					else
						ESX.ShowNotification(_U('garage_notauthorized'))
					end
				else
					ESX.ShowNotification(_U('garage_notauthorized'))
				end
			else
				ESX.ShowNotification(_U('garage_notauthorized'))
			end
		elseif data.current.action == 'garage' then
			local garage = {}

			ESX.TriggerServerCallback('esx_vehicleshop:retrieveJobVehicles', function(jobVehicles)
				if #jobVehicles > 0 then
					local allVehicleProps = {}

					for k,v in ipairs(jobVehicles) do
						local props = json.decode(v.vehicle)

						if IsModelInCdimage(props.model) then
							local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(props.model))
							local label = ('%s - <span style="color:darkgoldenrod;">%s</span>: '):format(vehicleName, props.plate)

							if v.stored then
								label = label .. ('<span style="color:green;">%s</span>'):format(_U('garage_stored'))
							else
								label = label .. ('<span style="color:darkred;">%s</span>'):format(_U('garage_notstored'))
							end

							table.insert(garage, {
								label = label,
								stored = v.stored,
								model = props.model,
								plate = props.plate
							})

							allVehicleProps[props.plate] = props
						end
					end

					if #garage > 0 then
						ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_garage', {
							title    = _U('garage_title'),
							align    = 'top-left',
							elements = garage
						}, function(data2, menu2)
							if data2.current.stored then
								local foundSpawn, spawnPoint = GetAvailableVehicleSpawnPoint(station, part, partNum)

								if foundSpawn then
									menu2.close()

									ESX.Game.SpawnVehicle(data2.current.model, spawnPoint.coords, spawnPoint.heading, function(vehicle)
										local vehicleProps = allVehicleProps[data2.current.plate]
										ESX.Game.SetVehicleProperties(vehicle, vehicleProps)
										TriggerServerEvent('esx_vehiclelock:givekey','no', vehicleProps.plate)
										TriggerServerEvent('esx_vehicleshop:setJobVehicleState', data2.current.plate, false)
										ESX.ShowNotification(_U('garage_released'))
									end)
								end
							else
								ESX.ShowNotification(_U('garage_notavailable'))
							end
						end, function(data2, menu2)
							menu2.close()
						end)
					else
						ESX.ShowNotification(_U('garage_empty'))
					end
				else
					ESX.ShowNotification(_U('garage_empty'))
				end
			end, type)
		elseif data.current.action == 'store_garage' then
			StoreNearbyVehicle(playerCoords)
		end
	end, function(data, menu)
		menu.close()
	end)
end

function StoreNearbyVehicle(playerCoords)
	local vehicles, vehiclePlates = ESX.Game.GetVehiclesInArea(playerCoords, 30.0), {}

	if #vehicles > 0 then
		for k,v in ipairs(vehicles) do

			-- Make sure the vehicle we're saving is empty, or else it wont be deleted
			if GetVehicleNumberOfPassengers(v) == 0 and IsVehicleSeatFree(v, -1) then
				table.insert(vehiclePlates, {
					vehicle = v,
					plate = ESX.Math.Trim(GetVehicleNumberPlateText(v))
				})
			end
		end
	else
		ESX.ShowNotification(_U('garage_store_nearby'))
		return
	end

	ESX.TriggerServerCallback('yrp_winemaker:storeNearbyVehicle', function(storeSuccess, foundNum)
		if storeSuccess then
			local vehicleId = vehiclePlates[foundNum]
			local attempts = 0
			ESX.Game.DeleteVehicle(vehicleId.vehicle)
			IsBusy = true

			Citizen.CreateThread(function()
				BeginTextCommandBusyspinnerOn('STRING')
				AddTextComponentSubstringPlayerName(_U('garage_storing'))
				EndTextCommandBusyspinnerOn(4)

				while IsBusy do
					Citizen.Wait(100)
				end

				BusyspinnerOff()
			end)

			-- Workaround for vehicle not deleting when other players are near it.
			while DoesEntityExist(vehicleId.vehicle) do
				Citizen.Wait(500)
				attempts = attempts + 1

				-- Give up
				if attempts > 30 then
					break
				end

				vehicles = ESX.Game.GetVehiclesInArea(playerCoords, 30.0)
				if #vehicles > 0 then
					for k,v in ipairs(vehicles) do
						if ESX.Math.Trim(GetVehicleNumberPlateText(v)) == vehicleId.plate then
							ESX.Game.DeleteVehicle(v)
							break
						end
					end
				end
			end
			TriggerServerEvent('esx_vehiclelock:deletekeyjobs','no', vehicleId.plate)
			IsBusy = false
			ESX.ShowNotification(_U('garage_has_stored'))
		else
			ESX.ShowNotification(_U('garage_has_notstored'))
		end
	end, vehiclePlates)
end

function GetAvailableVehicleSpawnPoint(station, part, partNum)
	local spawnPoints = Config.WinemakerStations[station][part][partNum].SpawnPoints
	local found, foundSpawnPoint = false, nil

	for i=1, #spawnPoints, 1 do
		if ESX.Game.IsSpawnPointClear(spawnPoints[i].coords, spawnPoints[i].radius) then
			found, foundSpawnPoint = true, spawnPoints[i]
			break
		end
	end

	if found then
		return true, foundSpawnPoint
	else
		ESX.ShowNotification(_U('vehicle_blocked'))
		return false
	end
end

function OpenShopMenu(elements, restoreCoords, shopCoords)
	local playerPed = PlayerPedId()
	isInShopMenu = true

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_shop', {
		title    = _U('vehicleshop_title'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_shop_confirm', {
			title    = _U('vehicleshop_confirm', data.current.name, data.current.price),
			align    = 'top-left',
			elements = {
				{label = _U('confirm_no'), value = 'no'},
				{label = _U('confirm_yes'), value = 'yes'}
		}}, function(data2, menu2)
			if data2.current.value == 'yes' then
				local newPlate = "Winemaker " .. math.random(10,90)
				local vehicle  = GetVehiclePedIsIn(playerPed, false)
				local props    = ESX.Game.GetVehicleProperties(vehicle)
				props.plate    = newPlate

				ESX.TriggerServerCallback('yrp_winemaker:buyJobVehicle', function (bought)
					if bought then
						--ESX.ShowNotification(_U('vehicleshop_bought', data.current.name))

						isInShopMenu = false
						ESX.UI.Menu.CloseAll()
						DeleteSpawnedVehicles()
						FreezeEntityPosition(playerPed, false)
						SetEntityVisible(playerPed, true)

						ESX.Game.Teleport(playerPed, restoreCoords)
					else
						ESX.ShowNotification(_U('vehicleshop_money'))
						menu2.close()
					end
				end, props, data.current.type)
			else
				menu2.close()
			end
		end, function(data2, menu2)
			menu2.close()
		end)
	end, function(data, menu)
		isInShopMenu = false
		ESX.UI.Menu.CloseAll()

		DeleteSpawnedVehicles()
		FreezeEntityPosition(playerPed, false)
		SetEntityVisible(playerPed, true)

		ESX.Game.Teleport(playerPed, restoreCoords)
	end, function(data, menu)
		DeleteSpawnedVehicles()
		WaitForVehicleToLoad(data.current.model)

		ESX.Game.SpawnLocalVehicle(data.current.model, shopCoords, 258.0, function(vehicle)
			table.insert(spawnedVehicles, vehicle)
			TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
			FreezeEntityPosition(vehicle, true)
			SetModelAsNoLongerNeeded(data.current.model)

			if data.current.props then
				ESX.Game.SetVehicleProperties(vehicle, data.current.props)
			end
		end)
	end)

	WaitForVehicleToLoad(elements[1].model)
	ESX.Game.SpawnLocalVehicle(elements[1].model, shopCoords, 258.0, function(vehicle)
		table.insert(spawnedVehicles, vehicle)
		TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
		FreezeEntityPosition(vehicle, true)
		SetModelAsNoLongerNeeded(elements[1].model)

		if elements[1].props then
			ESX.Game.SetVehicleProperties(vehicle, elements[1].props)
		end
	end)
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if isInShopMenu then
			DisableControlAction(0, 75, true)  -- Disable exit vehicle
			DisableControlAction(27, 75, true) -- Disable exit vehicle
		else
			Citizen.Wait(500)
		end
	end
end)

function DeleteSpawnedVehicles()
	while #spawnedVehicles > 0 do
		local vehicle = spawnedVehicles[1]
		ESX.Game.DeleteVehicle(vehicle)
		table.remove(spawnedVehicles, 1)
	end
end

function WaitForVehicleToLoad(modelHash)
	modelHash = (type(modelHash) == 'number' and modelHash or GetHashKey(modelHash))

	if not HasModelLoaded(modelHash) then
		RequestModel(modelHash)

		BeginTextCommandBusyspinnerOn('STRING')
		AddTextComponentSubstringPlayerName(_U('vehicleshop_awaiting_model'))
		EndTextCommandBusyspinnerOn(4)

		while not HasModelLoaded(modelHash) do
			Citizen.Wait(0)
			DisableAllControlActions(0)
		end

		BusyspinnerOff()
	end
end

----NUI callbacks

RegisterNUICallback('CloseYRPdrugs', function(data, cb)
    SendNUIMessage({
        yrp_all_close = true
	})
	SetNuiFocus(false)
end)

RegisterNUICallback('SeeRaisinCraft', function(data, cb)
    SendNUIMessage({
        yrp_see_raisin = true
	})
end)

RegisterNUICallback('SeeRedRaisinCraft', function(data, cb)
    SendNUIMessage({
        yrp_see_red_raisin = true
	})
end)

RegisterNUICallback('SeeRaisinPackage', function(data, cb)
    SendNUIMessage({
        yrp_see_raisin_c = true
	})
end)

RegisterNUICallback('SeeRedRaisinPackage', function(data, cb)
    SendNUIMessage({
        yrp_see_redraisin_c = true
	})
end)

RegisterNUICallback('BackToCrafting', function(data, cb)
	SendNUIMessage({
		yrp_back_craft = true
	})
end)

RegisterNUICallback('BackToPackage', function(data, cb)
	SendNUIMessage({
		yrp_back_pack = true
	})
end)

RegisterNUICallback('CraftRaisin', function(data, cb)
    SendNUIMessage({
		yrp_all_close = true
	})
    SetNuiFocus(false)

    local first = data.raisin
    local time = 1.5 * first

    TriggerEvent("mythic_progbar:client:progress", {
        name = "unique_action_name",
        duration = 1500 * first,
        label = "Picking " ..first.. "x white wines, it'll take you " ..time.. "s",
        useWhileDead = false,
        canCancel = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
        animation = {
            --animDict = "missheistdockssetup1clipboard@idle_a",
			--anim = "idle_a",
			animDict = "random@domestic",
            anim = "pickup_low",
        },
        --prop = {
        --    model = "prop_paper_bag_small",
        --}
    }, function(status)
        if not status then
            --TriggerEvent("yrp_sounds:PlayClientSounds", "test", 0.8) --buckle

            TriggerServerEvent('yrp_winemaker:CraftRaisin', 'white_raisin', data.raisin)
        end
    end)
end)

RegisterNUICallback('CraftRedRaisin', function(data, cb)
    SendNUIMessage({
		yrp_all_close = true
	})
    SetNuiFocus(false)

    local first = data.red_raisin
    local time = 2 * first

    TriggerEvent("mythic_progbar:client:progress", {
        name = "unique_action_name",
        duration = 2000 * first,
        label = "Picking " ..first.. "x red wines, it'll take you " ..time.. "s",
        useWhileDead = false,
        canCancel = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
        animation = {
            --animDict = "missheistdockssetup1clipboard@idle_a",
			--anim = "idle_a",
			animDict = "random@domestic",
            anim = "pickup_low",
        },
        --prop = {
        --    model = "prop_paper_bag_small",
        --}
    }, function(status)
        if not status then
            --TriggerEvent("yrp_sounds:PlayClientSounds", "test", 0.8) --buckle

            TriggerServerEvent('yrp_winemaker:CraftRedRaisin', 'red_raisin', data.red_raisin)
        end
    end)
end)

RegisterNUICallback('PackageRaisin', function(data, cb)
    SendNUIMessage({
		yrp_all_close = true
	})
    SetNuiFocus(false)

    local first = data.packraisin
    local time = 3 * first

    TriggerEvent("mythic_progbar:client:progress", {
        name = "unique_action_name",
        duration = 3000 * first,
        label = "Processing " ..first.. "x white wines, it'll take you " ..time.. "s",
        useWhileDead = false,
        canCancel = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
        animation = {
            animDict = "missheistdockssetup1clipboard@idle_a",
            anim = "idle_a",
        },
        prop = {
            model = "prop_paper_bag_small",
        }
    }, function(status)
        if not status then
            --TriggerEvent("yrp_sounds:PlayClientSounds", "test", 0.8) --buckle

            TriggerServerEvent('yrp_winemaker:PackageWhiteRaisin', 'flaska_white_raisin', data.packraisin)
        end
    end)
end)

RegisterNUICallback('PackageRedRaisin', function(data, cb)
    SendNUIMessage({
		yrp_all_close = true
	})
    SetNuiFocus(false)

    local first = data.packraisin
    local time = 3.5 * first

    TriggerEvent("mythic_progbar:client:progress", {
        name = "unique_action_name",
        duration = 3500 * first,
        label = "Processing " ..first.. "x red wines, it'll take you " ..time.. "s",
        useWhileDead = false,
        canCancel = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
        animation = {
            animDict = "missheistdockssetup1clipboard@idle_a",
            anim = "idle_a",
        },
        prop = {
            model = "prop_paper_bag_small",
        }
    }, function(status)
        if not status then
            --TriggerEvent("yrp_sounds:PlayClientSounds", "test", 0.8) --buckle

            TriggerServerEvent('yrp_winemaker:PackageRedRaisin', 'flaska_red_raisin', data.packraisin)
        end
    end)
end)

RegisterNUICallback('SellRaisin', function(data, cb)
    SendNUIMessage({
		yrp_all_close = true
	})
    SetNuiFocus(false)

    local first = data.packraisin
    local time = 1 * first

    TriggerEvent("mythic_progbar:client:progress", {
        name = "unique_action_name",
        duration = 1000 * first,
        label = "Selling " ..first.. "x bottles white wine, it'll take you " ..time.. "s",
        useWhileDead = false,
        canCancel = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
        animation = {
            animDict = "missheistdockssetup1clipboard@idle_a",
            anim = "idle_a",
        },
        prop = {
            model = "prop_paper_bag_small",
        }
    }, function(status)
        if not status then
            --TriggerEvent("yrp_sounds:PlayClientSounds", "test", 0.8) --buckle

            TriggerServerEvent('yrp_winemaker:SellWhiteRaisin', 'flaska_white_raisin', data.packraisin)
        end
    end)
end)

RegisterNUICallback('SellRedRaisin', function(data, cb)
    SendNUIMessage({
		yrp_all_close = true
	})
    SetNuiFocus(false)

    local first = data.packraisin
    local time = 2 * first

    TriggerEvent("mythic_progbar:client:progress", {
        name = "unique_action_name",
        duration = 2000 * first,
        label = "Selling " ..first.. "x bottles red wine, it'll take you " ..time.. "s",
        useWhileDead = false,
        canCancel = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
        animation = {
            animDict = "missheistdockssetup1clipboard@idle_a",
            anim = "idle_a",
        },
        prop = {
            model = "prop_paper_bag_small",
        }
    }, function(status)
        if not status then
            --TriggerEvent("yrp_sounds:PlayClientSounds", "test", 0.8) --buckle

            TriggerServerEvent('yrp_winemaker:SellRedRaisin', 'flaska_red_raisin', data.packraisin)
        end
    end)
end)

RegisterNUICallback('Notification', function(data, cb)
    SendNUIMessage({
		yrp_all_close = true
	})
    SetNuiFocus(false)
    ESX.ShowNotification(data.text)
end)

RegisterNetEvent('yrp_drugs:PlayerDead')
AddEventHandler('yrp_drugs:PlayerDead', function()
    SendNUIMessage({
		yrp_all_close = true
	})
    SetNuiFocus(false)
end)