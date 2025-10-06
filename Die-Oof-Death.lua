--  PART 1: Load Rayfield + ESP + Speed Settings + Auto Block
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer or Players.PlayerAdded:Wait()

connections = connections or {}
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
    Rayfield = (ok and lib and lib.CreateWindow) and lib or makeFallbackRayfield()
    if Rayfield.Notify then Rayfield.Notify = function() end end
end

local Window = Rayfield:CreateWindow({
    Name="HUB (Die of Death)TY @maxiedsu/gonnered bbbbb_090909-VN",
    LoadingTitle="Loading...TY @maxiedsu/gonnered",
    LoadingSubtitle="by cutotoite_10",
    ConfigurationSaving={Enabled=false}
})

-- ========== ESP ==========
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

local function setupHealthDisplay(plr, humanoid, healthLabel)
    local function update()
        local char = plr.Character
        if not char then return end
        local team = char.Parent and char.Parent.Name
        local cfg = team and espConfigs[team]
        if cfg and cfg.HP and cfg.Enabled then
            healthLabel.Visible = true
            healthLabel.Text = ("HP: %d/%d"):format(math.floor(humanoid.Health), humanoid.MaxHealth)
        else
            healthLabel.Visible = false
        end
    end
    update()  -- Gọi lần đầu
    connections[plr] = connections[plr] or {}
    if connections[plr].HealthChanged then
        pcall(function() connections[plr].HealthChanged:Disconnect() end)
    end
    connections[plr].HealthChanged = humanoid.HealthChanged:Connect(update)
end

local function updateESPConfig(plr)
    if not plr or not plr.Character then return end
    local char = plr.Character
    local highlight = Storage:FindFirstChild(plr.Name.."_Highlight")
    local nametag = Storage:FindFirstChild(plr.Name.."_Nametag")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local team = char.Parent and char.Parent.Name
    local cfg = espConfigs[team]
    if not cfg or not humanoid then return end

    if highlight then
        highlight.Enabled = cfg.Enabled
        highlight.FillColor = cfg.FillColor
        highlight.OutlineColor = cfg.OutlineColor
        highlight.FillTransparency = (cfg.Fill and cfg.FillTransparency) or 1
        highlight.OutlineTransparency = (cfg.Outline and cfg.OutlineTransparency) or 1
    end
    if nametag then
        local nameLabel = nametag:FindFirstChild("PlayerName")
        local healthLabel = nametag:FindFirstChild("HealthLabel")
        if nameLabel then 
            nameLabel.Visible = cfg.Enabled and cfg.Name
            nameLabel.TextColor3 = cfg.FillColor
            nameLabel.Text = plr.Name  -- Set name nếu chưa có
        end
        if healthLabel then 
            healthLabel.Visible = cfg.Enabled and cfg.HP
            -- Health sẽ update qua event riêng
        end
    end
end

local function cleanupESP(plr)
    for _, suffix in ipairs({"_Highlight","_Nametag"}) do
        local obj = Storage:FindFirstChild(plr.Name..suffix)
        if obj then pcall(function() obj:Destroy() end) end
    end
    if connections[plr] and connections[plr].HealthChanged then
        pcall(function() connections[plr].HealthChanged:Disconnect() end)
        connections[plr].HealthChanged = nil
    end
end

local function createOrUpdateESP(plr, char)
    if not char or not char.Parent or plr == lp or unloaded then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local team = char.Parent and char.Parent.Name
    local cfg = espConfigs[team]
    if not cfg or not humanoid then return end

    -- Cleanup trước nếu có ESP cũ
    cleanupESP(plr)

    -- Tạo mới
    local highlight = Instance.new("Highlight")
    highlight.Name = plr.Name.."_Highlight"
    highlight.DepthMode = DepthMode
    highlight.Adornee = char
    highlight.Parent = Storage

    if not hrp then return end

    local nametag = Instance.new("BillboardGui")
    nametag.Name = plr.Name.."_Nametag"
    nametag.Size = UDim2.new(0,120,0,40)
    nametag.StudsOffset = Vector3.new(0,2.5,0)
    nametag.AlwaysOnTop = true
    nametag.Adornee = hrp
    nametag.Parent = Storage
    local nameLabel = createLabel("PlayerName", nametag, 0)
    nameLabel.Text = plr.Name
    local healthLabel = createLabel("HealthLabel", nametag, 0.5)

    -- Update config
    updateESPConfig(plr)

    -- Setup health
    setupHealthDisplay(plr, humanoid, healthLabel)

    -- Thêm connection cho Died để cleanup
    connections[plr].Died = humanoid.Died:Connect(function()
        cleanupESP(plr)
    end)

    -- Thêm connection cho CharacterRemoving (nếu character destroyed)
    connections[plr].CharacterRemoving = plr.CharacterRemoving:Connect(function()
        cleanupESP(plr)
    end)
end

local function onPlayerAdded(plr)
    if plr == lp then return end
    connections[plr] = connections[plr] or {}
    connections[plr].CharacterAdded = plr.CharacterAdded:Connect(function(char)
        task.wait(2.5)
        createOrUpdateESP(plr, char)
    end)
    if plr.Character then createOrUpdateESP(plr, plr.Character) end
end

local function onPlayerRemoving(plr)
    cleanupESP(plr)
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

-- UI với callbacks update ESP
local function updateAllESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp then updateESPConfig(plr) end
    end
end

