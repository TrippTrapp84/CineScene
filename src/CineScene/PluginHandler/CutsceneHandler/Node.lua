--// SERIVCES

--// REQUIRES
local CineSceneEnums = require(script.Parent.Parent.CineSceneEnums)

--// CONSTANTS
local NULL = {}

--// CONSTRUCTOR
local Handler = {}
Handler.__index = Handler

local function DefaultValues()
	return {
		NodeType = CineSceneEnums.NodeType.Linear,
		CameraType = CineSceneEnums.CameraType.LookForward,
		CFrame = CFrame.new(),
		CameraCFrame = CFrame.new(),
		CameraTransitionTimeIn = 1,
		CameraTransitionTimeOut = 1,
		CameraSpeed = 1,
		CameraSubject = {CFrame = CFrame.new()},
		CameraAcceleration = Vector3.new(),
		CameraImpulse = Vector3.new(),
		CameraSpeedTransitionTimeIn = 1,
		CameraSpeedTransitionTimeOut = 1,
		IsMovementNode = true,
		IsCameraNode = true,
		NodeVectorStrength = 1,
		NodeTangentLength = 1,
		NodeMenu = NULL,
		CameraDropdown = NULL,
		MovementDropdown = NULL,
		CameraCheckbox = NULL,
		MovementCheckbox = NULL,
		NodeVectorStrengthSlider = NULL,
		NodeTangentLengthSlider = NULL,
		CameraSpeedInput = NULL
	}
end

function Handler.new(Data)
	Data = Data or {}
	local Obj = {}
	
	setmetatable(Obj,Handler)
	
	for i,v in pairs(DefaultValues()) do
		Obj[i] = (Data[i] == nil and v or Data[i]) or false
		if Obj[i] == NULL then error("Missing data for CineScene_Node constructor: ",i) end
	end
	
	return Obj
end

function Handler:SetIsMovementNode(IsMovementNode)
	self.IsMovementNode = IsMovementNode
	self.MovementCheckbox:SetValue(IsMovementNode)
end

function Handler:SetIsCameraNode(IsCameraNode)
	self.IsCameraNode = IsCameraNode
	self.CameraCheckbox:SetValue(IsCameraNode)
end

function Handler:SetNodeType(NodeType)
	self.NodeType = NodeType
	self.MovementDropdown:SetChoice(NodeType)
end

function Handler:SetCameraType(CameraType)
	self.CameraType = CameraType
	self.CameraDropdown:SetChoice(CameraType)
end

function Handler:SetVectorStrength(VectorStrength)
	self.NodeVectorStrength = (VectorStrength-1)/99
end

function Handler:SetTangentLength(TangentLength)
	self.NodeTangentLength = TangentLength
end

function Handler:SetCameraSpeed(CameraSpeed)
	self.CameraSpeed = CameraSpeed
end

function Handler:SetCameraSpeedTransitionTimeIn(CameraSpeedTransitionTimeIn)
	self.CameraSpeedTransitionTimeIn = CameraSpeedTransitionTimeIn
end

function Handler:SetCameraSpeedTransitionTimeOut(CameraSpeedTransitionTimeOut)
	self.CameraSpeedTransitionTimeOut = CameraSpeedTransitionTimeOut
end

return Handler