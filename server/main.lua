------------------------------------------------------------
---------------------- yrp_winemaker -----------------------
------------------------------------------------------------
--------------------- Created by Flap ----------------------
------------------------------------------------------------
----------------- YourRolePlay Development -----------------
--------- Thank you for using this winemaker job -----------
----- Regular updates and lots of interesting scripts ------
--------- discord -> https://discord.gg/hqZEXc8FSE ---------
------------------------------------------------------------

ESX = nil

TriggerEvent(Config.sv_config.es_extended, function(obj) ESX = obj end)

if Config.EnableESXService then
	TriggerEvent('esx_service:activateService', 'winemaker', Config.MaxInService)
end

TriggerEvent('esx_phone:registerNumber', 'winemaker', _U('alert_winemaker'), true, true)
TriggerEvent('esx_society:registerSociety', 'winemaker', 'Winemaker', 'society_winemaker', 'society_winemaker', 'society_winemaker', {type = 'public'})

RegisterNetEvent('yrp_winemaker:getStockItem')
AddEventHandler('yrp_winemaker:getStockItem', function(itemName, count)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_winemaker', function(inventory)
		local inventoryItem = inventory.getItem(itemName)

		-- is there enough in the society?
		if count > 0 and inventoryItem.count >= count then

			if Config.oldESX then
				local yrp = xPlayer.getInventoryItem(itemName)
				if yrp.limit ~= -1 and count >= yrp.limit then
					xPlayer.showNotification(_U('quantity_invalid'))
				else
					xPlayer.addInventoryItem(itemName, count)

					if Config.sv_config.webhook_on then
						local discord_webhook = Config.sv_config.webhook_armory_get
						if discord_webhook == '' then
							return
						end
						local headers = {
							['Content-Type'] = 'application/json'
						}
						local data = {
							["username"] = _U('webhook_get'),
							["embeds"] = {{
								["color"] = 0xa5ff4a,
								["timestamp"] = dateNow,
								['description'] = 'Player - **' ..GetPlayerName(source) .. '**\nIdentifier - **' .. GetPlayerIdentifier(source) ..'**\njob - **' ..xPlayer.job.name..'**\n item - **'..itemName..'**\n amount -  **'..count..'**'
							}}
						}
						PerformHttpRequest(discord_webhook, function(err, text, headers) end, 'POST', json.encode(data), headers)
					end
				end
			else
				if xPlayer.canCarryItem(itemName, count) then
					inventory.removeItem(itemName, count)
					xPlayer.addInventoryItem(itemName, count)
					xPlayer.showNotification(_U('have_withdrawn', count, inventoryItem.label))

					if Config.sv_config.webhook_on then
						local discord_webhook = Config.sv_config.webhook_armory_get
						if discord_webhook == '' then
							return
						end
						local headers = {
							['Content-Type'] = 'application/json'
						}
						local data = {
							["username"] = _U('webhook_get'),
							["embeds"] = {{
								["color"] = 0xa5ff4a,
								["timestamp"] = dateNow,
								['description'] = 'Player - **' ..GetPlayerName(source) .. '**\nIdentifier - **' .. GetPlayerIdentifier(source) ..'**\njob - **' ..xPlayer.job.name..'**\n item - **'..itemName..'**\n amount -  **'..count..'**'
							}}
						}
						PerformHttpRequest(discord_webhook, function(err, text, headers) end, 'POST', json.encode(data), headers)
					end
				else
					xPlayer.showNotification(_U('quantity_invalid'))
				end
			end
		else
			xPlayer.showNotification(_U('quantity_invalid'))
		end
	end)
end)