for teamName, cfg in pairs(espConfigs) do
    local tab = Window:CreateTab(teamName.." ESP", 4483362458)
    tab:CreateToggle({
        Name="Enable ESP", 
        CurrentValue=cfg.Enabled, 
        Callback=function(v) 
            cfg.Enabled = v 
            updateAllESP()
        end
    })
    tab:CreateToggle({
        Name="Show Name", 
        CurrentValue=cfg.Name, 
        Callback=function(v) 
            cfg.Name = v 
            updateAllESP()
        end
    })
    tab:CreateToggle({
        Name="Show HP", 
        CurrentValue=cfg.HP, 
        Callback=function(v) 
            cfg.HP = v 
            updateAllESP()
        end
    })
    tab:CreateToggle({
        Name="Show Fill", 
        CurrentValue=cfg.Fill, 
        Callback=function(v) 
            cfg.Fill = v 
            updateAllESP()
        end
    })
    tab:CreateColorPicker({
        Name="Fill Color", 
        Color=cfg.FillColor, 
        Callback=function(c) 
            cfg.FillColor = c 
            updateAllESP()
        end
    })
    tab:CreateSlider({
        Name="Fill Transparency", 
        Range={0,1}, 
        Increment=0.05, 
        CurrentValue=cfg.FillTransparency, 
        Callback=function(v) 
            cfg.FillTransparency = v 
            updateAllESP()
        end
    })
    tab:CreateToggle({
        Name="Show Outline", 
        CurrentValue=cfg.Outline, 
        Callback=function(v) 
            cfg.Outline = v 
            updateAllESP()
        end
    })
    tab:CreateColorPicker({
        Name="Outline Color", 
        Color=cfg.OutlineColor, 
        Callback=function(c) 
            cfg.OutlineColor = c 
            updateAllESP()
        end
    })
    tab:CreateSlider({
        Name="Outline Transparency", 
        Range={0,1}, 
        Increment=0.05, 
        CurrentValue=cfg.OutlineTransparency, 
        Callback=function(v) 
            cfg.OutlineTransparency = v 
            updateAllESP()
        end
    })
end
-- ========== Auto-Detect & Fix ESP (Mobile Resume Fix) ==========
local UserInputService = game:GetService("UserInputService")
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local lastEspCheck = 0
local ESP_CHECK_INTERVAL = 3  -- 3 giây (thấp lag)

task.spawn(function()
    while not unloaded do
        local now = tick()
        if now - lastEspCheck < ESP_CHECK_INTERVAL then
            task.wait(0.1)
            continue
        end
        lastEspCheck = now
        
        -- Chỉ poll trên mobile hoặc nếu enabled
        if not isMobile then task.wait(ESP_CHECK_INTERVAL); continue end
        
        -- Scan và fix ESP mismatch
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == lp or not plr.Character then continue end
            local char = plr.Character
            local team = char.Parent and char.Parent.Name
            local cfg = espConfigs[team]
            if not cfg or not cfg.Enabled then continue end
            
            -- Check Highlight
            local highlight = Storage:FindFirstChild(plr.Name.."_Highlight")
            if highlight and not highlight.Enabled then
                updateESPConfig(plr)  -- Fix properties
                print("[ESP Fix] Re-enabled Highlight for " .. plr.Name)
            end
            
            -- Check Nametag
            local nametag = Storage:FindFirstChild(plr.Name.."_Nametag")
            if nametag then
                local nameLabel = nametag:FindFirstChild("PlayerName")
                local healthLabel = nametag:FindFirstChild("HealthLabel")
                if (cfg.Name and nameLabel and not nameLabel.Visible) or (cfg.HP and healthLabel and not healthLabel.Visible) then
                    updateESPConfig(plr)  -- Fix visible
                    print("[ESP Fix] Re-showed labels for " .. plr.Name)
                end
            end
            
            -- Nếu object mất hẳn, recreate
            if not highlight and not nametag then
                createOrUpdateESP(plr, char)
                print("[ESP Fix] Recreated ESP for " .. plr.Name)
            end
        end
        
        task.wait(ESP_CHECK_INTERVAL)
    end
end)
-- ========== Speed Settings (Optimized) ==========
local character = lp.Character or lp.CharacterAdded:Wait()
if character:GetAttribute("WalkSpeed") == nil then character:SetAttribute("WalkSpeed", 10) end
if character:GetAttribute("SprintSpeed") == nil then character:SetAttribute("SprintSpeed", 27) end

local walkSpeedValue = character:GetAttribute("WalkSpeed") or 10
local sprintSpeedValue = character:GetAttribute("SprintSpeed") or 27
local walkSpeedEnabled = false
local sprintEnabled = false

-- Cache cho current values để tránh set thừa
local currentWalkSpeed = walkSpeedValue
local currentSprintSpeed = sprintSpeedValue

local speedConnection = nil  -- Để disconnect khi off

local function updateSpeeds()
    if unloaded or not character then return end
    local currentWS = character:GetAttribute("WalkSpeed") or 10
    local currentSS = character:GetAttribute("SprintSpeed") or 27
    
    if walkSpeedEnabled and currentWS ~= walkSpeedValue then
        character:SetAttribute("WalkSpeed", walkSpeedValue)
        currentWalkSpeed = walkSpeedValue
    end
    if sprintEnabled and currentSS ~= sprintSpeedValue then
        character:SetAttribute("SprintSpeed", sprintSpeedValue)
        currentSprintSpeed = sprintSpeedValue
    end
end

local function startSpeedLoop()
    if speedConnection then speedConnection:Disconnect() end
    speedConnection = RunService.Heartbeat:Connect(updateSpeeds)  -- Heartbeat thay vì RenderStepped
end

local function stopSpeedLoop()
    if speedConnection then
        speedConnection:Disconnect()
        speedConnection = nil
    end
end

local tabSpeed = Window:CreateTab("Speed Settings", 4483362458)
tabSpeed:CreateSlider({
    Name="WalkSpeed", 
    Range={8,200}, 
    Increment=1, 
    CurrentValue=walkSpeedValue, 
    Callback=function(val) 
        walkSpeedValue = val 
        if walkSpeedEnabled then updateSpeeds() end  -- Update ngay nếu đang on
    end
})
tabSpeed:CreateToggle({
    Name="Enable WalkSpeed", 
    CurrentValue=walkSpeedEnabled, 
    Callback=function(v) 
        walkSpeedEnabled = v
        if v then 
            startSpeedLoop()
            updateSpeeds()  -- Set ngay
        else 
            if character then character:SetAttribute("WalkSpeed", 10) end
            stopSpeedLoop()
        end
    end
})
tabSpeed:CreateSlider({
    Name="SprintSpeed", 
    Range={16,300}, 
    Increment=1, 
    CurrentValue=sprintSpeedValue, 
    Callback=function(val) 
        sprintSpeedValue = val 
        if sprintEnabled then updateSpeeds() end  -- Update ngay nếu đang on
    end
})
tabSpeed:CreateToggle({
    Name="Enable Sprint", 
    CurrentValue=sprintEnabled, 
    Callback=function(v) 
        sprintEnabled = v
        if v then 
            startSpeedLoop()
            updateSpeeds()  -- Set ngay
        else 
            if character then character:SetAttribute("SprintSpeed", 27) end
            stopSpeedLoop()
        end
    end
})

