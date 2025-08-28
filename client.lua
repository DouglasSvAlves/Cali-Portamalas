QBCore = exports['qb-core']:GetCoreObject()

targetintrunk = 0
local inTrunk = false

function DrawText3D(coords, text)
    local onScreen,_x,_y=World3dToScreen2d(coords.x,coords.y,coords.z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 251, 17, 138, 48)
    ClearDrawOrigin()
end

function loadDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) RequestAnimDict(dict) end
end

function VehicleinFront()
	local pos = GetEntityCoords(PlayerPedId())
	local entityWorld = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 6.0, 0.0)
	local rayHandle = CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 10, PlayerPedId(), 0)
	local _, _, _, _, result = GetRaycastResult(rayHandle)
	return result
end

function GetVehicles()
    local vehicles = {}
	for vehicle in EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle) do
		table.insert(vehicles, vehicle)
	end
	return vehicles
end

function GetNearbyVehicle(coords)
	local vehicles        = GetVehicles()
	local closestDist = -1
	local closestVehicle  = -1
	local coords          = coords

	if coords == nil then
		local playerPed = PlayerPedId()
		coords = GetEntityCoords(playerPed)
	end
	for i=1, #vehicles, 1 do
		local vehicleCoords = GetEntityCoords(vehicles[i])
		local distance      = GetDistanceBetweenCoords(vehicleCoords, coords.x, coords.y, coords.z, true)

		if closestDist == -1 or closestDist > distance then
			closestVehicle  = vehicles[i]
			closestDist = distance
		end
	end
	return closestVehicle
end

function EnumerateEntities(initFunc, moveFunc, disposeFunc)
	return coroutine.wrap(function()
		local iter, id = initFunc()
		if not id or id == 0 then
			disposeFunc(iter)
			return
		end
		local enum = {handle = iter, destructor = disposeFunc}
		setmetatable(enum, entityEnumerator)
		local next = true
		repeat
		coroutine.yield(id)
		next, id = moveFunc(iter)
		until not next
		enum.destructor, enum.handle = nil, nil
		disposeFunc(iter)
	end)
end


Citizen.CreateThread(function()
    while true do
		local idle = 1000
        if inTrunk then
			idle = 0
            local vehicle = GetEntityAttachedTo(PlayerPedId())
            local data = QBCore.Functions.GetPlayerData()
            if DoesEntityExist(vehicle) and not IsPedDeadOrDying(PlayerPedId()) and not IsPedFatallyInjured(PlayerPedId()) and not data.metadata['ishandcuffed'] then -- Colocado o check da pessoa está algemado
				local coords = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, 'platelight'))
				SetEntityCollision(PlayerPedId(), false, false)
				LocalPlayer.state:set('inv_busy', true, true)
				
				DrawText3D(coords,'[~q~G~w~] Abrir/Fechar porta-malas | [~q~F~w~] Para sair do porta-malas')   

				if(not DoesCamExist(cam)) then
					cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
					SetCamCoord(cam, GetEntityCoords(PlayerPedId()))
					SetCamRot(cam, 0.0, 0.0, 0.0)
					SetCamActive(cam,  true)
					RenderScriptCams(true,  false,  0,  true,  true)
					SetCamCoord(cam, GetEntityCoords(PlayerPedId()))
				end
				AttachCamToEntity(cam, PlayerPedId(), 0.0,-2.5,1.0, true)
				SetCamRot(cam, -30.0, 0.0, GetEntityHeading(PlayerPedId()))

                if GetVehicleDoorAngleRatio(vehicle, 5) < 0.9 then

                else
                    if not IsEntityPlayingAnim(PlayerPedId(), 'fin_ext_p1-7', 3) then
                        loadDict('fin_ext_p1-7')
                        TaskPlayAnim(PlayerPedId(), 'fin_ext_p1-7', 'cs_devin_dual-7', 8.0, -8.0, -1, 1, 0, false, false, false)
                    end
                end
				if GetVehicleDoorLockStatus(vehicle) == 1 and IsDisabledControlJustReleased(0, 47) then
					if GetVehicleDoorAngleRatio(vehicle, 5) > 0.0 then
						SetVehicleDoorShut(vehicle, 5, 1, true)
						NetworkSetEntityInvisibleToNetwork(PlayerPedId(),true)
						SetEntityVisible(PlayerPedId(),false,false)
						SetEntityAlpha(PlayerPedId(), 100, false)
						SetLocalPlayerVisibleLocally(true)
					else
						SetVehicleDoorOpen(vehicle, 5, 1, true)
						NetworkSetEntityInvisibleToNetwork(PlayerPedId(),false)
						SetEntityVisible(PlayerPedId(),true,true)
						SetEntityAlpha(PlayerPedId(), 255, false)
						SetLocalPlayerVisibleLocally(true)
						Citizen.Wait(100)
						SetVehicleDoorOpen(vehicle, 5, 1, true)							
					end	
				elseif GetVehicleDoorLockStatus(vehicle) == 4 or GetVehicleDoorLockStatus(vehicle) == 2 then
                    QBCore.Functions.Notify("O porta-malas está trancado.", 'error')			
				end
                if IsDisabledControlJustReleased(0, 49) and inTrunk then
					if GetVehicleDoorAngleRatio(vehicle, 5) ~= 0 then
						SetEntityCollision(PlayerPedId(), true, true)
						Wait(750)
						inTrunk = false
						DetachEntity(PlayerPedId(), true, true)
						ClearPedTasks(PlayerPedId())
						SetEntityCoords(PlayerPedId(), GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, -0.5, -0.75))
						RenderScriptCams(false, false, 0, 1, 0)
						DestroyCam(cam, false)
						SetVehicleDoorShut(vehicle, 5)
						Wait(250)
						NetworkSetEntityInvisibleToNetwork(PlayerPedId(),false)
						SetEntityVisible(PlayerPedId(),true,true)
						SetEntityAlpha(PlayerPedId(), 255, false)
						SetLocalPlayerVisibleLocally(true)
						LocalPlayer.state:set('inv_busy', false, true)
					else
                        QBCore.Functions.Notify("O porta-malas está fechado.", 'error')
					end					
                end
            else
                SetEntityCollision(PlayerPedId(), true, true)
                DetachEntity(PlayerPedId(), true, true)
                ClearPedTasks(PlayerPedId())
                SetEntityCoords(vehicle, GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, -0.5, -0.75))
				inTrunk = false
				RenderScriptCams(false, false, 0, 1, 0)
				DestroyCam(cam, false)
				NetworkSetEntityInvisibleToNetwork(PlayerPedId(),false)
				SetEntityVisible(PlayerPedId(),true,true)
				SetEntityAlpha(PlayerPedId(), 255, false)
				SetLocalPlayerVisibleLocally(true)
				LocalPlayer.state:set('inv_busy', false, true)
				Wait(250)
            end
        end
		Wait(idle)
    end