RegisterNetEvent('yrp_winemaker:putStockItems')
AddEventHandler('yrp_winemaker:putStockItems', function(itemName, count)
	local xPlayer = ESX.GetPlayerFromId(source)
	local sourceItem = xPlayer.getInventoryItem(itemName)

	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_winemaker', function(inventory)
		local inventoryItem = inventory.getItem(itemName)

		-- does the player have enough of the item?
		if sourceItem.count >= count and count > 0 then
			xPlayer.removeInventoryItem(itemName, count)
			inventory.addItem(itemName, count)
			xPlayer.showNotification(_U('have_deposited', count, inventoryItem.label))
		else
			xPlayer.showNotification(_U('quantity_invalid'))
		end
	end)

	if Config.sv_config.webhook_on then
	    local discord_webhook = Config.sv_config.webhook_armory_put
	    if discord_webhook == '' then
	        return
	    end
	    local headers = {
		    ['Content-Type'] = 'application/json'
		}
		local data = {
			["username"] = _U('webhook_put'),
			["embeds"] = {{
			    ["color"] = 0xa5ff4a,
			    ["timestamp"] = dateNow,
			    ['description'] = 'Player - **' ..GetPlayerName(source) .. '**\nIdentifier - **' .. GetPlayerIdentifier(source) ..'**\njob - **' ..xPlayer.job.name..'**\n item - **'..itemName..'**\n amount -  **'..count..'**'
	        }}
	    }
		PerformHttpRequest(discord_webhook, function(err, text, headers) end, 'POST', json.encode(data), headers)
	end
end)

ESX.RegisterServerCallback('yrp_winemaker:buyJobVehicle', function(source, cb, vehicleProps, type)
	local xPlayer = ESX.GetPlayerFromId(source)
	local price = getPriceFromHash(vehicleProps.model, xPlayer.job.grade_name, type)

	-- vehicle model not found
	if price == 0 then
		cb(false)
	else
		if xPlayer.getMoney() >= price then
			xPlayer.removeMoney(price)

			MySQL.Async.execute('INSERT INTO owned_vehicles (owner, vehicle, plate, type, job, `stored`) VALUES (@owner, @vehicle, @plate, @type, @job, @stored)', {
				['@owner'] = xPlayer.identifier,
				['@vehicle'] = json.encode(vehicleProps),
				['@plate'] = vehicleProps.plate,
				['@type'] = type,
				['@job'] = xPlayer.job.name,
				['@stored'] = true
			}, function (rowsChanged)
				cb(true)
			end)
		else
			cb(false)
		end
	end
end)

AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		Citizen.CreateThread(function()
			Citizen.Wait(1000)	
			print('^3[yrp_winemaker] If you found any problem or want to know what script will come out of YourRolePlay Development, here is discord -> ^2https://discord.gg/uSv9sWwhE9^7')
		end)
	end
end)

ESX.RegisterServerCallback('yrp_winemaker:storeNearbyVehicle', function(source, cb, nearbyVehicles)
	local xPlayer = ESX.GetPlayerFromId(source)
	local foundPlate, foundNum

	for k,v in ipairs(nearbyVehicles) do
		local result = MySQL.Sync.fetchAll('SELECT plate FROM owned_vehicles WHERE owner = @owner AND plate = @plate AND job = @job', {
			['@owner'] = xPlayer.identifier,
			['@plate'] = v.plate,
			['@job'] = xPlayer.job.name
		})

		if result[1] then
			foundPlate, foundNum = result[1].plazte, k
			break
		end
	end

	if not foundPlate then
		cb(false)
	else
		MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = true WHERE owner = @owner AND plate = @plate AND job = @job', {
			['@owner'] = xPlayer.identifier,
			['@plate'] = foundPlate,
			['@job'] = xPlayer.job.name
		}, function (rowsChanged)
			if rowsChanged == 0 then
				print(('yrp_winemaker: %s has exploited the garage!'):format(xPlayer.identifier))
				cb(false)
			else
				cb(true, foundNum)
			end
		end)
	end
end)

function getPriceFromHash(vehicleHash, jobGrade, type)
	local vehicles = Config.AuthorizedVehicles[type][jobGrade]

	for k,v in ipairs(vehicles) do
		if GetHashKey(v.model) == vehicleHash then
			return v.price
		end
	end

	return 0
end

ESX.RegisterServerCallback('yrp_winemaker:getStockItems', function(source, cb)
	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_winemaker', function(inventory)
		cb(inventory.items)
	end)
end)

ESX.RegisterServerCallback('yrp_winemaker:getPlayerInventory', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local items   = xPlayer.inventory

	cb({items = items})
end)

AddEventHandler('playerDropped', function()
	-- Save the source in case we lose it (which happens a lot)
	local playerId = source

	-- Did the player ever join?
	if playerId then
		local xPlayer = ESX.GetPlayerFromId(playerId)

		-- Is it worth telling all clients to refresh?
		if xPlayer and xPlayer.job.name == 'winemaker' then
			Citizen.Wait(5000)
		end
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		TriggerEvent('esx_phone:removeNumber', 'winemaker')
	end
end)

