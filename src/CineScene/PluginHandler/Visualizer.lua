--// SERVICES
local RunServ = game:GetService("RunService")
local PluginHandler = _G.CineScenePluginHandler

--// REQUIRES
local CineSceneEnums = require(script.Parent.CineSceneEnums)

--// VARIABLES
local Camera = workspace.CurrentCamera

--// HANDLER
local Handler = {
	Cutscenes = {},
	Parts = {},
	VisualizerFolder = workspace:FindFirstChild("CineScene_Visualizer_Folder") or Instance.new("Folder")
}
Handler.VisualizerFolder.Parent = workspace
Handler.VisualizerFolder.Name = "CineScene_Visualizer_Folder"

--// CONNECTIONS
RunServ.RenderStepped:Connect(function()
	local PartIndex = 1
	for i,v in pairs(Handler.Cutscenes) do
		if Handler.PreviewingCutscene and v == Handler.PreviewingCutscene then continue end
		local Path,CameraNodes = v:SolveFullCutscene(PluginHandler.Settings.Visualizer_Step.Value)
		local Speeds = Handler:CalculateCutsceneSpeeds(Path,CameraNodes)
		for Ind = 1,#Path-1 do
			local P1 = Path[Ind]
			local P2 = Path[Ind + 1]
			local Part = Handler:GetPart(PartIndex)
			PartIndex += 1
			Part.CFrame = CFrame.lookAt((P1+P2)/2,P2)
			local SpeedFactor = (Speeds[Ind] + Speeds[Ind + 1])/2
			if PluginHandler.Settings.Visualizer_Show_Speed.Value then
				local Hue
				if SpeedFactor > 128 then
					Hue = math.max(484 - SpeedFactor,192)
				else
					Hue = 128 - SpeedFactor
				end
				Part.Color = Color3.fromHSV(Hue/360,1,1)
			else
				Part.Color = Color3.fromRGB(12, 114, 158)
			end
			Part.Size = Vector3.new(0.1,0.1,(P1-P2).Magnitude)
		end
	end
	for i = PartIndex,#Handler.Parts do
		local Part = Handler.Parts[i]
		Part.Transparency = 1
	end
end)

--// LOCAL FUNCTIONS
local function ErrorFunction(x)
	-- constants
	local a1 =  0.254829592
	local a2 = -0.284496736
	local a3 =  1.421413741
	local a4 = -1.453152027
	local a5 =  1.061405429
	local p  =  0.3275911

	-- Save the sign of x
	local sign = 1
	if x < 0 then
		sign = -1
	end
	x = math.abs(x)

	-- A&S formula 7.1.26
	local t = 1.0/(1.0 + p*x)
	local y = 1.0 - (((((a5*t + a4)*t) + a3)*t + a2)*t + a1)*t*math.exp(-x*x)

	return sign*y
end

local function SmoothLerp(x)
	local z = math.sqrt(32) * (x - 0.5)
	return 0.5 * ErrorFunction(z) * 1/0.99993662792787
end

--// MEMBER FUNCTIONS
function Handler:GetPart(Ind)
	if not self.Parts[Ind] or not self.Parts[Ind].Parent then
		self.Parts[Ind] = Instance.new("Part")
		self.Parts[Ind].Parent = self.VisualizerFolder
		self.Parts[Ind].Material = Enum.Material.Neon
		self.Parts[Ind].Locked = true
	end
	self.Parts[Ind].Transparency = 0
	return self.Parts[Ind]
end

function Handler:AddCutscene(Cutscene)
	if table.find(self.Cutscenes,Cutscene) then return end
	table.insert(self.Cutscenes,Cutscene)
end

function Handler:RemoveCutscene(Cutscene)
	if not table.find(self.Cutscenes,Cutscene) then return end
	table.remove(self.Cutscenes,table.find(self.Cutscenes,Cutscene))
end

