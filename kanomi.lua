print("[Kanomi] Script Execution Started!")
-- [[ УЛЬТИМАТИВНЫЙ БАЙПАСС И SILENT AIM (LONE SURVIVAL) ]] --
if not game:IsLoaded() then 
    print("[Kanomi] Waiting for game to load...")
    game.Loaded:Wait() 
end
print("[Kanomi] Game is loaded!")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

print("[Kanomi] Waiting for LocalPlayer...")
local waitTime = 0
while not Players.LocalPlayer do 
    task.wait(0.1) 
    waitTime = waitTime + 0.1
    if waitTime > 10 then warn("[Kanomi] LocalPlayer is taking too long to load!") break end
end
local LocalPlayer = Players.LocalPlayer
print("[Kanomi] LocalPlayer found!")

print("[Kanomi] Waiting for Camera...")
while not workspace.CurrentCamera do task.wait(0.1) end
local Camera = workspace.CurrentCamera
print("[Kanomi] Camera found!")

local SilentAimCache = {
    TargetPart = nil,
    LastUpdate = 0
}

local GlobalRayParams = RaycastParams.new()
GlobalRayParams.FilterType = Enum.RaycastFilterType.Exclude
GlobalRayParams.IgnoreWater = true

local tiHeadList = {"Cloth HeadWrap","Wood Helmet","Sheet Facemask","Steel Helmet","Fast MT","Kyron's Helmet","Akria's Helmet","Basic Night Vision Goggles","Giraffe Cap","Ski mask","Helmet Of Ashes"}
local tiBodyList = {"Cloth Vest","Wood Chestplate","Hazmat","Sheet Chestplate","Steel Chestplate","MMAC RIG","Kyron's Body Armor","Akria's Chestplate","Rekia's Jacket"}
local tiLegsList = {"Wood Kilt","Sheet Kilt","Steel Kilt","Akria's Kilt"}
local tiGunsList = {"Makeshift Single Shot", "Handmade SMG", "Double Barrel Shotgun", "Bow", "Crossbow", "Revolver", "KEDR", "APC9K", "Python", "AKS-74U", "MP5", "AKM", "Rocket Launcher", "M4", "ShAK-12", "PKM", "Akira's M4", "M700", "Krimeth V", "Longsword", "Hustman Knife", "Stone Hatchet", "Stone Pickaxe", "Iron Hatchet", "Iron Pickaxe", "Packed Explosive", "Medical Zip Bag", "Bandage", "Shiv", "M870", "SVT-40", "M9A4", "Thumper", "USP", "Hammer", "Stone Spear", "Wood Spear", "AS VAL", "Lighter", "Hand Saw", "Green Keycard", "Yellow Keycard", "Red Keycard", "Construction Tool", "Prototype Pickaxe", "Prototype Hatchet", "Hand Drill", "Handmade Lever Action Rifle", "Sledgehammer", "Dynamite", "Incendiary Grenade", "Dynamite Bundle", "Rug", "Large Chest", "Safe Key", "Room #3 Key", "Room #9 Key", "??? Key", "Handmade Sniper"}

local function checkLists(childName)
    local lowerName = string.lower(childName)
    for _, v in ipairs(tiHeadList) do if string.find(lowerName, string.lower(v), 1, true) then return "head", v end end
    for _, v in ipairs(tiBodyList) do if string.find(lowerName, string.lower(v), 1, true) then return "body", v end end
    for _, v in ipairs(tiLegsList) do if string.find(lowerName, string.lower(v), 1, true) then return "legs", v end end
    for _, v in ipairs(tiGunsList) do if string.find(lowerName, string.lower(v), 1, true) then return "gun", v end end
    return nil, nil
end

-- [[ ЗАЩИЩЕННЫЙ КОНТЕЙНЕР GUI ]] --
local CoreGui = game:GetService("CoreGui")
local Kanomi_Container = Instance.new("ScreenGui")
Kanomi_Container.Name = "Kanomi_GUI_Container"
Kanomi_Container.ResetOnSpawn = false
Kanomi_Container.IgnoreGuiInset = true
Kanomi_Container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local targetGui = nil
if gethui then
    pcall(function() targetGui = gethui() end)
end
if not targetGui then targetGui = CoreGui end
if not targetGui then targetGui = Players.LocalPlayer:WaitForChild("PlayerGui") end

Kanomi_Container.Parent = targetGui

local function SafeLoad(url)
    print("[Kanomi] Attempting to load from URL:", url)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success or not result or #result < 100 then
        warn("[Kanomi] Original URL failed or returned empty. Trying proxy mirror...")
        local proxyUrl = url:gsub("raw.githubusercontent.com", "raw.kgithub.com")
        success, result = pcall(function()
            return game:HttpGet(proxyUrl)
        end)
        
        if not success or not result or #result < 100 then
            warn("[Kanomi] Proxy mirror also failed! Your ISP is blocking the connection. Please turn on a VPN.")
            return nil
        end
    end
    
    local loadFunc, err = loadstring(result)
    if not loadFunc then
        warn("[Kanomi] Failed to parse library code:", err)
        return nil
    end
    print("[Kanomi] Successfully downloaded:", url)
    local runSuccess, runResult = pcall(loadFunc)
    if not runSuccess then
        warn("[Kanomi] Execution error in library:", url, "\nError:", runResult)
        return nil
    end
    print("[Kanomi] Successfully executed:", url)
    return runResult
end

print("[Kanomi] Downloading UI Libraries...")
local Library = SafeLoad('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua') or getgenv().Library
local ThemeManager = SafeLoad('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua') or getgenv().ThemeManager
local SaveManager = SafeLoad('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua') or getgenv().SaveManager

if not Library then
    error("[Kanomi] Script halted: Library failed to load.")
end
print("[Kanomi] UI Libraries loaded! Creating window...")