RegisterNetEvent('yrp_winemaker:spawned')
AddEventHandler('yrp_winemaker:spawned', function()
	local xPlayer = ESX.GetPlayerFromId(playerId)

	if xPlayer and xPlayer.job.name == 'winemaker' then
		Citizen.Wait(5000)
	end
end)


-------- job --------

RegisterServerEvent('yrp_winemaker:CraftRaisin')
AddEventHandler('yrp_winemaker:CraftRaisin', function(itemName, amount)

	local xPlayer = ESX.GetPlayerFromId(source)

    if (itemName ~= 'white_raisin') then
	    print(('[yrp_winemaker] [^2INFO^7] "%s" attempted to spawn in an item!'):format(xPlayer.identifier))
	    return
	end

	if Config.oldESX then
		local yrp = xPlayer.getInventoryItem(itemName)
		if yrp.limit ~= -1 and amount >= yrp.limit then
			xPlayer.showNotification(_U('quantity_invalid'))
		else
			xPlayer.addInventoryItem(itemName, amount)

			if Config.sv_config.webhook_on then
				local discord_webhook = Config.sv_config.webhook_pick
				if discord_webhook == '' then
					return
				end
				local headers = {
					['Content-Type'] = 'application/json'
				}
				local data = {
					["username"] = _U('webhook_pick'),
					["embeds"] = {{
						["color"] = 0xa5ff4a,
						["timestamp"] = dateNow,
						['description'] = 'Player - **' ..GetPlayerName(source) .. '**\nIdentifier - **' .. GetPlayerIdentifier(source) ..'**\njob - **' ..xPlayer.job.name.. '**\npick - **' ..amount.. 'x ' ..itemName
					}}
				}
				PerformHttpRequest(discord_webhook, function(err, text, headers) end, 'POST', json.encode(data), headers)
			end
		end
	else
		if xPlayer.canCarryItem(itemName, amount) then
			xPlayer.addInventoryItem(itemName, amount)

			if Config.sv_config.webhook_on then
				local discord_webhook = Config.sv_config.webhook_pick
				if discord_webhook == '' then
					return
				end
				local headers = {
					['Content-Type'] = 'application/json'
				}
				local data = {
					["username"] = _U('webhook_pick'),
					["embeds"] = {{
						["color"] = 0xa5ff4a,
						["timestamp"] = dateNow,
						['description'] = 'Player - **' ..GetPlayerName(source) .. '**\nIdentifier - **' .. GetPlayerIdentifier(source) ..'**\njob - **' ..xPlayer.job.name.. '**\npick - **' ..amount.. 'x ' ..itemName
					}}
				}
				PerformHttpRequest(discord_webhook, function(err, text, headers) end, 'POST', json.encode(data), headers)
			end
		else
			xPlayer.showNotification(_U('quantity_invalid'))
		end
	end

end)

RegisterServerEvent('yrp_winemaker:CraftRedRaisin')
AddEventHandler('yrp_winemaker:CraftRedRaisin', function(itemName, amount)

	local xPlayer = ESX.GetPlayerFromId(source)

    if (itemName ~= 'red_raisin') then
	    print(('[yrp_winemaker] [^2INFO^7] "%s" attempted to spawn in an item!'):format(xPlayer.identifier))
	    return
	end

	if Config.oldESX then
		local yrp = xPlayer.getInventoryItem(itemName)
		if yrp.limit ~= -1 and amount >= yrp.limit then
			xPlayer.showNotification(_U('quantity_invalid'))
		else
			xPlayer.addInventoryItem(itemName, amount)

			if Config.sv_config.webhook_on then
				local discord_webhook = Config.sv_config.webhook_pick
				if discord_webhook == '' then
					return
				end
				local headers = {
					['Content-Type'] = 'application/json'
				}
				local data = {
					["username"] = _U('webhook_pick'),
					["embeds"] = {{
						["color"] = 0xa5ff4a,
						["timestamp"] = dateNow,
						['description'] = 'Player - **' ..GetPlayerName(source) .. '**\nIdentifier - **' .. GetPlayerIdentifier(source) ..'**\njob - **' ..xPlayer.job.name.. '**\npick - **' ..amount.. 'x ' ..itemName
					}}
				}
				PerformHttpRequest(discord_webhook, function(err, text, headers) end, 'POST', json.encode(data), headers)
			end
		end
	else
		if xPlayer.canCarryItem(itemName, amount) then
			xPlayer.addInventoryItem(itemName, amount)

			if Config.sv_config.webhook_on then
				local discord_webhook = Config.sv_config.webhook_pick
				if discord_webhook == '' then
					return
				end
				local headers = {
					['Content-Type'] = 'application/json'
				}
				local data = {
					["username"] = _U('webhook_pick'),
					["embeds"] = {{
						["color"] = 0xa5ff4a,
						["timestamp"] = dateNow,
						['description'] = 'Player - **' ..GetPlayerName(source) .. '**\nIdentifier - **' .. GetPlayerIdentifier(source) ..'**\njob - **' ..xPlayer.job.name.. '**\npick - **' ..amount.. 'x ' ..itemName
					}}
				}
				PerformHttpRequest(discord_webhook, function(err, text, headers) end, 'POST', json.encode(data), headers)
			end
		else
			xPlayer.showNotification(_U('quantity_invalid'))
		end
	end

end)

