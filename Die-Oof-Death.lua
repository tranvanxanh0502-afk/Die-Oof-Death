-- PART 1: Load Rayfield + ESP + Speed Settings + Auto Block
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local lp = Players.LocalPlayer

connections = connections or {}    -- global tables so other parts can reference if needed
mainConns = mainConns or {}
unloaded = false

local useAbilityRF = nil
pcall(function()
    useAbilityRF = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteFunctions"):WaitForChild("UseAbility")
end)

local Storage = CoreGui:FindFirstChild("Highlight_Storage") or Instance.new("Folder")
Storage.Name = "Highlight_Storage"
Storage.Parent = CoreGui

local espConfigs = {
    Survivor = {Enabled=true, Name=true, HP=true, Fill=true, Outline=true, FillColor=Color3.fromRGB(0,255,0),   OutlineColor=Color3.fromRGB(0,255,0),   FillTransparency=0.5, OutlineTransparency=0},
    Killer   = {Enabled=true, Name=true, HP=true, Fill=true, Outline=true, FillColor=Color3.fromRGB(255,0,0),   OutlineColor=Color3.fromRGB(255,0,0),   FillTransparency=0.5, OutlineTransparency=0},
    Ghost    = {Enabled=true, Name=true, HP=true, Fill=true, Outline=true, FillColor=Color3.fromRGB(0,255,255), OutlineColor=Color3.fromRGB(0,255,255), FillTransparency=0.5, OutlineTransparency=0},
}
local DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
local TextStrokeColor = Color3.fromRGB(0,0,0)

local oldGui = CoreGui:FindFirstChild("Rayfield")
if oldGui then pcall(function() oldGui:Destroy() end) end

local function makeFallbackRayfield()
    local DummyParagraph = { Set=function() end }
    local DummyTab = {
        CreateToggle=function() end, CreateSlider=function() end, CreateButton=function() end,
        CreateParagraph=function() return DummyParagraph end, CreateDropdown=function() end,
        CreateInput=function() end, CreateColorPicker=function() end,
    }
    return { CreateWindow=function() return { CreateTab=function() return DummyTab end } end }
end

local Rayfield
do
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    Rayfield = (ok and lib and lib.CreateWindow) and lib or {}
    -- Ghi đè Notify để tắt thông báo
    if Rayfield.Notify then
        Rayfield.Notify = function() end
    end
end

-- Window is global on purpose so other parts can use it
Window = Rayfield:CreateWindow({
    Name="HUB (Die of Death)",
    LoadingTitle="Loading...",
    LoadingSubtitle="by cutotoite_10",
    ConfigurationSaving={Enabled=false}
})

-- helper label maker for nametag
local function createLabel(name,parent,posY)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Parent = parent
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1,0,0.5,0)
    label.Position = UDim2.new(0,0,posY,0)
    label.TextSize = 14
    label.Font = Enum.Font.SourceSansBold
    label.TextStrokeColor3 = TextStrokeColor
    label.TextStrokeTransparency = 0
    label.TextColor3 = Color3.fromRGB(255,255,255)
    return label
end

local function setupHealthDisplay(plr, humanoid, healthLabel, cfg)
    local function update()
        if cfg.HP and cfg.Enabled then
            healthLabel.Visible = true
            healthLabel.Text = ("HP: %d/%d"):format(math.floor(humanoid.Health), humanoid.MaxHealth)
        else
            healthLabel.Visible = false
        end
    end
    update()
    connections[plr] = connections[plr] or {}
    if connections[plr].HealthChanged then
        pcall(function() connections[plr].HealthChanged:Disconnect() end)
    end
    connections[plr].HealthChanged = humanoid.HealthChanged:Connect(update)
end