local Window = Library:CreateWindow({
    Title = 'Lone Survival | Kanomi.lol',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Combat = Window:AddTab('Combat'),
    Movement = Window:AddTab('Movement'),
    Visuals = Window:AddTab('Visuals'),
    ESP = Window:AddTab('ESP'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local Toggles = getgenv().Toggles
local Options = getgenv().Options

-- [[ ФИКС МЫШКИ ДЛЯ LONE SURVIVAL ]] --
RunService.RenderStepped:Connect(function()
    if Library.Toggled then
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end)

-- [[ ВКЛАДКА COMBAT ]] --
local AimGroup = Tabs.Combat:AddLeftGroupbox('Aimbot Settings')
AimGroup:AddToggle('EnableAimbot', { Text = 'Enable Aimbot (Hold RMB)', Default = false })
AimGroup:AddToggle('WallCheck', { Text = 'Wall Check', Default = false })
AimGroup:AddToggle('AimbotIncludeAI', { Text = 'Target AI (Bots)', Default = false })
AimGroup:AddDropdown('TargetPart', { Values = { 'Head', 'HumanoidRootPart', 'UpperTorso' }, Default = 1, Multi = false, Text = 'Target Part' })
AimGroup:AddSlider('AimSmoothness', { Text = 'Smoothness', Default = 50, Min = 1, Max = 100, Rounding = 0, Compact = false })

AimGroup:AddDivider()

AimGroup:AddToggle('ShowFOV', { Text = 'Show FOV', Default = false })
AimGroup:AddSlider('FOVSize', { Text = 'FOV Radius', Default = 150, Min = 10, Max = 800, Rounding = 0, Compact = false })
AimGroup:AddLabel('FOV Color'):AddColorPicker('FOVColor', { Default = Color3.new(0, 0, 1), Title = 'FOV Color' })

local FilterGroup = Tabs.Combat:AddLeftGroupbox('Target Filtering')
FilterGroup:AddInput('WhitelistInput', {
    Default = '',
    Numeric = false,
    Finished = false,
    Text = 'Whitelist (comma separated)',
    Tooltip = 'Enter player or AI names separated by commas to ignore them.',
    Placeholder = 'Player1, Player2'
})

local SilentGroup = Tabs.Combat:AddRightGroupbox('Silent Aim Settings')
SilentGroup:AddToggle('EnableSilentAim', { Text = 'Enable Silent Aim', Default = false })
SilentGroup:AddDropdown('SilentTargetPart', { Values = { 'Head', 'HumanoidRootPart', 'Random' }, Default = 1, Multi = false, Text = 'Target Part' })
SilentGroup:AddSlider('HitChance', { Text = 'Hit Chance %', Default = 100, Min = 1, Max = 100, Rounding = 0, Compact = false })
SilentGroup:AddToggle('SilentWallCheck', { Text = 'Wall Check', Default = false })
SilentGroup:AddToggle('SilentIncludeAI', { Text = 'Target AI (Bots)', Default = false })

SilentGroup:AddDivider()

SilentGroup:AddToggle('ShowSilentFOV', { Text = 'Show Silent FOV', Default = false })
SilentGroup:AddSlider('SilentFOVSize', { Text = 'FOV Radius', Default = 150, Min = 10, Max = 800, Rounding = 0, Compact = false })
SilentGroup:AddLabel('Silent FOV Color'):AddColorPicker('SilentFOVColor', { Default = Color3.new(0, 0, 1), Title = 'Silent FOV Color' })

local GunModsGroup = Tabs.Combat:AddRightGroupbox('Gun Mods')
GunModsGroup:AddToggle('EnableNoRecoil', { Text = 'Enable No Recoil', Default = false })
GunModsGroup:AddSlider('RecoilControl', { Text = 'Recoil Control %', Default = 100, Min = 1, Max = 100, Rounding = 0, Compact = false, Tooltip = '100% = No Recoil. Lower slightly to bypass AC.' })



-- [[ ВКЛАДКА MOVEMENT ]] --
local SpeedGroup = Tabs.Movement:AddLeftGroupbox('Speed Settings')
SpeedGroup:AddToggle('EnableSpeed', { Text = 'Enable Speed', Default = false }):AddKeyPicker('SpeedBind', {
    Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'Toggle Speed', NoUI = false
})
SpeedGroup:AddDropdown('SpeedMethod', { Values = { 'CFrame', 'Velocity' }, Default = 1, Multi = false, Text = 'Speed Method' })
SpeedGroup:AddSlider('SpeedAmount', { Text = 'Speed Amount', Default = 50, Min = 16, Max = 200, Rounding = 0, Compact = false })

-- [[ ВКЛАДКА VISUALS ]] --
local WorldGroup = Tabs.Visuals:AddLeftGroupbox('World Settings')
WorldGroup:AddToggle('Fullbright', { Text = 'Fullbright', Default = false, Tooltip = 'Makes everything bright without flickering' })
WorldGroup:AddSlider('FullbrightBrightness', { Text = 'Brightness', Default = 1, Min = 0, Max = 10, Rounding = 1, Compact = false })
WorldGroup:AddSlider('FogDistance', { Text = 'Fog Distance', Default = 100000, Min = 100, Max = 100000, Rounding = 0, Compact = false })
WorldGroup:AddDivider()
WorldGroup:AddToggle('CustomAtmosphere', { Text = 'Custom Atmosphere', Default = false })
WorldGroup:AddLabel('Atmosphere Color'):AddColorPicker('AtmosphereColor', { Default = Color3.new(0.5, 0, 1), Title = 'Atmosphere Color' })

local CameraGroup = Tabs.Visuals:AddRightGroupbox('Camera Settings')
CameraGroup:AddToggle('CustomFOV', { Text = 'Custom FOV', Default = false })
CameraGroup:AddSlider('FOVValue', { Text = 'FOV Amount', Default = 100, Min = 10, Max = 120, Rounding = 0, Compact = false })
CameraGroup:AddDivider()
CameraGroup:AddToggle('EnableZoom', { Text = 'Enable Zoom', Default = false }):AddKeyPicker('ZoomBind', {
    Default = 'None', SyncToggleState = false, Mode = 'Hold', Text = 'Zoom Key', NoUI = false
})
CameraGroup:AddSlider('ZoomValue', { Text = 'Zoom FOV', Default = 30, Min = 1, Max = 120, Rounding = 0, Compact = false })

CameraGroup:AddDivider()
CameraGroup:AddToggle('EnableFreecam', { Text = 'Enable Freecam', Default = false }):AddKeyPicker('FreecamBind', {
    Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'Toggle Freecam', NoUI = false
})
CameraGroup:AddSlider('FreecamSpeed', { Text = 'Freecam Speed', Default = 50, Min = 10, Max = 200, Rounding = 0, Compact = false })

local LocalVisualsGroup = Tabs.Visuals:AddRightGroupbox('Local Visuals')
LocalVisualsGroup:AddToggle('HandChams', { Text = 'Hand Chams', Default = false, Tooltip = 'Changes material to ForceField' })
LocalVisualsGroup:AddLabel('Chams Color'):AddColorPicker('HandChamsColor', { Default = Color3.new(0, 0, 1), Title = 'Hand Chams Color' })

-- [[ ВКЛАДКА ESP ]] --
local ESPGroup = Tabs.ESP:AddLeftGroupbox('Entity ESP')
ESPGroup:AddToggle('MasterESP', { Text = 'Enable ESP', Default = false })
ESPGroup:AddToggle('BoxESP', { Text = 'Box', Default = false })
ESPGroup:AddToggle('HealthBarESP', { Text = 'Health Bar', Default = false })
ESPGroup:AddToggle('NameESP', { Text = 'Name', Default = false })
ESPGroup:AddToggle('DistanceESP', { Text = 'Distance', Default = false })
ESPGroup:AddToggle('SkeletonESP', { Text = 'Skeleton', Default = false })
ESPGroup:AddToggle('ChamsESP', { Text = 'Chams', Default = false })
ESPGroup:AddToggle('IncludeAI', { Text = 'Include AI (Bots)', Default = false })
ESPGroup:AddLabel('ESP Color'):AddColorPicker('ESPColor', { Default = Color3.new(0, 0, 1), Title = 'Main ESP Color' })

ESPGroup:AddDivider()
ESPGroup:AddToggle('TargetInfo', { Text = 'Target Info', Default = false })

local RadarGroup = Tabs.ESP:AddRightGroupbox('Other ESP')
RadarGroup:AddToggle('EnableRadar', { Text = 'Enable Radar', Default = false })
RadarGroup:AddSlider('RadarZoom', { Text = 'Radar Zoom', Default = 1, Min = 0.1, Max = 5, Rounding = 1, Compact = false })
RadarGroup:AddSlider('RadarSize', { Text = 'Radar Size', Default = 200, Min = 100, Max = 400, Rounding = 0, Compact = false })

local lsFolderCache = nil
local function GetCharacter(player)
    if not lsFolderCache or not lsFolderCache.Parent then
        lsFolderCache = workspace:FindFirstChild("Players")
    end
    
    if lsFolderCache then
        local char = lsFolderCache:FindFirstChild(player.Name)
        if char and char:IsA("Model") then return char end
    end
    if player.Character then return player.Character end
    return nil
end

local function GetHealth(char)
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if hum then return hum.Health > 0, hum.Health, hum.MaxHealth end
    local customHP = char:FindFirstChild("Health")
    if customHP then
        local maxHP = char:FindFirstChild("MaxHealth") and char.MaxHealth.Value or 100
        return customHP.Value > 0, customHP.Value, maxHP
    end
    return true, 100, 100 
end

local function GetCustomPart(char, partName)
    if partName == 'Random' then
        local parts = {'Head', 'HumanoidRootPart', 'UpperTorso', 'LowerTorso'}
        partName = parts[math.random(1, #parts)]
    end
    
    local part = char:FindFirstChild(partName)
    if part then return part end
    
    if partName == "Head" then 
        return char:FindFirstChild("HeadHitbox") or char:FindFirstChild("head") or char:FindFirstChild("FPSHead")
    elseif partName == "HumanoidRootPart" or partName == "UpperTorso" then 
        return char:FindFirstChild("Torso") or char:FindFirstChild("LowerTorso") or char.PrimaryPart
    end
    return char:FindFirstChildWhichIsA("BasePart")
end

local AINames = {
    ["Akira"] = true, ["Reika"] = true, ["Kyron"] = true, ["Arctic Militants"] = true,
    ["Sciencist"] = true, ["Akira Bodygruad"] = true, ["Kyron Bodyguard"] = true,
    ["Akira Bodyguard"] = true, ["Quarry Militants"] = true, ["Quarry Militants"] = true
}

local function IsWhitelisted(name)
    local whitelistStr = Options.WhitelistInput and Options.WhitelistInput.Value or ""
    if whitelistStr == "" then return false end
    for wName in string.gmatch(whitelistStr, "[^,]+") do
        if wName:match("^%s*(.-)%s*$") == name then
            return true
        end
    end
    return false
end

local function GetValidTargets(includeAI)
    local targets = {}
    local lpChar = GetCharacter(LocalPlayer)
    local lpRoot = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
    local lpPos = lpRoot and lpRoot.Position or Vector3.zero
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = GetCharacter(player)
        if char then targets[char] = player.Name end
    end
    
    local function isValidAI(child)
        if not child:IsA("Model") or child == lpChar then return false end
        local hum = child:FindFirstChildWhichIsA("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        
        local root = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart
        if not root then return false end
        
        if lpRoot then
            local dist = (root.Position - lpPos).Magnitude
            if dist > 1500 then return false end 
        end
        return true
    end
    
    if lsFolderCache then
        for _, child in pairs(lsFolderCache:GetChildren()) do
            if child:IsA("Model") and child ~= lpChar then
                if targets[child] == nil and child:FindFirstChildWhichIsA("Humanoid") then
                    if includeAI then
                        if isValidAI(child) then targets[child] = child.Name end
                    else
                        local isPlayer = false
                        for _, p in pairs(Players:GetPlayers()) do
                            if p.Name == child.Name then 
                                isPlayer = true 
                                break 
                            end
                        end
                        if isPlayer then targets[child] = child.Name end
                    end
                end
            end
        end
    end
    
    if includeAI then
        local aiFolders = {"Zombies", "NPCs", "Entities", "Mobs", "AI"}
        for _, fName in pairs(aiFolders) do
            local folder = workspace:FindFirstChild(fName)
            if folder then
                for _, child in pairs(folder:GetChildren()) do
                    if isValidAI(child) then targets[child] = child.Name end
                end
            end
        end
        
        for _, child in pairs(workspace:GetChildren()) do
            if AINames[child.Name] and isValidAI(child) then
                targets[child] = child.Name
            end
        end
    end
    
    return targets
end

local function GetMoveVector(char)
    local moveDir = Vector3.new(0,0,0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
    if moveDir.Magnitude > 0 then return Vector3.new(moveDir.X, 0, moveDir.Z).Unit end
    return Vector3.new(0,0,0)
end

-- [[ ОПТИМИЗИРОВАННАЯ МАГИЯ БАЙПАССА И SILENT AIM ]] --
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()

    if not checkcaller() then
        if method == "Kick" or method == "kick" then return nil end

        if method == "FireServer" or method == "fireServer" or method == "Raycast" or method == "raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
            
            if Toggles.EnableSilentAim and Toggles.EnableSilentAim.Value and SilentAimCache.TargetPart then
                local chance = Options.HitChance.Value
                if math.random(1, 100) <= chance then
                    
                    local args = {...}
                    local target = SilentAimCache.TargetPart
                    local targetPos = target.Position

                    if method == "FireServer" or method == "fireServer" then
                        if typeof(self) == "Instance" and self.ClassName == "RemoteEvent" then
                            for i, v in pairs(args) do
                                if type(v) == "table" then
                                    if v.Hit or v.hit or v.Cframe or v.CFrame or v.Position or v.position or v.Part then
                                        v.Hit = target
                                        v.hit = target
                                        v.Part = target
                                        v.Instance = target
                                        v.Cframe = target.CFrame
                                        v.CFrame = target.CFrame
                                        v.Position = targetPos
                                        v.position = targetPos
                                        v.p = targetPos
                                        v.HitNormal = Vector3.new(0, 1, 0)
                                        v.Normal = Vector3.new(0, 1, 0)
                                    end
                                end
                            end
                            return oldNamecall(self, unpack(args))
                        end
                    end

                    if (method == "Raycast" or method == "raycast") and self == workspace then
                        if args[1] and args[2] then
                            local origin = args[1]
                            local direction = args[2]
                            if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
                                args[2] = (targetPos - origin).Unit * direction.Magnitude 
                                return oldNamecall(self, unpack(args))
                            end
                        end
                    end

                    if method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
                        if args[1] and typeof(args[1]) == "Ray" then
                            local origin = args[1].Origin
                            args[1] = Ray.new(origin, (targetPos - origin).Unit * 1000)
                            return oldNamecall(self, unpack(args))
                        end
                    end
                end
            end
        end
    end
    return oldNamecall(self, ...)
end)

local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if not checkcaller() then
        if key == "WalkSpeed" or key == "JumpPower" then
            if typeof(self) == "Instance" and self:IsA("Humanoid") then
                return key == "WalkSpeed" and 16 or 50
            end
        end

        if key == "Hit" or key == "hit" or key == "Target" or key == "target" or key == "UnitRay" then
            if Toggles.EnableSilentAim and Toggles.EnableSilentAim.Value and SilentAimCache.TargetPart then
                if typeof(self) == "Instance" and self:IsA("Mouse") then
                    local chance = Options.HitChance.Value
                    if math.random(1, 100) <= chance then
                        if key == "Hit" or key == "hit" then
                            return SilentAimCache.TargetPart.CFrame
                        elseif key == "Target" or key == "target" then
                            return SilentAimCache.TargetPart
                        elseif key == "UnitRay" then
                            local origin = Camera.CFrame.Position
                            local targetPos = SilentAimCache.TargetPart.Position
                            return Ray.new(origin, (targetPos - origin).Unit)
                        end
                    end
                end
            end
        end
    end
    return oldIndex(self, key)
end)

-- [[ ЛОГИКА MOVEMENT (SPEED) ]] --
RunService.Heartbeat:Connect(function(deltaTime)
    if Toggles.EnableSpeed.Value then
        local char = GetCharacter(LocalPlayer)
        if char then
            local isAlive = GetHealth(char)
            local rootPart = GetCustomPart(char, "HumanoidRootPart")
            if isAlive and rootPart then
                local moveVector = GetMoveVector(char)
                if moveVector.Magnitude > 0 then
                    local speed = Options.SpeedAmount.Value
                    if Options.SpeedMethod.Value == 'CFrame' then 
                        rootPart.CFrame = rootPart.CFrame + (moveVector * (speed * deltaTime))
                    elseif Options.SpeedMethod.Value == 'Velocity' then 
                        rootPart.AssemblyLinearVelocity = Vector3.new(moveVector.X * speed, rootPart.AssemblyLinearVelocity.Y, moveVector.Z * speed) 
                    end
                end
            end
        end
    end
end)





local FreecamLoop = nil
local FreecamLastCFrame = nil
local FreecamPosition = Vector3.zero
local camRotX, camRotY = 0, 0
local FreecamInputConnection = nil
local ContextActionService = game:GetService("ContextActionService")

local function sinkMovement()
    return Enum.ContextActionResult.Sink
end

Toggles.EnableFreecam:OnChanged(function()
    local char = GetCharacter(LocalPlayer)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")

    if Toggles.EnableFreecam.Value then
        FreecamLastCFrame = Camera.CFrame
        FreecamPosition = Camera.CFrame.Position
        Camera.CameraType = Enum.CameraType.Scriptable
        local rx, ry, _ = Camera.CFrame:ToEulerAnglesYXZ()
        camRotX, camRotY = ry, rx
        
        -- Anchor character locally so they stand still
        if hrp then hrp.Anchored = true end
        if hum then hum.PlatformStand = true end
        
        FreecamLoop = RunService.RenderStepped:Connect(function(dt)
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0, 0, -1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0, 0, 1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move + Vector3.new(0, -1, 0) end

            if not Library.Toggled then
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
                local delta = UserInputService:GetMouseDelta()
                camRotX = camRotX - delta.X * 0.003
                camRotY = math.clamp(camRotY - delta.Y * 0.003, -math.pi/2, math.pi/2)
            else
                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
                    local delta = UserInputService:GetMouseDelta()
                    camRotX = camRotX - delta.X * 0.003
                    camRotY = math.clamp(camRotY - delta.Y * 0.003, -math.pi/2, math.pi/2)
                else
                    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                end
            end

            local rot = CFrame.Angles(0, camRotX, 0) * CFrame.Angles(camRotY, 0, 0)

            if move.Magnitude > 0 then
                -- Translate move vector relative to camera rotation
                local moveDir = rot:VectorToWorldSpace(move)
                FreecamPosition = FreecamPosition + moveDir * (dt * Options.FreecamSpeed.Value)
            end
            
            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.CFrame = CFrame.new(FreecamPosition) * rot
            Camera.Focus = CFrame.new(FreecamPosition + rot.LookVector * 10)
        end)
    else
        if FreecamLoop then FreecamLoop:Disconnect(); FreecamLoop = nil end
        if FreecamInputConnection then FreecamInputConnection:Disconnect(); FreecamInputConnection = nil end
        
        -- Unanchor character locally
        if hrp then hrp.Anchored = false end
        if hum then hum.PlatformStand = false end
        
        Camera.CameraType = Enum.CameraType.Custom
        if FreecamLastCFrame then Camera.CFrame = FreecamLastCFrame end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end)

-- [[ ОПТИМИЗИРОВАННЫЙ ЦИКЛ (HAND CHAMS) ]] --
local HitboxCache = {}
local HandChamsCache = {} 

task.spawn(function()
    while task.wait(0.1) do
        if Toggles.HandChams.Value then
            local targetColor = Options.HandChamsColor.Value
            for _, obj in pairs(Camera:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Transparency < 1 then
                    if not HandChamsCache[obj] then
                        HandChamsCache[obj] = { Material = obj.Material, Color = obj.Color }
                    end
                    if obj.Material ~= Enum.Material.ForceField then obj.Material = Enum.Material.ForceField end
                    if obj.Color ~= targetColor then obj.Color = targetColor end
                end
            end
        else
            for part, original in pairs(HandChamsCache) do
                if part and part.Parent then part.Material = original.Material; part.Color = original.Color end
            end
            table.clear(HandChamsCache)
        end
        for part in pairs(HandChamsCache) do if not part or not part.Parent then HandChamsCache[part] = nil end end
    end
end)

-- [[ ЛОГИКА VISUALS ]] --
local WorldLoop = nil
local LightingCache = { Saved = false }

local function SaveLighting()
    if not LightingCache.Saved then
        LightingCache.Ambient = Lighting.Ambient
        LightingCache.OutdoorAmbient = Lighting.OutdoorAmbient
        LightingCache.ColorShift_Bottom = Lighting.ColorShift_Bottom
        LightingCache.ColorShift_Top = Lighting.ColorShift_Top
        LightingCache.GlobalShadows = Lighting.GlobalShadows
        LightingCache.FogEnd = Lighting.FogEnd
        LightingCache.Brightness = Lighting.Brightness
        LightingCache.ClockTime = Lighting.ClockTime
        LightingCache.Saved = true
    end
end

local function RestoreLighting()
    if LightingCache.Saved then
        pcall(function()
            Lighting.Ambient = LightingCache.Ambient
            Lighting.OutdoorAmbient = LightingCache.OutdoorAmbient
            Lighting.ColorShift_Bottom = LightingCache.ColorShift_Bottom
            Lighting.ColorShift_Top = LightingCache.ColorShift_Top
            Lighting.GlobalShadows = LightingCache.GlobalShadows
            Lighting.FogEnd = LightingCache.FogEnd
            Lighting.Brightness = LightingCache.Brightness
            Lighting.ClockTime = LightingCache.ClockTime
        end)
        LightingCache.Saved = false
    end
end

local function UpdateWorldVisuals()
    if Toggles.Fullbright.Value or Toggles.CustomAtmosphere.Value then
        SaveLighting()
        if not WorldLoop then
            WorldLoop = RunService.RenderStepped:Connect(function()
                if Toggles.Fullbright.Value then
                    if Lighting.GlobalShadows ~= false then Lighting.GlobalShadows = false end
                    if Lighting.FogEnd ~= Options.FogDistance.Value then Lighting.FogEnd = Options.FogDistance.Value end
                    if Lighting.Brightness ~= Options.FullbrightBrightness.Value then Lighting.Brightness = Options.FullbrightBrightness.Value end
                    if Lighting.ClockTime ~= 12 then Lighting.ClockTime = 12 end
                end
                
                if Toggles.CustomAtmosphere.Value then
                    local color = Options.AtmosphereColor.Value
                    if Lighting.Ambient ~= color then Lighting.Ambient = color end
                    if Lighting.OutdoorAmbient ~= color then Lighting.OutdoorAmbient = color end
                    if Lighting.ColorShift_Bottom ~= color then Lighting.ColorShift_Bottom = color end
                    if Lighting.ColorShift_Top ~= color then Lighting.ColorShift_Top = color end
                elseif Toggles.Fullbright.Value then
                    local white = Color3.new(1, 1, 1)
                    if Lighting.Ambient ~= white then Lighting.Ambient = white end
                    if Lighting.OutdoorAmbient ~= white then Lighting.OutdoorAmbient = white end
                    if Lighting.ColorShift_Bottom ~= white then Lighting.ColorShift_Bottom = white end
                    if Lighting.ColorShift_Top ~= white then Lighting.ColorShift_Top = white end
                end
            end)
        end
    else
        if WorldLoop then WorldLoop:Disconnect(); WorldLoop = nil end
        RestoreLighting()
    end
end

Toggles.Fullbright:OnChanged(UpdateWorldVisuals)
Toggles.CustomAtmosphere:OnChanged(UpdateWorldVisuals)

-- [[ ЛОГИКА AIMBOT И КАМЕРЫ ]] --
local function CreateUI_Circle()
    local frame = Instance.new("Frame")
    frame.Parent = Kanomi_Container
    frame.BackgroundColor3 = Color3.new(1, 1, 1)
    frame.BackgroundTransparency = 1
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Active = false 
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Parent = frame
    stroke.Thickness = 1.5
    
    return frame, stroke
end

local FOVFrame, FOVStroke = CreateUI_Circle()
local SilentFOVFrame, SilentFOVStroke = CreateUI_Circle()

local RadarFrame = Instance.new("Frame")
RadarFrame.Name = "RadarFrame"
RadarFrame.Parent = Kanomi_Container
RadarFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
RadarFrame.BackgroundTransparency = 0.5
RadarFrame.Size = UDim2.new(0, 200, 0, 200)
RadarFrame.Position = UDim2.new(1, -220, 0, 20)
RadarFrame.Active = true
RadarFrame.Visible = false

local RadarCorner = Instance.new("UICorner")
RadarCorner.CornerRadius = UDim.new(1, 0)
RadarCorner.Parent = RadarFrame

local RadarStroke = Instance.new("UIStroke")
RadarStroke.Parent = RadarFrame
RadarStroke.Color = Color3.fromRGB(255, 255, 255)
RadarStroke.Thickness = 1.5

local PlayerArrow = Instance.new("TextLabel")
PlayerArrow.Parent = RadarFrame
PlayerArrow.BackgroundTransparency = 1
PlayerArrow.Size = UDim2.new(0, 16, 0, 16)
PlayerArrow.Position = UDim2.new(0.5, -8, 0.5, -8)
PlayerArrow.Text = "▲"
PlayerArrow.TextColor3 = Color3.new(0, 255, 0)
PlayerArrow.TextSize = 16
PlayerArrow.Font = Enum.Font.SourceSansBold

local dragging, dragInput, dragStart, startPos
RadarFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = RadarFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

RadarFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        RadarFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local function GetClosestPlayer(maxDist, targetPartName, wallCheck, includeAI)
    local targetPart = nil
    local mouseLoc = UserInputService:GetMouseLocation()

    if wallCheck then
        local lpChar = GetCharacter(LocalPlayer)
        GlobalRayParams.FilterDescendantsInstances = {lpChar, Camera}
    end

    local validTargets = GetValidTargets(includeAI)

    for char, name in pairs(validTargets) do
        if IsWhitelisted(name) then continue end
        if GetHealth(char) then
            local part = GetCustomPart(char, targetPartName)
            if part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mouseLoc).Magnitude
                    if dist < maxDist then
                        if wallCheck then
                            local dir = part.Position - Camera.CFrame.Position
                            local hit = workspace:Raycast(Camera.CFrame.Position, dir, GlobalRayParams)
                            if hit and hit.Instance and not hit.Instance:IsDescendantOf(char) then continue end
                        end
                        maxDist = dist
                        targetPart = part
                    end
                end
            end
        end
    end
    return targetPart
end

local WasOverridingFOV = false

RunService.RenderStepped:Connect(function()
    -- Отключаем зум, если работает свободная камера
    if not Toggles.EnableFreecam.Value then
        local isZooming = Toggles.EnableZoom.Value and Options.ZoomBind:GetState()

        if isZooming then
            Camera.FieldOfView = Options.ZoomValue.Value
            WasOverridingFOV = true
        elseif Toggles.CustomFOV.Value then
            Camera.FieldOfView = Options.FOVValue.Value
            WasOverridingFOV = true
        elseif WasOverridingFOV then
            Camera.FieldOfView = 70
            WasOverridingFOV = false
        end
    end

    local mouseLoc = UserInputService:GetMouseLocation()
    
    if Toggles.ShowFOV.Value then
        local r1 = Options.FOVSize.Value
        FOVFrame.Size = UDim2.new(0, r1 * 2, 0, r1 * 2)
        FOVFrame.Position = UDim2.new(0, mouseLoc.X, 0, mouseLoc.Y)
        FOVStroke.Color = Options.FOVColor.Value
        FOVFrame.Visible = true
    else
        FOVFrame.Visible = false
    end

    if Toggles.ShowSilentFOV.Value then
        local r2 = Options.SilentFOVSize.Value
        SilentFOVFrame.Size = UDim2.new(0, r2 * 2, 0, r2 * 2)
        SilentFOVFrame.Position = UDim2.new(0, mouseLoc.X, 0, mouseLoc.Y)
        SilentFOVStroke.Color = Options.SilentFOVColor.Value
        SilentFOVFrame.Visible = true
    else
        SilentFOVFrame.Visible = false
    end

    if Toggles.EnableSilentAim.Value then
        local now = tick()
        if now - SilentAimCache.LastUpdate > 0.05 then
            SilentAimCache.TargetPart = GetClosestPlayer(Options.SilentFOVSize.Value, Options.SilentTargetPart.Value, Toggles.SilentWallCheck.Value, Toggles.SilentIncludeAI.Value)
            SilentAimCache.LastUpdate = now
        end
    else
        SilentAimCache.TargetPart = nil
    end

    if Toggles.EnableAimbot.Value and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestPlayer(Options.FOVSize.Value, Options.TargetPart.Value, Toggles.WallCheck.Value, Toggles.AimbotIncludeAI.Value)
        if target then
            local smoothness = Options.AimSmoothness.Value / 100
            local targetCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smoothness)
        end
    end
end)

-- [[ ЛОГИКА ESP ]] --
local ESP_Cache = {}
local SkeletonConnections = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

local function CreateESPData(model, name)
    local data = {
        Box = Instance.new("Frame"),
        BoxStroke = Instance.new("UIStroke"),
        HealthBarBg = Instance.new("Frame"),
        HealthBar = Instance.new("Frame"),
        HealthText = Instance.new("TextLabel"),
        Name = Instance.new("TextLabel"),
        Distance = Instance.new("TextLabel"),
        Item = Instance.new("TextLabel"),
        Chams = Instance.new("Highlight"),
        Skeleton = {}
    }

    data.Box.Parent = Kanomi_Container
    data.Box.BackgroundTransparency = 1
    data.Box.BorderSizePixel = 0
    data.Box.Active = false

    data.BoxStroke.Parent = data.Box
    data.BoxStroke.Thickness = 1.5

    data.HealthBarBg.Parent = Kanomi_Container
    data.HealthBarBg.BackgroundColor3 = Color3.new(0, 0, 0)
    data.HealthBarBg.BorderSizePixel = 0
    data.HealthBarBg.Active = false

    data.HealthBar.Parent = data.HealthBarBg
    data.HealthBar.BorderSizePixel = 0

    data.HealthText.Parent = Kanomi_Container
    data.HealthText.BackgroundTransparency = 1
    data.HealthText.Font = Enum.Font.Code
    data.HealthText.Size = UDim2.new(0, 30, 0, 10)
    data.HealthText.TextSize = 10
    data.HealthText.TextStrokeTransparency = 0
    data.HealthText.Active = false

    data.Name.Parent = Kanomi_Container
    data.Name.BackgroundTransparency = 1
    data.Name.Font = Enum.Font.Code
    data.Name.Size = UDim2.new(0, 100, 0, 15)
    data.Name.TextSize = 13
    data.Name.TextStrokeTransparency = 0
    data.Name.Text = name
    data.Name.Active = false

    data.Distance.Parent = Kanomi_Container
    data.Distance.BackgroundTransparency = 1
    data.Distance.Font = Enum.Font.Code
    data.Distance.Size = UDim2.new(0, 100, 0, 15)
    data.Distance.TextSize = 12
    data.Distance.TextStrokeTransparency = 0
    data.Distance.Active = false

    data.Item.Parent = Kanomi_Container
    data.Item.BackgroundTransparency = 1
    data.Item.Font = Enum.Font.Code
    data.Item.Size = UDim2.new(0, 100, 0, 15)
    data.Item.TextSize = 12
    data.Item.TextStrokeTransparency = 0
    data.Item.Active = false

    data.Chams.FillTransparency = 0.5
    data.Chams.OutlineTransparency = 0
    data.Chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    for i = 1, #SkeletonConnections do
        local line = Instance.new("Frame")
        line.Parent = Kanomi_Container
        line.BackgroundColor3 = Color3.new(1, 1, 1)
        line.BorderSizePixel = 0
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.Active = false
        table.insert(data.Skeleton, line)
    end
    
    ESP_Cache[model] = data
end

local function DrawFrameLine(frame, p1, p2, color)
    local distance = (p1 - p2).Magnitude
    local center = (p1 + p2) / 2
    frame.Position = UDim2.new(0, center.X, 0, center.Y)
    frame.Size = UDim2.new(0, distance, 0, 1)
    frame.Rotation = math.deg(math.atan2(p2.Y - p1.Y, p2.X - p1.X))
    frame.BackgroundColor3 = color
    frame.Visible = true
end



RunService:BindToRenderStep("Kanomi_ESP", Enum.RenderPriority.Camera.Value + 1, function()
    local currentTargets = GetValidTargets(Toggles.IncludeAI and Toggles.IncludeAI.Value)

    for model, name in pairs(currentTargets) do
        if not ESP_Cache[model] then CreateESPData(model, name) end
        local data = ESP_Cache[model]
        local char = model
        local masterEnabled = Toggles.MasterESP.Value
        local color = Options.ESPColor.Value
        if IsWhitelisted(name) then
            color = Color3.fromRGB(0, 255, 0)
        end

        if masterEnabled and char then
            local isAlive, currentHP, maxHP = GetHealth(char)
            local rootPart = GetCustomPart(char, "HumanoidRootPart")
            local headPart = GetCustomPart(char, "Head")

            if isAlive and rootPart then
                local _, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                
                if onScreen then
                    local dist = (Camera.CFrame.Position - rootPart.Position).Magnitude
                    local headPos = headPart and headPart.Position or (rootPart.Position + Vector3.new(0, 1.5, 0))
                    
                    local topPos = Camera:WorldToViewportPoint(headPos + Vector3.new(0, 0.5, 0))
                    local bottomPos = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
                    local height = bottomPos.Y - topPos.Y
                    local width = height / 1.5

                    if Toggles.BoxESP.Value then
                        data.Box.Size = UDim2.new(0, width, 0, height)
                        data.Box.Position = UDim2.new(0, topPos.X - width/2, 0, topPos.Y)
                        data.BoxStroke.Color = color
                        data.Box.Visible = true
                    else 
                        data.Box.Visible = false 
                    end

                    if Toggles.HealthBarESP.Value then
                        local healthPercent = math.clamp(currentHP / maxHP, 0, 1)
                        local hpColor = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), healthPercent)
                        local barWidth = 2
                        local barOffset = 4
                        local startX = topPos.X - width/2 - barOffset - barWidth

                        data.HealthBarBg.Size = UDim2.new(0, barWidth, 0, height)
                        data.HealthBarBg.Position = UDim2.new(0, startX, 0, topPos.Y)
                        data.HealthBar.Size = UDim2.new(1, 0, healthPercent, 0)
                        data.HealthBar.Position = UDim2.new(0, 0, 1 - healthPercent, 0)
                        data.HealthBar.BackgroundColor3 = hpColor
                        
                        data.HealthText.Text = tostring(math.floor(currentHP))
                        data.HealthText.TextColor3 = hpColor
                        data.HealthText.Position = UDim2.new(0, startX - 25, 0, topPos.Y + (height * (1 - healthPercent)) - 5)
                        
                        data.HealthBarBg.Visible = true
                        data.HealthBar.Visible = true
                        data.HealthText.Visible = true
                    else
                        data.HealthBarBg.Visible = false
                        data.HealthBar.Visible = false
                        data.HealthText.Visible = false
                    end

                    if Toggles.NameESP.Value then
                        data.Name.Position = UDim2.new(0, topPos.X - 50, 0, topPos.Y - 15)
                        data.Name.TextColor3 = color
                        data.Name.Visible = true
                    else 
                        data.Name.Visible = false 
                    end

                    local bottomOffset = 0
                    if Toggles.DistanceESP.Value then
                        data.Distance.Position = UDim2.new(0, bottomPos.X - 50, 0, bottomPos.Y)
                        data.Distance.Text = math.floor(dist) .. "m"
                        data.Distance.TextColor3 = color
                        data.Distance.Visible = true
                        bottomOffset = 13
                    else 
                        data.Distance.Visible = false 
                    end

                    if Toggles.ItemESP and Toggles.ItemESP.Value then
                        local handItem = "None"
                        for _, child in pairs(char:GetDescendants()) do
                            local tType, matchName = checkLists(child.Name)
                            if tType == "gun" and handItem == "None" then
                                handItem = matchName
                            end
                        end
                        if handItem ~= "None" then
                            data.Item.Position = UDim2.new(0, bottomPos.X - 50, 0, bottomPos.Y + bottomOffset)
                            data.Item.Text = handItem
                            data.Item.TextColor3 = color
                            data.Item.Visible = true
                        else
                            data.Item.Visible = false
                        end
                    else
                        data.Item.Visible = false
                    end




                    if Toggles.SkeletonESP.Value and type(data.Skeleton) == "table" then
                        for i, connection in pairs(SkeletonConnections) do
                            local part1 = char:FindFirstChild(connection[1])
                            local part2 = char:FindFirstChild(connection[2])
                            local lineFrame = data.Skeleton[i]

                            if part1 and part2 and lineFrame then
                                local pos1, vis1 = Camera:WorldToViewportPoint(part1.Position)
                                local pos2, vis2 = Camera:WorldToViewportPoint(part2.Position)
                                if vis1 or vis2 then 
                                    DrawFrameLine(lineFrame, Vector2.new(pos1.X, pos1.Y), Vector2.new(pos2.X, pos2.Y), color) 
                                else 
                                    lineFrame.Visible = false 
                                end
                            elseif lineFrame then 
                                lineFrame.Visible = false 
                            end
                        end
                    else 
                        if type(data.Skeleton) == "table" then
                            for _, line in pairs(data.Skeleton) do line.Visible = false end 
                        end
                    end

                    if Toggles.ChamsESP.Value then
                        data.Chams.Parent = char
                        data.Chams.FillColor = color
                        data.Chams.OutlineColor = color
                        data.Chams.Enabled = true
                    else 
                        data.Chams.Enabled = false 
                    end

                else
                    data.Box.Visible = false
                    data.HealthBarBg.Visible = false
                    data.HealthBar.Visible = false
                    data.HealthText.Visible = false
                    data.Name.Visible = false
                    data.Distance.Visible = false
                    if data.Item then data.Item.Visible = false end
                    data.Chams.Enabled = false
                    if type(data.Skeleton) == "table" then for _, line in pairs(data.Skeleton) do line.Visible = false end end
                end
            else
                data.Box.Visible = false
                data.HealthBarBg.Visible = false
                data.HealthBar.Visible = false
                data.HealthText.Visible = false
                data.Name.Visible = false
                data.Distance.Visible = false
                if data.Item then data.Item.Visible = false end
                data.Chams.Enabled = false
                if type(data.Skeleton) == "table" then for _, line in pairs(data.Skeleton) do line.Visible = false end end
            end
        else
            data.Box.Visible = false
            data.HealthBarBg.Visible = false
            data.HealthBar.Visible = false
            data.HealthText.Visible = false
            data.Name.Visible = false
            data.Distance.Visible = false
            if data.Item then data.Item.Visible = false end
            data.Chams.Enabled = false
            if type(data.Skeleton) == "table" then for _, line in pairs(data.Skeleton) do line.Visible = false end end
        end
    end
    
    for model, data in pairs(ESP_Cache) do
        if not currentTargets[model] or not model.Parent then
            for _, obj in pairs(data) do
                if type(obj) == "table" then 
                    for _, line in pairs(obj) do line:Destroy() end 
                else 
                    obj:Destroy() 
                end
            end
            ESP_Cache[model] = nil
        end
    end
end)

local Radar_Cache = {}

RunService:BindToRenderStep("Kanomi_Radar", Enum.RenderPriority.Camera.Value + 1, function()
    if Toggles.EnableRadar and Toggles.EnableRadar.Value then
        local rSize = Options.RadarSize.Value
        RadarFrame.Size = UDim2.new(0, rSize, 0, rSize)
        RadarFrame.Visible = true
        
        local lpChar = GetCharacter(LocalPlayer)
        if lpChar then
            local lpRoot = GetCustomPart(lpChar, "HumanoidRootPart")
            if lpRoot then
                local lpPos = lpRoot.Position
                PlayerArrow.Rotation = 0
                
                local maxRadius = 200
                local zoom = Options.RadarZoom.Value
                local radiusPixels = rSize / 2
                
                local currentTargets = GetValidTargets(Toggles.IncludeAI and Toggles.IncludeAI.Value)
                
                for char, name in pairs(currentTargets) do
                    if not Radar_Cache[char] then
                        local dot = Instance.new("Frame")
                        dot.Size = UDim2.new(0, 6, 0, 6)
                        dot.BackgroundColor3 = Color3.new(1, 0, 0)
                        local corner = Instance.new("UICorner")
                        corner.CornerRadius = UDim.new(1, 0)
                        corner.Parent = dot
                        dot.Parent = RadarFrame
                        Radar_Cache[char] = dot
                    end
                    
                    local dot = Radar_Cache[char]
                    local root = GetCustomPart(char, "HumanoidRootPart")
                    if root then
                        local diff = root.Position - lpPos
                        local relPos = Camera.CFrame:VectorToObjectSpace(diff)
                        
                        local dist = Vector2.new(relPos.X, relPos.Z).Magnitude
                        if dist <= maxRadius then
                            local scaledX = relPos.X * zoom
                            local scaledY = relPos.Z * zoom
                            local ratio = radiusPixels / (maxRadius * zoom)
                            
                            local plotX = scaledX * ratio
                            local plotY = scaledY * ratio
                            
                            local plotDist = Vector2.new(plotX, plotY).Magnitude
                            if plotDist > radiusPixels - 3 then
                                local dir = Vector2.new(plotX, plotY).Unit
                                plotX = dir.X * (radiusPixels - 3)
                                plotY = dir.Y * (radiusPixels - 3)
                            end
                            
                            dot.Position = UDim2.new(0.5, plotX - 3, 0.5, plotY - 3)
                            dot.Visible = true
                            
                            local rayDir = root.Position - Camera.CFrame.Position
                            local hit = workspace:Raycast(Camera.CFrame.Position, rayDir, GlobalRayParams)
                            if IsWhitelisted(name) then
                                dot.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green
                            elseif hit and hit.Instance and not hit.Instance:IsDescendantOf(char) then
                                dot.BackgroundColor3 = Color3.fromRGB(255, 165, 0) -- Orange
                            else
                                dot.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Bright Red
                            end
                        else
                            dot.Visible = false
                        end
                    else
                        dot.Visible = false
                    end
                end
                
                for char, dot in pairs(Radar_Cache) do
                    if not currentTargets[char] or not char.Parent then
                        dot:Destroy()
                        Radar_Cache[char] = nil
                    end
                end
            end
        end
    else
        RadarFrame.Visible = false
        for _, dot in pairs(Radar_Cache) do dot.Visible = false end
    end
end)

-- [[ ЛОГИКА TARGET INFO ]] --
local TargetInfoFrame = Instance.new("Frame")
TargetInfoFrame.Name = "TargetInfoFrame"
TargetInfoFrame.Parent = Kanomi_Container
TargetInfoFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TargetInfoFrame.BorderSizePixel = 0
TargetInfoFrame.Size = UDim2.new(0, 300, 0, 70)
TargetInfoFrame.Position = UDim2.new(0.5, 100, 0.5, 0)
TargetInfoFrame.Active = true
TargetInfoFrame.Visible = false

local TIStroke = Instance.new("UIStroke")
TIStroke.Parent = TargetInfoFrame
TIStroke.Color = Color3.fromRGB(40, 40, 40)
TIStroke.Thickness = 1
TIStroke.LineJoinMode = Enum.LineJoinMode.Miter

local TargetInfoName = Instance.new("TextLabel")
TargetInfoName.Parent = TargetInfoFrame
TargetInfoName.BackgroundTransparency = 1
TargetInfoName.Size = UDim2.new(1, 0, 0, 20)
TargetInfoName.Font = Enum.Font.Code
TargetInfoName.TextSize = 13
TargetInfoName.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetInfoName.Text = "Target Name"
TargetInfoName.TextStrokeTransparency = 0

local TIDivider = Instance.new("Frame")
TIDivider.Parent = TargetInfoFrame
TIDivider.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TIDivider.BorderSizePixel = 0
TIDivider.Size = UDim2.new(1, 0, 0, 1)
TIDivider.Position = UDim2.new(0, 0, 0, 20)

local TICellContainer = Instance.new("Frame")
TICellContainer.Parent = TargetInfoFrame
TICellContainer.BackgroundTransparency = 1
TICellContainer.Size = UDim2.new(1, 0, 1, -21)
TICellContainer.Position = UDim2.new(0, 0, 0, 21)

local TILayout = Instance.new("UIListLayout")
TILayout.Parent = TICellContainer
TILayout.FillDirection = Enum.FillDirection.Horizontal
TILayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TILayout.VerticalAlignment = Enum.VerticalAlignment.Center
TILayout.Padding = UDim.new(0, 6)

local TICells = {}
local TICellNames = {"Hand", "Head", "Chest", "Pants"}

for i = 1, 4 do
    local cell = Instance.new("Frame")
    cell.Parent = TICellContainer
    cell.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    cell.BorderSizePixel = 0
    cell.Size = UDim2.new(0, 65, 0, 35)
    
    local cStroke = Instance.new("UIStroke")
    cStroke.Parent = cell
    cStroke.Color = Color3.fromRGB(40, 40, 40)
    
    local txt = Instance.new("TextLabel")
    txt.Parent = cell
    txt.BackgroundTransparency = 1
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.Font = Enum.Font.Code
    txt.TextScaled = true
    txt.TextColor3 = Color3.fromRGB(200, 200, 200)
    txt.Text = TICellNames[i]
    txt.TextWrapped = true
    txt.TextStrokeTransparency = 0.8
    
    table.insert(TICells, txt)
end

local tiDragging, tiDragInput, tiDragStart, tiStartPos
TargetInfoFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        tiDragging = true
        tiDragStart = input.Position
        tiStartPos = TargetInfoFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then tiDragging = false end
        end)
    end
end)

TargetInfoFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        tiDragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == tiDragInput and tiDragging then
        local delta = input.Position - tiDragStart
        TargetInfoFrame.Position = UDim2.new(tiStartPos.X.Scale, tiStartPos.X.Offset + delta.X, tiStartPos.Y.Scale, tiStartPos.Y.Offset + delta.Y)
    end
end)

RunService:BindToRenderStep("Kanomi_TargetInfo", Enum.RenderPriority.Camera.Value + 2, function()
    if not Toggles.TargetInfo or not Toggles.TargetInfo.Value then
        TargetInfoFrame.Visible = false
        return
    end

    local bestTarget = nil
    local bestDist = math.huge
    local mouseLoc = UserInputService:GetMouseLocation()
    
    local fovS = Options.SilentFOVSize and Options.SilentFOVSize.Value or 150
    local fovA = Options.FOVSize and Options.FOVSize.Value or 150
    local maxFov = math.max(fovS, fovA)

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = GetCharacter(player)
        if char then
            local isAlive = GetHealth(char)
            if isAlive then
                local root = GetCustomPart(char, "HumanoidRootPart")
                if root then
                    local dist3D = (Camera.CFrame.Position - root.Position).Magnitude
                    if dist3D <= 700 then
                        local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                        if onScreen then
                            local dist2D = (Vector2.new(pos.X, pos.Y) - mouseLoc).Magnitude
                            if dist2D <= maxFov and dist2D < bestDist then
                                bestDist = dist2D
                                bestTarget = player
                            end
                        end
                    end
                end
            end
        end
    end

    if bestTarget then
        TargetInfoFrame.Visible = true
        TargetInfoName.Text = bestTarget.Name
        
        local char = GetCharacter(bestTarget)
        local handItem = "None"
        local helmet, chest, pants = "None", "None", "None"

        for _, child in pairs(char:GetDescendants()) do
            local tType, matchName = checkLists(child.Name)
            if tType == "head" then helmet = matchName
            elseif tType == "body" then chest = matchName
            elseif tType == "legs" then pants = matchName
            elseif tType == "gun" and handItem == "None" then handItem = matchName
            end
        end

        TICells[1].Text = handItem
        if handItem ~= "None" then TICells[1].BackgroundColor3 = Color3.fromRGB(80, 50, 50) else TICells[1].BackgroundColor3 = Color3.fromRGB(20, 20, 20) end
        
        TICells[2].Text = helmet
        if helmet ~= "None" then TICells[2].BackgroundColor3 = Color3.fromRGB(50, 80, 50) else TICells[2].BackgroundColor3 = Color3.fromRGB(20, 20, 20) end
        
        TICells[3].Text = chest
        if chest ~= "None" then TICells[3].BackgroundColor3 = Color3.fromRGB(50, 50, 80) else TICells[3].BackgroundColor3 = Color3.fromRGB(20, 20, 20) end
        
        TICells[4].Text = pants
        if pants ~= "None" then TICells[4].BackgroundColor3 = Color3.fromRGB(80, 80, 50) else TICells[4].BackgroundColor3 = Color3.fromRGB(20, 20, 20) end
    else
        TargetInfoFrame.Visible = false
    end
end)