RegisterServerEvent('yrp_winemaker:PackageWhiteRaisin')
AddEventHandler('yrp_winemaker:PackageWhiteRaisin', function(itemName, amount)

	local xPlayer = ESX.GetPlayerFromId(source)
	local weedQuantity = xPlayer.getInventoryItem('white_raisin').count

    if (itemName ~= 'flaska_white_raisin') then
	    print(('[yrp_winemaker] [^2INFO^7] "%s" attempted to spawn in an item!'):format(xPlayer.identifier))
	    return
	end

	if weedQuantity < 5 * amount then
		TriggerClientEvent('esx:showNotification', source, 'You dont have enough white wine, you need ' ..amount * 5)
		return
	end

	if Config.oldESX then
		local yrp = xPlayer.getInventoryItem(itemName)
		local oldAmount = amount*5
		if yrp.limit ~= -1 and amount >= yrp.limit then
			xPlayer.showNotification(_U('quantity_invalid'))
		else
			xPlayer.removeInventoryItem('white_raisin', 5 * amount)
			xPlayer.addInventoryItem(itemName, amount)

			if Config.sv_config.webhook_on then
				local discord_webhook = Config.sv_config.webhook_processed
				if discord_webhook == '' then
					return
				end
				local headers = {
					['Content-Type'] = 'application/json'
				}
				local data = {
					["username"] = _U('webhook_processed'),
					["embeds"] = {{
						["color"] = 0xa5ff4a,
						["timestamp"] = dateNow,
						['description'] = 'Player - **' ..GetPlayerName(source) .. '**\nIdentifier - **' .. GetPlayerIdentifier(source) ..'**\njob - **' ..xPlayer.job.name.. '**\nprocessed - **' ..oldAmount.. 'x white_raisin** for **' ..amount.. 'x ' ..itemName
					}}
				}
				PerformHttpRequest(discord_webhook, function(err, text, headers) end, 'POST', json.encode(data), headers)
			end
		end
	else
		if xPlayer.canCarryItem(itemName, amount) then
			xPlayer.removeInventoryItem('white_raisin', 5 * amount)
			xPlayer.addInventoryItem(itemName, amount)

			if Config.sv_config.webhook_on then
				local discord_webhook = Config.sv_config.webhook_processed
				if discord_webhook == '' then
					return
				end
				local headers = {
					['Content-Type'] = 'application/json'
				}
				local data = {
					["username"] = _U('webhook_processed'),
					["embeds"] = {{
						["color"] = 0xa5ff4a,
						["timestamp"] = dateNow,
						['description'] = 'Player - **' ..GetPlayerName(source) .. '**\nIdentifier - **' .. GetPlayerIdentifier(source) ..'**\njob - **' ..xPlayer.job.name.. '**\nprocessed - **' ..oldAmount.. 'x white_raisin** for **' ..amount.. 'x ' ..itemName
					}}
				}
				PerformHttpRequest(discord_webhook, function(err, text, headers) end, 'POST', json.encode(data), headers)
			end
		else
			xPlayer.showNotification(_U('quantity_invalid'))
		end
	end
end)