local function createOrUpdateESP(plr, char)
    if not char or not char.Parent or plr == lp or unloaded then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local team = char.Parent and char.Parent.Name
    local cfg = espConfigs[team]
    if not cfg or not humanoid then return end

    local highlight = Storage:FindFirstChild(plr.Name.."_Highlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = plr.Name.."_Highlight"
        highlight.DepthMode = DepthMode
        highlight.Parent = Storage
    end
    highlight.Adornee = char
    highlight.Enabled = cfg.Enabled
    highlight.FillColor = cfg.FillColor
    highlight.OutlineColor = cfg.OutlineColor
    highlight.FillTransparency = (cfg.Fill and cfg.FillTransparency) or 1
    highlight.OutlineTransparency = (cfg.Outline and cfg.OutlineTransparency) or 1

    if hrp then
        local nametag = Storage:FindFirstChild(plr.Name.."_Nametag")
        if not nametag then
            nametag = Instance.new("BillboardGui")
            nametag.Name = plr.Name.."_Nametag"
            nametag.Size = UDim2.new(0,120,0,40)
            nametag.StudsOffset = Vector3.new(0,2.5,0)
            nametag.AlwaysOnTop = true
            nametag.Parent = Storage
            createLabel("PlayerName", nametag, 0).Text = plr.Name
            createLabel("HealthLabel", nametag, 0.5)
        end
        nametag.Adornee = hrp
        nametag.Enabled = cfg.Enabled
        local nameLabel = nametag:FindFirstChild("PlayerName")
        local healthLabel = nametag:FindFirstChild("HealthLabel")
        if nameLabel then nameLabel.Visible = cfg.Enabled and cfg.Name; nameLabel.TextColor3 = cfg.FillColor end
        if healthLabel then setupHealthDisplay(plr, humanoid, healthLabel, cfg) end
    end
end

local function onPlayerAdded(plr)
    if plr == lp then return end
    connections[plr] = connections[plr] or {}
    connections[plr].CharacterAdded = plr.CharacterAdded:Connect(function(char)
        task.wait(1)
        createOrUpdateESP(plr, char)
    end)
    if plr.Character then createOrUpdateESP(plr, plr.Character) end
end

local function onPlayerRemoving(plr)
    for _, suffix in ipairs({"_Highlight","_Nametag"}) do
        local obj = Storage:FindFirstChild(plr.Name..suffix)
        if obj then pcall(function() obj:Destroy() end) end
    end
    if connections[plr] then
        for _, conn in pairs(connections[plr]) do
            if typeof(conn) == "RBXScriptConnection" then
                pcall(function() conn:Disconnect() end)
            end
        end
        connections[plr] = nil
    end
end

mainConns.playersAdded = Players.PlayerAdded:Connect(onPlayerAdded)
mainConns.playersRemoving = Players.PlayerRemoving:Connect(onPlayerRemoving)
for _,v in ipairs(Players:GetPlayers()) do onPlayerAdded(v) end

task.spawn(function()
    while not unloaded do
        task.wait(1)
        for _,v in ipairs(Players:GetPlayers()) do
            if v ~= lp and v.Character then createOrUpdateESP(v, v.Character) end
        end
        if unloaded then break end
    end
end)

for teamName, cfg in pairs(espConfigs) do
    local tab = Window:CreateTab(teamName.." ESP", 4483362458)
    tab:CreateToggle({Name="Enable ESP", CurrentValue=cfg.Enabled, Callback=function(v) cfg.Enabled=v end})
    tab:CreateToggle({Name="Show Name", CurrentValue=cfg.Name, Callback=function(v) cfg.Name=v end})
    tab:CreateToggle({Name="Show HP", CurrentValue=cfg.HP, Callback=function(v) cfg.HP=v end})
    tab:CreateToggle({Name="Show Fill", CurrentValue=cfg.Fill, Callback=function(v) cfg.Fill=v end})
    tab:CreateColorPicker({Name="Fill Color", Color=cfg.FillColor, Callback=function(c) cfg.FillColor=c end})
    tab:CreateSlider({Name="Fill Transparency", Range={0,1}, Increment=0.05, CurrentValue=cfg.FillTransparency, Callback=function(v) cfg.FillTransparency=v end})
    tab:CreateToggle({Name="Show Outline", CurrentValue=cfg.Outline, Callback=function(v) cfg.Outline=v end})
    tab:CreateColorPicker({Name="Outline Color", Color=cfg.OutlineColor, Callback=function(c) cfg.OutlineColor=c end})
    tab:CreateSlider({Name="Outline Transparency", Range={0,1}, Increment=0.05, CurrentValue=cfg.OutlineTransparency, Callback=function(v) cfg.OutlineTransparency=v end})
end

-- Speed settings
local character = lp.Character or lp.CharacterAdded:Wait()
if character:GetAttribute("WalkSpeed") == nil then character:SetAttribute("WalkSpeed",10) end
if character:GetAttribute("SprintSpeed") == nil then character:SetAttribute("SprintSpeed",27) end
local walkSpeedValue = character:GetAttribute("WalkSpeed")
local sprintSpeedValue = character:GetAttribute("SprintSpeed")
local walkSpeedEnabled = false
local sprintEnabled = false

local tabSpeed = Window:CreateTab("Speed Settings", 4483362458)
tabSpeed:CreateSlider({Name="WalkSpeed", Range={8,200}, Increment=1, CurrentValue=walkSpeedValue, Callback=function(val) walkSpeedValue=val end})
tabSpeed:CreateToggle({Name="Enable WalkSpeed", CurrentValue=walkSpeedEnabled, Callback=function(v) walkSpeedEnabled=v; if not v and character then character:SetAttribute("WalkSpeed",10) end end})
tabSpeed:CreateSlider({Name="SprintSpeed", Range={16,300}, Increment=1, CurrentValue=sprintSpeedValue, Callback=function(val) sprintSpeedValue=val end})
tabSpeed:CreateToggle({Name="Enable Sprint", CurrentValue=sprintEnabled, Callback=function(v) sprintEnabled=v; if not v and character then character:SetAttribute("SprintSpeed",27) end end})

mainConns.renderStepped = RunService.RenderStepped:Connect(function()
    if unloaded then return end
    local char = lp.Character
    if not char then return end
    if walkSpeedEnabled and char:GetAttribute("WalkSpeed") ~= walkSpeedValue then
        char:SetAttribute("WalkSpeed", walkSpeedValue)
    end
    if sprintEnabled and char:GetAttribute("SprintSpeed") ~= sprintSpeedValue then
        char:SetAttribute("SprintSpeed", sprintSpeedValue)
    end
end)

mainConns.charAdded_speed = lp.CharacterAdded:Connect(function(char)
    character = char
    if character:GetAttribute("WalkSpeed") == nil then character:SetAttribute("WalkSpeed",walkSpeedValue) end
    if character:GetAttribute("SprintSpeed") == nil then character:SetAttribute("SprintSpeed",sprintSpeedValue) end
end)

-- Auto Block
local autoBlockEnabled = false
local blockDistance = 15
local tabBlock = Window:CreateTab("Auto Block", 4483362458)
local logLabel = tabBlock:CreateParagraph({Title="AutoBlock Log", Content="Nothing"})
tabBlock:CreateToggle({Name="Enable Auto Block", CurrentValue=autoBlockEnabled, Callback=function(v) autoBlockEnabled=v end})
tabBlock:CreateSlider({Name="Block Distance (studs)", Range={5,50}, Increment=1, CurrentValue=blockDistance, Callback=function(val) blockDistance=val end})

local function doBlock(plr,dist)
    if unloaded then return end
    pcall(function()
        if useAbilityRF then useAbilityRF:InvokeServer("Block") end
    end)
    logLabel:Set({Content="Blocked "..plr.Name.." ("..math.floor(dist).." studs)"})
end

mainConns.autoBlockHB = RunService.Heartbeat:Connect(function()
    if unloaded or not autoBlockEnabled then return end
    local myChar = lp.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    local myPos = myHRP.Position
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=lp and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local teamName = plr.Character.Parent and plr.Character.Parent.Name
            if teamName == "Killer" then
                local dist = (plr.Character.HumanoidRootPart.Position - myPos).Magnitude
                if dist <= blockDistance then doBlock(plr,dist) end
            end
        end
    end
end)
-- PART 2: Skills & Selector
-- expects Window, ReplicatedStorage, lp to already exist (tạo ở Part1)
local ReplicatedStorage = ReplicatedStorage or game:GetService("ReplicatedStorage")
local lp = lp or game:GetService("Players").LocalPlayer

local skillList = {"Revolver","Punch","Block","Caretaker","Hotdog","Taunt","Cloak","Dash","Banana","BonusPad","Adrenaline"}
local selectedSkill1, selectedSkill2 = "Revolver", "Caretaker"

local tabSkills = Window:CreateTab("Skills & Selector", 4483362458)
local skillParagraph = tabSkills:CreateParagraph({Title="Selected Skills", Content="Skill 1: "..selectedSkill1.."\nSkill 2: "..selectedSkill2})

tabSkills:CreateDropdown({Name="Select Skill 1", Options=skillList, CurrentOption={selectedSkill1}, Callback=function(opt)
    selectedSkill1 = opt[1]
    skillParagraph:Set({Content="Skill 1: "..selectedSkill1.."\nSkill 2: "..selectedSkill2})
end})

tabSkills:CreateDropdown({Name="Select Skill 2", Options=skillList, CurrentOption={selectedSkill2}, Callback=function(opt)
    selectedSkill2 = opt[1]
    skillParagraph:Set({Content="Skill 1: "..selectedSkill1.."\nSkill 2: "..selectedSkill2})
end})

tabSkills:CreateButton({Name="Select Skills", Callback=function()
    local abilitySelection = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteEvents"):WaitForChild("AbilitySelection")
    abilitySelection:FireServer({selectedSkill1, selectedSkill2})
end})

-- Skill GUI (draggable buttons)
local SkillsModule = require(ReplicatedStorage.ClientModules:WaitForChild("AbilityConfig"))
local guiStorage = lp:FindFirstChild("SkillScreenGui") or Instance.new("ScreenGui")
guiStorage.Name = "SkillScreenGui"
guiStorage.ResetOnSpawn = false
guiStorage.IgnoreGuiInset = true
guiStorage.Parent = lp:WaitForChild("PlayerGui")

local buttonConfigs = {} -- [skillName] = {size,pos}
local lastUsed = {}      -- [skillName] = os.clock()

local function makeDraggable(frame, skillName)
    local dragging, dragStart, startPos = false, Vector2.new(), frame.Position
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
    end
    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging=true; dragStart=input.Position; startPos=frame.Position
            input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false; buttonConfigs[skillName].pos={frame.Position.X.Offset,frame.Position.Y.Offset} end end)
        end
    end
    local function onInputChanged(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then update(input) end
    end
    frame.InputBegan:Connect(onInputBegan)
    frame.InputChanged:Connect(onInputChanged)
    for _, child in ipairs(frame:GetDescendants()) do
        if child:IsA("GuiObject") then
            child.InputBegan:Connect(onInputBegan)
            child.InputChanged:Connect(onInputChanged)
        end
    end
end

local function createSkillButton(skillName)
    local skillData = SkillsModule[skillName]
    if not skillData then return end
    local cfg = buttonConfigs[skillName] or {size=46,pos={100,100}}
    buttonConfigs[skillName] = cfg
    local old = guiStorage:FindFirstChild(skillName.."_Btn")
    if old then old:Destroy() end

    local btnFrame = Instance.new("Frame")
    btnFrame.Name = skillName.."_Btn"; btnFrame.Size=UDim2.new(0,cfg.size,0,cfg.size); btnFrame.Position=UDim2.new(0,cfg.pos[1],0,cfg.pos[2]); btnFrame.BackgroundTransparency=1; btnFrame.Parent=guiStorage
    local border=Instance.new("UIStroke"); border.Thickness=2; border.Color=Color3.fromRGB(198,198,198); border.Parent=btnFrame
    local innerFrame=Instance.new("Frame"); innerFrame.Size=UDim2.new(1,0,1,0); innerFrame.BackgroundColor3=Color3.fromRGB(0,0,0); innerFrame.BackgroundTransparency=0.6; innerFrame.BorderSizePixel=0; innerFrame.Parent=btnFrame
    local icon=Instance.new("ImageLabel"); icon.Size=UDim2.new(0.9,0,0.9,0); icon.Position=UDim2.new(0.5,0,0.5,0); icon.AnchorPoint=Vector2.new(0.5,0.5); icon.BackgroundTransparency=1; icon.Image=skillData.Icon or ""; icon.ScaleType=Enum.ScaleType.Fit; icon.Parent=innerFrame
    local cooldownOverlay=Instance.new("Frame"); cooldownOverlay.Size=UDim2.new(1,0,1,0); cooldownOverlay.BackgroundColor3=Color3.fromRGB(0,0,0); cooldownOverlay.BackgroundTransparency=0.6; cooldownOverlay.BorderSizePixel=0; cooldownOverlay.Visible=false; cooldownOverlay.Parent=innerFrame
    local cdLabel=Instance.new("TextLabel"); cdLabel.Size=UDim2.new(1,0,1,0); cdLabel.BackgroundTransparency=1; cdLabel.TextColor3=Color3.fromRGB(255,255,255); cdLabel.TextScaled=true; cdLabel.Font=Enum.Font.GothamBold; cdLabel.Visible=false; cdLabel.Parent=cooldownOverlay
    local button=Instance.new("TextButton"); button.Size=UDim2.new(1,0,1,0); button.BackgroundTransparency=1; button.Text=""; button.Parent=innerFrame

    button.MouseButton1Click:Connect(function()
        local cooldown = tonumber(skillData.Cooldown) or 1
        local now = os.clock()
        if not lastUsed[skillName] or now-lastUsed[skillName]>=cooldown then
            lastUsed[skillName]=now
            local remoteFunc = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteFunctions"):WaitForChild("UseAbility")
            pcall(function() remoteFunc:InvokeServer(skillName) end)
            cooldownOverlay.Visible=true; cdLabel.Visible=true
            task.spawn(function()
                local t=cooldown
                while t>0 do
                    cdLabel.Text=tostring(math.ceil(t))
                    task.wait(1)
                    t-=1
                end
                cooldownOverlay.Visible=false; cdLabel.Visible=false
            end)
        end
    end)
    makeDraggable(btnFrame, skillName)
end

local function removeSkillButton(skillName)
    local old=guiStorage:FindFirstChild(skillName.."_Btn")
    if old then old:Destroy() end
end

-- Create toggles + sliders for each skill using tabSkills
for _, skillName in ipairs(skillList) do
    local enabled=false
    tabSkills:CreateToggle({Name="Enable "..skillName, CurrentValue=false, Callback=function(v)
        enabled=v
        if v then createSkillButton(skillName) else removeSkillButton(skillName) end
    end})
    tabSkills:CreateSlider({Name=skillName.." Size", Range={40,120}, Increment=1, CurrentValue=46, Callback=function(val)
        if not buttonConfigs[skillName] then buttonConfigs[skillName]={size=val,pos={100,100}} else buttonConfigs[skillName].size=val end
        if enabled then createSkillButton(skillName) end
    end})
end
-- PART 3: Gameplay Settings + Settings
-- expects Window, RunService, lp, Workspace, Storage, connections, mainConns, unloaded exist from Part1
local RunService = RunService or game:GetService("RunService")
local lp = lp or game:GetService("Players").LocalPlayer
local Workspace = Workspace or game:GetService("Workspace")
local CoreGui = CoreGui or game:GetService("CoreGui")
local Storage = Storage or CoreGui:FindFirstChild("Highlight_Storage")

local tabGameplay = Window:CreateTab("Gameplay Settings", 4483362458)

-- WalkSpeedModifier lock
local lockWSM = true
tabGameplay:CreateToggle({Name="Lock WalkSpeedModifier", CurrentValue=lockWSM, Callback=function(v) lockWSM=v end})

-- Stamina controls
local keepStaminaEnabled = true
local customStamina = 100
local defaultStamina = (lp.Character or lp.CharacterAdded:Wait()):GetAttribute("MaxStamina") or 100

tabGameplay:CreateToggle({
    Name="Enable Custom MaxStamina",
    CurrentValue=keepStaminaEnabled,
    Callback=function(v)
        keepStaminaEnabled = v
        local ch = lp.Character
        if not ch then return end
        if not v then
            ch:SetAttribute("MaxStamina", defaultStamina)
        else
            ch:SetAttribute("MaxStamina", customStamina)
        end
    end
})

tabGameplay:CreateInput({
    Name="Custom MaxStamina (0 - 10000)",
    PlaceholderText="Nhập số...",
    RemoveTextAfterFocusLost=true,
    Callback=function(text)
        local num = tonumber(text)
        if num and num >= 0 and num <= 10000 then
            customStamina = num
            local ch = lp.Character
            if keepStaminaEnabled and ch then
                ch:SetAttribute("MaxStamina", customStamina)
            end
        else
            warn("Giá trị không hợp lệ (0 - 10000)")
        end
    end
})

mainConns.staminaHB = RunService.Heartbeat:Connect(function()
    if unloaded then return end
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if lockWSM then
        for _, obj in pairs({hum, char, lp}) do
            if obj and obj.GetAttributes then
                for name, val in pairs(obj:GetAttributes()) do
                    if typeof(name)=="string" and name:lower():find("walkspeedmodifier") then
                        if val <= 0 then obj:SetAttribute(name, 0) end
                    end
                end
            end
        end
    end

    if keepStaminaEnabled and char then
        if char:GetAttribute("MaxStamina") ~= customStamina then
            char:SetAttribute("MaxStamina", customStamina)
        end
    elseif char then
        if char:GetAttribute("MaxStamina") ~= defaultStamina then
            char:SetAttribute("MaxStamina", defaultStamina)
        end
    end
end)

mainConns.charAdded_gameplay = lp.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    if keepStaminaEnabled then
        char:SetAttribute("MaxStamina", customStamina)
    else
        char:SetAttribute("MaxStamina", defaultStamina)
    end
    if lockWSM then
        for _, obj in pairs({hum, char, lp}) do
            if obj and obj.GetAttributes then
                for name, val in pairs(obj:GetAttributes()) do
                    if typeof(name)=="string" and name:lower():find("walkspeedmodifier") then
                        if val <= 0 then obj:SetAttribute(name, 0) end
                    end
                end
            end
        end
    end
end)

