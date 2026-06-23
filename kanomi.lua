local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function kickLocalPlayer()
    player:Kick("kanomi.lol is currently down!")
end

task.wait(1) 
kickLocalPlayer()