-- [[ ЛОГИКА NO RECOIL (AC BYPASS) ]] --
local RecoilFunction = nil
local RecoilHook = nil

task.spawn(function()
    while task.wait(3) do
        if not RecoilFunction then
            for i, v in pairs(getgc(true)) do
                if type(v) == "function" and debug.getinfo(v)["name"] == "Add" then
                    local src = debug.getinfo(v)["short_src"]
                    if src and src:find("Recoil") then
                        RecoilFunction = v
                        break
                    end
                end
            end

            if RecoilFunction then
                RecoilHook = hookfunction(RecoilFunction, function(...)
                    local args = {...}
                    if Toggles.EnableNoRecoil and Toggles.EnableNoRecoil.Value then
                        local control = Options.RecoilControl.Value
                        local multiplier = (100 - control) / 100
                        
                        -- Nullify visual shake/sway args to completely eliminate visual recoil
                        if typeof(args[1]) == "number" then args[1] = args[1] * multiplier end
                        if typeof(args[2]) == "number" then args[2] = args[2] * multiplier end
                        if typeof(args[3]) == "number" then args[3] = args[3] * multiplier end
                        if typeof(args[4]) == "number" then args[4] = args[4] * multiplier end
                    end
                    return RecoilHook(unpack(args))
                end)
                break
            end
        else
            break
        end
    end
end)

