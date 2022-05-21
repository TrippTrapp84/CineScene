local PluginHandler = _G.CineScenePluginHandler

local function StringifyVector3(Vector3 : Vector3)
    local Source = "Vector3.new(" ..
    Vector3.X .. "," ..
    Vector3.Y .. "," ..
    Vector3.Z .. ")"
    return Source
end

local function StringifyCFrame(CFrame : CFrame)
    local Source = "CFrame.fromMatrix(" ..
    StringifyVector3(CFrame.Position) .. "," ..
    StringifyVector3(CFrame.XVector) .. "," ..
    StringifyVector3(CFrame.YVector) .. "," ..
    StringifyVector3(CFrame.ZVector) .. ")"
    return Source
end

local function StringifyInstance(Instance : Instance)
    local Source = ""
    while Instance ~= game do
        Source = "\v" .. Instance.Name .. Source
        Instance = Instance.Parent
    end
    Source = "game" .. Source
    return Source
end


local function StringifyBool(bool : boolean)
    return bool and "true" or "false"
end

local Handler = {}

Handler.CutsceneViewFunction = ""

function Handler:MakeCutsceneDataModule(Cutscene)
    local Module = Instance.new("ModuleScript")
end

function Handler:SaveCutscene(Cutscene)
    local Module = Instance.new("ModuleScript")
    Module.Name = Cutscene.Name
    local CutsceneData = self:GenerateCutsceneSaveTable(Cutscene)
    Module.Source = "local CutsceneData = " .. CutsceneData ..
    "\nreturn CutsceneData"
    if PluginHandler.Settings.Cutscene_Data:FindFirstChild(Cutscene.Name) then
        PluginHandler.Settings.Cutscene_Data:FindFirstChild(Cutscene.Name):Destroy()
    end
    Module.Parent = PluginHandler.Settings.Cutscene_Data
end

function Handler:LoadCutscene(Module)
    local ModuleTable = require(Module)
    for i,v in pairs(ModuleTable.Nodes) do
        if typeof(v.CameraSubject) == "string" then
            local Names = v.CameraSubject:split("\v")
            table.remove(Names,1)
            local instance = game
            for _,ParentName in ipairs(Names) do
                if instance:FindFirstChild(ParentName) then
                    instance = instance:FindFirstChild(ParentName)
                else
                    instance = nil
                    break
                end
            end
            v.CameraSubject = instance
        end
    end
    return ModuleTable
end

--[[ CUTSCENE CONSTRUCTOR
    local function DefaultValues()
        return {
            Nodes = {},
            Active = false,
            Looped = false,
            Visualized = false,
            DrawEnds = false,
            ID = NULL,
            CutsceneMenu = NULL,
            ActiveCheckbox = NULL,
            Name = NULL
        }
    end
]]

function Handler:GenerateCutsceneSaveTable(Cutscene)
    local Source = "{" ..
    "Nodes = {"
    for i,v in pairs(Cutscene.Nodes) do
        Source ..= self:GenerateCutsceneNodeSaveTable(v) .. ","
    end
    Source ..= ("}," ..
    "Active = " .. StringifyBool(Cutscene.Active) .. "," ..
    "Looped = " .. StringifyBool(Cutscene.Looped) .. "," ..
    "Visualized = " .. StringifyBool(Cutscene.Visualized) .. "," ..
    "DrawEnds = " .. StringifyBool(Cutscene.DrawEnds) .. "," ..
    "ID = " .. Cutscene.ID .. "," ..
    "Name = ")
    print(Cutscene.Name)
    Source ..= ("\"" .. Cutscene.Name .. "\"}")
    return Source
end

--[[ CUTSCENE NODE CONSTRUCTOR
    local function DefaultValues()
        return {
            NodeType = CineSceneEnums.NodeType.Linear,
            CameraType = CineSceneEnums.CameraType.LookForward,
            CFrame = CFrame.new(),
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
            NodeVectorStrength = 0,
            NodeTangentLength = 1,
            NodeMenu = NULL,
            CameraDropdown = NULL,
            MovementDropdown = NULL,
            CameraCheckbox = NULL,
            MovementCheckbox = NULL,
            NodeVectorStrengthSlider = NULL,
            NodeTangentLengthSlider = NULL
        }
    end
]]

function Handler:GenerateCutsceneNodeSaveTable(Node)
    local Source = "{" ..
    "NodeType = " .. Node.NodeType .. "," ..
    "CameraType = " .. Node.CameraType .. "," ..
    "CFrame = " .. StringifyCFrame(Node.CFrame) .. "," ..
    "CameraCFrame = " .. StringifyCFrame(Node.CameraCFrame) .. "," ..
    "CameraTransitionTimeIn = " .. Node.CameraTransitionTimeIn .. "," ..
    "CameraTransitionTimeOut = " .. Node.CameraTransitionTimeOut .. "," ..
    "CameraSpeed = " .. Node.CameraSpeed .. "," ..
    "CameraSubject = "
    if typeof(Node.CameraSubject) == "table" then
        Source ..= "{ CFrame = " .. StringifyCFrame(Node.CameraSubject.CFrame) .. "},"
    else
        Source ..= StringifyInstance(Node.CameraSubject) .. ","
    end
    Source = Source ..
    "CameraAcceleration = " .. StringifyVector3(Node.CameraAcceleration) .. "," ..
    "CameraImpulse = " .. StringifyVector3(Node.CameraImpulse) .. "," ..
    "CameraSpeedTransitionTimeIn = " .. Node.CameraSpeedTransitionTimeIn .. "," ..
    "CameraSpeedTransitionTimeOut = " .. Node.CameraSpeedTransitionTimeOut .. "," ..
    "IsMovementNode = " .. StringifyBool(Node.IsMovementNode) .. "," ..
    "IsCameraNode = " .. StringifyBool(Node.IsCameraNode) .. "," ..
    "NodeVectorStrength = " .. Node.NodeVectorStrength .. "," ..
    "NodeTangentLength = " .. Node.NodeTangentLength ..
    "}"
    return Source
end

return Handler