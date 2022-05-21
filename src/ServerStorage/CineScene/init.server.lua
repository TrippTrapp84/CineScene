--// SERVICES

--// REQUIRES
local PluginHandler = require(script.PluginHandler)

--// SETUP
local Toolbar = plugin:CreateToolbar("CineScene Cutscene Editor")
local OpenButton = Toolbar:CreateButton("Editor","Open the CineScene editor","")

OpenButton.Click:Connect(function()
	PluginHandler:Toggle()
end)

PluginHandler:Init(plugin,Toolbar,OpenButton)