-- [[ UNLOAD И НАСТРОЙКИ UI ]] --
Library:OnUnload(function()
    if WorldLoop then WorldLoop:Disconnect() end
    if FreecamLoop then FreecamLoop:Disconnect() end
    if FreecamInputConnection then FreecamInputConnection:Disconnect() end
    pcall(function() game:GetService("ContextActionService"):UnbindAction("FreecamMovementSink") end)
    pcall(function() RunService:UnbindFromRenderStep("Kanomi_ESP") end)
    
    Camera.CameraType = Enum.CameraType.Custom
    RestoreLighting()
    
    for part, original in pairs(HitboxCache) do
        if part and part.Parent then
            part.Size = original.Size
            part.Transparency = original.Transparency
            part.Color = original.Color
            part.Material = original.Material
            part.CanCollide = original.CanCollide
            part.Massless = original.Massless
            if original.CanQuery ~= nil then part.CanQuery = original.CanQuery end
            if original.CanTouch ~= nil then part.CanTouch = original.CanTouch end
        end
    end
    
    for part, original in pairs(HandChamsCache) do
        if part and part.Parent then 
            part.Material = original.Material
            part.Color = original.Color 
        end
    end
    
    local char = GetCharacter(LocalPlayer)
    if char then
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if hum then hum.PlatformStand = false; hum.AutoRotate = true end
    end
    
    if Kanomi_Container then Kanomi_Container:Destroy() end
    Library.Unloaded = true
end)

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu Settings')
MenuGroup:AddButton('Unload Script', function() Library:Unload() end)

MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'Insert', NoUI = true, Text = 'Menu keybind' })
Library.ToggleKeybind = Options.MenuKeybind

MenuGroup:AddToggle('ShowKeybinds', { Text = 'Show Keybinds', Default = true }):OnChanged(function()
    Library.KeybindFrame.Visible = Toggles.ShowKeybinds.Value
end)

Library:SetWatermarkVisibility(true)
Library:SetWatermark('Kanomi.lol | Lone Survival')
Library.KeybindFrame.Visible = true

pcall(function()
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    
    ThemeManager:SetFolder('Kanomi_lol')
    SaveManager:SetFolder('Kanomi_lol/LoneSurvival')

    SaveManager:BuildConfigSection(Tabs['UI Settings'])
    
    print("[Kanomi] Menu UI has fully loaded.")
end)

-- Debug error catching for menu initialization
if not Library.Toggled then
    print("[Kanomi] WARNING: Library.Toggled was false at the end of the script, menu might have failed to show.")
end
