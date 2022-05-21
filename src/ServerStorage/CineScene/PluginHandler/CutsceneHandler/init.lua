--// SERIVCES
local RunServ = game:GetService("RunService")
local Selection = game:GetService("Selection")
local PluginHandler = _G.CineScenePluginHandler
local plugin = _G.CineScenePluginHandler.plugin

--// REQUIRES
local StudioWidgets = script.Parent.Parent.StudioWidgets
local WidgetLibrary = require(script.Parent.Parent.StudioWidgets.Require)()
local CineSceneEnums = require(script.Parent.CineSceneEnums)
local NodeClass = require(script.Node)

--// CONSTANTS
local NULL = {}

--// CONSTRUCTOR
local Handler = {}
Handler.__index = Handler

local function DefaultValues()
	return {
		Nodes = {},
		Active = false,
		Visualized = false,
		Looped = false,
		DrawEnds = false,
		ID = NULL,
		CutsceneMenu = NULL,
		ActiveCheckbox = NULL,
		Name = NULL
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
	
	Obj.PluginHandler = _G.CineScenePluginHandler
	Obj.NodeHandles = {}
	local TempNodes = Obj.Nodes
	Obj.Nodes = {}
	for i,v in ipairs(TempNodes) do
		Obj:AddNode(i,v)
	end
	
	Obj.Connections = {}
	
	Obj.Connections[1] = RunServ.RenderStepped:Connect(function()
		for i,Node in ipairs(Obj.Nodes) do
			local NodeHandle = Obj.NodeHandles[i]
			if PluginHandler.Settings.Camera_CFrame_Edit_Mode_Enabled.Value then
				NodeHandle.Color = Color3.new(0.768627, 0.203921, 0.203921)
			else
				NodeHandle.Color = Color3.new(0.596078, 0.796078, 0.847058)
			end
			if Node.IsMovementNode then
				Obj:SetNodeCFrame(Node,NodeHandle)
				if not Obj.Looped and (i == 1 or i == #Obj.Nodes) then
					Node:SetNodeType(CineSceneEnums.NodeType.Linear)
				end
			else
				if i == 1 or (not Obj.Looped and i == #Obj.Nodes) then
					Node:SetIsMovementNode(true)
					Obj:SetNodeCFrame(Node,NodeHandle)
				else
					Obj:RealignCameraNode(i)
				end
			end
		end
	end)
	
	Obj.Connections[2] = Selection.SelectionChanged:Connect(function()
		local Selected = Selection:Get()
		if #Selected ~= 1 then return end
		local HandleInd = table.find(Obj.NodeHandles,Selected[1])
		if HandleInd then
			Obj.PluginHandler:OpenCutscene(Obj)
		end
	end)

	Obj:SetActive(Obj.Active)
	
 	return Obj
end

--// DESTRUCTOR
function Handler:Destroy()
	for i,v in pairs(self.Connections) do
		v:Disconnect()
	end
	for i,v in pairs(self.NodeHandles) do
		v:Destroy()
	end
	for i,v in pairs(self.Nodes) do
		v.NodeMenu:GetSectionFrame():Destroy()
	end
end

--// MEMBER FUNCTIONS
function Handler:SetName(Name)
	local PreviousModule = PluginHandler.Settings.Cutscene_Storage_Location.Value:FindFirstChild(self.Name)
	if PreviousModule then
		PreviousModule.Name = Name
	end
	PreviousModule = PluginHandler.Settings.Cutscene_Data:FindFirstChild(self.Name)
	if PreviousModule then
		PreviousModule.Name = Name
	end
	self.Name = Name
end

function Handler:SetNodeCFrame(Node,NodeHandle)
	local CameraCFrameEditMode = PluginHandler.Settings.Camera_CFrame_Edit_Mode_Enabled.Value
	if Node.PreviousCFrameEditMode == CameraCFrameEditMode then
		if CameraCFrameEditMode then
			Node.CameraCFrame = NodeHandle.CFrame
		else
			Node.CFrame = NodeHandle.CFrame
		end
	else
		if CameraCFrameEditMode then
			NodeHandle.CFrame = Node.CameraCFrame
		else
			NodeHandle.CFrame = Node.CFrame
		end
		Node.PreviousCFrameEditMode = CameraCFrameEditMode
	end
	Node.CameraCFrame = CFrame.fromMatrix(
		Node.CFrame.Position,
		Node.CameraCFrame.XVector,
		Node.CameraCFrame.YVector,
		Node.CameraCFrame.ZVector
	)
	if CameraCFrameEditMode then
		NodeHandle.CFrame = Node.CameraCFrame
	end
end

function Handler:AddNode(Index,Data)
	Data.NodeMenu = WidgetLibrary.CollapsibleTitledSection.new{
		Suffix = "CutsceneNode",
		LabelText = "Node " .. Index,
		AutoScalingEnabled = true,
		Minimizable = true,
		Minimized = true,
		TitleBarInset = 20,
		ChildInset = 20,
		Renamable = false
	}
	
	Data.NodeMenu:GetSectionFrame().Visible = self.Active
	Data.NodeMenu:GetSectionFrame().LayoutOrder = Index
	Data.NodeMenu:GetSectionFrame().Parent = self.PluginHandler.CutsceneNodeListFrame:GetFrame()
	
	local NodeTypeDropdown = WidgetLibrary.LabeledDropdownMenu.new{
		Suffix = "NodeTypeMenu",
		LabelText = "Node Movement Type",
		ButtonInset = 30,
		SelectionTable = {
			{
				"Linear",
				CineSceneEnums.NodeType.Linear,
				CineSceneEnums.NodeType.Linear
			},
			{
				"Spline",
				CineSceneEnums.NodeType.Spline,
				CineSceneEnums.NodeType.Spline
			}
		}
	}
	
	NodeTypeDropdown:GetSectionFrame().LayoutOrder = 1
	NodeTypeDropdown:GetSectionFrame().Parent = Data.NodeMenu:GetContentsFrame()
	Data.MovementDropdown = NodeTypeDropdown
	NodeTypeDropdown:SetChoice(Data.NodeType)
	
	
	local MovementEnabledCheckbox = WidgetLibrary.LabeledCheckbox.new{
		Suffix = "NodeTypeEnabled",
		LabelText = "Movement Type Enabled",
		InitialValue = Data.IsMovementNode,
		Disabled = false,
		ButtonInset = 40
	}
	
	MovementEnabledCheckbox:GetFrame().LayoutOrder = 2
	MovementEnabledCheckbox:GetFrame().Parent = Data.NodeMenu:GetContentsFrame()
	Data.MovementCheckbox = MovementEnabledCheckbox
	
	local CameraTypeDropdown = WidgetLibrary.LabeledDropdownMenu.new{
		Suffix = "CameraTypeMenu",
		LabelText = "Node Camera Type",
		ButtonInset = 30,
		SelectionTable = {
			{
				"LookForward",
				CineSceneEnums.CameraType.LookForward,
				CineSceneEnums.CameraType.LookForward
			},
			{
				"FollowSubject",
				CineSceneEnums.CameraType.FollowSubject,
				CineSceneEnums.CameraType.FollowSubject
			},
			{
				"Static",
				CineSceneEnums.CameraType.Static,
				CineSceneEnums.CameraType.Static
			},
			{
				"AngularPhysics",
				CineSceneEnums.CameraType.AngularPhysics,
				CineSceneEnums.CameraType.AngularPhysics
			}
		}
	}
	
	CameraTypeDropdown:GetSectionFrame().LayoutOrder = 3
	CameraTypeDropdown:GetSectionFrame().Parent = Data.NodeMenu:GetContentsFrame()
	Data.CameraDropdown = CameraTypeDropdown
	CameraTypeDropdown:SetChoice(Data.CameraType)
	
	local CameraTypeEnabledCheckbox = WidgetLibrary.LabeledCheckbox.new{
		Suffix = "CameraTypeEnabled",
		LabelText = "Camera Type Enabled",
		InitialValue = Data.IsCameraNode,
		Disabled = false,
		ButtonInset = 35
	}
	
	CameraTypeEnabledCheckbox:GetFrame().LayoutOrder = 4
	CameraTypeEnabledCheckbox:GetFrame().Parent = Data.NodeMenu:GetContentsFrame()
	Data.CameraCheckbox = CameraTypeEnabledCheckbox

	local NodeVectorStrength = WidgetLibrary.LabeledSlider.new{
		Suffix = "NodeVectorStrength",
		LabelText = "LookVector Bias",
		StepCount = 100,
		InitialValue = Data.NodeVectorStrength
	}

	NodeVectorStrength:GetFrame().LayoutOrder = 5
	NodeVectorStrength:GetFrame().Parent = Data.NodeMenu:GetContentsFrame()
	Data.NodeVectorStrengthSlider = NodeVectorStrength

	local NodeTangentLength = WidgetLibrary.LabeledTextInput.new{
		Suffix = "NodeTangentLength",
		LabelText = "Tangent Distance",
		InitialValue = Data.NodeTangentLength
	}

	NodeTangentLength:GetFrame().LayoutOrder = 6
	NodeTangentLength:GetFrame().Parent = Data.NodeMenu:GetContentsFrame()
	Data.NodeTangentLengthSlider = NodeTangentLength

	local CameraSpeed = WidgetLibrary.LabeledTextInput.new{
		Suffix = "CameraSpeed",
		LabelText = "Camera Speed",
		InitialValue = Data.CameraSpeed
	}

	CameraSpeed:GetFrame().LayoutOrder = 7
	CameraSpeed:GetFrame().Parent = Data.NodeMenu:GetContentsFrame()
	Data.CameraSpeedInput = CameraSpeed


	local SpeedTransitionTimeIn = WidgetLibrary.LabeledTextInput.new{
		Suffix = "CameraSpeedTransitionTimeIn",
		LabelText = "Speed Transition Time In",
		TextBoxInset = 35,
		InitialValue = Data.CameraSpeedTransitionTimeIn
	}

	SpeedTransitionTimeIn:GetFrame().LayoutOrder = 8
	SpeedTransitionTimeIn:GetFrame().Parent = Data.NodeMenu:GetContentsFrame()

	local SpeedTransitionTimeOut = WidgetLibrary.LabeledTextInput.new{
		Suffix = "CameraSpeedTransitionTimeOut",
		LabelText = "Speed Transition Time Out",
		TextBoxInset = 35,
		InitialValue = Data.CameraSpeedTransitionTimeIn
	}

	SpeedTransitionTimeOut:GetFrame().LayoutOrder = 9
	SpeedTransitionTimeOut:GetFrame().Parent = Data.NodeMenu:GetContentsFrame()

	local TopButtonsFrame = Instance.new("Frame")
	TopButtonsFrame.Name = "Node_TopButtonsFrame"
	TopButtonsFrame.Size = UDim2.new(1,0,0,30)
	TopButtonsFrame.Position = UDim2.fromOffset(-20,0)
	TopButtonsFrame.LayoutOrder = 0
	TopButtonsFrame.BackgroundTransparency = 1
	TopButtonsFrame.Parent = Data.NodeMenu:GetContentsFrame()

	local InsertNodeAfter = WidgetLibrary.CustomTextButton.new{
		ButtonName = "InsertNodeAfter",
		LabelText = "Duplicate Node"
	}

	InsertNodeAfter:GetButton().Size = UDim2.fromScale(0.5,1)
	InsertNodeAfter:GetButton().Parent = TopButtonsFrame

	local DeleteNode = WidgetLibrary.CustomTextButton.new{
		ButtonName = "DeleteNode",
		LabelText = "Remove Node"
	}

	DeleteNode:GetButton().Size = UDim2.fromScale(0.5,1)
	DeleteNode:GetButton().Position = UDim2.fromScale(0.5,0)
	DeleteNode:GetButton().Parent = TopButtonsFrame

	local Node = NodeClass.new(Data)
	
	NodeTypeDropdown:SetSelectionChangedFunction(function(newSelection,InternalTrigger)
		if InternalTrigger then return end
		Node:SetNodeType(newSelection)
	end)
	CameraTypeDropdown:SetSelectionChangedFunction(function(newSelection,InternalTrigger)
		if InternalTrigger then return end
		Node:SetCameraType(newSelection)
	end)
	MovementEnabledCheckbox:SetValueChangedFunction(function(newValue)
		local MovementCount = 0
		for i,v in pairs(self.Nodes) do
			if v.IsMovementNode then
				MovementCount += 1
			end
		end
		if MovementCount > 1 then
			Node:SetIsMovementNode(newValue)
		end
	end)
	
	CameraTypeEnabledCheckbox:SetValueChangedFunction(function(newValue)
		Node:SetIsCameraNode(newValue)
	end)
	NodeVectorStrength:SetValueChangedFunction(function(newValue)
		Node:SetVectorStrength(newValue)
	end)

	local NodeTangentLengthPreviousValue = Data.NodeTangentLength
	NodeTangentLength:SetFocusLostFunction(function(newValue)
		if not tonumber(newValue) then CameraSpeed:SetValue(NodeTangentLengthPreviousValue) return end
		Node:SetTangentLength(tonumber(newValue))
		NodeTangentLengthPreviousValue = tonumber(newValue)
	end)

	local CameraSpeedPreviousValue = Data.CameraSpeed
	CameraSpeed:SetFocusLostFunction(function(newValue)
		if not tonumber(newValue) then CameraSpeed:SetValue(CameraSpeedPreviousValue) return end
		Node:SetCameraSpeed(tonumber(newValue))
		CameraSpeedPreviousValue = tonumber(newValue)
	end)

	local PreviousSpeedTransitionTimeIn = Data.CameraSpeedTransitionTimeIn
	SpeedTransitionTimeIn:SetFocusLostFunction(function(newValue)
		if not tonumber(newValue) then SpeedTransitionTimeIn:SetValue(PreviousSpeedTransitionTimeIn) return end
		Node:SetCameraSpeedTransitionTimeIn(tonumber(newValue))
		PreviousSpeedTransitionTimeIn = tonumber(newValue)
	end)

	local PreviousSpeedTransitionTimeOut = Data.CameraSpeedTransitionTimeIn
	SpeedTransitionTimeOut:SetFocusLostFunction(function(newValue)
		if not tonumber(newValue) then SpeedTransitionTimeOut:SetValue(PreviousSpeedTransitionTimeOut) return end
		Node:SetCameraSpeedTransitionTimeOut(tonumber(newValue))
		PreviousSpeedTransitionTimeOut = tonumber(newValue)
	end)

	InsertNodeAfter:GetButton().Activated:Connect(function()
		local NodeInd = table.find(self.Nodes,Node)
		self:AddNode(NodeInd,Node)
	end)

	Node:SetVectorStrength((Data.NodeTangentLength-1)/99)
	
	local NodeHandle = Instance.new("Part")
	table.insert(self.NodeHandles,Index,NodeHandle)
	NodeHandle.Size = Vector3.new(1,1,1)
	NodeHandle.Color = Color3.new(1,1,1)
	NodeHandle.Anchored = true
	NodeHandle.Material = Enum.Material.SmoothPlastic
	NodeHandle.Transparency = self.Active and 0 or 1
	NodeHandle.Locked = not self.Active
	NodeHandle.CFrame = Node.CFrame
	NodeHandle.Parent = workspace
	
	table.insert(self.Nodes,Index,Node)
	
	for i = Index+1,#self.Nodes do
		self.Nodes[i].NodeMenu:SetTitle("Node " .. i)
	end

	if Node.IsMovementNode then
		Node.PointInd = -1
	else
		self:RealignCameraNode(Index)
	end
	
	return Node
end

function Handler:RealignCameraNode(Ind)

	local NodeHandle = self.NodeHandles[Ind]
	local Node = self.Nodes[Ind]

	local MoveNodes = {}
	local LowestMoveNode,HighestMoveNode = 0,math.huge
	for i = 1,#self.Nodes do
		if self.Nodes[i].IsMovementNode then
			MoveNodes[#MoveNodes + 1] = i
			if i < Ind and i > LowestMoveNode then
				LowestMoveNode = #MoveNodes
			elseif i > Ind and i < HighestMoveNode then
				HighestMoveNode = #MoveNodes
			end
		end
	end
	local MoveNodesListSize = #MoveNodes

	local N2Ind = LowestMoveNode % MoveNodesListSize + 1
	local N0Ind = (LowestMoveNode - 2) % MoveNodesListSize + 1
	local N3Ind = N2Ind % MoveNodesListSize + 1
	local N0,N1,N2,N3 = self.Nodes[MoveNodes[N0Ind]],self.Nodes[MoveNodes[LowestMoveNode]],self.Nodes[MoveNodes[N2Ind]],self.Nodes[MoveNodes[N3Ind]]
	local Points = self:SolvePathSection(N0,N1,N2,N3,self.PluginHandler.Settings.Cutscene_Step.Value)
	local ClosestPoint,Dist,Index = nil,math.huge,nil
	for PointInd = 2,#Points do
		local v = Points[PointInd]
		local Distance = (v - NodeHandle.Position).Magnitude
		if Distance < Dist then
			Dist = Distance
			ClosestPoint = v
			Index = PointInd
		end
	end
	NodeHandle.Position = ClosestPoint
	Node.PointInd = Index
	self:SetNodeCFrame(Node,NodeHandle)
end

function Handler:RemoveNode(Index)
	table.remove(self.NodeHandles,Index):Destroy()
	local Node = table.remove(self.Nodes,Index)
	Node:GetSectionFrame():Destroy()
	for i = Index,#self.Nodes do
		self.Nodes[i]:SetTitle("Node " .. i)
	end
	return Node
end

function Handler:SetActive(Active)
	if self.Active ~= Active then
		self.Active = Active
		for i,v in pairs(self.NodeHandles) do
			v.Transparency = self.Active and 0 or 1
			v.Locked = not self.Active
		end
		for i,v in pairs(self.Nodes) do
			v.NodeMenu:GetSectionFrame().Visible = self.Active
		end
		if self.ActiveCheckbox:GetValue() ~= self.Active then
			self.ActiveCheckbox:SetValue(self.Active)
		end
		if self.Active then
			self.NodeHandleSelectionConnection = Selection.SelectionChanged:Connect(function()
				if #Selection:Get() == 1 then
					local SelectedHandle = Selection:Get()[1]
					local NodeIndex = table.find(self.NodeHandles,SelectedHandle)
					if not NodeIndex then return end
					local Node = self.Nodes[NodeIndex]
					local NodeMenu = Node.NodeMenu:GetSectionFrame()
					local ScrollingFrame = NodeMenu.Parent.Parent
					local ScrollDistance = ScrollingFrame.CanvasSize.Y.Offset - ScrollingFrame.AbsoluteSize.Y
					local ScrollAmount = math.min(NodeMenu.AbsolutePosition.Y - NodeMenu.Parent.AbsolutePosition.Y,ScrollDistance)
					ScrollingFrame.CanvasPosition = Vector2.new(0,ScrollAmount)
				end
			end)
		else
			if self.NodeHandleSelectionConnection then
				self.NodeHandleSelectionConnection:Disconnect()
			end
			local Selections = Selection:Get()
			local NewSelection = {}
			for i,v in pairs(Selections) do
				if not table.find(self.NodeHandles,v) then
					NewSelection[#NewSelection + 1] = v
				end
			end
			Selection:Set(NewSelection)
		end
	end
end

function Handler:SetLooped(Looped)
	self.Looped = Looped
end

function Handler:SetDrawEnds(DrawEnds)
	self.DrawEnds = DrawEnds
end

function Handler:SetVisualized(Visualized)
	self.Visualized = Visualized
end

function Handler:SolvePathSection(N0,N1,N2,N3,StepCount)
	local P0,P1,P2,P3 = N0 and N0.CFrame.Position,N1.CFrame.Position,N2.CFrame.Position,N3 and N3.CFrame.Position
	
	local PathPoints = {}
	
	if N1.NodeType == CineSceneEnums.NodeType.Linear then
		local Direction,Distance = (P2 - P1).Unit,(P2 - P1).Magnitude
		local Step = Distance / StepCount
		local StepVector = Direction * Step
		if N2.NodeType == CineSceneEnums.NodeType.Linear then
			for i = 0,StepCount-1 do
				PathPoints[i+1] = P1 + StepVector * i
			end
		else
			local HalfStepCount = math.floor(StepCount/2)
			for i = 0,HalfStepCount do
				PathPoints[i+1] = P1 + StepVector * i
			end
			local SP0,SP1,SP2 = N1,{
				CFrame = CFrame.lookAt((P1 + P2)/2,P2),
				NodeTangentLength = 1,
				NodeVectorStrength = 0
			},N2
			local SP3
			if N3.NodeType == CineSceneEnums.NodeType.Linear then
				SP3 = {
					CFrame = CFrame.lookAt((P2 + P3)/2,P3),
					NodeTangentLength = 1,
					NodeVectorStrength = 0
				}
			else
				SP3 = N3
			end
			local SplineHalfStepCount = StepCount - HalfStepCount
			for i = 1,SplineHalfStepCount do
				PathPoints[i + HalfStepCount] = self:SolveSplinePoint(SP0,SP1,SP2,SP3,(i-1)/SplineHalfStepCount)
			end
		end
	else
		if N2.NodeType == CineSceneEnums.NodeType.Linear then
			
			local SplineHalfStepCount = math.floor(StepCount/2)
			local SP1,SP2,SP3 = N1,{
				CFrame = CFrame.lookAt((P1 + P2)/2,P2),
				NodeTangentLength = 1,
				NodeVectorStrength = 0
			},N2
			local SP0
			if N0.NodeType == CineSceneEnums.NodeType.Linear then
				SP0 = {
					CFrame = CFrame.lookAt((P0 + P1)/2,P1),
					NodeTangentLength = 1,
					NodeVectorStrength = 0
				}
			else
				SP0 = N0
			end
			for i = 0,SplineHalfStepCount do
				PathPoints[i+1] = self:SolveSplinePoint(SP0,SP1,SP2,SP3,i/SplineHalfStepCount)
			end
			
			local Direction,Distance = (P2 - P1).Unit,(P2 - P1).Magnitude
			local Step = Distance / StepCount
			local StepVector = Direction * Step
			
			local HalfStepCount = StepCount - SplineHalfStepCount
			for i = 1,HalfStepCount do
				PathPoints[i + SplineHalfStepCount] = SP2.CFrame.Position + StepVector * (i-1)
			end
		else
			local SP0,SP3
			local SP1,SP2 = N1,N2
			if N0.NodeType == CineSceneEnums.NodeType.Linear then
				SP0 = {
					CFrame = CFrame.lookAt((P0 + P1)/2,P1),
					NodeTangentLength = 1,
					NodeVectorStrength = 0
				}
			else
				SP0 = N0
			end
			
			if N3.NodeType == CineSceneEnums.NodeType.Linear then
				SP3 = {
					CFrame = CFrame.lookAt((P2 + P3)/2,P3),
					NodeTangentLength = 1,
					NodeVectorStrength = 0
				}
			else
				SP3 = N3
			end
			for i = 0,StepCount-1 do
				PathPoints[i+1] = self:SolveSplinePoint(SP0,SP1,SP2,SP3,i/StepCount)
			end
		end
	end
	
	return PathPoints
end

function Handler:SolveFullPath(StepCount)
	local NodeListSize = #self.Nodes
	if NodeListSize < (self.DrawEnds and 2 or 4) then return {} end
	local MoveNodes = {}
	if not self.Looped then
		if not self.Nodes[1].IsMovementNode then
			self.Nodes[1]:SetIsMovementNode(true)
		end
		if not self.Nodes[NodeListSize].IsMovementNode then
			self.Nodes[NodeListSize]:SetIsMovementNode(true) 
		end
		if not self.DrawEnds then
			if not self.Nodes[2].IsMovementNode then
				self.Nodes[2]:SetIsMovementNode(true)
			end
			if not self.Nodes[NodeListSize - 1].IsMovementNode then
				self.Nodes[NodeListSize - 1]:SetIsMovementNode(true)
			end
		end
	end

	for i = 1,NodeListSize do
		if self.Nodes[i].IsMovementNode then
			MoveNodes[#MoveNodes + 1] = i
		end
	end
	local MoveNodesListSize = #MoveNodes

	local Path = {}
	local PathInd = 1

	for MoveNodeListIndex,NodeInd in ipairs(MoveNodes) do
		if not self.DrawEnds then
			MoveNodeListIndex += 1
		end
		local Node = self.Nodes[NodeInd]
		local N2Ind = MoveNodeListIndex % MoveNodesListSize + 1
		local N0Ind = (MoveNodeListIndex - 2) % MoveNodesListSize + 1
		local N3Ind = N2Ind % MoveNodesListSize + 1
		local N0,N1,N2,N3 = self.Nodes[MoveNodes[N0Ind]],Node,self.Nodes[MoveNodes[N2Ind]],self.Nodes[MoveNodes[N3Ind]]
		local PathSection = self:SolvePathSection(N0,N1,N2,N3,StepCount)
		for Ind,Point in ipairs(PathSection) do
			Path[PathInd] = Point
			PathInd += 1
		end
		if (self.Looped and MoveNodeListIndex == MoveNodesListSize) or (not self.Looped and MoveNodeListIndex == MoveNodesListSize - 1) then
			Path[PathInd] = self.Nodes[MoveNodes[N2Ind]].CFrame.Position
			break
		end
	end

	return Path
end

function Handler:SolveFullCutscene(StepCount)
	local NodeListSize = #self.Nodes
	if NodeListSize < (self.DrawEnds and 2 or 4) then return {} end
	local MoveNodes = {}
	local CameraNodes = {}

	if not self.Looped then
		if not self.Nodes[1].IsMovementNode then
			self.Nodes[1]:SetIsMovementNode(true)
		end
		if not self.Nodes[NodeListSize].IsMovementNode then
			self.Nodes[NodeListSize]:SetIsMovementNode(true) 
		end
		if not self.DrawEnds then
			if not self.Nodes[2].IsMovementNode then
				self.Nodes[2]:SetIsMovementNode(true)
			end
			if not self.Nodes[NodeListSize - 1].IsMovementNode then
				self.Nodes[NodeListSize - 1]:SetIsMovementNode(true)
			end
		end
	end

	local MoveNodeCount = 0
	for i = 1,NodeListSize do
		if self.Nodes[i].IsMovementNode then
			MoveNodes[#MoveNodes + 1] = i
			MoveNodeCount += 1
		end
		if self.DrawEnds then
			if self.Nodes[i].IsCameraNode then
				CameraNodes[1 + (MoveNodeCount-1)*StepCount + math.max(self.Nodes[i].PointInd,0)] = self.Nodes[i]
			end
		elseif i > 1 and i < NodeListSize then
			if self.Nodes[i].IsCameraNode then
				CameraNodes[1 + (MoveNodeCount-2)*StepCount + math.max(self.Nodes[i].PointInd,0)] = self.Nodes[i]
			end
		end
	end
	if self.Looped then
		CameraNodes[1 + MoveNodeCount * StepCount] = self.Nodes[1]
	end
	local MoveNodesListSize = #MoveNodes

	local Path = {}
	local PathInd = 1

	for MoveNodeListIndex,NodeInd in ipairs(MoveNodes) do
		if not self.DrawEnds then
			MoveNodeListIndex += 1
		end
		local Node = self.Nodes[NodeInd]
		local N2Ind = MoveNodeListIndex % MoveNodesListSize + 1
		local N0Ind = (MoveNodeListIndex - 2) % MoveNodesListSize + 1
		local N3Ind = N2Ind % MoveNodesListSize + 1
		local N0,N1,N2,N3 = self.Nodes[MoveNodes[N0Ind]],Node,self.Nodes[MoveNodes[N2Ind]],self.Nodes[MoveNodes[N3Ind]]
		local PathSection = self:SolvePathSection(N0,N1,N2,N3,StepCount)
		for Ind,Point in ipairs(PathSection) do
			Path[PathInd] = Point
			PathInd += 1
		end
		if (self.Looped and MoveNodeListIndex == MoveNodesListSize) or (not self.Looped and MoveNodeListIndex == MoveNodesListSize - 1) then
			Path[PathInd] = self.Nodes[MoveNodes[N2Ind]].CFrame.Position
			break
		end
	end

	return Path,CameraNodes
end

local function CalculateT(P0,P1,T0,Alpha)
	local Pi = P1-P0
	return T0 + (Pi.X^2 + Pi.Y^2 + Pi.Z^2)^(Alpha/2)
end

function Handler:SolveSplinePoint(N0,N1,N2,N3,t)
	local CF0,CF1,CF2,CF3 = N0.CFrame,N1.CFrame,N2.CFrame,N3.CFrame
	local P0,P1,P2,P3 = CF0.Position,CF1.Position,CF2.Position,CF3.Position
	local t0 = 0
	local t1 = CalculateT(P0,P1,t0,0.5)
	local t2 = CalculateT(P1,P2,t1,0.5)
	local t3 = CalculateT(P2,P3,t2,0.5)
	local M1,M2 = (P2-P0)/(t2)*5*N1.NodeTangentLength,(P3-P1)/(t3-t1)*5*N2.NodeTangentLength
	M1 = (1-N1.NodeVectorStrength)*M1 + N1.NodeVectorStrength*(CF1.ZVector*M1.Magnitude)
	M2 = (1-N2.NodeVectorStrength)*M2 + N2.NodeVectorStrength*(CF2.ZVector*M2.Magnitude)

	-- return (2*t^3 - 3*t^2 + 1) * P1 + (t^3 - 2*t^2 + t) * M1
	-- 		+
	-- 		(-2*t^3 + 3*t^2) * P2 + (t^3 - t^2) * M2
			
	return P1 + t * (
		M1 
		+ 
		t * (
			3*(P2-P1) - (2*M1+M2) 
			+ 
			t * (
				2 * (P1-P2) + M1 + M2
			)
		)
	)
end

return Handler