-- Handle CharacterAdded cho speed
mainConns.charAdded_speed = lp.CharacterAdded:Connect(function(char)
    character = char
    task.wait(0.5)  -- Đợi load đầy đủ
    if character:GetAttribute("WalkSpeed") == nil then character:SetAttribute("WalkSpeed", walkSpeedValue) end
    if character:GetAttribute("SprintSpeed") == nil then character:SetAttribute("SprintSpeed", sprintSpeedValue) end
    currentWalkSpeed = walkSpeedValue
    currentSprintSpeed = sprintSpeedValue
    -- Restart loop nếu đang enabled
    if walkSpeedEnabled or sprintEnabled then
        startSpeedLoop()
    end
end)

-- Cleanup khi unload (thêm vào nếu có unload event)
-- stopSpeedLoop()

--// Auto Block+
--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local lp = Players.LocalPlayer

--// Giáº£ sá»­ Window Ä‘Ă£ Ä‘Æ°á»£c táº¡o tá»« Rayfield chĂ­nh
-- local Window = MainWindow

-- ================= AutoBlock Settings =================
local BLOCK_DISTANCE = 15
local watcherEnabled = true
local Logged = {}

-- Remote
local UseAbility = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteFunctions"):WaitForChild("UseAbility")

-- Killer Configs
-- khai bĂ¡o biáº¿n tráº¡ng thĂ¡i bĂªn ngoĂ i
-- Biáº¿n tráº¡ng thĂ¡i riĂªng cho Badware
local badwareState = {
    active = false,
    startTime = 0,
    lastWS = nil
}

local KillerConfigs = {
    ["Pursuer"] = {
        enabled = true,
        check = function(_, ws)
            local valid = {4,6,7,8,10,12,14,16,20}
            for _, v in ipairs(valid) do
                if ws == v then return true end
            end
            return false
        end
    },

    ["Artful"] = {
        enabled = true,
        check = function(_, ws)
            local valid = {4,7,8,12,16,20,9,13,17,21}
            for _, v in ipairs(valid) do
                if ws == v then return true end
            end
            return false
        end
    },

    
    ["Harken"] = {
    enabled = true,
    check = function(playerFolder, ws)
        local enraged = playerFolder:GetAttribute("Enraged")
        local seq = enraged and {7.5,10,5,13.5,17.5,21.5,25.5} or {4,7,8,12,16,20}

        -- Náº¿u AgitationCooldown báº­t thĂ¬ block luĂ´n
        if playerFolder:GetAttribute("AgitationCooldown") then
            return true
        end

        for _, v in ipairs(seq) do
            if ws == v then return true end
        end
        return false
    end
},
    ["Badware"] = {
    enabled = true,
    check = function(_, ws)
        local valid = {4,8,12,16,20}
        local function isValid(val)
            for _, v in ipairs(valid) do
                if val == v then return true end
            end
            return false
        end

        local now = tick()
        if isValid(ws) then
            -- Náº¿u báº¯t Ä‘áº§u theo dĂµi
            if not badwareState.active then
                badwareState.startTime = now
                badwareState.active = true
                badwareState.lastWS = ws
                return false
            else
                -- Náº¿u Ä‘á»•i tá»« giĂ¡ trá»‹ há»£p lá»‡ nĂ y sang giĂ¡ trá»‹ há»£p lá»‡ khĂ¡c -> tiáº¿p tá»¥c, khĂ´ng reset
                badwareState.lastWS = ws
                return false
            end
        else
            -- Náº¿u Ä‘ang active mĂ  bá»‹ tá»¥t ra ngoĂ i dĂ£y há»£p lá»‡
            if badwareState.active then
                local duration = now - badwareState.startTime
                badwareState.active = false
                badwareState.lastWS = nil
                badwareState.startTime = nil

                if duration < 0.3 then
                    return true   -- block vĂ¬ tá»¥t quĂ¡ sá»›m
                else
                    return false  -- khĂ´ng block vĂ¬ giá»¯ Ä‘á»§ lĂ¢u
                end
            end
        end
        return false
    end
},
    ["Killdroid"] = {
        enabled = true,
        check = function(_, ws)
            local valid = {-4,0,4,12,16,20}
            for _, v in ipairs(valid) do
                if ws == v then return true end
            end
            return false
        end
    }
}
-- Helpers
local function sendBlock()
    UseAbility:InvokeServer("Block")
end

local function getWalkSpeedModifier(killer)
    return killer:GetAttribute("WalkSpeedModifier") or 0
end

local function getDistanceFromPlayer(killer)
    if killer:FindFirstChild("HumanoidRootPart") and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        return (killer.HumanoidRootPart.Position - lp.Character.HumanoidRootPart.Position).Magnitude
    end
    return math.huge
end

local function checkAndBlock(killer)
    if not watcherEnabled or not killer then return end
    local ws = getWalkSpeedModifier(killer)
    local name = killer:GetAttribute("KillerName")
    if not name then return end
    local config = KillerConfigs[name]
    if not config or not config.enabled then return end
    if getDistanceFromPlayer(killer) > BLOCK_DISTANCE then return end
    if config.check(killer, ws) then
        sendBlock()
        Logged[killer] = Logged[killer] or {}
        if not Logged[killer][ws] then
            print("[AutoBlock] "..name.." ("..killer.Name..") WalkSpeedModifier = "..ws.." -> blocked")
            Logged[killer][ws] = true
            task.delay(3, function() Logged[killer][ws] = nil end)
        end
    end
end

local function monitorKiller(killer)
    if not killer then return end
    checkAndBlock(killer)
    if not killer:GetAttribute("__AB_CONNECTED") then
        killer:SetAttribute("__AB_CONNECTED", true)
        killer.AttributeChanged:Connect(function(attr)
            if attr == "WalkSpeedModifier" or attr == "KillerName" or attr == "Enraged" then
                checkAndBlock(killer)
            end
        end)
    end
