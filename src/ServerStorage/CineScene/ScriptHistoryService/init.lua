local CHS = game:GetService("ChangeHistoryService")
local HTTP = game:GetService("HttpService")

local API_URL = "https://raw.githubusercontent.com/CloneTrooper1019/Roblox-Client-Tracker/roblox/API-Dump.json"

type Dictionary = { [any] : any }

local Handler = {
    IDCount = 0,
    HistoryTables = {},
    HistoryInstances = {},
    UndoSnapshots = {}
}

local ClassAPIList = {}
do --// INITIALIZE CLASS API LIST
    local APIDumpResponse = HTTP:JSONDecode(HTTP:GetAsync(API_URL)).Classes
    for i,v in pairs(APIDumpResponse) do
        if v.Tags and table.find(v.Tags,"Service") then continue end
        local API = {
            Props = {}
        }
        ClassAPIList[v.Name] = API
        for _,Member in pairs(v.Members) do
            if Member.MemberType ~= "Property" then continue end
            if Member.Tags and table.find(Member.Tags,"ReadOnly") then continue end
            API.Props[#API.Props + 1] = Member.Name
        end
        if v.Name ~= "Instance" then
            API.BaseClass = v.Superclass
        end
    end
end

function Handler:GenerateUID()
    self.IDCount += 1
    return self.IDCount
end

function Handler:GetClassProperties(Class)
    if not ClassAPIList[Class] then error(Class .. " is not a valid Roblox class name.") end
    local Properties = {}
    while Class do
        local ClassProps = ClassAPIList[Class].Props
        for i,v in pairs(ClassProps) do
            Properties[#Properties + 1] = v
        end
        Class = ClassAPIList[Class].BaseClass
    end

    return Properties
end

function Handler:TrackTable(Table : Dictionary)
    local TableTable = {
        ID = self:GenerateUID(),
        Table = Table
    }
    table.insert(self.HistoryTables,TableTable)
end

function Handler:TrackInstance(Instance : Instance)
    local Properties = self:GetClassProperties(Instance.ClassName)
    local Values = {}
    for i,v in pairs(Properties) do
        Values[v] = Instance[v]
    end
    local InstanceTable = {
        ID = self:GenerateUID(),
        Instance = Instance,
        Values = Values
    }
    table.insert(self.HistoryInstances,InstanceTable)
end
function Handler:UntrackTable(Table)
    for i,v in pairs(self.HistoryTables) do
        if v.Table == Table then
            table.remove(self.Table,i)
            break
        end
    end
end

function Handler:UntrackInstance(Instance)
    for i,v in pairs(self.HistoryInstances) do
        if v.Instance == Instance then
            table.remove(self.HistoryInstances,i)
            break
        end
    end
end

function Handler:MakeHistoryWaypoint()
    
end