function Handler:CalculateCutsceneSpeeds(Path,CameraNodes)
	local Distances = {}
	local CurrentDistCounter = 0
	for i = 1,#Path do
		Distances[i] = CurrentDistCounter
		if Path[i + 1] then
			CurrentDistCounter += (Path[i + 1] - Path[i]).Magnitude
		else
			break
		end
	end
	local Speed = {}
	do --// SPEED CALCULATIONS
		local CurrentNodeInd = 1
		local NextNodeInd = 1
		local CurrentNodeIndOutDist
		local NextNodeIndInDist
		local LastPoint = 1
		local CurrentSpeed = CameraNodes[1].CameraSpeed --// CameraNodes[1].CameraSpeedTransitionTimeOut == 0 and CameraNodes[1].CameraSpeed or 0
		--[[
			    	Doesn't work because it's not acceleration based. Speed starts at 0 so it never moves anywhere.

			TODO:   Possibly switch to Acceleration based system? Future update idea
		]]
		local SpeedDiff = 0
		local CurrentTransitionMode = "None"
		local CurrentTransitionInInd = 0
		for i = 1,#Path do
			if i == NextNodeInd then
				for NextInd = i+1,#Path do
					if CameraNodes[NextInd] then
						CurrentNodeInd = NextNodeInd
						NextNodeInd = NextInd
						CurrentNodeIndOutDist = nil
						NextNodeIndInDist = nil
						break
					end
				end
				if NextNodeInd == i then
					CurrentNodeInd = NextNodeInd
					NextNodeInd = nil
					CurrentNodeIndOutDist = nil
					NextNodeIndInDist = nil
				end
			end
			if not CurrentNodeIndOutDist then
				local OutTime = CameraNodes[CurrentNodeInd].CameraSpeedTransitionTimeOut
				if OutTime == 0 then
					CurrentNodeIndOutDist = 0
				else
					CurrentNodeIndOutDist = 0.5 * OutTime * (2*CurrentSpeed + (CameraNodes[CurrentNodeInd].CameraSpeed - CurrentSpeed) * (OutTime / (OutTime + CameraNodes[CurrentNodeInd].CameraSpeedTransitionTimeIn)))
				end
			end
			if NextNodeInd then
				local InTime = CameraNodes[NextNodeInd].CameraSpeedTransitionTimeIn
				if InTime == 0 then
					NextNodeIndInDist = 0
				else
					NextNodeIndInDist = 0.5 * InTime * (2*CurrentSpeed + (CameraNodes[NextNodeInd].CameraSpeed - CurrentSpeed) * (InTime / (InTime + CameraNodes[NextNodeInd].CameraSpeedTransitionTimeOut)))
				end
			end

			if Distances[i] - Distances[CurrentNodeInd] < CurrentNodeIndOutDist and (not NextNodeIndInDist or Distances[NextNodeInd] - Distances[i] > NextNodeIndInDist) then
				if CurrentTransitionMode ~= "Out" then
					CurrentTransitionMode = "Out"
					SpeedDiff = CameraNodes[CurrentNodeInd].CameraSpeed - CurrentSpeed
				end
				CurrentSpeed += (Distances[i] - Distances[LastPoint]) / CurrentNodeIndOutDist * SpeedDiff
			elseif NextNodeIndInDist and Distances[NextNodeInd] - Distances[i] < NextNodeIndInDist then
				if CurrentTransitionMode ~= "In" or CurrentTransitionInInd ~= NextNodeInd then
					CurrentTransitionInInd = NextNodeInd
					CurrentTransitionMode = "In"
					local TimeFactor = CameraNodes[NextNodeInd].CameraSpeedTransitionTimeOut
					TimeFactor /= TimeFactor + CameraNodes[NextNodeInd].CameraSpeedTransitionTimeOut
					SpeedDiff = (CameraNodes[NextNodeInd].CameraSpeed - CurrentSpeed) * TimeFactor
				end
				CurrentSpeed += (Distances[i] - Distances[LastPoint]) / NextNodeIndInDist * SpeedDiff
			else
				CurrentTransitionMode = "None"
				CurrentSpeed = CameraNodes[CurrentNodeInd].CameraSpeed
			end

			Speed[i] = CurrentSpeed
			LastPoint = i
		end
	end

	return Speed
end

local function CalculateT(P0,P1,T0,Alpha)
	local Pi = P1-P0
	return T0 + (Pi.X^2 + Pi.Y^2 + Pi.Z^2)^(Alpha/2)
end