end

-- Monitor existing and new killers
local killersFolder = Workspace:WaitForChild("GameAssets"):WaitForChild("Teams"):WaitForChild("Killer")
for _, killer in pairs(killersFolder:GetChildren()) do monitorKiller(killer) end
killersFolder.ChildAdded:Connect(monitorKiller)
-- UI Toggle (nếu có Window từ Rayfield)
-- local autoBlockTab = Window:CreateTab("AutoBlock", 4483362458)
-- autoBlockTab:CreateToggle({Name="Enable AutoBlock", CurrentValue=true, Callback=function(v) watcherEnabled = v end})
-- autoBlockTab:CreateSlider({Name="Block Distance", Range={5,30}, Increment=1, CurrentValue=BLOCK_DISTANCE, Callback=function(v) BLOCK_DISTANCE = v end})

-- Global cleanup (thêm vào unloadScript trước)
-- for killer, _ in pairs(killerPolls) do stopKillerPoll(killer) end
-- cache = {}; Logged = {}; lastBlockPerKiller = {}      
-- ================= Cooldown GUI =================
-- Tạo GUI Cooldown (chỉ 1 lần)
local CooldownGUI = Instance.new("ScreenGui")
CooldownGUI.Name = "AutoBlockCooldown"
CooldownGUI.ResetOnSpawn = false
CooldownGUI.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local CooldownFrame = Instance.new("Frame")
CooldownFrame.Size = UDim2.new(0,65,0,25)
CooldownFrame.Position = UDim2.new(1,-5,0,-50)
CooldownFrame.AnchorPoint = Vector2.new(1,0)
CooldownFrame.BackgroundTransparency = 1
CooldownFrame.Parent = CooldownGUI

local cooldownLabel = Instance.new("TextLabel")
cooldownLabel.Size = UDim2.new(1,0,1,0)
cooldownLabel.BackgroundTransparency = 1
cooldownLabel.TextColor3 = Color3.fromRGB(0,255,0)
cooldownLabel.Font = Enum.Font.SourceSansBold
cooldownLabel.TextScaled = true
cooldownLabel.Text = "Ready"
cooldownLabel.Parent = CooldownFrame

-- ================= Kéo Thả GUI Cooldown (Ready / On Cooldown) =================
local UserInputService = game:GetService("UserInputService")
-- Biến hỗ trợ drag
local dragging = false
local dragInput, startPos, frameStart

-- Hàm cập nhật vị trí frame
local function updatePosition(delta)
    if frameStart then
        CooldownFrame.Position = UDim2.new(
            frameStart.X.Scale,
            frameStart.X.Offset + delta.X,
            frameStart.Y.Scale,
            frameStart.Y.Offset + delta.Y
        )
    end
end

-- Bắt đầu kéo (Mouse hoặc Touch)
local function inputBegan(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragInput = input
        startPos = input.Position
        frameStart = CooldownFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                dragInput = nil
            end
        end)
    end
end

-- Cập nhật khi di chuyển chuột hoặc touch
local function inputChanged(input)
    if input == dragInput and dragging then
        local delta = input.Position - startPos
        updatePosition(delta)
    end
end

-- Kết nối sự kiện
CooldownFrame.InputBegan:Connect(inputBegan)
CooldownFrame.InputChanged:Connect(inputChanged)
UserInputService.InputChanged:Connect(inputChanged)

-- ================= Tích hợp vị trí lưu trữ =================
CooldownFrame:GetAttributeChangedSignal("Position"):Connect(function()
    frameStart = CooldownFrame.Position
end)
-- ================= Rayfield GUI Tab =================
local tabAutoBlock = Window:CreateTab("AutoBlock", 4483362458)

-- Delete Block (Animation)
-- Biến toggle
local removeAnimEnabled = false
tabAutoBlock:CreateToggle({
    Name = "Delete Block (Animation)",
    CurrentValue = removeAnimEnabled,
    Callback = function(v)
        removeAnimEnabled = v
    end
})

-- Vòng lặp xóa animation (gắn với biến removeAnimEnabled)
task.spawn(function()
    while true do
        task.wait(0.1)
        if removeAnimEnabled and lp.Character then
            local humanoid = lp.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
                    -- Nếu đúng animation ID thì stop
                    if track.Animation and tostring(track.Animation.AnimationId):match("134233326423882") then
                        track:Stop()
                    end
                end
            end
        end
    end
end)

-- Show Cooldown toggle
local showCooldown = true
tabAutoBlock:CreateToggle({
    Name = "Show Cooldown",
    CurrentValue = showCooldown,
    Callback = function(v)
        showCooldown = v
        CooldownGUI.Enabled = v
    end
})

-- Killer toggles
for killerName, cfg in pairs(KillerConfigs) do
    tabAutoBlock:CreateToggle({
        Name = "Enable "..killerName,
        CurrentValue = cfg.enabled,
        Callback = function(val) cfg.enabled = val end
    })
end

-- Block distance slider
tabAutoBlock:CreateSlider({
    Name = "Block Distance",
    Range = {5,50},
    Increment = 1,
    CurrentValue = BLOCK_DISTANCE,
    Callback = function(val) BLOCK_DISTANCE = val end,
    Suffix = "studs"
})

-- ================= Loops =================
-- Delete animation loop
task.spawn(function()
    while true do
        task.wait(0.1)
        if removeAnimEnabled and lp.Character then
            local humanoid = lp.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
                    if track.Animation and tostring(track.Animation.AnimationId):match("134233326423882") then
                        track:Stop()
                    end
                end
            end
        end
    end
end)