-- ============================
-- Implement Fast Artful (HoldInAir)
-- ============================
tabGameplay:CreateToggle({
    Name = "Implement Fast Artful",
    CurrentValue = false,
    Callback = function(Value)
        getgenv().ImplementEnabled = Value
        if Value then
            pcall(function() HoldImpl_CheckAttributes() end)
        end
    end,
})

do
    local player = lp
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")

    local function getKillerFolder()
        local ga = Workspace:FindFirstChild("GameAssets")
        if not ga then return nil end
        local teams = ga:FindFirstChild("Teams")
        if not teams then return nil end
        return teams:FindFirstChild("Killer")
    end

    local function HoldImpl_isKiller()
        local kf = getKillerFolder()
        if not kf then return false end
        return kf:FindFirstChild(player.Name) ~= nil
    end

    local function HoldImpl_holdInAir(humanoidRootPart, duration, offsetY)
        task.spawn(function()
            if not humanoidRootPart or not humanoidRootPart.Parent then return end
            local bp = Instance.new("BodyPosition")
            bp.Position = humanoidRootPart.Position + Vector3.new(0, offsetY, 0)
            bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bp.P = 100000
            bp.D = 1000
            bp.Parent = humanoidRootPart

            task.wait(duration)
            if bp and bp.Parent then
                bp:Destroy()
            end
        end)
    end

    function HoldImpl_CheckAttributes()
        if not getgenv().ImplementEnabled then return end
        if not HoldImpl_isKiller() then return end
        if not character or not hrp then return end

        local killerName = character:GetAttribute("KillerName")
        local implementCooldown = character:GetAttribute("ImplementCooldown")
        if killerName == "Artful" and implementCooldown == true then
            HoldImpl_holdInAir(hrp, 2, 2.2)
        end
    end

    character.AttributeChanged:Connect(function(attr)
        if attr == "KillerName" or attr == "ImplementCooldown" then
            HoldImpl_CheckAttributes()
        end
    end)

    player.CharacterAdded:Connect(function(newChar)
        character = newChar
        hrp = character:WaitForChild("HumanoidRootPart")
        HoldImpl_CheckAttributes()
    end)

    local kf = getKillerFolder()
    if kf then
        kf.ChildAdded:Connect(function(child)
            if child.Name == player.Name then
                HoldImpl_CheckAttributes()
            end
        end)
        kf.ChildRemoved:Connect(function(child)
            if child.Name == player.Name then
                HoldImpl_CheckAttributes()
            end
        end)
    end