RegisterServerEvent('yrp_winemaker:PackageRedRaisin')
AddEventHandler('yrp_winemaker:PackageRedRaisin', function(itemName, amount)

	local xPlayer = ESX.GetPlayerFromId(source)
	local weedQuantity = xPlayer.getInventoryItem('red_raisin').count

    if (itemName ~= 'flaska_red_raisin') then
	    print(('[yrp_winemaker] [^2INFO^7] "%s" attempted to spawn in an item!'):format(xPlayer.identifier))
	    return
	end

	if weedQuantity < 5 * amount then
		TriggerClientEvent('esx:showNotification', source, 'You dont have enough red wine, you need ' ..amount * 5)
		return
	end

	if Config.oldESX then
		local yrp = xPlayer.getInventoryItem(itemName)
		if yrp.limit ~= -1 and amount >= yrp.limit then
			xPlayer.showNotification(_U('quantity_invalid'))
		else
			xPlayer.removeInventoryItem('red_raisin', 5 * amount)
			xPlayer.addInventoryItem(itemName, amount)

			if Config.sv_config.webhook_on then
				local discord_webhook = Config.sv_config.webhook_processed
				if discord_webhook == '' then
					return
				end
				local headers = {
					['Content-Type'] = 'application/json'
				}
				local data = {
					["username"] = _U('webhook_processed'),
					["embeds"] = {{
						["color"] = 0xa5ff4a,
						["timestamp"] = dateNow,
						['description'] = 'Player - **' ..GetPlayerName(source) .. '**\nIdentifier - **' .. GetPlayerIdentifier(source) ..'**\njob - **' ..xPlayer.job.name.. '**\nprocessed - **' ..oldAmount.. 'x red_raisin** for **' ..amount.. 'x ' ..itemName
					}}
				}
				PerformHttpRequest(discord_webhook, function(err, text, headers) end, 'POST', json.encode(data), headers)
			end
		end
	else
		if xPlayer.canCarryItem(itemName, amount) then
			xPlayer.removeInventoryItem('red_raisin', 5 * amount)
			xPlayer.addInventoryItem(itemName, amount)

			if Config.sv_config.webhook_on then
				local discord_webhook = Config.sv_config.webhook_processed
				if discord_webhook == '' then
					return
				end
				local headers = {
					['Content-Type'] = 'application/json'
				}
				local data = {
					["username"] = _U('webhook_processed'),
					["embeds"] = {{
						["color"] = 0xa5ff4a,
						["timestamp"] = dateNow,
						['description'] = 'Player - **' ..GetPlayerName(source) .. '**\nIdentifier - **' .. GetPlayerIdentifier(source) ..'**\njob - **' ..xPlayer.job.name.. '**\nprocessed - **' ..oldAmount.. 'x red_raisin** for **' ..amount.. 'x ' ..itemName
					}}
				}
				PerformHttpRequest(discord_webhook, function(err, text, headers) end, 'POST', json.encode(data), headers)
			end
		else
			xPlayer.showNotification(_U('quantity_invalid'))
		end
	end
end)

RegisterServerEvent('yrp_winemaker:SellWhiteRaisin')
AddEventHandler('yrp_winemaker:SellWhiteRaisin', function(itemName, amount)

	local xPlayer = ESX.GetPlayerFromId(source)
	local weedQuantity = xPlayer.getInventoryItem('flaska_white_raisin').count

    if (itemName ~= 'flaska_white_raisin') then
	    print(('[yrp_winemaker] [^2INFO^7] "%s" attempted to spawn in an item!'):format(xPlayer.identifier))
	    return
	end

	if weedQuantity < 1 * amount then
		TriggerClientEvent('esx:showNotification', source, 'You dont have enough white wine, you need ' ..amount)
		return
	end

	TriggerEvent('esx_addonaccount:getSharedAccount', 'society_winemaker', function(account)
		if account then
			local societyMoney = amount*Config.sv_config.white_bootle

			xPlayer.removeInventoryItem('flaska_white_raisin', amount)
			account.addMoney(societyMoney)

			TriggerClientEvent('esx:showNotification', source, 'Your company got ' ..societyMoney.. '$')

			if Config.sv_config.webhook_on then
				local discord_webhook = Config.sv_config.webhook_earn
				if discord_webhook == '' then
					return
				end
				local headers = {
					['Content-Type'] = 'application/json'
				}
				local data = {
					["username"] = _U('webhook_earn'),
					["embeds"] = {{
						["color"] = 0xa5ff4a,
						["timestamp"] = dateNow,
						['description'] = 'Player - **' ..GetPlayerName(source) .. '**\nIdentifier - **' .. GetPlayerIdentifier(source) ..'**\ncompany earn - **' ..xPlayer.job.name.. ' ' ..societyMoney.. '**$'
					}}
				}
				PerformHttpRequest(discord_webhook, function(err, text, headers) end, 'POST', json.encode(data), headers)
			end
		else
			xPlayer.removeInventoryItem('flaska_white_raisin', amount)
			xPlayer.addMoney(societyMoney)
			TriggerClientEvent('esx:showNotification', source, 'You got ' ..societyMoney.. '$')

			if Config.sv_config.webhook_on then
				local discord_webhook = Config.sv_config.webhook_earn
				if discord_webhook == '' then
					return
				end
				local headers = {
					['Content-Type'] = 'application/json'
				}
				local data = {
					["username"] = _U('webhook_earn'),
					["embeds"] = {{
						["color"] = 0xa5ff4a,
						["timestamp"] = dateNow,
						['description'] = 'Player - **' ..GetPlayerName(source) .. '**\nIdentifier - **' .. GetPlayerIdentifier(source) ..'**\nPersonal earn - **' ..xPlayer.job.name.. ' ' ..societyMoney.. '**$'
					}}
				}
				PerformHttpRequest(discord_webhook, function(err, text, headers) end, 'POST', json.encode(data), headers)
			end
		end
	end)
end)