-- Cooldown check loop
RunService.Heartbeat:Connect(function()
    local survivorFolder = Workspace:FindFirstChild("GameAssets")
        and Workspace.GameAssets:FindFirstChild("Teams")
        and Workspace.GameAssets.Teams:FindFirstChild("Survivor")
        and Workspace.GameAssets.Teams.Survivor:FindFirstChild(lp.Name)

    local killersFolderCheck = Workspace:FindFirstChild("GameAssets")
        and Workspace.GameAssets:FindFirstChild("Teams")
        and Workspace.GameAssets.Teams:FindFirstChild("Killer")

    if killersFolderCheck and lp.Name then
        local inKiller = killersFolderCheck:FindFirstChild(lp.Name) ~= nil
        watcherEnabled = not inKiller and (survivorFolder ~= nil)
    end

    if survivorFolder then
        local onCD = survivorFolder:GetAttribute("BlockCooldown")
        if onCD then
            cooldownLabel.Text = "On Cooldown"
            cooldownLabel.TextColor3 = Color3.fromRGB(255,0,0)
        else
            cooldownLabel.Text = "Ready"
            cooldownLabel.TextColor3 = Color3.fromRGB(0,255,0)
        end
    end
end)

-- PART 2: Skills & Selector
-- expects Window, ReplicatedStorage, lp to already exist (tạo ở Part 1)
local ReplicatedStorage = ReplicatedStorage or game:GetService("ReplicatedStorage")
local lp = lp or game:GetService("Players").LocalPlayer

local skillList = {"Revolver","Punch","Block","Caretaker","Hotdog","Taunt","Cloak","Dash","Banana","BonusPad","Adrenaline"}
local selectedSkill1, selectedSkill2 = "Revolver", "Caretaker"

-- Tab GUI
local tabSkills = Window:CreateTab("Skills & Selector", 4483362458)
local skillParagraph = tabSkills:CreateParagraph({
    Title = "Selected Skills",
    Content = "Skill 1: "..selectedSkill1.."\nSkill 2: "..selectedSkill2
})

-- Dropdowns
tabSkills:CreateDropdown({
    Name = "Select Skill 1",
    Options = skillList,
    CurrentOption = {selectedSkill1},
    Callback = function(opt)
        selectedSkill1 = opt[1]
        skillParagraph:Set({Content="Skill 1: "..selectedSkill1.."\nSkill 2: "..selectedSkill2})
    end
})

tabSkills:CreateDropdown({
    Name = "Select Skill 2",
    Options = skillList,
    CurrentOption = {selectedSkill2},
    Callback = function(opt)
        selectedSkill2 = opt[1]
        skillParagraph:Set({Content="Skill 1: "..selectedSkill1.."\nSkill 2: "..selectedSkill2})
    end
})

-- Button to select skills
tabSkills:CreateButton({
    Name = "Select Skills",
    Callback = function()
        local abilitySelection = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteEvents"):WaitForChild("AbilitySelection")
        abilitySelection:FireServer({selectedSkill1, selectedSkill2})
    end
})

-- Skill GUI (draggable buttons)
local SkillsModule = require(ReplicatedStorage.ClientModules:WaitForChild("AbilityConfig"))
local guiStorage = lp:FindFirstChild("SkillScreenGui") or Instance.new("ScreenGui")
guiStorage.Name = "SkillScreenGui"
guiStorage.ResetOnSpawn = false
guiStorage.IgnoreGuiInset = true
guiStorage.Parent = lp:WaitForChild("PlayerGui")

local buttonConfigs = {} -- [skillName] = {size,pos}
local lastUsed = {}      -- [skillName] = os.clock()

-- Make GUI draggable
local function makeDraggable(frame, skillName)
    local dragging, dragStart, startPos = false, Vector2.new(), frame.Position

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
    end

    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    buttonConfigs[skillName].pos = {frame.Position.X.Offset, frame.Position.Y.Offset}
                end
            end)
        end
    end

    local function onInputChanged(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            update(input)
        end
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

-- Create skill button
local function createSkillButton(skillName)
    local skillData = SkillsModule[skillName]
    if not skillData then return end

    local cfg = buttonConfigs[skillName] or {size=46,pos={100,100}}
    buttonConfigs[skillName] = cfg

    local old = guiStorage:FindFirstChild(skillName.."_Btn")
    if old then old:Destroy() end

    -- Frame & visuals
    local btnFrame = Instance.new("Frame")
    btnFrame.Name = skillName.."_Btn"
    btnFrame.Size = UDim2.new(0,cfg.size,0,cfg.size)
    btnFrame.Position = UDim2.new(0,cfg.pos[1],0,cfg.pos[2])
    btnFrame.BackgroundTransparency = 1
    btnFrame.Parent = guiStorage

    local border = Instance.new("UIStroke")
    border.Thickness = 2
    border.Color = Color3.fromRGB(197,197,197)
    border.Parent = btnFrame

    local innerFrame = Instance.new("Frame")
    innerFrame.Size = UDim2.new(1,0,1,0)
    innerFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
    innerFrame.BackgroundTransparency = 0.5
    innerFrame.BorderSizePixel = 0
    innerFrame.Parent = btnFrame

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0.9,0,0.9,0)
    icon.Position = UDim2.new(0.5,0,0.5,0)
    icon.AnchorPoint = Vector2.new(0.5,0.5)
    icon.BackgroundTransparency = 1
    icon.Image = skillData.Icon or ""
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = innerFrame

    local cooldownOverlay = Instance.new("Frame")
    cooldownOverlay.Size = UDim2.new(1,0,1,0)
    cooldownOverlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
    cooldownOverlay.BackgroundTransparency = 0.6
    cooldownOverlay.BorderSizePixel = 0
    cooldownOverlay.Visible = false
    cooldownOverlay.Parent = innerFrame

    local cdLabel = Instance.new("TextLabel")
    cdLabel.Size = UDim2.new(1,0,1,0)
    cdLabel.BackgroundTransparency = 1
    cdLabel.TextColor3 = Color3.fromRGB(255,255,255)
    cdLabel.TextScaled = true
    cdLabel.Font = Enum.Font.GothamBold
    cdLabel.Visible = false
    cdLabel.Parent = cooldownOverlay

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1,0,1,0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = innerFrame

    -- Button click
    button.MouseButton1Click:Connect(function()
        local cooldown = tonumber(skillData.Cooldown) or 1
        local now = os.clock()
        if not lastUsed[skillName] or now - lastUsed[skillName] >= cooldown then
            lastUsed[skillName] = now
            local remoteFunc = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteFunctions"):WaitForChild("UseAbility")
            pcall(function() remoteFunc:InvokeServer(skillName) end)
            cooldownOverlay.Visible = true
            cdLabel.Visible = true

            task.spawn(function()
                local t = cooldown
                while t > 0 do
                    cdLabel.Text = tostring(math.ceil(t))
                    task.wait(1)
                    t -= 1
                end
                cooldownOverlay.Visible = false
                cdLabel.Visible = false
            end)
        end
    end)

    makeDraggable(btnFrame, skillName)