function Handler:SolveSplinePoint(N0,N1,N2,N3,t)
	local t0 = 0
	local t1 = CalculateT(N0,N1,t0,0.5)
	local t2 = CalculateT(N1,N2,t1,0.5)
	local t3 = CalculateT(N2,N3,t2,0.5)
	local M1,M2 = (N2-N0),(N3-N1)

	-- return (2*t^3 - 3*t^2 + 1) * P1 + (t^3 - 2*t^2 + t) * M1
	-- 		+
	-- 		(-2*t^3 + 3*t^2) * P2 + (t^3 - t^2) * M2
			
	return N1 + t * (
		M1 
		+ 
		t * (
			3*(N2-N1) - (2*M1+M2) 
			+ 
			t * (
				2 * (N1-N2) + M1 + M2
			)
		)
	)
end

function Handler:DisplayCutscene(Cutscene)
	if self.IsPlayingCutscene then self.IsPlayingCutscene = false return end
	local Path,CameraNodes = Cutscene:SolveFullCutscene(PluginHandler.Settings.Cutscene_Step.Value)
	local PathLength = #Path
	print(PathLength)
	self.PreviewingCutscene = Cutscene
	self.IsPlayingCutscene = true
	local PrevStudioCameraSpeed = settings().Studio["Camera Speed"]
	local PrevStudioCameraScrollSpeed = settings().Studio["Camera Mouse Wheel Speed"]
	local PrevCameraType = Camera.CameraType
	settings().Studio["Camera Speed"] = 0
	settings().Studio["Camera Mouse Wheel Speed"] = 0
	Camera.CameraType = Enum.CameraType.Scriptable

	local Speeds = self:CalculateCutsceneSpeeds(Path,CameraNodes)
	local SegmentLengths = {}
	for i = 1,(PathLength-1)/PluginHandler.Settings.Cutscene_Step.Value do
		local Distance = 0
		local Offset = (i-1) * PluginHandler.Settings.Cutscene_Step.Value
		for Step = 1,PluginHandler.Settings.Cutscene_Step.Value do
			Distance += (Path[Offset+Step+1] - Path[Offset+Step]).Magnitude
		end
		SegmentLengths[i] = Distance
	end

	local CameraCFramePath = {}

	local PreviousCameraNode = CameraNodes[1]
	local CurrentCameraNode = PreviousCameraNode
	local CameraData = {}
	if CurrentCameraNode.CameraType == CineSceneEnums.CameraType.LookForward then
		Camera.CFrame = CFrame.lookAt(Path[1],Path[2])
	elseif CurrentCameraNode.CameraType == CineSceneEnums.CameraType.FollowSubject then
		Camera.CFrame = CFrame.lookAt(Path[1],CurrentCameraNode.CameraSubject.CFrame.Position)
	elseif CurrentCameraNode.CameraType == CineSceneEnums.CameraType.Static then
		Camera.CFrame = CurrentCameraNode.CFrame
	elseif CurrentCameraNode.CameraType == CineSceneEnums.CameraType.AngularPhysics then
		Camera.CFrame = CurrentCameraNode.CFrame
		CameraData.Velocity = CurrentCameraNode.CameraImpulse
		CameraData.Acceleration = CurrentCameraNode.CameraAcceleration
	end
	local Speed
	local Time = 0
	local PreviousNodeTime = 0
	local CurrentNodeTime = 0
	local IsSpeedTransition = false
	local IsDataTransition = false
	local RolloverDistance = 0
	local CurrentTraveledDistance = 0
	local CurrentSectionInd = 1
	local CurrentSectionLength = SegmentLengths[1]
	local CurrentPointInd = 1
	local Finished = false
	local PreviousInd = CurrentPointInd
	local PreviousPosition = Camera.CFrame
	while not Finished and self.IsPlayingCutscene do
		local Point = Path[CurrentPointInd]

		local FrameTime = RunServ.RenderStepped:Wait()
		Time += FrameTime
		local SpeedLerpFactor = (Camera.CFrame.Position - Path[CurrentPointInd]).Magnitude / (Path[CurrentPointInd] - Path[CurrentPointInd + 1] or Path[CurrentPointInd]*2).Magnitude
		Speed = Speeds[CurrentPointInd] * (1 - SpeedLerpFactor) + (Speeds[CurrentPointInd + 1] or 0) * SpeedLerpFactor
		RolloverDistance = Speed * FrameTime
		CurrentTraveledDistance += RolloverDistance
		
		while RolloverDistance ~= 0 do
			if not Path[CurrentPointInd+1] then
				Finished = true
				FrameTime -= RolloverDistance/Speed
				break
			end
			local NextPointDist =  Path[CurrentPointInd+1] - Camera.CFrame.Position
			local NextPointDistance = NextPointDist.Magnitude
			local TravelDistance = math.min(NextPointDistance,RolloverDistance)
			if TravelDistance < RolloverDistance then
				RolloverDistance -= TravelDistance
				Camera.CFrame = CFrame.fromMatrix(
					Path[CurrentPointInd + 1],
					Camera.CFrame.XVector,
					Camera.CFrame.YVector,
					Camera.CFrame.ZVector
				)
				CurrentPointInd += 1
				CurrentSectionInd = 1+math.floor((CurrentPointInd-1) / PluginHandler.Settings.Cutscene_Step.Value)
				CurrentSectionLength = SegmentLengths[CurrentSectionInd]
			else
				RolloverDistance = 0
				Camera.CFrame = CFrame.fromMatrix(
					Camera.CFrame.Position + NextPointDist.Unit * TravelDistance,
					Camera.CFrame.XVector,
					Camera.CFrame.YVector,
					Camera.CFrame.ZVector
				)
				if Path[CurrentPointInd+1]-Camera.CFrame.Position == Vector3.new() then
					CurrentPointInd += 1
					CurrentSectionInd = 1+math.floor((CurrentPointInd-1) / PluginHandler.Settings.Cutscene_Step.Value)
					CurrentSectionLength = SegmentLengths[CurrentSectionInd]
				end
			end
			if CameraNodes[CurrentPointInd] and CameraNodes[CurrentPointInd] ~= CurrentCameraNode then
				PreviousCameraNode = CurrentCameraNode
				CurrentCameraNode = CameraNodes[CurrentPointInd]
				PreviousNodeTime = CurrentNodeTime
				CurrentNodeTime = Time
				if CurrentCameraNode.CameraTransitionTimeOut > 0 then
					IsDataTransition = true
				end
			end
		end

		if Finished == true then continue end

		if IsDataTransition then
			local DistanceLerpFactor = math.clamp((Time - PreviousNodeTime) / CurrentCameraNode.CameraSpeedTransitionTime,0,1)
			if CurrentCameraNode.CameraType == CineSceneEnums.CameraType.LookForward then
				if PreviousCameraNode.CameraType == CineSceneEnums.CameraType.LookForward then
					Camera.CFrame = CFrame.new()
					IsDataTransition = false
				elseif PreviousCameraNode.CameraType == CineSceneEnums.CameraType.FollowSubject then
				elseif PreviousCameraNode.CameraType == CineSceneEnums.CameraType.Static then
				elseif PreviousCameraNode.CameraType == CineSceneEnums.CameraType.AngularPhysics then
				end
			elseif CurrentCameraNode.CameraType == CineSceneEnums.CameraType.FollowSubject then
				Camera.CFrame = CFrame.lookAt(Path[1],CurrentCameraNode.CameraSubject.CFrame.Position)
			elseif CurrentCameraNode.CameraType == CineSceneEnums.CameraType.Static then
				Camera.CFrame = CurrentCameraNode.CFrame
			elseif CurrentCameraNode.CameraType == CineSceneEnums.CameraType.AngularPhysics then
				Camera.CFrame = CurrentCameraNode.CFrame
			end
			if DistanceLerpFactor == 1 then IsDataTransition = false end
		else
		end
		-- local PreviousLookVector = Path[CurrentPointInd - 1] and (Path[CurrentPointInd] - Path[CurrentPointInd-1]).Unit or (Path[CurrentPointInd+1] - Path[CurrentPointInd]).Unit
		-- local PreviousCFrame = CFrame.lookAt(Camera.CFrame.Position,Camera.CFrame.Position + PreviousLookVector)

		-- local CurrentLookVector = (Path[CurrentPointInd+1] - Path[CurrentPointInd]).Unit
		-- local CurrentCFrame = CFrame.lookAt(Camera.CFrame.Position,Camera.CFrame.Position + CurrentLookVector)

		-- local TotalDistance = (Path[CurrentPointInd + 1] - Path[CurrentPointInd]).Magnitude
		-- local CameraDistance = (Camera.CFrame.Position - Path[CurrentPointInd]).Magnitude
		-- local CameraLerpFactor = CameraDistance/TotalDistance

		-- Camera.CFrame = PreviousCFrame:Lerp(CurrentCFrame,CameraLerpFactor)
		
		--[[ OLD CODE
			-- if CurrentCameraNode.CameraType == CineSceneEnums.CameraType.LookForward then
			-- 	local PreviousLookVector = Path[CurrentPointInd - 1] and (Path[CurrentPointInd] - Path[CurrentPointInd-1]).Unit or (Path[CurrentPointInd+1] - Path[CurrentPointInd]).Unit
			-- 	local PreviousCFrame = CFrame.lookAt(Camera.CFrame.Position,Camera.CFrame.Position + PreviousLookVector)

			-- 	local CurrentLookVector = (Path[CurrentPointInd+1] - Path[CurrentPointInd]).Unit
			-- 	local CurrentCFrame = CFrame.lookAt(Camera.CFrame.Position,Camera.CFrame.Position + CurrentLookVector)

			-- 	local TotalDistance = (Path[CurrentPointInd + 1] - Path[CurrentPointInd]).Magnitude
			-- 	local CameraDistance = Camera.CFrame.Position - Path[CurrentPointInd]
			-- 	local CameraLerpFactor = CameraDistance/TotalDistance

			-- 	Camera.CFrame = PreviousCFrame:Lerp(CurrentCFrame,CameraLerpFactor)

			-- elseif CurrentCameraNode.CameraType == CineSceneEnums.CameraType.FollowSubject then
			-- 	Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position,Path[CurrentPointInd+1])
			-- elseif CurrentCameraNode.CameraType == CineSceneEnums.CameraType.Static then
			-- 	Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position,Path[CurrentPointInd+1])
			-- elseif CurrentCameraNode.CameraType == CineSceneEnums.CameraType.AngularPhysics then
			-- 	Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position,Path[CurrentPointInd+1])
			-- end
		]]
	end

	settings().Studio["Camera Speed"] = PrevStudioCameraSpeed
	settings().Studio["Camera Mouse Wheel Speed"] = PrevStudioCameraScrollSpeed
	Camera.CameraType = PrevCameraType

	self.IsPlayingCutscene = false
	self.PreviewingCutscene = nil