RegisterServerEvent('yrp_winemaker:SellRedRaisin')
AddEventHandler('yrp_winemaker:SellRedRaisin', function(itemName, amount)

	local xPlayer = ESX.GetPlayerFromId(source)
	local weedQuantity = xPlayer.getInventoryItem('flaska_red_raisin').count

    if (itemName ~= 'flaska_red_raisin') then
	    print(('[yrp_winemaker] [^2INFO^7] "%s" attempted to spawn in an item!'):format(xPlayer.identifier))
	    return
	end

	if weedQuantity < 1 * amount then
		TriggerClientEvent('esx:showNotification', source, 'Nemáš dostatek flašek bílého vína, potřebuješ jich ' ..amount * 1)
		return
	end

	TriggerEvent('esx_addonaccount:getSharedAccount', 'society_winemaker', function(account)
		if account then
			local societyMoney = amount*Config.sv_config.red_bootle

			xPlayer.removeInventoryItem('flaska_red_raisin', amount)
			account.addMoney(societyMoney)

			TriggerClientEvent('esx:showNotification', source, 'Your company got ' ..societyMoney.. '$')

			if Config.sv_config.webhook_on then
				local discord_webhook = Config.sv_config.webhook_earn
				if discord_webhook == '' then
					return
				end
				local headers = {
					['Content-Type'] = 'application/json'
				}
				local data = {
					["username"] = _U('webhook_earn'),
					["embeds"] = {{
						["color"] = 0xa5ff4a,
						["timestamp"] = dateNow,
						['description'] = 'Player - **' ..GetPlayerName(source) .. '**\nIdentifier - **' .. GetPlayerIdentifier(source) ..'**\ncompany earn - **' ..xPlayer.job.name.. ' ' ..societyMoney.. '**$'
					}}
				}
				PerformHttpRequest(discord_webhook, function(err, text, headers) end, 'POST', json.encode(data), headers)
			end

		else
			xPlayer.removeInventoryItem('flaska_red_raisin', amount)
			xPlayer.addMoney(societyMoney)
			TriggerClientEvent('esx:showNotification', source, 'You got ' ..societyMoney.. '$')

			if Config.sv_config.webhook_on then
				local discord_webhook = Config.sv_config.webhook_earn
				if discord_webhook == '' then
					return
				end
				local headers = {
					['Content-Type'] = 'application/json'
				}
				local data = {
					["username"] = _U('webhook_earn'),
					["embeds"] = {{
						["color"] = 0xa5ff4a,
						["timestamp"] = dateNow,
						['description'] = 'Player - **' ..GetPlayerName(source) .. '**\nIdentifier - **' .. GetPlayerIdentifier(source) ..'**\nPersonal earn - **' ..xPlayer.job.name.. ' ' ..societyMoney.. '**$'
					}}
				}
				PerformHttpRequest(discord_webhook, function(err, text, headers) end, 'POST', json.encode(data), headers)
			end
		end
	end)
end)