end

-- Remove skill button
local function removeSkillButton(skillName)
    local old = guiStorage:FindFirstChild(skillName.."_Btn")
    if old then old:Destroy() end
end

-- Create toggles + sliders for each skill
for _, skillName in ipairs(skillList) do
    local enabled = false

    tabSkills:CreateToggle({
        Name = "Enable "..skillName,
        CurrentValue = false,
        Callback = function(v)
            enabled = v
            if v then
                createSkillButton(skillName)
            else
                removeSkillButton(skillName)
            end
        end
    })

    tabSkills:CreateSlider({
        Name = skillName.." Size",
        Range = {40,120},
        Increment = 1,
        CurrentValue = 46,
        Callback = function(val)
            if not buttonConfigs[skillName] then
                buttonConfigs[skillName] = {size=val,pos={100,100}}
            else
                buttonConfigs[skillName].size = val
            end
            if enabled then createSkillButton(skillName) end
        end
    })
end
-- PART 3: Gameplay Settings + AntiWalls + Implement Fast Artful (Rayfield GUI + AntiAnim + Other Tab)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer
local Storage = CoreGui:FindFirstChild("Highlight_Storage")

-- Khai bĂ¡o máº·c Ä‘á»‹nh trĂ¡nh nil
mainConns = mainConns or {}
unloaded = unloaded or false
connections = connections or {}

-- Tab GUI
local tabGameplay = Window:CreateTab("Gameplay Settings", 4483362458)

-- ============================
-- WalkSpeed Modifier Lock
-- ============================
local lockWSM = true
tabGameplay:CreateToggle({
    Name="Lock WalkSpeedModifier",
    CurrentValue=lockWSM,
    Callback=function(v) lockWSM=v end
})

-- ============================
-- Stamina Controls
-- ============================
-- 🧩 Custom MaxStamina System (Tối ưu - 5 giây kiểm tra 1 lần)

local keepStaminaEnabled = true
local customStamina = 100
lp.CharacterAdded:Wait()
local defaultStamina = ((lp.Character or lp.CharacterAdded:Wait()):GetAttribute("MaxStamina")) or 100


-- ⚙️ Tab GUI (giả định bạn có tabGameplay)
tabGameplay:CreateToggle({
    Name = "Enable Custom MaxStamina",
    CurrentValue = keepStaminaEnabled,
    Callback = function(v)
        keepStaminaEnabled = v
        local ch = lp.Character
        if ch then
            ch:SetAttribute("MaxStamina", v and customStamina or defaultStamina)
        end
    end
})

tabGameplay:CreateInput({
    Name = "Custom MaxStamina (0-999999)",
    PlaceholderText = "Nhập số...",
    RemoveTextAfterFocusLost = true,
    Callback = function(text)
        local num = tonumber(text)
        if num and num >= 0 and num <= 999999 then
            customStamina = num
            if keepStaminaEnabled and lp.Character then
                lp.Character:SetAttribute("MaxStamina", customStamina)
            end
        else
            warn("Giá trị không hợp lệ (0-999999)")
        end
    end
})

-- Kiểm tra định kỳ 5 giây/lần thay vì mỗi frame
task.spawn(function()
    while task.wait(5) do
        if unloaded then break end

        local char = lp.Character
        if not char then continue end

        local current = char:GetAttribute("MaxStamina")

        if keepStaminaEnabled then
            if current ~= customStamina then
                char:SetAttribute("MaxStamina", customStamina)
            end
        else
            if current ~= defaultStamina then
                char:SetAttribute("MaxStamina", defaultStamina)
            end
        end

        if lockWSM then
            local wsm = char:GetAttribute("WalkSpeedModifier")
            if wsm and wsm < 0 then
                char:SetAttribute("WalkSpeedModifier", 0)
            end
        end
    end
end)

-- 🔁 Khi nhân vật respawn, tự gán lại stamina
mainConns.charAdded_gameplay = lp.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end

    task.defer(function()
        if keepStaminaEnabled then
            char:SetAttribute("MaxStamina", customStamina)
        else
            char:SetAttribute("MaxStamina", defaultStamina)
        end
    end)

    if lockWSM then
        task.defer(function()
            local attrs = char:GetAttributes()
            for name, val in pairs(attrs) do
                if typeof(name) == "string" and name:lower():find("walkspeedmodifier") then
                    if val <= 0 then char:SetAttribute(name, 0) end
                end
            end
        end)
    end
end)

-- ============================
-- AntiWalls
-- ============================
local AntiWalls = false
tabGameplay:CreateToggle({
    Name="Anti-Artful Walls",
    CurrentValue=AntiWalls,
    Callback=function(v) AntiWalls=v end
})

local function HandleWallPart(part)
    if part and part.Name=="HumanoidRootPart" and part.Anchored==true then
        part.CanCollide=false
        part.CanTouch=false
        part.Transparency=0.5
    end
end

task.spawn(function()
    while true do
        task.wait(0.2)
        if AntiWalls and Workspace:FindFirstChild("GameAssets") then
            local teams = Workspace.GameAssets:FindFirstChild("Teams")
            if teams and teams:FindFirstChild("Other") then
                for _, desc in pairs(teams.Other:GetDescendants()) do
                    HandleWallPart(desc)
                end
            end
        end
    end
end)

local otherTeamFolder = Workspace:WaitForChild("GameAssets"):WaitForChild("Teams"):WaitForChild("Other")
otherTeamFolder.DescendantAdded:Connect(function(desc)
    if AntiWalls then HandleWallPart(desc) end
end)

-- ============================
-- Implement Fast Artful
-- ============================
getgenv().ImplementEnabled=false
local canTrigger=true

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
    return kf:FindFirstChild(lp.Name)~=nil