end)   

Citizen.CreateThread(function()
	while true do
		local idle = 1000
		if inTrunk then 
			idle = 0
			DisableAllControlActions(0)
			DisableAllControlActions(1)
			DisableAllControlActions(2)		 	
			EnableControlAction(0, 0, true) 
			EnableControlAction(0, 249, true) 
			EnableControlAction(2, 1, true) 
			EnableControlAction(2, 2, true) 
			EnableControlAction(0, 177, true) 
		 	EnableControlAction(0, 200, true)
			while not IsEntityPlayingAnim(GetPlayerPed(-1), 'fin_ext_p1-7', 'cs_devin_dual-7', 3) do
				TaskPlayAnim(GetPlayerPed(-1), 'fin_ext_p1-7', 'cs_devin_dual-7', 8.0, 8.0, -1, 1, 999.0, 0, 0, 0)
				Citizen.Wait(0)
			end
		else
			RenderScriptCams(false, false, 0, 1, 0)
			DestroyCam(cam, false)
		end
		Wait(idle)
	end
end)

Citizen.CreateThread(function() 
	while true do 
		local idle = 1000
        local vehicle = VehicleinFront()
        local trunk = GetEntityBoneIndexByName(vehicle, 'boot')					
        local coords = GetWorldPositionOfEntityBone(vehicle, trunk)
        local distance  = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), coords, true)	
        if GetVehicleDoorAngleRatio(vehicle,5) ~= 0 and not inTrunk then
            if not IsEntityAttached(PlayerPedId()) and distance < 1.5 then		
				idle = 0													
                DrawText3D(coords,'Pressione [~q~E~w~] Para entrar no porta-malas')														
                if IsControlJustReleased(0, 38) then
                    local d1,d2 = GetModelDimensions(GetEntityModel(vehicle))													
                    AttachEntityToEntity(PlayerPedId(), vehicle, 0, -0.1,d1["y"]+0.85,d2["z"]-0.87, 0, 0, 40.0, 1, 1, 1, 1, 1, 1)																		
                    inTrunk = true
                end
            end						
        end
		Citizen.Wait(idle)
	end
end)