end

function Handler:PlayCutscene(Cutscene)
	if self.IsPlayingCutscene then self.IsPlayingCutscene = false return end
	local Path,CameraNodes = Cutscene:SolveFullCutscene(PluginHandler.Settings.Cutscene_Step.Value)
	local PathLength = #Path
	self.PreviewingCutscene = Cutscene
	self.IsPlayingCutscene = true
	local PrevStudioCameraSpeed = settings().Studio["Camera Speed"]
	local PrevStudioCameraScrollSpeed = settings().Studio["Camera Mouse Wheel Speed"]
	local PrevCameraType = Camera.CameraType
	settings().Studio["Camera Speed"] = 0
	settings().Studio["Camera Mouse Wheel Speed"] = 0
	Camera.CameraType = Enum.CameraType.Scriptable

	local Speeds = self:CalculateCutsceneSpeeds(Path,CameraNodes)
	local SegmentLengths = {}
	for i = 1,(PathLength-1)/PluginHandler.Settings.Cutscene_Step.Value do
		local Distance = 0
		local Offset = (i-1) * PluginHandler.Settings.Cutscene_Step.Value
		for Step = 1,PluginHandler.Settings.Cutscene_Step.Value do
			Distance += (Path[Offset+Step+1] - Path[Offset+Step]).Magnitude
		end
		SegmentLengths[i] = Distance
	end

	local PreviousCameraNode = CameraNodes[1]
	local CurrentCameraNode = PreviousCameraNode
	local CameraData = {}
	if CurrentCameraNode.CameraType == CineSceneEnums.CameraType.LookForward then
		Camera.CFrame = CFrame.lookAt(Path[1],Path[2])
	elseif CurrentCameraNode.CameraType == CineSceneEnums.CameraType.FollowSubject then
		Camera.CFrame = CFrame.lookAt(Path[1],CurrentCameraNode.CameraSubject.CFrame.Position)
	elseif CurrentCameraNode.CameraType == CineSceneEnums.CameraType.Static then
		Camera.CFrame = CurrentCameraNode.CFrame
	elseif CurrentCameraNode.CameraType == CineSceneEnums.CameraType.AngularPhysics then
		Camera.CFrame = CurrentCameraNode.CFrame
		CameraData.Velocity = CurrentCameraNode.CameraImpulse
		CameraData.Acceleration = CurrentCameraNode.CameraAcceleration
	end
end

return Handler