end

-- ============================
-- Settings tab
-- ============================
local tabSettings = Window:CreateTab("Settings", 4483362458)

local instantPPEnabled = true
tabSettings:CreateToggle({
    Name="Instant ProximityPrompt",
    CurrentValue=instantPPEnabled,
    Callback=function(v)
        instantPPEnabled = v
        for _, prompt in ipairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                if instantPPEnabled then prompt.HoldDuration = 0
                else prompt.HoldDuration = prompt:GetAttribute("OriginalHoldDuration") or 1 end
            end
        end
    end
})

mainConns.workspaceDescendant = Workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("ProximityPrompt") then
        if obj:GetAttribute("OriginalHoldDuration") == nil then
            obj:SetAttribute("OriginalHoldDuration", obj.HoldDuration)
        end
        if instantPPEnabled then obj.HoldDuration = 0 end
    end
end)

tabSettings:CreateButton({
    Name="Unload Script",
    Callback=function()
        if unloaded then return end
        unloaded = true

        if Storage and Storage:IsA("Instance") then
            pcall(function() Storage:ClearAllChildren() end)
        end

        -- disconnect connections table (per-player)
        for plr, conns in pairs(connections) do
            if conns then
                for k, conn in pairs(conns) do
                    if typeof(conn) == "RBXScriptConnection" then
                        pcall(function() conn:Disconnect() end)
                    end
                end
            end
            connections[plr] = nil
        end

        -- disconnect mainConns
        for k, conn in pairs(mainConns) do
            if conn and typeof(conn) == "RBXScriptConnection" then
                pcall(function() conn:Disconnect() end)
            end
            mainConns[k] = nil
        end

        local g = CoreGui:FindFirstChild("Rayfield")
        if g then pcall(function() g:Destroy() end) end

        warn("[SCRIPT] Đã Unload thành công.")
    end
})