end

local function HoldImpl_holdInAir(duration,offsetY)
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not hrp.Parent then return end
    local bp = Instance.new("BodyPosition")
    bp.Position = hrp.Position + Vector3.new(0,offsetY,0)
    bp.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
    bp.P = 100000
    bp.D = 1000
    bp.Parent = hrp
    task.spawn(function()
        task.wait(duration)
        if bp and bp.Parent then bp:Destroy() end
    end)
end

local function HoldImpl_CheckAttributes()
    if not getgenv().ImplementEnabled then return end
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hrp then return end
    if not HoldImpl_isKiller() then return end

    local killerName = char:GetAttribute("KillerName")
    local implementCooldown = char:GetAttribute("ImplementCooldown")

    if killerName=="Artful" and canTrigger and (implementCooldown==true or (type(implementCooldown)=="number" and implementCooldown>0)) then
        HoldImpl_holdInAir(2,2.5)
        canTrigger=false
    end

    if implementCooldown==false or implementCooldown==0 then canTrigger=true end
end

mainConns.implementHB = RunService.Heartbeat:Connect(HoldImpl_CheckAttributes)
lp.CharacterAdded:Connect(function() canTrigger=true end)

tabGameplay:CreateToggle({
    Name="Implement Fast Artful",
    CurrentValue=getgenv().ImplementEnabled,
    Callback=function(v)
        getgenv().ImplementEnabled=v
        if v then HoldImpl_CheckAttributes() end
    end
})
-- Cập nhật KillerFolder khi cấu trúc Workspace thay đổi
updateKillerFolder()
Workspace.ChildAdded:Connect(updateKillerFolder)
Workspace.ChildRemoved:Connect(updateKillerFolder)
if Workspace:FindFirstChild("GameAssets") then
    Workspace.GameAssets.ChildAdded:Connect(updateKillerFolder)
    Workspace.GameAssets.ChildRemoved:Connect(updateKillerFolder)
end

-- Theo dõi thay đổi thuộc tính
mainConns.implementHB = lp:GetAttributeChangedSignal("KillerName"):Connect(function()
    if not getgenv().ImplementEnabled then return end
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hrp or not HoldImpl_isKiller() then return end

    local killerName = char:GetAttribute("KillerName")
    local implementCooldown = char:GetAttribute("ImplementCooldown")

    if killerName == "Artful" and canTrigger and (implementCooldown == true or (type(implementCooldown) == "number" and implementCooldown > 0)) then
        HoldImpl_holdInAir(2, 2.5)
        canTrigger = false
    end

    if implementCooldown == false or implementCooldown == 0 then
        canTrigger = true
    end
end)

mainConns.implementCooldown = lp:GetAttributeChangedSignal("ImplementCooldown"):Connect(function()
    if not getgenv().ImplementEnabled then return end
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hrp or not HoldImpl_isKiller() then return end

    local killerName = char:GetAttribute("KillerName")
    local implementCooldown = char:GetAttribute("ImplementCooldown")

    if killerName == "Artful" and canTrigger and (implementCooldown == true or (type(implementCooldown) == "number" and implementCooldown > 0)) then
        HoldImpl_holdInAir(2, 2.5)
        canTrigger = false
    end

    if implementCooldown == false or implementCooldown == 0 then
        canTrigger = true
    end
end)

-- Reset canTrigger khi nhân vật respawn
lp.CharacterAdded:Connect(function()
    canTrigger = true
end)

-- Toggle cho Implement Fast Artful
tabGameplay:CreateToggle({
    Name = "Implement Fast Artful",
    CurrentValue = getgenv().ImplementEnabled,
    Callback = function(v)
        getgenv().ImplementEnabled = v
        if v then
            -- Kiểm tra ngay lập tức khi bật toggle
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if char and hrp and HoldImpl_isKiller() then
                local killerName = char:GetAttribute("KillerName")
                local implementCooldown = char:GetAttribute("ImplementCooldown")
                if killerName == "Artful" and canTrigger and (implementCooldown == true or (type(implementCooldown) == "number" and implementCooldown > 0)) then
                    HoldImpl_holdInAir(2, 2.5)
                    canTrigger = false
                end
            end
        end
    end
})

-- ============================
-- Settings Tab + Instant ProximityPrompt + Unload Script
-- ============================
local tabSettings = Window:CreateTab("Settings",4483362458)
local instantPPEnabled = true
local proximityPrompts = {} -- Lưu trữ danh sách các ProximityPrompt

-- Hàm cập nhật HoldDuration cho tất cả ProximityPrompt
local function updateProximityPrompts()
    for prompt, _ in pairs(proximityPrompts) do
        if prompt and prompt:IsA("ProximityPrompt") then
            if instantPPEnabled then
                prompt.HoldDuration = 0
            else
                prompt.HoldDuration = prompt:GetAttribute("OriginalHoldDuration") or 1
            end
        end
    end
end

-- Hàm xử lý ProximityPrompt mới
local function handleProximityPrompt(prompt)
    if prompt:IsA("ProximityPrompt") then
        if prompt:GetAttribute("OriginalHoldDuration") == nil then
            prompt:SetAttribute("OriginalHoldDuration", prompt.HoldDuration)
        end
        proximityPrompts[prompt] = true -- Thêm vào danh sách
        if instantPPEnabled then
            prompt.HoldDuration = 0
        end
        -- Kết nối sự kiện AncestryChanged để dọn dẹp
        prompt.AncestryChanged:Connect(function()
            if not prompt:IsDescendantOf(Workspace) then
                proximityPrompts[prompt] = nil
            end
        end)
    end
end

-- Khởi tạo: Tìm tất cả ProximityPrompt trong Workspace.GameAssets.Teams.Other
local otherFolder = Workspace:WaitForChild("GameAssets", 5)
    and Workspace.GameAssets:WaitForChild("Teams", 5)
    and Workspace.GameAssets.Teams:WaitForChild("Other", 5)

if otherFolder then
    for _, obj in pairs(otherFolder:GetDescendants()) do
        handleProximityPrompt(obj)
    end
    -- Theo dõi các ProximityPrompt mới trong Other
    mainConns.workspaceDescendant = otherFolder.DescendantAdded:Connect(handleProximityPrompt)
