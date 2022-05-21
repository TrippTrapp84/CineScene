--// SERVICES
local Geometry = game:GetService("Geometry")
local RepStore = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")

--// CONSTANTS

--// VARIABLES
local plugin = nil
local WidgetLibrary = script.Parent.StudioWidgets.Require
local CutsceneClass,Visualizer,CutsceneDataBuilder
local CineSceneEnums = require(script.CineSceneEnums)

--// HANDLER
local SettingsInitType : Folder
local Handler = {
	Active = false,
	Settings = SettingsInitType
	
}
_G.CineScenePluginHandler = Handler

--// FUNCTIONS
function Handler:Toggle()
	self.Active = not self.Active
	self.Widget:SetEnabled(self.Active)
	self.PluginActivateButton:SetActive(self.Active)
end

function Handler:ToggleSettings()
	self.SettingsWidget:SetEnabled()
end

function Handler:CleanupPlugin()

end

function Handler:SavePlugin()
	local Cutscene
	for i,v in pairs(self.Cutscenes) do
		Cutscene = v
		break
	end
	if not Cutscene then return end
	print(CutsceneDataBuilder:GenerateCutsceneSaveTable(Cutscene))
end

function Handler:AddCutscene(CutsceneData)
	CutsceneData = CutsceneData or {}
	local CutsceneID = self.Settings.Cutscene_Counter.Value
	
	local VisualizeButton = WidgetLibrary.LabeledCheckbox.new{
		Suffix = "CutsceneVisualized",
		LabelText = "Visualize",
		InitialValue = CutsceneData.Visualized,
		Disabled = false
	}
	
	local ActiveButton = WidgetLibrary.LabeledCheckbox.new{
		Suffix = "CutsceneActivated",
		LabelText = "Active",
		InitialValue = CutsceneData.Active,
		Disabled = false
	}

	local LoopedButton = WidgetLibrary.LabeledCheckbox.new{
		Suffix = "CutsceneLooped",
		LabelText = "Closed Loop",
		InitialValue = CutsceneData.Looped,
		Disabled = false
	}

	local DrawEndsButton = WidgetLibrary.LabeledCheckbox.new{
		Suffix = "CutsceneDrawEnds",
		LabelText = "Draw Ends",
		InitialValue = CutsceneData.DrawEnds,
		Disabled = false
	}

	local TopButtonsFrame = Instance.new("Frame")
	
	local AddNode = WidgetLibrary.CustomTextButton.new{
		ButtonName = "CutsceneAddNode",
		LabelText = "Add Path Node"
	}

	local PreviewCutscene = WidgetLibrary.CustomTextButton.new{
		ButtonName = "CutscenePreviewCutscene",
		LabelText = "Preview Cutscene"

	}

	local SaveCutscene = WidgetLibrary.CustomTextButton.new{
		ButtonName = "CutsceneSave",
		LabelText = "Save"
	}
	
	local Cutscene = CutsceneClass.new{
		CutsceneMenu = WidgetLibrary.CollapsibleTitledSection.new{
			Suffix = "CineSceneCutscene_" .. CutsceneID,
			LabelText = CutsceneData.Name or ("CineScene Cutscene " .. CutsceneID),
			AutoScalingEnabled = true,
			Minimizable = true,
			Minimized = true,
			TitleBarInset = 20,
			ChildInset = 35,
			Renamable = true
		},
		ActiveCheckbox = ActiveButton,
		Active = CutsceneData.Active,
		Visualized = CutsceneData.Visualized,
		Looped = CutsceneData.Looped,
		DrawEnds = CutsceneData.DrawEnds,
		ID = CutsceneData.ID or CutsceneID,
		Name = CutsceneData.Name or ("CineScene Cutscene " .. CutsceneID),
		Nodes = CutsceneData.Nodes
	}

	TopButtonsFrame.LayoutOrder = 1
	VisualizeButton:GetFrame().LayoutOrder = 2
	ActiveButton:GetFrame().LayoutOrder = 3
	LoopedButton:GetFrame().LayoutOrder = 4
	DrawEndsButton:GetFrame().LayoutOrder = 5

	TopButtonsFrame.Name = "TopButtonsFrame"
	TopButtonsFrame.Size = UDim2.new(1,0,0,60)
	TopButtonsFrame.Position = UDim2.fromOffset(-35,0)
	TopButtonsFrame.BackgroundTransparency = 1
	
	--WidgetLibrary.GuiUtilities.MakeFrameAutoPushEnd(AddNode:GetButton(),1) --// Old way of pushing frame to end, no longer needed
	AddNode:GetButton().Size = UDim2.fromScale(0.5,0.5)
	AddNode:GetButton().Position = UDim2.fromScale(0,0)

	PreviewCutscene:GetButton().Size = UDim2.fromScale(0.5,0.5)
	PreviewCutscene:GetButton().Position = UDim2.fromScale(0.5,0)

	SaveCutscene:GetButton().Size = UDim2.fromScale(1,0.5)
	SaveCutscene:GetButton().Position = UDim2.fromScale(0,0.5)
	
	AddNode:GetButton().Activated:Connect(function()
		local NodeData = {
			NodeType = CineSceneEnums.NodeType.Linear,
			CameraType = CineSceneEnums.CameraType.LookForward,
			CFrame = CFrame.new(),
			CameraTransitionTimeIn = 1,
			CameraTransitionTimeOut = 1,
			CameraSpeedTransitionTimeIn = 1,
			CameraSpeedTransitionTimeOut = 1,
			IsMovementNode = true,
			IsCameraNode = true,
			NodeVectorStrength = 1,
			NodeTangentLength = 1,
			CameraSpeed = 1
		}
		Cutscene:AddNode(#Cutscene.Nodes + 1,NodeData)
	end)
	PreviewCutscene:GetButton().Activated:Connect(function()
		Visualizer:DisplayCutscene(Cutscene)
	end)
	VisualizeButton:SetValueChangedFunction(function(newValue)
		if newValue then
			Visualizer:AddCutscene(Cutscene)
		else
			Visualizer:RemoveCutscene(Cutscene)
		end
		Cutscene:SetVisualized(newValue)
	end)
	ActiveButton:SetValueChangedFunction(function(newValue,InternalTrigger)
		if InternalTrigger then return end
		if newValue then
			self:OpenCutscene(Cutscene)
		elseif self.CurrentCutscene == Cutscene then
			self:CloseCutscene()
		end
	end)
	LoopedButton:SetValueChangedFunction(function(newValue)
		if newValue and not Cutscene.DrawEnds then
			Cutscene:SetDrawEnds(true)
			DrawEndsButton:SetValue(true)
		end
		Cutscene:SetLooped(newValue)
	end)
	DrawEndsButton:SetValueChangedFunction(function(newValue)
		if Cutscene.Looped then
			DrawEndsButton:SetValue(true)
		else
			DrawEndsButton:SetValue(newValue)
			Cutscene:SetDrawEnds(newValue)
		end
	end)
	SaveCutscene:GetButton().Activated:Connect(function()
		CutsceneDataBuilder:SaveCutscene(Cutscene)
	end)
	
	TopButtonsFrame.Parent = Cutscene.CutsceneMenu:GetContentsFrame()
	VisualizeButton:GetFrame().Parent = Cutscene.CutsceneMenu:GetContentsFrame()
	ActiveButton:GetFrame().Parent = Cutscene.CutsceneMenu:GetContentsFrame()
	AddNode:GetButton().Parent = TopButtonsFrame
	PreviewCutscene:GetButton().Parent = TopButtonsFrame
	SaveCutscene:GetButton().Parent = TopButtonsFrame
	DrawEndsButton:GetFrame().Parent = Cutscene.CutsceneMenu:GetContentsFrame()
	LoopedButton:GetFrame().Parent = Cutscene.CutsceneMenu:GetContentsFrame()
	
	local CutsceneTitle = Cutscene.CutsceneMenu:GetTitleInput()
	
	CutsceneTitle:SetMaxGraphemes(30)
	Cutscene.CutsceneMenu:SetTitleBarColor(WidgetLibrary.GuiUtilities.FrameSelectionColor)
	CutsceneTitle._textBox.Size += UDim2.new(1.5,0)
	
	local PrevValue = CutsceneData.Name or ("CineScene Cutscene " .. CutsceneID)
	CutsceneTitle:SetFocusLostFunction(function(newValue)
		if newValue:find("CineScene Cutscene ") or newValue == "" then
			CutsceneTitle:SetValue(PrevValue)
		else
			local TempCutscene = self.Cutscenes[PrevValue]
			self.Cutscenes[PrevValue] = nil
			if self.Cutscenes[newValue] then
				self.Cutscenes[PrevValue] = TempCutscene
				CutsceneTitle:SetValue(PrevValue)
			else
				Cutscene:SetName(newValue)
				self.Cutscenes[newValue] = Cutscene
				PrevValue = newValue
			end
		end
	end)

	Cutscene.CutsceneMenu:SetTitleDoublePressedFunction(function(Minimized)
		if not Minimized then
			self:OpenCutscene(Cutscene)
		elseif Cutscene == self.CurrentCutscene then
			self:CloseCutscene()
		end
	end)
	
	if Cutscene.Visualized then
		Visualizer:AddCutscene(Cutscene)
	end
	
	self.Cutscenes[PrevValue] = Cutscene
	
	self.Settings.Cutscene_Counter.Value += 1
	
	self.CutsceneListFrame:AddChild(Cutscene.CutsceneMenu:GetSectionFrame())
end

function Handler:OpenCutscene(Cutscene)
	if Cutscene == self.CurrentCutscene then return end
	if self.CurrentCutscene then self:CloseCutscene() end
	self.CurrentCutscene = Cutscene
	self.CurrentCutscene.CutsceneMenu:SetCollapsedState(false)
	Cutscene.CutsceneMenu:SetTitleBarColorOverrides(true)
	self.CurrentCutscene:SetActive(true)
end

function Handler:CloseCutscene()
	if not self.CurrentCutscene then return end
	self.CurrentCutscene.CutsceneMenu:SetCollapsedState(true)
	self.CurrentCutscene.CutsceneMenu:SetTitleBarColorOverrides(false)
	self.CurrentCutscene:SetActive(false)
	self.CurrentCutscene = nil
	
end

function Handler:SetCutsceneDirectory(Directory)
	local PrevStorage = self.Settings.Cutscene_Storage_Location.Value
	self.Settings.Cutscene_Storage_Location.Value = Directory
	for i,v in pairs(PrevStorage:GetChildren()) do
		v.Parent = Directory
	end
	PrevStorage:Destroy()
end

--// INITIALIZATION
local Init = false
function Handler:Init(plug,Toolbar,CreateButton)
	if Init then return end
	Init = true
	self.Toolbar = Toolbar
	self.PluginActivateButton = CreateButton

	do --// SETTINGS
		local SettingsRoot : Folder
		SettingsRoot = Geometry:FindFirstChild("CineScene_Plugin_Settings_Root")
		if not SettingsRoot then
			SettingsRoot = Instance.new("Folder")
			SettingsRoot.Name = "CineScene_Plugin_Settings_Root"
			SettingsRoot.Parent = Geometry
		end
		self.Settings = SettingsRoot
		if not self.Settings:FindFirstChild("Cutscene_Storage_Location") then
			local CutsceneStorage = Instance.new("ObjectValue")
			CutsceneStorage.Name = "Cutscene_Storage_Location"
			CutsceneStorage.Parent = self.Settings
		end
		if not self.Settings:FindFirstChild("Cutscene_Data") then
			local CutsceneDataStorage = Instance.new("Folder")
			CutsceneDataStorage.Name = "Cutscene_Data"
			CutsceneDataStorage.Parent = self.Settings
		end
		if not self.Settings:FindFirstChild("Cutscene_Counter") then
			local CutsceneCounter = Instance.new("IntValue")
			CutsceneCounter.Name = "Cutscene_Counter"
			CutsceneCounter.Value = 0
			CutsceneCounter.Parent = self.Settings
		end
		if not self.Settings:FindFirstChild("Visualizer_Step") then
			local VisualizerStepCount = Instance.new("IntValue")
			VisualizerStepCount.Name = "Visualizer_Step"
			VisualizerStepCount.Value = 50
			VisualizerStepCount.Parent = self.Settings
		end
		if not self.Settings:FindFirstChild("Cutscene_Step") then
			local CutsceneStepCount = Instance.new("IntValue")
			CutsceneStepCount.Name = "Cutscene_Step"
			CutsceneStepCount.Value = 50
			CutsceneStepCount.Parent = self.Settings
		end
		if not self.Settings:FindFirstChild("Camera_CFrame_Edit_Mode_Enabled") then
			local CCFrameEModeEnabled = Instance.new("BoolValue")
			CCFrameEModeEnabled.Value = false
			CCFrameEModeEnabled.Name = "Camera_CFrame_Edit_Mode_Enabled"
			CCFrameEModeEnabled.Parent = self.Settings
		end
		if not self.Settings:FindFirstChild("Visualizer_Show_Speed") then
			local VisualizerShowSpeed = Instance.new("BoolValue")
			VisualizerShowSpeed.Value = false
			VisualizerShowSpeed.Name = "Visualizer_Show_Speed"
			VisualizerShowSpeed.Parent = self.Settings
		end
		
		if not self.Settings.Cutscene_Storage_Location.Value then
			local Directory = RepStore:FindFirstChild("CineScene_Cutscenes") or Instance.new("Folder")
			Directory.Name = "CineScene_Cutscenes"
			Directory.Parent = RepStore
			self.Settings.Cutscene_Storage_Location.Value = Directory
		end
	end
	
	plugin = plug
	self.plugin = plugin
	
	WidgetLibrary = require(WidgetLibrary)(plugin)
	
	--// REQUIRES
	CutsceneClass = require(script:FindFirstChild("CutsceneHandler"))
	CutsceneDataBuilder = require(script.CutsceneDataBuilder)
	Visualizer = require(script.Visualizer)
	
	do --// MAIN WIDGET
		self.Widget = WidgetLibrary.DockWidget.new{
			Name = "CineScene Cutscene Animator",
			WidgetInfo = DockWidgetPluginGuiInfo.new(
				Enum.InitialDockState.Float,
				false,
				false,
				450,
				800,
				225,
				400
			)
		}
		self.Widget:BindToClose(function()
			self:Toggle()
		end)
		
		local ListLayout = Instance.new("UIListLayout")
		ListLayout.FillDirection = Enum.FillDirection.Vertical
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		ListLayout.SortOrder= Enum.SortOrder.LayoutOrder
		self.Widget:AddChild(ListLayout)
	end
	
	do --// MAIN TOOLS MENU
		local MainTools = WidgetLibrary.CollapsibleTitledSection.new{
			Suffix = "MainTools",
			LabelText = "Editor Tools",
			AutoScalingEnabled = false,
			Minimizable = true,
			Minimized = false
		}
		
		self.MainTools = MainTools
		MainTools:GetSectionFrame().LayoutOrder = 2
		self.Widget:AddChild(MainTools:GetSectionFrame())
		
		local MainToolsGridLayout = Instance.new("UIGridLayout")
		MainToolsGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		MainToolsGridLayout.FillDirection = Enum.FillDirection.Horizontal
		MainToolsGridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		MainToolsGridLayout.CellSize = UDim2.fromOffset(85,85)
		
		WidgetLibrary.GuiUtilities.MakeFrameAutoScalingList(MainTools:GetContentsFrame(),MainToolsGridLayout)
	end
	
	do --// SETTINGS MENU
		local Settings = WidgetLibrary.ImageButtonWithText.new{
			Name = "Settings",
			LayoutOrder = 1,
			ButtonImage = "rbxassetid://1402032193",
			LabelText = "Settings",
			ButtonSize = UDim2.fromOffset(85,85),
			ImageSize = UDim2.fromOffset(55,55),
			ImagePosition = UDim2.fromOffset(15,7.5),
			TextSize = UDim2.fromOffset(55,15),
			TextPosition = UDim2.fromOffset(15,62.5)
		}
		
		Settings:GetButton().Parent = self.MainTools:GetContentsFrame()
		Settings:GetButton().LayoutOrder = 1
		Settings:GetButton().Activated:Connect(function()
			self:ToggleSettings()
		end)
		
		self.SettingsWidget = WidgetLibrary.DockWidget.new{
			Name = "CineScene Settings",
			WidgetInfo = DockWidgetPluginGuiInfo.new(
				Enum.InitialDockState.Float,
				false,
				false,
				450,
				800,
				225,
				400
			)
		}
		
		local FunctionalSettings = WidgetLibrary.CollapsibleTitledSection.new{
			Suffix = "PluginSettings",
			LabelText = "Plugin Settings",
			AutoScalingEnabled = true,
			Minimizable = true,
			Minimized = false
		}
		
		local RootLocation = WidgetLibrary.LabeledInstanceSelection.new{
			Suffix = "CinesceneSettings_CutsceneLocation",
			LabelText = "Set Cutscene Directory",
			ButtonInset = 40,
			ButtonWidth = 300,
			InitialValue = self.Settings.Cutscene_Storage_Location.Value
		}
		local VisualizerStepCount = WidgetLibrary.LabeledTextInput.new{
			Suffix = "VisualizerStepCount",
			LabelText = "Visualizer Detail",
			InitialValue = self.Settings.Visualizer_Step.Value
		}

		local CutsceneStepCount = WidgetLibrary.LabeledTextInput.new{
			Suffix = "CutsceneStepCount",
			LabelText = "Cutscene Detail",
			InitialValue = self.Settings.Cutscene_Step.Value
		}

		local VisualizerShowSpeed = WidgetLibrary.LabeledCheckbox.new{
			Suffix = "VisualizerShowSpeed",
			LabelText = "Visualize Speed",
			InitialValue = false,
			Disabled = false
		}
		
		local PrevDirectory = self.Settings.Cutscene_Storage_Location.Value
		RootLocation:SetSelectionChangedFunction(function(Selection,Processed)
			if Processed then return end
			if not Selection then
				RootLocation:SetSelection(PrevDirectory)
			else
				RootLocation:SetSelection(Selection)
			end
		end)
		
		local PreviousVisualizerStepValue = self.Settings.Visualizer_Step.Value
		VisualizerStepCount:SetFocusLostFunction(function(newValue)
			if not tonumber(newValue) then VisualizerStepCount:SetValue(PreviousVisualizerStepValue) return end
			self.Settings.Visualizer_Step.Value = tonumber(newValue)
			PreviousVisualizerStepValue = tonumber(newValue)
		end)
		
		local PreviousCutsceneStepValue = self.Settings.Cutscene_Step.Value
		CutsceneStepCount:SetFocusLostFunction(function(newValue)
			if not tonumber(newValue) then CutsceneStepCount:SetValue(PreviousCutsceneStepValue) return end
			self.Settings.Cutscene_Step.Value = tonumber(newValue)
			PreviousCutsceneStepValue = tonumber(newValue)
		end)

		VisualizerShowSpeed:SetValueChangedFunction(function(newValue)
			self.Settings.Visualizer_Show_Speed.Value = newValue
		end)

		self.SettingsWidget:AddChild(FunctionalSettings:GetSectionFrame())
		
		RootLocation:GetFrame().Parent = FunctionalSettings:GetContentsFrame()
		RootLocation:GetFrame().LayoutOrder = 1

		VisualizerStepCount:GetFrame().Parent = FunctionalSettings:GetContentsFrame()
		VisualizerStepCount:GetFrame().LayoutOrder = 2

		CutsceneStepCount:GetFrame().Parent = FunctionalSettings:GetContentsFrame()
		CutsceneStepCount:GetFrame().LayoutOrder = 3

		VisualizerShowSpeed:GetFrame().Parent = FunctionalSettings:GetContentsFrame()
		VisualizerShowSpeed:GetFrame().LayoutOrder = 4
	end
	
	do --// CUTSCENE ADDITION MENU
		
		local CutsceneManager = WidgetLibrary.CollapsibleTitledSection.new{
			Suffix = "CutsceneList",
			LabelText = "Cutscenes",
			AutoScalingEnabled = false,
			Minimizable = true,
			Minimized = false
		}

		CutsceneManager:GetContentsFrame().Size = UDim2.new(1,0,0,200)

		local ResizeableCutsceneList = WidgetLibrary.VerticallyResizableListFrame.new{
			Suffix = "CutsceneList_ResizableFrame",
			InitialHeight = 200,
			MinimumHeight = 100,
			MaximumHeight = 1000,
			HeightLocked = false
		}

		ResizeableCutsceneList:SetCallbackOnResize(function(newSize)
			CutsceneManager:GetContentsFrame().Size = UDim2.new(1,0,0,newSize)
		end)
		
		ResizeableCutsceneList:GetFrame().Parent = CutsceneManager:GetContentsFrame()
		
		local CutsceneList = WidgetLibrary.VerticalScrollingFrame.new{
			Suffix = "CutsceneList_ScrollingFrame"
		}
		
		CutsceneList:GetSectionFrame().Parent = ResizeableCutsceneList:GetFrame()
		
		local CutsceneListFrame = WidgetLibrary.VerticallyScalingListFrame.new{
			Suffix = "CutsceneList_ScalingFrame"
		}
		
		CutsceneListFrame:AddBottomPadding()
		CutsceneListFrame:GetFrame().Parent = CutsceneList:GetContentsFrame()
		self.CutsceneListFrame = CutsceneListFrame
		
		CutsceneManager:GetSectionFrame().LayoutOrder = 2
		self.Widget:AddChild(CutsceneManager:GetSectionFrame())
		
		
		local AddCutscene = WidgetLibrary.ImageButtonWithText.new{
			Name = 'AddCutscene',
			LayoutOrder = 2,
			ButtonImage = "rbxassetid://257579835",
			LabelText = "Add Cutscene",
			ButtonSize = UDim2.fromOffset(85,85),
			ImageSize = UDim2.fromOffset(55,55),
			ImagePosition = UDim2.fromOffset(15,7.5),
			TextSize = UDim2.fromOffset(55,15),
			TextPosition = UDim2.fromOffset(15,62.5)
		}
		
		AddCutscene:GetButton().Parent = self.MainTools:GetContentsFrame()
		AddCutscene:GetButton().Activated:Connect(function()
			self:AddCutscene()
		end)  
	end

	do --// CFRAME EDIT MODE BUTTON
		local CFrameEditModeButton = WidgetLibrary.StatefulImageButton.new{
			ButtonName = "CFrameEditMode",
			ButtonImage = "rbxassetid://145360569",
			ButtonSize = UDim2.fromOffset(85,85)
		}

		CFrameEditModeButton:GetButton().Parent = self.MainTools:GetContentsFrame()
		CFrameEditModeButton:GetButton().LayoutOrder = 3

		local IsSelected = self.Settings.Camera_CFrame_Edit_Mode_Enabled.Value
		CFrameEditModeButton:SetSelected(IsSelected)
		CFrameEditModeButton:GetButton().Activated:Connect(function()
			IsSelected = not IsSelected
			CFrameEditModeButton:SetSelected(IsSelected)
			self.Settings.Camera_CFrame_Edit_Mode_Enabled.Value = IsSelected
		end)
	end

	do --// SAVING BUTTON
		local SaveButton = WidgetLibrary.ImageButtonWithText.new{
			Name = "Save",
			LayoutOrder = 4,
			ButtonImage = "rbxassetid://1173589333",
			LabelText = "Save",
			ButtonSize = UDim2.fromOffset(85,85),
			ImageSize = UDim2.fromOffset(55,55),
			ImagePosition = UDim2.fromOffset(15,7.5),
			TextSize = UDim2.fromOffset(55,15),
			TextPosition = UDim2.fromOffset(15,62.5)
		}

		SaveButton:GetButton().Parent = self.MainTools:GetContentsFrame()
		SaveButton:GetButton().Activated:Connect(function()
			self:SavePlugin()
		end)
	end
	
	do --// CUTSCENE SETTINGS MENU
		local CutsceneNodeManager = WidgetLibrary.CollapsibleTitledSection.new{
			Suffix = "CutsceneNodes",
			LabelText = "Cutscene Nodes",
			AutoScalingEnabled = false,
			Minimizable = true,
			Minimized = false
		}

		CutsceneNodeManager:GetContentsFrame().Size = UDim2.new(1,0,0,200)
		
		local ResizeableCutsceneNodeList = WidgetLibrary.VerticallyResizableListFrame.new{
			Suffix = "CutsceneNodeList_ResizableFrame",
			InitialHeight = 200,
			MinimumHeight = 100,
			MaximumHeight = 1000,
			HeightLocked = false
		}

		ResizeableCutsceneNodeList:SetCallbackOnResize(function(newSize)
			CutsceneNodeManager:GetContentsFrame().Size = UDim2.new(1,0,0,newSize)
		end)
		
		ResizeableCutsceneNodeList:GetFrame().Parent = CutsceneNodeManager:GetContentsFrame()

		local CutsceneNodeList = WidgetLibrary.VerticalScrollingFrame.new{
			Suffix = "CutsceneNodeList_ScrollingFrame"
		}

		CutsceneNodeList:GetSectionFrame().Parent = ResizeableCutsceneNodeList:GetFrame()

		local CutsceneNodeListFrame = WidgetLibrary.VerticallyScalingListFrame.new{
			Suffix = "CutsceneNodeList_ScalingFrame"
		}

		CutsceneNodeListFrame:AddBottomPadding()
		CutsceneNodeListFrame:GetFrame().Parent = CutsceneNodeList:GetContentsFrame()
		self.CutsceneNodeListFrame = CutsceneNodeListFrame

		CutsceneNodeManager:GetSectionFrame().LayoutOrder = 2
		self.Widget:AddChild(CutsceneNodeManager:GetSectionFrame())
	end
	
	plugin.Unloading:Connect(function()
		self:CleanupPlugin()
	end)

	--// LOAD CUTSCENES
	self.Cutscenes = {}
	for i,v in pairs(self.Settings.Cutscene_Data:GetChildren()) do
		self:AddCutscene(require(v))
	end
end

--// RETURN
return Handler