else
    warn("[InstantPP] Không tìm thấy Workspace.GameAssets.Teams.Other, không giám sát ProximityPrompt")
end

-- Toggle cho Instant ProximityPrompt
tabSettings:CreateToggle({
    Name = "Instant ProximityPrompt",
    CurrentValue = instantPPEnabled,
    Callback = function(v)
        instantPPEnabled = v
        updateProximityPrompts() -- Cập nhật tất cả ProximityPrompt hiện có
    end
})

tabSettings:CreateButton({
    Name="Unload Script",
    Callback=function()
        if unloaded then return end
        unloaded=true

        if Storage and Storage:IsA("Instance") then
            pcall(function() Storage:ClearAllChildren() end)
        end

        for plr,conns in pairs(connections) do
            if conns then
                for _,conn in pairs(conns) do
                    if typeof(conn)=="RBXScriptConnection" then pcall(function() conn:Disconnect() end) end
                end
            end
            connections[plr]=nil
        end

        for k,conn in pairs(mainConns) do
            if conn and typeof(conn)=="RBXScriptConnection" then pcall(function() conn:Disconnect() end) end
            mainConns[k]=nil
        end

        local g = CoreGui:FindFirstChild("Rayfield")
        if g then pcall(function() g:Destroy() end) end

        warn("[SCRIPT] ÄĂ£ Unload thĂ nh cĂ´ng.")
    end
})

-- ============================
-- Tab Animation (Change Animation)
-- ============================
local animationTab = Window:CreateTab("Animation", 4483362458)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local selectedAnimation = "Old" -- máº·c Ä‘á»‹nh

-- Dá»¯ liá»‡u Animation Old / New
local animationSets = {
    Old = {
        Adrenaline = "77399794134778",
        AdrenalineEnd = "108799715147231",
        Banana = "95775571866935",
        BlockLand = "94027412516651",
        BlockStart = "100651795910153",
        Caretaker = "136588017093606",
        CloakEnd = "120142279051418",
        CloakStart = "117841747115136",
        Dash = "82265255195607",
        DynamiteHold = "137091713941325",
        DynamiteThrow = "99551865645121",
        DynamiteWindup = "133960279206605",
        Hotdog = "93503428349113",
        PadBuild = "82160380573308",
        Punch = "135619604085485",
        Revolver = "73034688541555",
        RevolverReload = "79026181033717",
        Taunt = "113732291990231"
    },
    New = {
        Adrenaline = "77399794134778",
        AdrenalineEnd = "92333601998082",
        Banana = "95775571866935",
        BlockLand = "94027412516651",
        BlockStart = "134233326423882",
        Caretaker = "128767098320893",
        CloakEnd = "120142279051418",
        CloakStart = "133960698072483",
        Dash = "78278813483757",
        DynamiteHold = "137091713941325",
        DynamiteThrow = "99551865645121",
        DynamiteWindup = "133960279206605",
        Hotdog = "78595119178919",
        PadBuild = "79104831518074",
        Punch = "124781750889573",
        Revolver = "74108653904830",
        RevolverReload = "79026181033717",
        Taunt = "113732291990231"
    }
}

-- HĂ m láº¥y folder Abilities
local function getAbilitiesFolder()
    local playerName = LocalPlayer.Name
    local abilitiesFolder

    local survivorPath = workspace:FindFirstChild("GameAssets")
        and workspace.GameAssets:FindFirstChild("Teams")
        and workspace.GameAssets.Teams:FindFirstChild("Survivor")
        and workspace.GameAssets.Teams.Survivor:FindFirstChild(playerName)

    if survivorPath and survivorPath:FindFirstChild("Animations") and survivorPath.Animations:FindFirstChild("Abilities") then
        abilitiesFolder = survivorPath.Animations.Abilities
    end

    if not abilitiesFolder then
        local localModel = workspace:FindFirstChild(playerName)
        if localModel and localModel:GetChildren()[13] and localModel:GetChildren()[13]:FindFirstChild("Abilities") then
            abilitiesFolder = localModel:GetChildren()[13].Abilities
        end
    end

    return abilitiesFolder
end

-- HĂ m thay Animation
local function replaceAnimations(animationSet)
    local abilitiesFolder = getAbilitiesFolder()
    if not abilitiesFolder then
        warn("[â ï¸] KhĂ´ng tĂ¬m tháº¥y folder Abilities!")
        return
    end

    for name, id in pairs(animationSet) do
        local anim = abilitiesFolder:FindFirstChild(name)
        if anim and anim:IsA("Animation") then
            anim.AnimationId = "rbxassetid://" .. id
        end
        task.wait(0.05)
    end
end

-- NĂºt Anim Skill Old
animationTab:CreateButton({
    Name = "Anim Skill Old",
    Callback = function()
        selectedAnimation = "Old"
        replaceAnimations(animationSets.Old)
    end
})

-- NĂºt Anim Skill New
animationTab:CreateButton({
    Name = "Anim Skill New",
    Callback = function()
        selectedAnimation = "New"
        replaceAnimations(animationSets.New)
    end
})

-- Respawn tá»± Ä‘á»™ng Ă¡p dá»¥ng animation
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if animationSets[selectedAnimation] then
        replaceAnimations(animationSets[selectedAnimation])
    end
end)

-- ============================
-- Other Tab (Loadstring)
-- ============================
local tabOther = Window:CreateTab("Other", 4483362458)

tabOther:CreateButton({
    Name="Change Animation V2",
    Callback=function()
        -- Load vĂ  cháº¡y script tá»« URL
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://gist.githubusercontent.com/tranvanxanh0502-afk/be6bf6dc9e3f5c2beb438418277af445/raw/d66fc9b710a26454b5eb1787f1b79bc00024ecb0/I%2520am%2520not%2520the%2520owner,%2520just%2520an%2520update"))()
        end)
        if not success then
            warn("[Other Tab] KhĂ´ng thá»ƒ load script: "..tostring(err))
        else
            print("[Other Tab] Script Ä‘Ă£ Ä‘Æ°á»£c load thĂ nh cĂ´ng!")
        end
    end
})
